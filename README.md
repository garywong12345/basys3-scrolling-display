# Basys 3 FPGA Scrolling Display

## Overview
A SystemVerilog hardware design for the Digilent Basys 3 (Artix-7) FPGA that continuously scrolls a custom character message across four 7-segment displays. This project demonstrates foundational sequential logic, state-holding circuits, and proper hardware interfacing techniques.

## Core Hardware Concepts
Instead of relying on basic combinational logic, this project implements advanced sequential architecture:
* **Single-Clock Domain & Tick Generation:** Avoids clock domain crossing (CDC) issues by keeping all sequential modules on the main 100 MHz board clock. Slower updates (like scrolling) are handled by a parameterized "tick generator" that emits one-cycle clock-enable pulses.
* **Metastability Mitigation:** Interfaces with imperfect physical hardware (asynchronous pushbuttons and switches) using a two-flop synchronizer to safely handle asynchronous inputs and eliminate button bounce issues.
* **Sequential Components:** Utilizes parameterized registers, loadable up/down counters (with custom wrap-around logic), and a 5-bit wide shift register to act as the sliding "window" for the display.
* **Hardware ROM:** Implements a custom character converter (`char7seg`) and a Read-Only Memory (`message_rom`) using multiplexed case statements to store and index a custom 16-character phrase.

## Project Structure
* `top.sv`: Top-level integration wiring the clock, synchronizers, display mux, and shift registers.
* `window.sv`: A 5-bit wide shift register managing the 4-character active viewing window.
* `message_rom.sv`: The hardcoded character memory.
* `char7seg.sv`: Custom hexadecimal and custom character segment decoder.
* `counter.sv` & `mod_counter.sv`: Loadable up/down counters for position tracking.
* `tick_gen.sv`: Clock-enable pulse generator.
* `register.sv`: Parameterized base register.

## Hardware & Tools
* **Board:** Digilent Basys 3 (Xilinx Artix-7 FPGA)
* **Language:** SystemVerilog
* **Simulation:** Vivado Simulator