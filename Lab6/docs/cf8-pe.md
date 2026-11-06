# MAC processing element

One cell of the 3×3 array: forwards its A and B operands one step, and accumulates `a · b` into an 8-bit CFloat8 accumulator.

**Status:** Not started. Step 5 in the [progress table](../README.md#progress).

## Spec

### Purpose
PE(i,j) takes A from its left and B from above, adds their product to its accumulator, and registers both operands unchanged for its right and lower neighbors (Figures 1 and 2 in the PDF). Nine of these make the array in [matrix.md](matrix.md).

### Interface
Module `cf8_pe`, file `rtl/cf8_pe.v`. Contains one [`cf8_mul`](cf8-mul.md) and one [`cf8_add`](cf8-add.md).

| Signal | Width | Dir | Description |
|---|---|---|---|
| `clk` | 1 | in | rising-edge clock |
| `clear` | 1 | in | synchronous clear of accumulator and operand registers |
| `en` | 1 | in | compute enable, high for cycles 1–7 |
| `bias` | 6 | in | latched shared bias |
| `a_in` | 8 | in | A operand from the left (or the row's boundary stream) |
| `b_in` | 8 | in | B operand from above (or the column's boundary stream) |
| `a_out` | 8 | out | `a_in`, registered one cycle, to the PE on the right |
| `b_out` | 8 | out | `b_in`, registered one cycle, to the PE below |
| `acc` | 8 | out | accumulator register |

### Behavior
On each rising edge of `clk`, in priority order:
1. `clear`: `a_out`, `b_out`, `acc` all go to `8'h00`.
2. `en`: `a_out <= a_in`, `b_out <= b_in`, `acc <= acc_next`, where `acc_next = cf8_add(acc, cf8_mul(a_in, b_in))`.
3. Otherwise everything holds.

There is no valid bit. A zero operand gives a zero product, and adding zero leaves `acc` unchanged, so the padding zeros in the input schedule are harmless.

### Files
| File | Status | What it is |
|---|---|---|
| `rtl/cf8_pe.v` | planned | the PE |

### Done when
- [ ] Passes the system testbench in [matrix.md](matrix.md#done-when) with the real mul and add.

### Open questions
None yet.
