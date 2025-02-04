// ******************************************************************************************************
//
// BHG_FP_clk_divider.v   V1.3, Feb 02, 2025.
// Floating point clock divider/synthesizer.
// 24.16 (m.n) bit floating point clock divider. (Actually it is a fixed point fractional divider.)
//
// 1.3 - Corrected the PPM calculation + added 1 bit to the M divider counter for the occasional requirement. (Thanks to 'dennowiggle' for catching the bugs)
// 1.2 - Added a protection for when the integer divider has less than 2 bits.
//     - Added a compilation $error and $stop with instructions if the user supplies inoperable CLK_HZ parameters.
// 1.1 - Fixed a bug with some Modelsim versions where its 'Compile / Compile Options / Language Syntax' is set to 'Use Verilog 2001' instead of 'Default'.
// 1.0 - Initial release.
//
// Written by Brian Guralnick.
// https://github.com/BrianHGinc / or / https://www.eevblog.com/forum/fpga/ User BrianHG.
//
// Provide / define the INPUT_CLK_HZ parameter and the BHG_FP_clk_divider
// will generate a clock at the specified CLK_OUT_HZ parameter.  The module
// will output a 50:50 duty cycle clock plus two single clk_in cycle pulsed
// outputs, one at the rise of the clk_out, and another at the fall of clk_out.
//
// *** The module will generate a report of the synthesized output clock specs
// in your FPGA vendor compiler's message processing window during compile.
// The report will contain the resulting frequency down to the 0.01Hz,
// calculated PPM error and jitter spec.
//
//
// For public use.  Just be fair and give credit where it is due.
//
// ******************************************************************************************************

module BHG_FP_clk_divider (

    input        clk_in         , // System source clock.
    input        rst_in         , // Synchronous reset.
    output reg   clk_out    = 0 , // Synthesized output clock, 50:50 duty cycle.
    output reg   clk_p0     = 0 , // Strobe pulse at the rise of 'clk_out'.
    output reg   clk_p180   = 0   // Strobe pulse at the fall of 'clk_out'.

);

parameter USE_FLOATING_DIVIDE = 1         ; // 1= use floating point, 0= simple integer divide mode.
parameter INPUT_CLK_HZ        = 100000000 ; // Source  clk_in  frequency in Hz.
parameter OUTPUT_CLK_HZ       = 3579545   ; // Desired clk_out frequency in Hz.


