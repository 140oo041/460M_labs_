# Lab 6 plan

How the two of us split [Lab 6](ECE460M_Lab6_Fall2026.pdf), and in what order. What each block must do is in its doc under [`docs/`](docs/). This file only says who builds what and when we sync. Delete it after we submit.

Due one week from Thu Nov 5 (check the exact time on Canvas). Target: everything passing by Sunday, synthesis and zip by Tuesday, Wednesday as buffer.

## Before we start
- The PDF refers to an instructor `matrix.v` (the port list) and `matrix_tb.v` (three sample cases). Neither is in the repo. Whoever has Canvas open: `matrix.v` goes in `rtl/`, `matrix_tb.v` goes in `tb/provided/`.
- We each read the PDF once (6 pages), then [cf8-format.md](docs/cf8-format.md). That file closes the corners the PDF leaves open. Object now, not on Sunday.

## The split
The seam is arithmetic versus dataflow. Whoever writes a block doesn't write what checks it: Person A's arithmetic is checked by Person B's model, and Person B's top level is checked by Person A's system testbench.

| | Person A: arithmetic | Person B: dataflow |
|---|---|---|
| RTL | `rtl/cf8_mul.v`, `rtl/cf8_add.v` | `rtl/cf8_pe.v`, `rtl/matrix.v` |
| Checks | `tb/cf8_mul_tb.v`, `tb/cf8_add_tb.v`, `tb/matrix_sys_tb.v` | `model/cf8.py`, `model/test_cf8.py`, `tb/cf8_pe_tb.v` |
| Docs | [cf8-mul](docs/cf8-mul.md), [cf8-add](docs/cf8-add.md) | [golden-model](docs/golden-model.md), [cf8-pe](docs/cf8-pe.md), [matrix](docs/matrix.md) |
| Shared | | `Makefile`, `scripts/` |

You each edit only your own files, so we shouldn't hit merge conflicts. [`README.md`](README.md) (progress table) is the one file we both touch.

## Person A: arithmetic
1. **Placeholders first.** Push `cf8_mul.v` and `cf8_add.v` with the right ports and a dummy body, so B can compile the PE. Ten minutes, do it before anything else.
2. **Multiplier**, step 3. [Spec](docs/cf8-mul.md). Write `cf8_mul_tb.v` as an exhaustive check against B's vectors. The vectors land with B's step 1, so write the RTL first.
3. **Adder**, step 4. [Spec](docs/cf8-add.md). The hardest block, so start it early Saturday. Same exhaustive testbench pattern.
4. **System testbench**, for step 6. `tb/matrix_sys_tb.v`, checklist in [matrix.md](docs/matrix.md#done-when). You can write it from the spec before B's top level exists. Start from the provided `matrix_tb.v`.

## Person B: dataflow
1. **Golden model**, step 2. [Spec](docs/golden-model.md). First thing, because A's testbenches need its vectors. Check it against the worked examples in [cf8-format.md](docs/cf8-format.md#worked-examples). Add a `vectors` target to the `Makefile`.
2. **PE**, step 5. [Spec](docs/cf8-pe.md). Write `cf8_pe_tb.v`. Use A's placeholders until the real mul and add land.
3. **Top level**, step 6. [Spec](docs/matrix.md). Start from the instructor's `matrix.v`. Latch, cycle counter, schedule mux, 3×3 grid, output gating. Test the schedule on its own first: check each PE's operand inputs cycle by cycle against the schedule in the spec. That doesn't need working arithmetic.
4. **Synthesis script**, step 7. `make synth` already runs `scripts/synth.tcl`. Read the report, check latches are 0, hand the numbers to the shared task below.

## Together
- **Integration.** Swap in the real mul and add, run A's system testbench against B's top level, fix what breaks. Bias sweep 9–12.
- **Submission**, step 7. Fill the utilization table in [matrix.md](docs/matrix.md#results) from `reports/utilization.txt`. Build `EID1_EID2_Lab6.zip` from all `rtl/` and `tb/` Verilog plus the table.
- **Walkthrough.** The checkout asks about any part of the design. Each of us walks the other through the half they wrote, and we trace one 3×3 case through the array by hand.

## Sync points
| # | When | What has to be true |
|---|---|---|
| S0 | Fri | Both read the docs. Format rules agreed. Instructor files in the repo. |
| S1 | Sat morning | A's placeholders pushed. B's model and vectors pushed. |
| S2 | Sat night to Sun | Mul and add pass exhaustively. PE passes. Top level compiles. If the adder isn't passing by Saturday night, B drops what they're doing and pairs on it. |
| S3 | Sunday | System testbench passes on the real design. |
| S4 | Mon–Tue | Synthesis table filled, zip built, walkthrough done. |

## Working rules
- Commit prefix `lab6:`. `git pull --rebase` before every push. We push to `main`, same as Lab 4.
- A step ships when its "Done when" boxes are checked in its doc. Check them in the same commit, and update the progress table in the [README](README.md#progress).
- Change a rule in [cf8-format.md](docs/cf8-format.md) and both of us hear about it before anyone codes against it.
- Don't commit `vectors/`. `make` regenerates it.
