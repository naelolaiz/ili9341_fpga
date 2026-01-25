// iCE40 PLL Module for iCEsugar 1.5
// Generates different clock frequencies from the 12MHz input clock
module pll(
    input clk_i,
    output clk_o
);

    parameter DIV = 1;
    parameter MUL = 25;
    parameter FREQ = "100"; // output frequency in MHz

    // Instantiate SB_PLL40_CORE for iCE40
    // Default: 12MHz * 25 / 3 = 100MHz
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0100),        // DIVR = 4 (12MHz input divider)
        .DIVF(7'b0011000),     // DIVF = 24 (multiply by 25, so 24+1)
        .DIVQ(3'b011),         // DIVQ = 3 (divide by 8, final divider)
        .FILTER_RANGE(3'b001)
    ) pll_inst (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk_i),
        .PLLOUTCORE(clk_o)
    );

endmodule