// ****************************************************************************
// Inoperable Parameter Error
// ****************************************************************************
generate
if ( (OUTPUT_CLK_HZ*2)>INPUT_CLK_HZ )  initial begin
$display("");
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$display("  XXXXX                                                       XXXXX");
$display("  XXXXX   BHG_FP_clk_divider.v inoperable parameter error.    XXXXX");
$display("  XXXXX   https://github.com/BrianHGinc                       XXXXX");
$display("  XXXXX                                                       XXXXX");
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$display("  XXXXX                                                                                                        XXXXX");
$display("  XXXXX   BHG_FP_clk_divider.v can only generate an output clock at least 1/2 the source clock frequency.      XXXXX");
$display("  XXXXX                                                                                                        XXXXX");
$display("  XXXXX   Your current set parameters:                                                                         XXXXX");
$display("  XXXXX                                                                                                        XXXXX");
$display("  XXXXX     .INPUT_CLK_HZ  = %d Hz.                                                                   XXXXX",31'(INPUT_CLK_HZ));
$display("  XXXXX     .OUTPUT_CLK_HZ = %d Hz.                                                                   XXXXX",31'(OUTPUT_CLK_HZ));
$display("  XXXXX                                                                                                        XXXXX");
$display("  XXXXX   .OUTPUT_CLK_HZ must be less than or equal to .INPUT_CLK_HZ/2 for BHG_FP_clk_divider.v to function.   XXXXX");
$display("  XXXXX                                                                                                        XXXXX");
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$warning("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$error;
$stop;
end
endgenerate

// *************************************************************************************************************************************************************
//     Forcing 64 bits is required due to a ModelSim internal bug where if 'PLL1_OUT_TRUE_HZ*655360' exceeds 31 bits, it's considered negative and cropped
//     when computing the localparam.  So, never use 'localparam int' when going above 2 billion anywhere inside, or you will get bogus results.
// *************************************************************************************************************************************************************

localparam [63:0] clk_per_x65kX10  = INPUT_CLK_HZ * 655360 / OUTPUT_CLK_HZ                             ; // Determine the audio period 655360 fold.
localparam [63:0] clk_per_x65k     = (clk_per_x65kX10 + 5) / 10                                        ; // Trick to consider the decimal 0.5 rounding.
localparam [63:0] clk_per_round    = clk_per_x65k + 32768                                              ; // Prepare a rounded version.

localparam [23:0] clk_per_int      = USE_FLOATING_DIVIDE  ? clk_per_x65k[39:16] : clk_per_round[39:16] ; // Select between the rounded integer period or true integer period.
localparam [15:0] clk_per_f        = USE_FLOATING_DIVIDE  ? clk_per_x65k[15:0]  : 16'd0                ; // select between no floating point and floating point clock period.

localparam [63:0] clk_tru_hzX100   = INPUT_CLK_HZ * 6553600 / (clk_per_int*65536+clk_per_f)            ; // Calculate the true output clock X 100.
localparam signed clk_dif_hzX100   = (clk_tru_hzX100 - (OUTPUT_CLK_HZ*100))                            ;
localparam signed clk_ppm_x100     =  clk_dif_hzX100 * 1000000 / OUTPUT_CLK_HZ                         ; // Calculate the PPM offset error X 100.
localparam [63:0] clk_jitterx100   = (clk_per_f==0) ? 0 : (100000*1000000/INPUT_CLK_HZ) /2             ; // Calculate the occasional jitter X 100 generated by the floating point clock correction clock step.  

localparam real   f_tru            = clk_tru_hzX100                                                    ; // Necessary for being able to display the decimal point
localparam real   f_ppm            = clk_ppm_x100                                                      ; // in both Modelsim and Quartus's compiler messages
localparam real   f_jit            = clk_jitterx100                                                    ; // in the same way.
localparam real   f_div            = clk_per_f                                                         ;

// ****************************************************************************
// Display calculated clock divider specs in the compiler's message window.
// ****************************************************************************
generate
initial begin
$display("");
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$display("  XXX   BHG_FP_clk_divider.v settings/results.   XXX");
$display("  XXX   https://github.com/BrianHGinc            XXX");
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$display("  XXX   USE_FLOATING_DIVIDE = %0d"                                                                  ,   (USE_FLOATING_DIVIDE    ));
$display("  XXX   Set INPUT_CLK_HZ    = %0d Hz."                                                              ,   (INPUT_CLK_HZ           ));
$display("  XXX   Set OUTPUT_CLK_HZ   = %0d Hz."                                                              ,   (OUTPUT_CLK_HZ          ));
$display("  XXX   --------------------------------------------- (Floats only accurate to 2 decimal places)"); //**** %0.2f works in Modelsim, not Quartus. ****
$display("  XXX   True output freq    = %f Hz."                                                               ,   (f_tru/100              ));
$display("  XXX   Frequency error     = %f ppm."                                                              ,   (f_ppm/100              ));
$display("  XXX   Periodic jitter     = +/- %f ns."                                                           ,   (f_jit/100              ));
$display("  XXX   ---------------------------------------------");
$display("  XXX   Integer Divider     = %0d."                                                                 ,   (clk_per_int            ));
$display("  XXX   Divider Fraction    = %0d/65536.           OutHz = InHz/(ID+(DF/65536))"                    ,   (clk_per_f              ));
$display("  XXX   ~Divider to 6dp.    = %f."                                                                  ,   (f_div/65536+clk_per_int));
$display("  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
$display("");
end
endgenerate


// ****************************************************************************
// Floating point clock divider logic.
// ****************************************************************************

localparam pmb = $clog2(clk_per_int) + 1;
localparam mb  = (pmb<2) ? 2 : pmb  ; // Protection for when the integer divider has less than 2 bits.

reg [mb-1:0] clk_cnt_m = (mb)'(0) ; // This integer counts up 1 by 1 requiring manual bit reduction 'mb' for minimum logic cells.
reg [16:0]   clk_cnt_n = 17'd0    ; // This fractional int adds upward by a fixed parameter, the FPGA compiler is capable of automatically pruning unused bits.

always @(posedge clk_in) begin

    if (rst_in) begin
            clk_cnt_m  <= (mb)'(0) ;
            clk_cnt_n  <= 17'd0    ;
            clk_out    <=  1'b0    ;
            clk_p0     <=  1'b0    ;
            clk_p180   <=  1'b0    ;
    end else begin
    
        if ( clk_cnt_m == (clk_per_int[mb-1:0] - !clk_cnt_n[16]) ) begin      // Add 1 extra count to the period if the carry flag clk_cnt_n[16] is set.

            clk_cnt_m  <= (mb)'(0) ;
            clk_p0     <=  1'b1    ;
            clk_out    <=  1'b1    ;
            clk_cnt_n  <= clk_cnt_n[15:0] + clk_per_f ;                       // add the floating point period while clearing the carry flag clk_cnt_n[16].

        end else begin

            clk_cnt_m  <= 1'b1 + clk_cnt_m ;
            clk_p0     <= 1'b0 ;

            if (clk_cnt_m[mb-2:0]==(clk_per_int[mb-1:1]-1)) clk_out  <= 1'b0 ; // generate an approximate 50/50 duty cycle clk_out output.

        end
        
            if (clk_cnt_m[mb-2:0]==(clk_per_int[mb-1:1]-1)) clk_p180 <= 1'b1 ; // generate the 180 degree phase pulse.
            else                                            clk_p180 <= 1'b0 ; // clear the 180 degree phase pulse.
        
    end
end
endmodule
