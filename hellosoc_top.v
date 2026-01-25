// iCEsugar 1.5 Top Module for ILI9341 TFT Display
// Convert SystemVerilog to plain Verilog for iCE40 FPGA
module hellosoc_top(
    input clk,
    output tft_sck,
    output tft_sdi,
    output tft_dc,
    output tft_cs,
    output [2:0] leds
);

    // Clock generation (12 MHz input from iCEsugar 1.5)
    // We need to generate ~100 MHz for the TFT and ~10 kHz for game logic
    wire tft_clk;
    wire clk_10khz;
    wire gameClk;

    // Simple clock multiplier using SB_PLL40_CORE (iCE40 PLL)
    // For iCEsugar 1.5, generate 100MHz from 12MHz input
    pll #(.DIV(1), .MUL(25), .FREQ("100")) pll_inst(
        .clk_i(clk),
        .clk_o(tft_clk)
    );

    // Clock divider: 100MHz / 10000 ~= 10 kHz
    clkdiv #(.div(10000), .bitSize(14)) clk_10k_div(tft_clk, clk_10khz);

    // Clock divider: 10kHz / 80 ~= 125 Hz (game clock)
    clkdiv #(.div(80), .bitSize(7)) gameClk_div(clk_10khz, gameClk);

    // LEDs
    reg ledA = 1'b1;
    assign leds = ~{ledA, 1'b0, 1'b0};

    // *************************** Framebuffer
    reg [16:0] framebufferIndex = 17'd0;
    wire fbClk;

    initial framebufferIndex = 17'd0;

    always @(posedge fbClk) begin
        if (framebufferIndex >= (320 * 240 - 1))
            framebufferIndex <= 17'd0;
        else
            framebufferIndex <= framebufferIndex + 1'b1;
    end

    // X,Y calc
    wire [8:0] x = framebufferIndex / 240;
    wire [7:0] y = framebufferIndex % 240;

    wire b1;
    wire b2;
    wire b3;
    ball #(.X(240), .Y(200), .VX(3), .RADIUS(48)) ball1(x, y, b1, gameClk);
    ball #(.X(120), .Y(130), .VX(-4), .RADIUS(32)) ball2(x, y, b2, gameClk);
    ball #(.X(150), .Y(210), .VX(2), .RADIUS(24)) ball3(x, y, b3, gameClk);

    wire [15:0] currentPixel = (b1 ?      16'hF800 : 16'd0) |
                               (b2 ?      16'hF805 : 16'd0) |
                               (b3 ?      16'h07E0 : 16'd0) |
                               (y == 32 ? 16'hFFFF : 16'd0) |
                               (y <= 31 && y > 0
                                   ? (((y % 4) != (x % 4)) ? 16'h001F : 16'h0005)
                                   : 16'd0);

    // *************************** TFT Module
    tft_ili9341 #(.INPUT_CLK_MHZ(100)) tft(tft_clk, 1'b0, tft_sck, tft_sdi, tft_dc, 1'b1, tft_cs, currentPixel, fbClk);

endmodule

// Ball simulation module
module ball(input [8:0] checkX, input [7:0] checkY, output reg isSet, input physicsClk);
    parameter X = 30;
    parameter Y = 30;
    parameter VX = 1;
    parameter RADIUS = 32;

    // Fixed point math (6-bit fractional part)
    localparam MIN_Y = ((31 + RADIUS/6) << 6);
    localparam MAX_Y = ((240 - RADIUS/6) << 6);
    localparam MIN_X = ((0 + RADIUS/6) << 6);
    localparam MAX_X = ((320 - RADIUS/6) << 6);

    reg signed [15:0] x = X << 6;
    reg signed [15:0] y = Y << 6;
    reg signed [15:0] vx = VX << 4;
    reg signed [15:0] vy = 0;

    wire signed [15:0] newX = x + vx;
    wire signed [15:0] newY = y - vy;

    always @(posedge physicsClk) begin
        if (newY < MIN_Y || newY > MAX_Y)
            vy <= -vy - 1;
        else begin
            y <= newY;
            vy <= vy - 1;
        end

        if (newX < MIN_X || newX > MAX_X)
            vx <= -vx;
        else
            x <= newX;
    end

    // Rendering
    wire [15:0] pixelX = (x >> 6);
    wire [15:0] pixelY = (y >> 6);
    wire [15:0] signedCheckX = checkX;
    wire [15:0] signedCheckY = checkY;
    wire [31:0] squaredDist = (pixelX - signedCheckX) * (pixelX - signedCheckX)
                              + (pixelY - signedCheckY) * (pixelY - signedCheckY);

    always @(*) begin
        isSet = (squaredDist <= (RADIUS * RADIUS));
    end

endmodule
