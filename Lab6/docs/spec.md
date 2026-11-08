# What we're building

A 3×3 matrix multiplier, `C = A × B`. Nine processing elements (PEs) in a grid. Every number is an 8-bit CFloat8 float. The only graded file is `rtl/matrix.v`, module `Matrix`. Don't change its ports. The PDF is the source of truth; this page is the short version.

## Number format

8 bits: 1 sign, 4 exponent (`E`), 3 fraction (`F`). The 6-bit `bias` comes in on a port.

- If `E != 0`: value = ±(1 + F/8) × 2^(E − bias). Example at bias 10: `50` = +1.0, `D4` = −1.5.
- If `E == 0`: the value is zero. Both `00` and `80` count as zero when they come in.

Rules for every multiply and every add:
- Round the exact result to 3 fraction bits, nearest, ties to even.
- Round the multiply and the add separately. Never combine them.
- Too big (exponent over 15): `7F` if positive, `FF` if negative.
- Zero results are always `00`, never `80`.
- Too small (exponent 0 or less): the lab never tests this. Use `00`.
- Only biases 9 to 12 are tested.

## Multiplier

Inputs `a`, `b`, `bias`. Output `p`. No clock.

1. If `a` or `b` is zero, `p = 00`.
2. Sign is `a[7] ^ b[7]`.
3. Multiply the mantissas `{1,Fa}` and `{1,Fb}` (4 bits each). The product is 8 bits.
4. Exponent = `Ea + Eb − bias`, plus 1 if product bit 7 is set. Use a signed exponent wide enough for negatives (8 bits is plenty).
5. If product bit 7 is set: fraction = bits [6:4], guard = bit 3, sticky = bits [2:0] OR'd. Otherwise fraction = bits [5:3], guard = bit 2, sticky = bits [1:0] OR'd.
6. Round up if `guard && (sticky || lowest fraction bit)`. If the fraction wraps from 111 to 000, add 1 to the exponent.
7. Apply the too-big and too-small rules above.

## Adder

Inputs `acc`, `p`, `bias`. Output `acc_next`. No clock. This is the hard one.

1. If one input is zero, the answer is the other one. If both are zero, `00`.
2. Put the bigger magnitude first (compare the 7 bits `{E,F}`). The exponent difference `d` is 0 to 15.
3. Shift the smaller mantissa `{1,F}` right by `d`. Don't lose the shifted-out bits, you need them for rounding. Two ways:
   - keep 3 extra bits (guard, round, sticky), or
   - shift the bigger one left by `d` instead, so nothing is lost. About 19 bits wide, but easier to get right.
4. Same sign: add. Different signs: subtract the smaller from the bigger. The result's sign is the bigger one's sign.
5. Normalize. If there's a carry out, shift right and add 1 to the exponent. If bits cancelled, shift left until the leading 1 is back and subtract the shift from the exponent.
6. Round the same way as the multiplier. Equal magnitudes with opposite signs give `00`.
7. Apply the too-big and too-small rules above.

## Examples to check against (bias 10)

| Op | a | b | Result | Why |
|---|---|---|---|---|
| mul | `54` | `54` | `59` | 1.5 × 1.5 = 2.25, exact |
| mul | `51` | `51` | `52` | 1.265625 is closer to 1.25 |
| mul | `51` | `54` | `56` | 1.6875 is a tie, rounds to even (1.75) |
| mul | `52` | `52` | `54` | 1.5625 is a tie, rounds to even (1.5) |
| mul | `7F` | `7F` | `7F` | too big, saturates |
| mul | `80` | `54` | `00` | `80` is zero |
| add | `50` | `50` | `58` | 1 + 1 = 2 |
| add | `50` | `D0` | `00` | 1 + (−1) = 0 |
| add | `50` | `30` | `50` | 1.0625 is a tie, rounds to even (1.0) |
| add | `50` | `31` | `51` | 1.0703125 is past the midpoint, rounds to 1.125 |

## PE

Each PE multiplies its two inputs and adds the product to its accumulator, then passes both inputs along unchanged, one clock later. A goes right, B goes down.

Each clock edge, in this order:
1. `clear`: set `acc`, `a_out`, `b_out` to `00`.
2. `en`: `acc <= add(acc, mul(a_in, b_in))`, `a_out <= a_in`, `b_out <= b_in`.
3. Otherwise hold.

Zero inputs make a zero product and adding zero changes nothing, so the zero padding below needs no special handling.

Ports we agreed on (so we can work separately). Change them if you both want to, they aren't graded.

```
cf8_mul (a[7:0], b[7:0], bias[5:0], p[7:0])
cf8_add (acc[7:0], p[7:0], bias[5:0], acc_next[7:0])
cf8_pe  (clk, clear, en, bias[5:0], a_in[7:0], b_in[7:0], a_out[7:0], b_out[7:0], acc[7:0])
```

## Top level behavior

Call the clock edge where `start` is accepted **cycle 0**. The next seven edges are **cycles 1 to 7**.

- **Reset** (synchronous, beats everything): `busy = 0`, `done = 0`, all outputs `00`, all PE state cleared.
- **Accept start:** when `reset = 0`, `busy = 0`, `start = 1`. Latch all 18 inputs and `bias`. Clear the PEs and outputs. `busy = 1`, `done = 0`.
- **Cycles 1 to 7:** run the PEs on the latched values only. Ignore changes on the input ports. Ignore `start`, including during cycle 7.
- **After cycle 7:** `busy = 0`, `done = 1`, all nine outputs hold their final values. They stay until reset or the next accepted `start`. A new `start` can come on the very next edge, no reset needed.
- **Before that,** every output `c00` to `c22` reads `00`. One easy way: `c = done ? acc : 00`.

What gets fed in each cycle. A rows enter from the left, B columns from the top. `00` is real zero padding.

| Cycle | A row 0 | A row 1 | A row 2 | B col 0 | B col 1 | B col 2 |
|---|---|---|---|---|---|---|
| 1 | a00 | 00 | 00 | b00 | 00 | 00 |
| 2 | a01 | a10 | 00 | b10 | b01 | 00 |
| 3 | a02 | a11 | a20 | b20 | b11 | b02 |
| 4 | 00 | a12 | a21 | 00 | b21 | b12 |
| 5 | 00 | 00 | a22 | 00 | 00 | b22 |
| 6 | 00 | 00 | 00 | 00 | 00 | 00 |
| 7 | 00 | 00 | 00 | 00 | 00 | 00 |

Handy for debugging: PE(i,j) sees the pair `(a_ik, b_kj)` at cycle `i + j + k + 1`.

Rules from the PDF: no procedural `for` loop doing the matrix multiply (use `generate` or write out the instances), no `real` types, no vendor IP. `+` and `*` are fine.

## What to test

The provided `matrix_tb` only checks final results for three matrices. The autograder checks more. Test at least:
- reset, including in the middle of a run, and reset winning over `start`
- `busy` and `done` timing: done right after the cycle-7 edge, not a cycle early or late
- outputs stay `00` until then, and hold after
- `start` ignored while busy, cycle 7 included
- changing the inputs and `bias` after cycle 0 changes nothing
- two runs back to back with no reset
- negative numbers, both zeros (`00` and `80`), ties, saturation, at biases 9 to 12
- multiplier and adder alone: every input pair at each bias, against the Python model

## Submitting

Run `make synth`, then fill the four numbers (LUT, flip-flop, latch, DSP) into `reports/utilization_table.md`. Zip everything in `rtl/` and `tb/` plus that table as `EID1_EID2_Lab6.zip`. Latches should be 0. Be ready to explain any part of the design at checkout.
