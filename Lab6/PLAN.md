# Who does what

Details of what to build are in [docs/spec.md](docs/spec.md). Read it first, both of you. Aim: everything passing by Sunday night, synthesis and zip Monday or Tuesday, Wednesday spare.

## Person A: floating-point math
Files: `rtl/cf8_mul.v`, `rtl/cf8_add.v`, `tb/cf8_mul_tb.v`, `tb/cf8_add_tb.v`, `tb/matrix_sys_tb.v`

1. Push `cf8_mul.v` and `cf8_add.v` with the right ports and an empty body, so Person B can compile.
2. Build the multiplier. Test it against Person B's model.
3. Build the adder. Start this early, it's the hardest part. Test it the same way.
4. Write `tb/matrix_sys_tb.v`, the full-design test from "What to test" in the spec. Use `tb/provided/matrix_tb.v` as a template.

## Person B: PE and top level
Files: `model/cf8.py`, `rtl/cf8_pe.v`, `rtl/matrix.v`

1. Write `model/cf8.py` first, because Person A's tests need it. Python with exact fractions: mul, add, and matrix multiply that match the spec. Check it against the examples table. Make it write expected-output files the testbenches can load. Simplest is one hex file per bias, 65 536 lines, line number = `{a, b}`, for `$readmemh`.
2. Build `cf8_pe.v`. Use Person A's empty modules until the real ones land.
3. Fill in the body of `rtl/matrix.v`: latch the inputs, cycle counter, feed the schedule, nine PEs, `busy`, `done`, outputs held at `00` until done.
4. Run the provided test: `make sim T=matrix_tb`.

## Both
- Plug in the real math, run Person A's full test against Person B's top level, fix what breaks.
- `make synth`, fill in `reports/utilization_table.md`, build the zip (see spec).
- Each of you explains the half you didn't write to the other. Checkout can ask about any part.

## Ground rules
- Edit your own files only. Pull before you push (`git pull --rebase`), commit messages start with `lab6:`.
- Tick the boxes in the [README](README.md) as things pass.
- If the adder isn't passing by Saturday night, Person B stops and helps.
