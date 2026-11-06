# CFloat8 numerics

The number format, rounding, and corner-case rules that the multiplier, the adder, and the golden model all follow. This doc owns them. Those blocks link here and don't restate them.

**Status:** Spec written. Not yet checked against the golden model. Step 1 in the [progress table](../README.md#progress).

## Spec

### Purpose
The lab PDF (§b and §c in [`ECE460M_Lab6_Fall2026.pdf`](../ECE460M_Lab6_Fall2026.pdf)) defines Tesla CFloat8 E4M3 and says "round to nearest, ties-to-even, saturate". It leaves a few corners open. We close them here once, so the model and the RTL can't disagree.

### Encoding
Bit 7 sign, bits [6:3] exponent `E`, bits [2:0] fraction `F`. The 6-bit `bias` is shared by the whole operation. For `E >= 1`: value = (−1)^s · (1 + F/8) · 2^(E − bias). Examples from the PDF at bias 10: `8'h50` = +1.0, `8'hD4` = −1.5.

### Rules
1. **Zero.** `E == 0` decodes as zero, whatever `F` and the sign are. `8'h00` and `8'h80` are both zero on input.
2. **Zero output.** Any zero result is encoded `8'h00`, never `8'h80`. That covers a zero operand and exact cancellation (`x + (−x)`).
3. **One rounding per operation.** Take the exact real result of a single multiply or a single add, round it once to nearest, ties to even, onto 3 fraction bits, then saturate. A multiply and the add after it are two roundings. Never fuse them.
4. **Overflow.** If the rounded exponent is above 15, the result is `8'h7F` (positive) or `8'hFF` (negative). Rounding up from `E = 15, F = 7` counts as overflow.
5. **Underflow.** If the rounded exponent is 0 or below, the result is `8'h00`. The lab never tests this.
6. **Exponent width.** Exponent arithmetic is signed. For a 6-bit bias the multiplier's exponent runs from −61 to +32, so 8 signed bits is enough.
7. **Biases.** Only 9 through 12 are tested, so those are the only ones we verify.

Rules 1, 2, and 5 close gaps the PDF leaves. Denormal encodings (`E == 0`, `F != 0`) and underflow are "will not be tested" in §b and §e, so these choices are for determinism only.

### Worked examples
Bias 10, computed by hand. The golden model has to reproduce every row.

| Op | `a` | `b` | Result | Why |
|---|---|---|---|---|
| mul | `54` | `54` | `59` | 1.5 × 1.5 = 2.25, exact |
| mul | `51` | `51` | `52` | 1.265625 is nearer 1.25 than 1.375 |
| mul | `51` | `54` | `56` | 1.6875 is a tie between 1.625 and 1.75, even is 1.75 |
| mul | `52` | `52` | `54` | 1.5625 is a tie between 1.5 and 1.625, even is 1.5 |
| mul | `7F` | `7F` | `7F` | overflow saturates |
| mul | `7F` | `FF` | `FF` | negative overflow saturates |
| mul | `80` | `54` | `00` | −0 is zero |
| add | `50` | `50` | `58` | 1 + 1 = 2 |
| add | `50` | `D0` | `00` | 1 + (−1) is +0 |
| add | `50` | `30` | `50` | 1 + 0.0625 is a tie between 1.0 and 1.125, even is 1.0 |
| add | `50` | `31` | `51` | 1.0703125 is above the midpoint, rounds to 1.125 |
| add | `7F` | `7F` | `7F` | overflow saturates |

### Files
This doc owns no files. The executable version of these rules is `model/cf8.py`, described in [golden-model.md](golden-model.md).

### Done when
- [ ] Both of us have read the rules and agree with them.
- [ ] `model/cf8.py` reproduces every worked example above.
- [ ] [cf8-mul](cf8-mul.md) and [cf8-add](cf8-add.md) match the model on every input pair at biases 9–12.

### Open questions
None yet.
