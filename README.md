**************************************************************************************************

  BHG_FP_clk_divider.v   V1.0, August 2022.
  
  Floating point clock divider/synthesizer.
  
  24.16 (m.n) bit floating point clock divider. (Actually it is a fixed point fractional divider.)
  
  Written by Brian Guralnick.
  
  https://github.com/BrianHGinc / or / https://www.eevblog.com/forum/fpga/verilog-floating-point-clock-divider-release/
  
  Provide / define the INPUT_CLK_HZ parameter and the BHG_FP_clk_divider
  will generate a clock at the specified CLK_OUT_HZ parameter.  The module
  will output a 50:50 duty cycle clock plus two single clk_in cycle pulsed
  outputs, one at the rise of the clk_out, and another at the fall of clk_out.
  
  *** The module will generate a report of the synthesized output clock specs
  in your FPGA vendor compiler's message processing window during compile.
  The report will contain the resulting frequency down to the 0.01Hz,
  calculated PPM error and jitter spec.
  
  To simulate this project in Modelsim:
   1) Run Modelsim all by itself.  You do not need your FPGA compiler studio.
   2) Select 'File / Change Directory' and choose this project's folder.
   3) In the transcript, type:                'do setup_fpd.do'.  (DONE!)
   4) To re-compile and simulate again, type: 'do run_fpd.do'.    (DONE!)
  
  For public use.  Just be fair and give credit where it is due.

**************************************************************************************************

Example Modelsim screenshot of simulating a full second:

(USE_FLOATING_DIVIDE=1,CLK_IN_HZ=100000000,CLK_OUT_HZ=3579545)
![plot](https://github.com/BrianHGinc/Verilog-Floating-Point-Clock-Divider/blob/main/screenshots/Modelsim_FPD_fp_on.png)

(USE_FLOATING_DIVIDE=0,CLK_IN_HZ=100000000,CLK_OUT_HZ=3579545)
![plot](https://github.com/BrianHGinc/Verilog-Floating-Point-Clock-Divider/blob/main/screenshots/Modelsim_FPD_fp_off.png)


Example Quartus screenshot of compilation report with LUT/LR:

(USE_FLOATING_DIVIDE=1,CLK_IN_HZ=148500000,CLK_OUT_HZ=3072000 = Audio I2S sclk for 48Khz sound)
![plot](https://github.com/BrianHGinc/Verilog-Floating-Point-Clock-Divider/blob/main/screenshots/Quartus_FPD_fp_on.png)

(USE_FLOATING_DIVIDE=0,CLK_IN_HZ=148500000,CLK_OUT_HZ=3072000 = Audio I2S sclk for 48Khz sound)
![plot](https://github.com/BrianHGinc/Verilog-Floating-Point-Clock-Divider/blob/main/screenshots/Quartus_FPD_fp_off.png)


Looking at the 'Frequency error PPM' alone shows the value in this code.

Even most consumer grade crystals are around +/-50ppm tolerant.

If you require a single or multiple fractional clocks when you only have a single source clock,
or want your FPGA compiler to only deal with one clock domain this code will fit the bill.

Enjoy, BrianHG.
