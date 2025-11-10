# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Niklas Höher

# ----------------------------------------------------------
# Vivado Out-of-Context Implementation Script (Artix-7 100T)
# ----------------------------------------------------------
# Usage:
#   vivado -mode batch -source syn_vivado.tcl \
#          -tclargs <src_dir> <build_dir> <generic_str>
# ----------------------------------------------------------

# Parse command line parameters
set src_dir   [lindex $argv 0]
set build_dir [lindex $argv 1]
set nb        [lindex $argv 2]
set nk        [lindex $argv 3]

# Collect RTL sources
set src_files [glob -nocomplain -directory $src_dir -types f *.sv *.v *.vhd]
puts "Found [llength $src_files] source files:"
foreach f $src_files { puts "  $f" }

read_verilog -sv $src_files
set_property top rijndael_encrypt [current_fileset]

# Run synthesis / implementation
puts "Running synthesis...\n"
synth_design -top rijndael_encrypt -part xc7a100tftg256-1 -mode out_of_context \
    -generic "NB=$nb NK=$nk"

create_clock -name clk_i -period 10.0 [get_ports clk_i]

puts "Running optimization...\n"
opt_design

puts "Running placement...\n"
place_design

puts "Running routing...\n"
route_design

# Generate reports
set rpt_dir "${build_dir}"
file mkdir $rpt_dir

report_utilization      -file "$rpt_dir/utilization_post_impl.rpt"
report_timing_summary   -file "$rpt_dir/timing_summary_post_impl.rpt"
report_timing -max_paths 10 -file "$rpt_dir/critical_paths_post_impl.rpt"
report_power            -file "$rpt_dir/power_post_impl.rpt"

# Save design checkpoint
write_checkpoint -force "$rpt_dir/impl_design.dcp"

puts "\n"
puts "Reports generated in: $rpt_dir"
puts "Done."
exit 0
