# build.tcl
# run from the Lab4 folder: vivado -mode batch -source synth/rx/build.tcl
set part xc7a35tcpg236-1
set top  top
set name rx_top

# 1. Read sources
read_verilog [glob ./common/*.v ./rx/*.v]
read_xdc     ./Lab_4/Lab_4.srcs/constrs_1/imports/460M/Basys3_Master.xdc

# 2. Synthesis
synth_design -top $top -part $part

# 3. Optimization, placement, routing
opt_design
place_design
phys_opt_design
route_design

# 4. Final reports
report_utilization      -file ./synth/rx/util_impl.rpt
report_timing_summary   -file ./synth/rx/timing_impl.rpt
file delete -force clockInfo.txt

# 5. Generate bitstream
write_bitstream -force ./synth/rx/${name}.bit

# 6. Cleanup
exit
