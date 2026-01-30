# GitHub Actions Workflow Artifacts

This document describes the extra artifacts added to the GitHub Actions workflow for this project.

## Overview

The workflow now generates and uploads additional artifacts to help visualize and understand the FPGA design:

### 1. Testbench Waveform Graphics

**Artifacts Uploaded:**
- `testbench-graphics/tb_hellosoc_wavedrom.json` - WaveDrom format representation of simulation signals
- `testbench-graphics/tb_hellosoc_waveform.svg` - Visual waveform diagram (if wavedrom-cli succeeds)
- `testbench-graphics/tb_hellosoc_waveform_info.txt` - Fallback info file with VCD details

**How it works:**
1. After the testbench simulation runs and generates `tb_hellosoc.vcd`, the workflow installs visualization tools
2. The Python script `scripts/vcd2img.py` reads the VCD file using the `vcdvcd` library
3. It converts the VCD signals to WaveDrom JSON format (up to 20 signals, 100 samples each)
4. If `wavedrom-cli` is available, it generates an SVG visualization
5. All generated files are uploaded as artifacts with 30-day retention

### 2. Logic Diagrams

**Artifacts Uploaded:**
- `logic-diagrams/hellosoc_top_diagram.svg` - Visual representation of the synthesized netlist

**How it works:**
1. After synthesis, Yosys generates `hellosoc_top.json` with the netlist
2. The workflow uses `netlistsvg` to convert this JSON to an SVG diagram
3. The diagram shows the logic gates and connections in the design
4. The SVG is uploaded as an artifact with 30-day retention

## Package Versions

The workflow uses pinned versions for reproducibility:
- `vcdvcd==2.3.3` (Python, via pip)
- `netlistsvg@1.0.0` (Node.js, via npm)
- `wavedrom-cli@2.6.8` (Node.js, via npm)

## Usage

After a workflow run completes, you can:
1. Go to the Actions tab in GitHub
2. Click on a workflow run
3. Scroll down to the "Artifacts" section
4. Download `testbench-graphics` and/or `logic-diagrams` archives
5. Extract and view the SVG files in a browser or image viewer

## Troubleshooting

If the visualization steps fail:
- The original VCD file is still uploaded separately as `testbench-waveform` artifact
- Check the workflow logs for error messages
- The workflow continues even if visualization fails (using `|| echo` for error tolerance)

## References

This implementation is based on the approach used in:
- https://github.com/naelolaiz/learning_fpga/blob/main/.github/workflows/ci.yml

Key differences:
- Uses WaveDrom instead of GTKWave for waveform visualization
- Works within the existing Docker container environment
- Includes fallback mechanisms for robustness
