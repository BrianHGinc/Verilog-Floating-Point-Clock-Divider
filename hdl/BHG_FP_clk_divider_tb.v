// ***************************************************************************************************************
// BHG_FP_clk_divider_tb.v   V1.0, August 2022.
// Floating point clock divider/synthesizer testbench.
// 13.16 (m.n) bit floating point clock divider. (Actually it is a fixed point fractional divider.)
//
// Written by Brian Guralnick.
// https://github.com/BrianHGinc / or / https://www.eevblog.com/forum/fpga/ User BrianHG.
//
// Provide / define the INPUT_CLK_HZ parameter and the BHG_FP_clk_divider will synthesize a clock at the specified
// CLK_OUT_HZ parameter.  The module will output a 50:50 duty cycle clock plus two single clk_in cycle pulsed
// outputs, one at the rise of the clk_out, and another at the fall of clk_out.
//
// *** The module will generate a report of the synthesized output clock specs in your FPGA vendor compiler's
// message processing window during compile. The report will contain the resulting frequency down to the 0.01Hz,
// calculated PPM error and jitter spec.
//
// To simulate this project in Modelsim:
// 1) Run Modelsim all by itself.  You do not need your FPGA compiler studio.
// 2) Select 'File / Change Directory' and choose this project's folder.
// 3) In the transcript, type:                'do setup_fpd.do'.  (DONE!)
// 4) To re-compile and simulate again, type: 'do run_fpd.do'.    (DONE!)
//
// For public use.  Just be fair and give credit where it is due.
// ***************************************************************************************************************
`timescale 1 ps/1 ps
`include "BHG_FP_clk_divider.v"

localparam  USE_FLOATING_DIVIDE = 1         ; // 1= use floating point, 0= simple integer divide mode.
localparam  CLK_IN_HZ           = 100000000 ; // Source  clk_in  frequency in Hz.
localparam  CLK_OUT_HZ          = 3579545   ; // Desired clk_out frequency in Hz.

localparam  [63:0] RUNTIME_MS   = 1                        ; // Number of milliseconds to simulate.  (Must be 64 bit because of picosecond time calculation)
localparam  [63:0] PS_NUMERATOR = 1000000 * 1000000        ; // Need this number to be a 64bit integer.
localparam  [63:0] CLK_PERIOD   = PS_NUMERATOR/CLK_IN_HZ   ; // Period of simulated clock.

module BHG_FP_clk_divider_tb ();
    reg clk = 0 ; wire cnt_ena ; integer p_count = 0 ;
// ***********************************************************************************************************************************************
// Instantiate BHG_FP_clk_divider.
// ***********************************************************************************************************************************************
    BHG_FP_clk_divider #(   .USE_FLOATING_DIVIDE  ( USE_FLOATING_DIVIDE ),  // 1= use floating point, 0= simple integer divide mode.
                            .INPUT_CLK_HZ         ( CLK_IN_HZ           ),  // Source  clk_in  frequency in Hz.
                            .OUTPUT_CLK_HZ        ( CLK_OUT_HZ          )   // Desired clk_out frequency in Hz.
                  ) FPD (
                            .clk_in               ( clk                 ),  // System source clock.
                            .rst_in               ( 1'b0                ),  // Synchronous reset.
                            .clk_out              (                     ),  // Synthesized output clock, 50:50 duty cycle.
                            .clk_p0               ( cnt_ena             ),  // Strobe pulse at the rise of 'clk_out'.
                            .clk_p180             (                     )); // Strobe pulse at the fall of 'clk_out'.
// ***********************************************************************************************************************************************
    always begin clk=1'b1;#(CLK_PERIOD/2);clk=1'b0;#(CLK_PERIOD/2);end      // an ipso-de-facto source clock generator.
// ***********************************************************************************************************************************************
    always @(posedge clk) if (cnt_ena) p_count <= p_count + 1'b1 ;          // Generate a pule/frequency counter.
// ***********************************************************************************************************************************************
    always #(RUNTIME_MS * 1000 * 1000 * 1000) $stop ;                       // Stop simulation at RUNTIME_MS (milliseconds).
// ***********************************************************************************************************************************************
endmodule
