vlog -sv -work work {BHG_FP_clk_divider_tb.v}

restart -force
run -all

wave cursor active
wave refresh
wave zoom range 0.9995ms 1ms
view signals
