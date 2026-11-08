# Lab 6: 3×3 systolic matrix multiplier

A 3×3 matrix multiplier made of nine multiply-accumulate PEs, with all math in Tesla CFloat8 E4M3. Simulated and synthesized in Vivado, no board. Assignment: [`ECE460M_Lab6_Fall2026.pdf`](ECE460M_Lab6_Fall2026.pdf). What to build: [docs/spec.md](docs/spec.md). Who does what: [PLAN.md](PLAN.md).

## Who does what
- **Person A:** floating-point multiplier, floating-point adder, and the full-design testbench.
- **Person B:** Python reference model, the PE, and the top level (`Matrix`, control and 3×3 array).
- **Both:** hook it together, synthesize, fill in the table, zip, learn each other's half.

## Progress
- [ ] Python model (B)
- [ ] Multiplier (A)
- [ ] Adder (A)
- [ ] PE (B)
- [ ] `Matrix` top level (B)
- [ ] Provided `matrix_tb` passes
- [ ] Full testbench passes (A)
- [ ] `make synth` run, table filled in
- [ ] Zip built

## Build and run
Run from this folder. Uses Vivado.

```
make sim T=matrix_tb   # run a testbench by module name (files in tb/ or tb/provided/)
make synth             # synthesize Matrix, writes reports/utilization.txt
make clean
```

## Layout
- `rtl/`: our Verilog. `matrix.v` is the instructor's starter, we fill in the body.
- `tb/`: our testbenches. `tb/provided/` has the instructor's.
- `model/`: Python reference model.
- `reports/`: synthesis report and the table we submit.
- `scripts/`: the synthesis script `make synth` runs.
