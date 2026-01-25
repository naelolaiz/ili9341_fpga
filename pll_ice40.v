// iCE40 PLL Module for iCEsugar 1.5
// Generates different clock frequencies from the 12MHz input clock

// For synthesis: Use the iCE40 PLL primitive
// For simulation: Simple clock passthrough
(* blackbox *)
module SB_PLL40_CORE(
    input REFERENCECLK,
    input RESETB,
    input BYPASS,
    output PLLOUTCORE
);
    parameter FEEDBACK_PATH = "SIMPLE";
    parameter PLLOUT_SELECT = "GENCLK";
    parameter DIVR = 4'b0100;
    parameter DIVF = 7'b0011000;
    parameter DIVQ = 3'b011;
    parameter FILTER_RANGE = 3'b001;
endmodule

module pll(
    input clk_i,
    output clk_o
);

    parameter DIV = 1;
    parameter MUL = 25;
    parameter FREQ = "100"; // output frequency in MHz
    
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0100),        // DIVR = 4
        .DIVF(7'b0011000),     // DIVF = 24
        .DIVQ(3'b011),         // DIVQ = 3
        .FILTER_RANGE(3'b001)
    ) pll_inst (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk_i),
        .PLLOUTCORE(clk_o)
    );

endmodule
