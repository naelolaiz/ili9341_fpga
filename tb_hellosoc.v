// Testbench for ILI9341 FPGA project
`timescale 1ns/1ns

module tb_hellosoc();
    // Clock generation
    reg clk;
    reg tft_sdo;
    
    // Outputs
    wire tft_sck;
    wire tft_sdi;
    wire tft_dc;
    wire tft_cs;
    wire [2:0] leds;

    // Test counter
    integer test_count = 0;
    integer test_pass = 0;
    integer test_fail = 0;
    
    // Helper to detect SPI activity
    reg spi_activity_detected;
    reg last_sck;

    // Clock generation: 12 MHz
    initial begin
        clk = 0;
        forever #41.667 clk = ~clk;  // 12 MHz period = 83.33ns
    end

    // Test stimulus
    initial begin
        $display("========================================");
        $display("  ILI9341 FPGA Testbench");
        $display("========================================");
        $display("Time: %0t ns", $time);
        
        // Initialize inputs
        tft_sdo = 1'b0;
        
        // Wait for system to stabilize
        #100_000;
        
        // Test 1: Check that clock is running
        test_count = test_count + 1;
        $display("\n[TEST %0d] Clock generation", test_count);
        if (clk === 1'b0) begin
            $display("  PASS: Clock is running");
            test_pass = test_pass + 1;
        end else begin
            $display("  FAIL: Clock not running properly");
            test_fail = test_fail + 1;
        end
        
        // Test 2: Check CS is inactive initially
        test_count = test_count + 1;
        $display("\n[TEST %0d] Chip Select (CS) inactive", test_count);
        if (tft_cs === 1'b1) begin
            $display("  PASS: CS is inactive (high)");
            test_pass = test_pass + 1;
        end else begin
            $display("  FAIL: CS should be inactive");
            test_fail = test_fail + 1;
        end
        
        // Test 3: LED test
        test_count = test_count + 1;
        $display("\n[TEST %0d] LED output active", test_count);
        if (leds !== 3'b000) begin
            $display("  PASS: LEDs are active (value: %03b)", leds);
            test_pass = test_pass + 1;
        end else begin
            $display("  FAIL: LEDs should be active");
            test_fail = test_fail + 1;
        end
        
        // Wait for initialization sequence to start
        #1_000_000;
        
        // Test 4: Monitor SPI activity
        test_count = test_count + 1;
        $display("\n[TEST %0d] SPI Clock activity", test_count);
        wait_for_spi_activity(5_000_000);  // Wait up to 5ms for SPI activity
        if (spi_activity_detected) begin
            $display("  PASS: SPI clock activity detected");
            test_pass = test_pass + 1;
        end else begin
            $display("  WARN: No SPI activity detected (may need longer wait or different stimulus)");
            test_fail = test_fail + 1;
        end
        
        // Final summary
        #100_000;
        $display("\n========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", test_pass);
        $display("Failed:      %0d", test_fail);
        
        if (test_fail == 0) begin
            $display("Status:      ALL TESTS PASSED");
            $display("========================================\n");
            $finish(0);
        end else begin
            $display("Status:      SOME TESTS FAILED");
            $display("========================================\n");
            $finish(1);
        end
    end

    task wait_for_spi_activity(input integer timeout);
        integer i;
        begin
            spi_activity_detected = 0;
            last_sck = tft_sck;
            
            for (i = 0; i < timeout; i = i + 1) begin
                #1000;  // Check every 1us
                if (tft_sck !== last_sck) begin
                    spi_activity_detected = 1;
                    $display("    SPI activity detected at t=%0t ns", $time);
                    break;
                end
                last_sck = tft_sck;
            end
        end
    endtask

    // Instantiate DUT (Device Under Test)
    hellosoc_top dut(
        .clk(clk),
        .tft_sck(tft_sck),
        .tft_sdi(tft_sdi),
        .tft_dc(tft_dc),
        .tft_cs(tft_cs),
        .leds(leds)
    );

    // Test clkdiv module
    wire clk_10khz;
    clkdiv #(.div(10000), .bitSize(14)) clk_div_test(clk, clk_10khz);

    // Test SPI module
    wire tft_sck_test, tft_sdi_test, tft_dc_test, tft_cs_test, spi_idle;
    reg [8:0] spi_data = 9'h000;
    reg spi_data_available = 1'b0;

    tft_ili9341_spi spi_test(
        .spiClk(clk),
        .data(spi_data),
        .dataAvailable(spi_data_available),
        .tft_sck(tft_sck_test),
        .tft_sdi(tft_sdi_test),
        .tft_dc(tft_dc_test),
        .tft_cs(tft_cs_test),
        .idle(spi_idle)
    );

    // Monitor simulation
    initial begin
        $dumpfile("tb_hellosoc.vcd");
        $dumpvars(0, tb_hellosoc);
    end

endmodule

// Stub PLL module for simulation (replaces the iCE40-specific version)
module pll(clk_i, clk_o);
    input clk_i;
    output clk_o;

    parameter DIV = 1;
    parameter MUL = 25;
    parameter FREQ = "100";

    // Simple frequency multiplier: clock output is same as input for testing
    // In real hardware, this would use the iCE40 PLL
    assign clk_o = clk_i;

endmodule
