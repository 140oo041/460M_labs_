# CFloat8 adder

Combinational CFloat8 E4M3 adder. One instance per PE adds the new product to the accumulator.

**Status:** Not started. Step 4 in the [progress table](../README.md#progress). This is the hardest block in the lab: alignment, cancellation, and rounding.

## Spec

### Purpose
Add two CFloat8 values, either sign, at the shared bias and return a rounded, saturated CFloat8 sum. Rules are in [cf8-format.md](cf8-format.md). [cf8-pe](cf8-pe.md) is the only user.

### Interface
Module `cf8_add`, file `rtl/cf8_add.v`. Purely combinational, no clock. Names follow Figure 2 in the PDF.

| Signal | Width | Dir | Description |
|---|---|---|---|
| `acc` | 8 | in | current accumulator |
| `p` | 8 | in | product from [cf8-mul](cf8-mul.md) |
| `bias` | 6 | in | shared exponent bias |
| `acc_next` | 8 | out | rounded, saturated sum |

### Behavior
1. If `acc` is zero, `acc_next = p` (or `00` if `p` is also zero). If `p` is zero, `acc_next = acc`. A zero result is always `8'h00`. No rounding is needed: both inputs are already representable.
2. Otherwise order the operands by magnitude, comparing `{E, F}`. Call them `big` and `small`. `d = E_big − E_small`, 0 to 15.
3. Mantissas are `{1, F}`. Shift `small`'s mantissa right by `d`, keeping the bits shifted out (see Design notes).
4. Same signs: add the mantissas. Different signs: subtract `small` from `big`, which is never negative. The sign of the result is the sign of `big`.
5. Normalize. A carry out of the top shifts right by 1 and adds 1 to the exponent. Cancellation shifts left until the leading 1 is back in place and subtracts the shift from the exponent.
6. Round to nearest, ties to even, onto 3 fraction bits. If the fraction wraps from `111` to `000`, add 1 to the exponent.
7. Exact zero (equal magnitudes, opposite signs) gives `8'h00`. Exponent above 15 gives `{sign, 7'h7F}`. Exponent 0 or below gives `8'h00`.

### Files
| File | Status | What it is |
|---|---|---|
| `rtl/cf8_add.v` | planned | the adder. A first commit has the right ports and a placeholder body so [cf8-pe](cf8-pe.md) can compile |
| `tb/cf8_add_tb.v` | planned | exhaustive testbench against `vectors/add_b<bias>.hex` |

### Done when
- [ ] `make sim T=cf8_add_tb` compares all 65 536 `{acc, p}` pairs at each of biases 9, 10, 11, 12 and reports zero mismatches. Pairs with `dc = 1` are skipped.
- [ ] The add rows in the worked examples of [cf8-format.md](cf8-format.md#worked-examples) pass.
- [ ] No latches inferred. Checked in the full-design synthesis report.

### Open questions
None yet.

## Design notes
Two ways to handle the shifted-out bits, pick one:
- **Guard, round, sticky.** Keep 3 extra bits below the mantissa, OR everything shifted past them into sticky. Small, but the sticky and cancellation corner cases are easy to get wrong.
- **Exact alignment.** Shift `big` left by `d` instead, so nothing is lost. The sum is up to about 19 bits wide. Bigger, but it's obviously correct, and rounding happens once at the end.

The exhaustive testbench settles whichever you choose.

## Results
Fill in during step 4. Measured numbers only, with the command that produced them.

## Bug log
| # | Symptom | Root cause | Fix | Caught by |
|---|---|---|---|---|
