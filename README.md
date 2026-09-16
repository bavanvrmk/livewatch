# livewatch

A plug-and-play open hardware watchpoint module for non-intrusive multicore debugging on FPGAs. 

## The Problem
When debugging concurrent/multicore programs, traditional debuggers (like gdb) work by halting execution. Pausing even one core changes the relative timing between cores. This often makes race conditions and concurrency bugs disappear while debugging, only to reappear in production.

## The Solution
This project implements a small hardware "watchpoint" module that sits passively on the memory bus. When a core writes to a watched address, the module captures the new value, a precise timestamp, and the core ID. It streams this data out over a UART channel to a host PC. The program never stops, and you get a live, ordered history of how a variable evolved across cores.

## Project Structure
* `hw/src/`: Hardware RTL (Verilog) for the watchpoint IP, UART transmitter, and a sample SoC integration.
* `hw/tb/`: Simulation testbenches.
* `sw/firmware/`: Sample C firmware demonstrating a multicore race condition to be deployed on soft cores.
* `sw/host/`: Python host-side tool (`watch.py`) to stream the UART data and render the live timeline.

## Usage
### 1. Hardware Integration
Instantiate the `watchpoint.v` (or the included AXI4-Lite wrapper `axi4l_watchpoint.v`) IP on your SoC's memory bus, connect its FIFO output to the `uart_tx.v` serializer, and route the UART pin to a physical pad on your FPGA. 
A hardware simulation can be run using the included Makefile in the `hw/` directory (requires Icarus Verilog).

### 2. Host Tool
Run the python watcher script on your host machine to monitor the variable.
```bash
pip install pyserial
python sw/host/watch.py --port COM1 --baud 115200 --live 0x1000
```

## Status
This repo is an open-hardware reference implementation for the Live Watch system. The core bus-snooping IP, standard AXI4-Lite wrappers, simulation build tools, and the host Python timeline-viewer are all implemented. The provided C demo firmware can be compiled using the standard RISC-V GNU toolchain.
