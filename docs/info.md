## How it works

This project implements the **Butterfly Unit** for the Number Theoretic Transform (NTT) used in the **CRYSTALS-Dilithium** Post-Quantum Cryptography (PQC) scheme.

The design performs modular arithmetic operations required for polynomial multiplication in the ring `Z_q[X]/(X^256 + 1)` where `q = 8380417`.

Key features:
* **Modular Arithmetic:** Implements efficient modular addition, subtraction, and multiplication.
* **Barrett Reduction:** Uses a hardware-optimized Barrett Reducer (generated via Chisel) to perform fast modular reduction without expensive division operations.
* **Configurable Modes:** Supports Forward NTT, Inverse NTT, Point-wise Multiplication, Addition, and Subtraction.

**Data Flow:**
Due to the limited IO pins on TinyTapeout (8 in, 8 out), the design uses a **Shift Register Interface**:
1.  **Input Loading:** 76 bits of configuration and data (Mode, Valid, Coefficient A, Length A, Zeta) are shifted in serially via `ui_in[1]` using `ui_in[0]` as the shift enable.
2.  **Processing:** Once loaded, the `load_inputs` signal (`ui_in[2]`) latches the data into the core. The Butterfly unit processes the data in a single clock cycle.
3.  **Output Retrieval:** The results (Coefficient B, Length B, Valid Out) are loaded into an output shift register via `ui_in[3]` and then shifted out serially via `uo_out[0]`.

## How to test

To test the chip, you need to interface with the serial protocol:

1.  **Reset:** Pulse `rst_n` low to reset the internal state.
2.  **Shift In Data:**
    * Set `ui_in[0]` (Shift Enable) HIGH.
    * Feed 76 bits of data into `ui_in[1]` (Data In) synchronized with the clock.
    * The data order is: `{mode[2:0], validi, aj[23:0], ajlen[23:0], zeta[23:0]}`.
3.  **Load & Compute:**
    * Set `ui_in[0]` LOW.
    * Pulse `ui_in[2]` (Load Inputs) HIGH for one clock cycle.
    * Wait one clock cycle for the result to compute.
4.  **Capture Output:**
    * Pulse `ui_in[3]` (Load Outputs) HIGH for one clock cycle.
5.  **Shift Out Results:**
    * Set `ui_in[0]` HIGH.
    * Read the result bit-by-bit from `uo_out[0]`.
    * The data order is: `{valido, bj[23:0], bjlen[23:0]}`.

This sequence can be automated using a microcontroller (like the RP2040 on the TinyTapeout demo board) or the provided Cocotb testbench.

## External hardware

* No specific external hardware is required, but a logic analyzer or microcontroller is recommended to drive the serial interface at high speeds.
