# build.tcl
# run from the Lab4 folder: vivado -mode batch -source synth/tx/build.tcl
set part xc7a35tcpg236-1
set top  tx_top

# 1. Read sources
read_verilog [glob ./common/*.v ./tx/*.v]
read_xdc     [glob ./tx/*.xdc]

# 2. Synthesis
synth_design -top $top -part $part

# 3. Optimization, placement, routing
opt_design
place_design
phys_opt_design
route_design

# 4. Final reports
report_utilization      -file ./synth/tx/util_impl.rpt
report_timing_summary   -file ./synth/tx/timing_impl.rpt
file delete -force clockInfo.txt

# 5. Generate bitstream
write_bitstream -force ./synth/tx/${top}.bit

# 6. Cleanup
exit
