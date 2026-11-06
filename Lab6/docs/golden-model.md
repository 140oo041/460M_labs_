# Golden model

A Python reference for CFloat8 multiply, add, and 3×3 matrix multiply, plus the generator for every test vector file. It's the oracle for all the testbenches.

**Status:** Not started. Step 2 in the [progress table](../README.md#progress).

## Spec

### Purpose
The RTL author shouldn't also write the thing that checks it. So the model is written by the other partner, from [cf8-format.md](cf8-format.md) and not from the RTL. It uses exact rational arithmetic, so it shares no algorithm with the hardware.

### Interface
All values are Python `int` in 0–255 (an encoding) unless noted.

| Function | Arguments | Returns |
|---|---|---|
| `decode(x, bias)` | encoding, bias | `fractions.Fraction`, exact value |
| `encode(v, bias)` | `Fraction`, bias | encoding, after round, saturate, flush rules |
| `mul(a, b, bias)` | two encodings, bias | encoding |
| `add(x, y, bias)` | two encodings, bias | encoding |
| `matmul(A, B, bias)` | two 3×3 lists of encodings, bias | 3×3 list of encodings |

Command line: `python3 model/cf8.py` writes all vector files into `vectors/` (gitignored, regenerated on demand).
Self-test: `python3 model/test_cf8.py` checks the worked examples in [cf8-format.md](cf8-format.md).

### Behavior
- `matmul` accumulates in the hardware's order: start at `00`, then for `k = 0, 1, 2` do `acc = add(acc, mul(A[i][k], B[k][j], bias), bias)`.
- Matrix vector cases skip any case where a product or partial sum would underflow, and any input with `E == 0, F != 0`. Those are outside what the lab tests.

### Vector files
Biases 9, 10, 11, 12. One file per bias and kind. All files are `$readmemh` text, one word per line.

| File | Words | Word | Index means |
|---|---|---|---|
| `vectors/mul_b<bias>.hex` | 65 536 | 3 hex digits `{dc, p[7:0]}` | address = `{a, b}` |
| `vectors/add_b<bias>.hex` | 65 536 | 3 hex digits `{dc, s[7:0]}` | address = `{acc, p}` |
| `vectors/matrix_b<bias>.hex` | 27 × cases | 2 hex digits | case `n` uses words `27n` to `27n+26`: `a00 a01 a02 a10 … a22`, then `b00 … b22`, then expected `c00 … c22` |

`dc` is 1 when the case is outside the tested range (denormal input or underflow). The testbench skips the comparison then. Overflow and ±0 inputs are tested, so `dc` is 0 for them.

Matrix files hold directed cases (identity, all zeros, ±0 inputs, saturating, cancelling, rounding ties) followed by 2000 random cases per bias, fixed seed.

### Files
| File | Status | What it is |
|---|---|---|
| `model/cf8.py` | planned | `decode`, `encode`, `mul`, `add`, `matmul`, vector writer |
| `model/test_cf8.py` | planned | worked examples as asserts |
| `vectors/` | generated | not committed |

### Done when
- [ ] `python3 model/test_cf8.py` passes.
- [ ] `python3 model/cf8.py` writes all 12 vector files.
- [ ] One 3×3 case worked by hand matches `matmul`. Identity times `B` returns `B`.

### Open questions
None yet.

## Design notes
Fill in during step 2.

## Results
None. Tooling only.

## Bug log
| # | Symptom | Root cause | Fix | Caught by |
|---|---|---|---|---|
