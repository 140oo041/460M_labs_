# CFloat8 multiplier

Combinational CFloat8 E4M3 multiplier. One instance per PE computes the product `P` that the adder folds into the accumulator.

**Status:** Not started. Step 3 in the [progress table](../README.md#progress).

## Spec

### Purpose
Multiply two CFloat8 values at the shared bias and return a rounded, saturated CFloat8 product. Rounding and saturation rules are in [cf8-format.md](cf8-format.md). [cf8-pe](cf8-pe.md) is the only user.

### Interface
Module `cf8_mul`, file `rtl/cf8_mul.v`. Purely combinational, no clock.

| Signal | Width | Dir | Description |
|---|---|---|---|
| `a` | 8 | in | CFloat8 operand |
| `b` | 8 | in | CFloat8 operand |
| `bias` | 6 | in | shared exponent bias |
| `p` | 8 | out | rounded, saturated product |

### Behavior
1. If `a` or `b` is zero (`E == 0`), `p = 8'h00`.
2. Sign of `p` is `a[7] ^ b[7]`.
3. Mantissas are `Ma = {1, Fa}` and `Mb = {1, Fb}`, each 8 to 15. `Prod = Ma * Mb` is 8 bits, 64 to 225.
4. Biased exponent `e = Ea + Eb − bias`, plus 1 if `Prod[7]` is set (product is 2.0 or more).
5. Fraction bits: if `Prod[7]`, keep `Prod[6:4]`, guard `Prod[3]`, sticky `|Prod[2:0]`. Otherwise keep `Prod[5:3]`, guard `Prod[2]`, sticky `|Prod[1:0]`.
6. Round up when `guard && (sticky || lsb)`, where `lsb` is the lowest kept fraction bit. If the fraction wraps from `111` to `000`, add 1 to `e`.
7. If `e > 15`, `p = {sign, 7'h7F}`. If `e <= 0`, `p = 8'h00`. Otherwise `p = {sign, e[3:0], frac}`.

`e` is signed and needs 8 bits (see rule 6 in [cf8-format.md](cf8-format.md#rules)).

### Files
| File | Status | What it is |
|---|---|---|
| `rtl/cf8_mul.v` | planned | the multiplier. A first commit has the right ports and a placeholder body so [cf8-pe](cf8-pe.md) can compile |
| `tb/cf8_mul_tb.v` | planned | exhaustive testbench against `vectors/mul_b<bias>.hex` |

### Done when
- [ ] `make sim T=cf8_mul_tb` compares all 65 536 `{a, b}` pairs at each of biases 9, 10, 11, 12 and reports zero mismatches. Pairs with `dc = 1` are skipped.
- [ ] The multiply rows in the worked examples of [cf8-format.md](cf8-format.md#worked-examples) pass.

### Open questions
None yet.
