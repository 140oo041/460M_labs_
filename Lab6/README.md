# Lab 6: systolic matrix multiplier

We're building a 3×3 matrix multiplier for ECE 460M: nine multiply-accumulate PEs in a systolic array, all arithmetic in Tesla CFloat8 E4M3 with a runtime exponent bias. It's simulated and synthesized in Vivado for the XC7A35T. No board. The assignment is [`ECE460M_Lab6_Fall2026.pdf`](ECE460M_Lab6_Fall2026.pdf). Who builds what is in [PLAN.md](PLAN.md).

**Work in progress: step 1 of 7.** Specs are written. No RTL yet.

```
          B col 0   B col 1   B col 2     boundary streams, generated from the
             |         |         |        latched matrices by a cycle counter
A row 0 --> PE00 ---> PE01 ---> PE02
             |         |         |
A row 1 --> PE10 ---> PE11 ---> PE12
             |         |         |
A row 2 --> PE20 ---> PE21 ---> PE22
```

## How it works
`start` latches both matrices and the bias. A counter then runs seven compute cycles. In each one it feeds staggered, zero-padded A rows in from the left and B columns in from the top. Every PE multiplies, rounds, adds to its accumulator, rounds again, and forwards its operands unchanged. After cycle 7 the nine accumulators are `C` and `done` goes high.

- [CFloat8 numerics](docs/cf8-format.md): format, rounding, and corner-case rules shared by everything below.
- [Golden model](docs/golden-model.md): Python reference and test vector generator.
- [Multiplier](docs/cf8-mul.md): combinational CFloat8 multiply.
- [Adder](docs/cf8-add.md): combinational CFloat8 add.
- [PE](docs/cf8-pe.md): operand forwarding, accumulator, one mul and one add.
- [Matrix top level](docs/matrix.md): latching, schedule, 3×3 grid, `busy` and `done`, and the synthesis results.

## Progress
| Step | Block | Status |
|---|---|---|
| 1 | [CFloat8 numerics](docs/cf8-format.md) | Spec written |
| 2 | [Golden model](docs/golden-model.md) | Not started |
| 3 | [Multiplier](docs/cf8-mul.md) | Not started |
| 4 | [Adder](docs/cf8-add.md) | Not started |
| 5 | [PE](docs/cf8-pe.md) | Not started |
| 6 | [Matrix top level](docs/matrix.md) | Not started |
| 7 | [Synthesis and submission](docs/matrix.md#results) | Not started |

## Build and run
Run from this directory. Simulation uses Vivado xsim.

```
make sim T=<testbench>   # T is the testbench module name, file in tb/ or tb/provided/
make synth               # Vivado batch synthesis, writes reports/utilization.txt
make clean
```

## Repository layout
| Path | What's in it |
|---|---|
| `docs/` | one doc per block |
| `rtl/` | synthesizable Verilog |
| `tb/` | our testbenches. `tb/provided/` holds the instructor's |
| `model/` | Python golden model |
| `scripts/` | Vivado synthesis script |
| `reports/` | post-synthesis utilization report |
