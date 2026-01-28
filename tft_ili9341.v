// Simple frame-buffer based driver for the ILI9341 TFT module
module tft_ili9341(
    input clk,
    input tft_sdo,
    output tft_sck,
    output tft_sdi,
    output tft_dc,
    output tft_reset,
    output tft_cs,
    input [15:0] framebufferData,
    output framebufferClk
);

    parameter INPUT_CLK_MHZ = 120; // recommended

    // Initial assignments
    reg tft_reset_reg;
    assign tft_reset = tft_reset_reg;

    initial tft_reset_reg = 1'b1;

    // Assign pins and modules
    reg [8:0] spiData;
    reg spiDataSet = 1'b0;
    wire spiIdle;

    reg frameBufferLowNibble = 1'b1;
    assign framebufferClk = !frameBufferLowNibble;

    tft_ili9341_spi spi(
        .spiClk(clk),
        .data(spiData),
        .dataAvailable(spiDataSet),
        .tft_sck(tft_sck),
        .tft_sdi(tft_sdi),
        .tft_dc(tft_dc),
        .tft_cs(tft_cs),
        .idle(spiIdle)
    );

    // Init Sequence Data
    localparam INIT_SEQ_LEN = 52;
    reg [5:0] initSeqCounter = 6'b0;
    reg [8:0] INIT_SEQ [0:51];

    initial begin
        INIT_SEQ[0]  = {1'b0, 8'h28};
        INIT_SEQ[1]  = {1'b0, 8'hCF};
        INIT_SEQ[2]  = {1'b1, 8'h00};
        INIT_SEQ[3]  = {1'b1, 8'h83};
        INIT_SEQ[4]  = {1'b1, 8'h30};
        INIT_SEQ[5]  = {1'b0, 8'hED};
        INIT_SEQ[6]  = {1'b1, 8'h64};
        INIT_SEQ[7]  = {1'b1, 8'h03};
        INIT_SEQ[8]  = {1'b1, 8'h12};
        INIT_SEQ[9]  = {1'b1, 8'h81};
        INIT_SEQ[10] = {1'b0, 8'hE8};
        INIT_SEQ[11] = {1'b1, 8'h85};
        INIT_SEQ[12] = {1'b1, 8'h01};
        INIT_SEQ[13] = {1'b1, 8'h79};
        INIT_SEQ[14] = {1'b0, 8'hCB};
        INIT_SEQ[15] = {1'b1, 8'h39};
        INIT_SEQ[16] = {1'b1, 8'h2C};
        INIT_SEQ[17] = {1'b1, 8'h00};
        INIT_SEQ[18] = {1'b1, 8'h34};
        INIT_SEQ[19] = {1'b1, 8'h02};
        INIT_SEQ[20] = {1'b0, 8'hF7};
        INIT_SEQ[21] = {1'b1, 8'h20};
        INIT_SEQ[22] = {1'b0, 8'hEA};
        INIT_SEQ[23] = {1'b1, 8'h00};
        INIT_SEQ[24] = {1'b1, 8'h00};
        INIT_SEQ[25] = {1'b0, 8'hC0};
        INIT_SEQ[26] = {1'b1, 8'h26};
        INIT_SEQ[27] = {1'b0, 8'hC1};
        INIT_SEQ[28] = {1'b1, 8'h11};
        INIT_SEQ[29] = {1'b0, 8'hC5};
        INIT_SEQ[30] = {1'b1, 8'h35};
        INIT_SEQ[31] = {1'b1, 8'h3E};
        INIT_SEQ[32] = {1'b0, 8'hC7};
        INIT_SEQ[33] = {1'b1, 8'hBE};
        INIT_SEQ[34] = {1'b0, 8'h3A};
        INIT_SEQ[35] = {1'b1, 8'h55};
        INIT_SEQ[36] = {1'b0, 8'hB1};
        INIT_SEQ[37] = {1'b1, 8'h00};
        INIT_SEQ[38] = {1'b1, 8'h1B};
        INIT_SEQ[39] = {1'b0, 8'h26};
        INIT_SEQ[40] = {1'b1, 8'h01};
        INIT_SEQ[41] = {1'b0, 8'h51};
        INIT_SEQ[42] = {1'b1, 8'hFF};
        INIT_SEQ[43] = {1'b0, 8'hB7};
        INIT_SEQ[44] = {1'b1, 8'h07};
        INIT_SEQ[45] = {1'b0, 8'hB6};
        INIT_SEQ[46] = {1'b1, 8'h0A};
        INIT_SEQ[47] = {1'b1, 8'h82};
        INIT_SEQ[48] = {1'b1, 8'h27};
        INIT_SEQ[49] = {1'b1, 8'h00};
        INIT_SEQ[50] = {1'b0, 8'h29};
        INIT_SEQ[51] = {1'b0, 8'h2C};
    end

    // State machine states
    localparam START = 0;
    localparam HOLD_RESET = 1;
    localparam WAIT_FOR_POWERUP = 2;
    localparam SEND_INIT_SEQ = 3;
    localparam LOOP = 4;

    // State machine with delay + idle support
    reg [23:0] remainingDelayTicks = 24'b0;
    reg [2:0] state = START;

    always @(posedge clk) begin
        // clear data flag first
        spiDataSet <= 1'b0;

        // always decrement delay ticks
        if (remainingDelayTicks > 0) begin
            remainingDelayTicks <= remainingDelayTicks - 1'b1;
        end
        else if (spiIdle && !spiDataSet) begin
            // advance state machine to next state
            case (state)
                // initialize all pins in START mode; reset the LCD
                START: begin
                    tft_reset_reg <= 1'b0;
                    remainingDelayTicks <= INPUT_CLK_MHZ * 10; // min: 10us
                    state <= HOLD_RESET;
                end

                // wait for RESET to kick in; then release pin & wait for power up
                HOLD_RESET: begin
                    tft_reset_reg <= 1'b1; // release pin
                    remainingDelayTicks <= INPUT_CLK_MHZ * 120000; // min: 120ms
                    state <= WAIT_FOR_POWERUP;
                    frameBufferLowNibble <= 1'b0; // request first pixel
                end

                // if power up is completed -> sw reset
                WAIT_FOR_POWERUP: begin
                    spiData <= {1'b0, 8'h11}; // take out of sleep mode
                    spiDataSet <= 1'b1;
                    remainingDelayTicks <= INPUT_CLK_MHZ * 5000; // min: 5ms
                    state <= SEND_INIT_SEQ;
                    frameBufferLowNibble <= 1'b1;
                end

                // setup the LCD by sending the init sequence
                SEND_INIT_SEQ: begin
                    if (initSeqCounter < INIT_SEQ_LEN) begin
                        spiData <= INIT_SEQ[initSeqCounter];
                        spiDataSet <= 1'b1;
                        initSeqCounter <= initSeqCounter + 1'b1;
                    end else begin
                        state <= LOOP;
                        remainingDelayTicks <= INPUT_CLK_MHZ * 10000; // min: 10ms
                    end
                end

                // frame buffer loop
                LOOP: begin
                    spiData <= !frameBufferLowNibble ? {1'b1, framebufferData[15:8]} : {1'b1, framebufferData[7:0]};
                    spiDataSet <= 1'b1;
                    frameBufferLowNibble <= !frameBufferLowNibble;
                end

                default: begin
                    // default case
                end
            endcase
        end
    end
endmodule
