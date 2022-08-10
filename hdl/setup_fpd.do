transcript on
if {[file exists work]} {
	vdel -lib work -all
}
vlib work
vmap work work

vlog -sv -work work {BHG_FP_clk_divider_tb.v}
vsim -t 1ps -L work -voptargs="+acc"  BHG_FP_clk_divider_tb

restart -force -nowave

# This line shows only the variable name instead of the full path and which module it was in
config wave -signalnamewidth 1

add wave -divider     "Input:"
add wave -hexadecimal FPD/rst_in
add wave -hexadecimal FPD/clk_in

add wave -divider     "Output:"
add wave -hexadecimal FPD/clk_out
add wave -hexadecimal FPD/clk_p0
add wave -hexadecimal FPD/clk_p180

add wave -divider     "Counter"
add wave -decimal      p_count


do run_fpd.do
