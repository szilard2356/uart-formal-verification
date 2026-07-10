# uart-formal-verification
Independent Laboratory and Thesis project at Budapest University of Technology and Economics exploring modern SystemVerilog verification. Showcases custom RTL design, Assertion-Based Verification (SVA), automated Scoreboards, and Black-Box hardware testing methodologies.

# Lab Project:
**Educational Objective:** The core focus of this combined laboratory and thesis work is to gain hands-on knowledge of modern digital verification methodologies, bridging the gap between university studies and industry-standard practices.

## Architecture
Based on the project documentation, the overall system consists of a custom-designed UART Receiver (RX) and a provided UART Transmitter (TX)

### 1. The Custom UART RX Module (White-Box)

The UART RX module was fully custom-designed and implemented using SystemVerilog. It supports robust asynchronous communication configured via parameterizable data bits (5-8), stop bits (1-2), parity, and baud rate (P_DIVISOR).

* **Architecture:** The design utilizes two counters for baud rate generation and a 13x oversampling mechanism.
* **Data Path & Control:** It features a shift register for data parallelization and a Finite State Machine (FSM) operating through specific states: IDLE, START, DATA, CHECK_PARITY, and CHECK_FRAME.
* **Refinement:** During the verification phase, a false-positive frame_err issue was identified and successfully resolved by enforcing strict mid-bit sampling (counter == 6) within the FSM. 

### 2. **The UART TX Module (Black-Box IP)**

The UART TX module was provided by the project consultant as a pre-existing component. Throughout the project, this module was strictly treated as a "Black Box" Third-Party IP. The verification environment was built to validate its functional correctness solely through its external ports and interfaces without modifying its internal RTL implementation.

## Applied Verification Methodologies
To ensure the hardware met the required specifications, the verification process was executed in three stages:

* **Traditional Waveform Verification:** Initial testing relied on structured tasks and randomized stimulus generation, followed by manual visual inspection of the waveforms to detect basic functional errors.
* **Automated Self-Checking Verification (Scoreboard):** To handle extensive, automated testing (e.g., verifying robustness against baud rate deviations), parallel prediction algorithms were implemented. A Scoreboard component continuously monitored the DUT, comparing the real-time received data (rx_data) against the expected outputs.
* **Assertion-Based Verification (SVA):** To mathematically validate strict temporal rules and protocol specifications—such as ensuring the ready signal drops exactly one clock cycle after the tx_strobe—SystemVerilog Assertions were integrated into the environment. Both assert and cover statements were utilized to guarantee that all protocol states were reachable and unviolated during simulation.

# Thesis Project (Starting September 2026)

The continuation of this project will serve as the foundation for my university thesis. The primary objective is to upgrade the current UART module with additional peripherals, creating a robust RTL design, and to verify it using standard industry methodologies. 

Key milestones include:
* **System Expansion:** Upgrading the core UART architecture by integrating complex peripherals to develop a more comprehensive hardware design.
* **UVM Integration:** Transitioning the testbench environment to the Universal Verification Methodology (UVM) for highly scalable, reusable, and structured automated testing.
* **Formal Verification:** Expanding the use of SystemVerilog Assertions (SVA) beyond dynamic simulation to perform formal verification, mathematically proving corner cases and strict protocol properties.
