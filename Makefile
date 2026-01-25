# Makefile for iCEsugar 1.5 FPGA build
# Builds ILI9341 TFT display controller for iCE40 FPGA

PROJ = hellosoc_top
DEVICE = 1k
PACKAGE = cb132

YOSYS = yosys
NEXTPNR = nextpnr-ice40
ICEPACK = icepack
ICEPROG = iceprog

# Source files
SOURCES = \
	hellosoc_top.v \
	tft_ili9341.v \
	tft_ili9341_spi.v \
	clkdiv.v \
	pll_ice40.v

CONSTRAINT = icesugar.pcf

# Build targets
all: $(PROJ).bin

$(PROJ).json: $(SOURCES)
	$(YOSYS) -p "synth_ice40 -json $@ -top $(PROJ)" $(SOURCES)

$(PROJ).config: $(PROJ).json $(CONSTRAINT)
	$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --json $< --pcf $(CONSTRAINT) --asc $@

$(PROJ).bin: $(PROJ).config
	$(ICEPACK) $< $@

.PHONY: prog
prog: $(PROJ).bin
	$(ICEPROG) $<

.PHONY: clean
clean:
	rm -f $(PROJ).json $(PROJ).config $(PROJ).bin

.PHONY: help
help:
	@echo "iCEsugar 1.5 Build System"
	@echo "========================"
	@echo "Targets:"
	@echo "  all       - Build the bitstream (default)"
	@echo "  prog      - Build and program the FPGA"
	@echo "  clean     - Remove build artifacts"
	@echo ""
	@echo "Requirements:"
	@echo "  - yosys"
	@echo "  - nextpnr-ice40"
	@echo "  - icepack"
	@echo "  - iceprog (for programming)"

.DEFAULT_GOAL := all
