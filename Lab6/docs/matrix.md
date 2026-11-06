# Matrix top level

The graded top level. It latches the two input matrices and the bias, feeds a 3×3 grid of [PEs](cf8-pe.md) with the staggered schedule, and raises `done` after the cycle-7 edge.

**Status:** Not started. Steps 6 and 7 in the [progress table](../README.md#progress).

## Spec

### Purpose
Compute `C = A · B` for two 3×3 CFloat8 matrices in a fixed number of cycles. An autograder checks the ports and the cycle timing, so both are exact. Source of truth for the protocol is §d of [`ECE460M_Lab6_Fall2026.pdf`](../ECE460M_Lab6_Fall2026.pdf).

### Interface
Module `Matrix`, file `rtl/matrix.v`. Keep the name, ports, directions, and widths exactly as the instructor's `matrix.v` has them.

| Signal | Width | Dir | Description |
|---|---|---|---|
| `clk` | 1 | in | rising-edge clock |
| `reset` | 1 | in | synchronous, active high, beats `start` |
| `start` | 1 | in | begin an operation when `busy = 0` |
| `bias` | 6 | in | shared exponent bias, latched at accept |
| `a00` … `a22` | 8 each | in | matrix A, 9 inputs, latched at accept |
| `b00` … `b22` | 8 each | in | matrix B, 9 inputs, latched at accept |
| `busy` | 1 | out | high after the accept edge, low again after the cycle-7 edge |
| `done` | 1 | out | high after the cycle-7 edge |
| `c00` … `c22` | 8 each | out | matrix C, `cIJ` is row I, column J |

### Behavior
Call the edge that accepts `start` **E0** (setup cycle 0) and the following edges **E1 … E7** (compute cycles 1–7).

1. **Reset.** On an edge with `reset = 1`: `busy = 0`, `done = 0`, `c00 … c22 = 00`, all PE state cleared.
2. **Accept.** On an edge with `reset = 0`, `busy = 0`, `start = 1` (this is E0): latch all 18 matrix inputs and `bias`, clear all PE state, set `busy = 1`, `done = 0`. Outputs go to `00`.
3. **Compute.** On E1 … E7 the PEs run with `en = 1`, fed the boundary values for that cycle from the latched matrices. Live inputs and `bias` are ignored. `start` is ignored while `busy = 1`, E7 included.
4. **Complete.** After E7: `busy = 0`, `done = 1`, and every `cIJ` holds its final encoding. They hold until `reset` or the next accepted `start`. A new accept may happen on the very next edge, no reset needed.
5. **Outputs before completion.** `c00 … c22` read `00` after E0 through E6. Only after E7 do they show the accumulators.

Observable timing:

| After edge | `busy` | `done` | `cIJ` |
|---|---|---|---|
| E0 | 1 | 0 | `00` |
| E1 … E6 | 1 | 0 | `00` |
| E7 | 0 | 1 | final |

Boundary schedule (PDF §d, "Input schedule"). A rows enter from the left, B columns from the top, `00` is explicit padding:

| Cycle | A row 0 | A row 1 | A row 2 | B col 0 | B col 1 | B col 2 |
|---|---|---|---|---|---|---|
| 1 | a00 | 00 | 00 | b00 | 00 | 00 |
| 2 | a01 | a10 | 00 | b10 | b01 | 00 |
| 3 | a02 | a11 | a20 | b20 | b11 | b02 |
| 4 | 00 | a12 | a21 | 00 | b21 | b12 |
| 5 | 00 | 00 | a22 | 00 | 00 | b22 |
| 6 | 00 | 00 | 00 | 00 | 00 | 00 |
| 7 | 00 | 00 | 00 | 00 | 00 | 00 |

Checkable consequence: PE(i,j) sees the pair `(a_ik, b_kj)` at cycle `i + j + k + 1`. PE(2,2) sees its last pair at cycle 7.

Structure and rules:
- Operand links are the registered `a_out` / `b_out` of the neighboring PE. A flows right, B flows down.
- No procedural `for` loop does any matrix arithmetic. Use `generate` or explicit instances for the grid.
- Nothing from `real`, `shortreal`, or vendor IP. `+` and `*` are fine.

### Files
| File | Status | What it is |
|---|---|---|
| `rtl/matrix.v` | planned | module `Matrix`: latch, cycle counter, schedule mux, PE grid, output gating |
| `tb/provided/matrix_tb.v` | planned | instructor's 3-case example testbench. Not in the repo yet, see [PLAN.md](../PLAN.md#before-we-start) |
| `tb/matrix_sys_tb.v` | planned | our system testbench, covers the checklist below |
| `scripts/synth.tcl` | present | post-synthesis utilization, run by `make synth` |
| `reports/utilization.txt` | generated | the report the table below comes from |

### Done when
Simulation (system testbench):
- [ ] The three provided sample cases pass.
- [ ] Random matrices from `vectors/matrix_b<bias>.hex` pass at biases 9, 10, 11, 12.
- [ ] Reset clears everything, including in the middle of an operation, and wins over a same-edge `start`.
- [ ] `start` during cycles 1–7, E7 included, changes nothing.
- [ ] `busy` and `done` flip exactly as in the timing table, and `cIJ` is `00` until E7.
- [ ] Outputs and `done` hold after completion until `reset` or an accepted `start`.
- [ ] Changing `a00 … b22` and `bias` right after E0 does not change the result.
- [ ] Back-to-back operations with different matrices and no reset give the right result each time.
- [ ] Directed cases: `A = I` returns `B`, ±0 inputs, saturation in both signs, exact cancellation, rounding ties.

Synthesis and submission:
- [ ] `make synth` succeeds on `XC7A35TCPG236-1` and the table below is filled from `reports/utilization.txt`. Latches should be 0.
- [ ] `EID1_EID2_Lab6.zip` holds all `rtl/` and `tb/` Verilog and the filled table. Lab 4 used `sc73994_at49454_Lab4.zip`, check the Lab 6 pair is the same.
- [ ] Each of us can explain every block, including the half we didn't write.

### Open questions
1. Gate the outputs with `done` (`c = done ? acc : 00`, no extra flops) or add nine output registers? Leaning gating.

## Design notes
Fill in during step 6.

## Results
Post-synthesis, `XC7A35TCPG236-1`, Vivado, from `reports/utilization.txt`. Fill in during step 7.

| LUT usage | Flip-flop usage | Latch usage | DSP usage |
|---|---|---|---|
| | | | |

## Bug log
| # | Symptom | Root cause | Fix | Caught by |
|---|---|---|---|---|
