# ILI9341 LCD Driver for iCE40 FPGA (iCEsugar 1.5)

This is a port of the ILI9341 TFT LCD display driver to the iCEsugar 1.5 board, converted from SystemVerilog to plain Verilog and adapted for the open-source FPGA toolchain.

## Changes from Original

- **Converted from SystemVerilog to plain Verilog** - Removed all SystemVerilog-specific syntax
  - Replaced `enum` with `localparam` constants
  - Replaced `<<<` and `>>>` with `<<` and `>>` shift operators
  - Removed `wire` keyword from outputs in module instantiation
  - Converted array initialization to explicit assignment in initial blocks

- **Ported to iCE40 HX8K FPGA** (iCEsugar 1.5)
  - Replaced Quartus-specific files with open-source toolchain files
  - Updated PLL module to use iCE40 `SB_PLL40_PAD` primitive
  - Created PCF constraint file for iCEsugar 1.5 pinout

- **Build system changes**
  - Quartus project files removed
  - Added Makefile for yosys + nextpnr workflow

## Files

### Core Driver
- `tft_ili9341.v` - Main display driver (plain Verilog)
- `tft_ili9341_spi.v` - SPI interface implementation
- `hellosoc_top.v` - Top-level module with example animation
- `clkdiv.v` - Clock divider utility module
- `pll_ice40.v` - iCE40 PLL configuration

### Build Files
- `Makefile` - Build system for yosys/nextpnr
- `icesugar.pcf` - Pin constraint file for iCEsugar 1.5

## Hardware Connections (iCEsugar 1.5)

| Signal | iCEsugar Pin | Description |
|--------|------------|-------------|
| clk | J3 | 12 MHz clock input |
| tft_sck | G2 | SPI Clock |
| tft_sdi | H2 | SPI Data In (MOSI) |
| tft_sdo | F1 | SPI Data Out (MISO) |
| tft_dc | H1 | Data/Command select |
| tft_reset | K1 | Display reset (active low) |
| tft_cs | K2 | Chip Select (active low) |
| leds[0:3] | C3, B3, C4, A4 | Status LEDs |

## Building

### Prerequisites

Install the open-source FPGA toolchain:

```bash
# On Ubuntu/Debian
sudo apt-get install yosys nextpnr-ice40 icepack

# For programming (if using iceprog)
sudo apt-get install iceprog libftdi-dev
```

### Build Commands

```bash
# Build bitstream
make

# Build and program the FPGA
make prog

# Clean build artifacts
make clean

# Show help
make help
```

The build output is `hellosoc_top.bin`, which can be programmed to the iCEsugar 1.5 board.

## How It Works

The driver implements a frame-buffer based controller for the ILI9341 display:

1. **Initialization** - Resets the display and sends initialization sequence per ILI9341 datasheet
2. **Pixel Output** - Continuously updates the display at ~50 MHz SPI clock
3. **Demo Animation** - Includes bouncing ball animation on the 320x240 display

The example includes three bouncing balls with physics simulation running at ~125 Hz.

## Design Notes

- Input clock: 12 MHz (provided by iCEsugar 1.5)
- Generated TFT clock: ~100 MHz
- Display SPI clock: ~50 MHz (from SPI divider)
- Game/physics clock: ~125 Hz
- Display resolution: 320x240 pixels
- Color depth: 16-bit RGB565

## Pinout Customization

To change pins, edit `icesugar.pcf` and modify the `set_io` commands. Refer to the iCEsugar 1.5 pinout diagram for available pins.

## Troubleshooting

### Build Fails
- Ensure yosys, nextpnr-ice40, and icepack are installed and in PATH
- Check that Verilog files have no syntax errors

### Display Not Working
- Verify SPI connections match the PCF file
- Check that 3.3V power is supplied to both the FPGA and display
- Ensure display reset pin is properly connected
- Some ILI9341 modules require a 10kΩ pull-up on the reset line

### Slow Simulation
- The design is optimized for hardware; simulation may be slow
- Use `make clean` and rebuild if making changes

## References

- [iCEsugar 1.5 Documentation](https://github.com/musashino205/icesugar)
- [iCE40 HX8K Datasheet](https://www.latticesemi.com/en/Products/FPGAandCPLD/iCE40)
- [ILI9341 Display Datasheet](http://www.buydisplay.com/)
- [Yosys Synthesis Tool](http://www.clifford.at/yosys/)
- [nextpnr Place & Route](https://github.com/YosysHQ/nextpnr)
