# Post-synthesis utilization for the Matrix top level.
# Run from Lab6/:  vivado -mode batch -source scripts/synth.tcl   (or: make synth)
set part xc7a35tcpg236-1

read_verilog [glob rtl/*.v]
synth_design -top Matrix -part $part

file mkdir reports
report_utilization -file reports/utilization.txt
report_utilization
