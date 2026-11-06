# ECE 460M Lab 6. Simulator: Vivado xsim. Synthesis: Vivado batch mode.
# Run from the Lab6 directory.

RTL := $(wildcard rtl/*.v)
T   ?= matrix_tb
TB  := $(firstword $(wildcard tb/$(T).v tb/provided/$(T).v))

.PHONY: sim synth clean

# make sim T=cf8_mul_tb    T is the testbench module name, in tb/<T>.v
sim:
	@test -n "$(TB)" || { echo "no tb/$(T).v or tb/provided/$(T).v"; exit 1; }
	xvlog $(RTL) $(TB)
	xelab --timescale 1ns/1ps $(T) -s $(T)_sim
	xsim $(T)_sim -runall

# Post-synthesis utilization for Matrix, written to reports/utilization.txt
synth:
	vivado -mode batch -source scripts/synth.tcl

clean:
	rm -rf xsim.dir *.wdb *.pb webtalk* xelab.* xvlog.* xsim.* vivado_pid* .Xil
