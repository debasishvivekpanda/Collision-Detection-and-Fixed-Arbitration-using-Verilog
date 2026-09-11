# Collision-Detection-and-Fixed-Arbitration-using-Verilog

A modular Verilog HDL implementation of a centralized, fixed-priority bus arbitration and collision-free communication scheme designed for multi-node shared-medium architectures (e.g., RS-485 multi-drop networks).

---

## 📖 Table of Contents
- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Module Descriptions](#module-descriptions)
  - [1. Fixed-Priority Arbiter (`Arbitration_fixed.v`)](#1-fixed-priority-arbiter-arbitration_fixedv)
  - [2. Node Controller (`node.v`)](#2-node-controller-nodev)
  - [3. Shared Bus & Collision Detector (`bus.v`)](#3-shared-bus--collision-detector-busv)
  - [4. Top-Level Integration (`top.v`)](#4-top-level-integration-topv)
- [FSM State Diagram & Protocol Timing](#fsm-state-diagram--protocol-timing)
- [Directory Layout](#directory-layout)
- [Simulation & Verification](#simulation--verification)
  - [Prerequisites](#prerequisites)
  - [Using Icarus Verilog & GTKWave](#using-icarus-verilog--gtkwave)
  - [Using ModelSim / QuestaSim](#using-modelsim--questasim)
  - [Using Vivado Simulator (xsim)](#using-vivado-simulator-xsim)
- [Synthesis Considerations & Latch Prevention](#synthesis-considerations--latch-prevention)

---

## Overview

In multi-drop shared-medium topologies such as RS-485, bus contention and packet collision occur if multiple nodes assert transmit enable (`tx_en`) concurrently. This project implements a hardware-based **Fixed-Priority Bus Access Protocol** where:
- Four independent transmitter nodes (`Node 0` to `Node 3`) assert transaction requests asynchronously.
- A centralized combinational arbiter resolves concurrent requests using strict priority ordering:
  $$\text{Node 0 (Highest Priority)} > \text{Node 1} > \text{Node 2} > \text{Node 3 (Lowest Priority)}$$
- A shared tri-state multiplexed bus model drives serial line data and monitors for concurrent transmission violations via a real-time hardware collision flag.

---

## System Architecture

```
        +--------------------------------------------------------------+
        |                            top.v                             |
        |                                                              |
        |  +-----------+           grant[3:0]           +-----------+  |
        |  |           |<-------------------------------|           |  |
        |  |  Node 0   |-----------\                    |           |  |
        |  +-----------+  req[0]    \                   |           |  |
        |  +-----------+             \                  |           |  |
        |  |  Node 1   |-----------+  +---------------->|  Fixed    |  |
        |  +-----------+  req[1]   |  |   request[3:0]  |  Priority |  |
        |  +-----------+           +--+                 |  Arbiter  |  |
        |  |  Node 2   |-----------+  |                 |           |  |
        |  +-----------+  req[2]   |  |                 +-----------+  |
        |  +-----------+           |  |                                |
        |  |  Node 3   |-----------+--+                                |
        |  +-----------+  req[3]                                       |
        |       |                                                      |
        |       | tx_en[3:0], tx_data[3:0]                             |
        |       v                                                      |
        |  +--------------------------------------------------------+  |
        |  |                      rs485_bus                         |  |
        |  |  - Priority Multiplexer                                |  |
        |  |  - Real-time Collision Detector: (sum(tx_en) > 1)      |  |
        |  +--------------------------------------------------------+  |
        +-------------------|-------------------|----------------------+
                            |                   |
                         bus (wire)      collision (wire)
```

---

## Module Descriptions

### 1. Fixed-Priority Arbiter (`Arbitration_fixed.v`)
- **Inputs:** `request[3:0]`
- **Outputs:** `grant[3:0]` (One-hot encoded)
- **Functionality:** Evaluates concurrent requests and immediately asserts a one-hot grant to the active node with the lowest index:
  - `request[0] == 1` $\rightarrow$ `grant = 4'b0001` (Highest priority)
  - `request[1] == 1` $\rightarrow$ `grant = 4'b0010`
  - `request[2] == 1` $\rightarrow$ `grant = 4'b0100`
  - `request[3] == 1` $\rightarrow$ `grant = 4'b1000` (Lowest priority)
  - `request == 2'b00` $\rightarrow$ `grant = 4'b0000`

### 2. Node Controller (`node.v`)
- Implements a Moore-style 4-state Finite State Machine (FSM):
  - **`IDLE (3'b000)`:** Bus driver quiescent. Listens for `start` flag. If `start && !sent`, transitions to `REQUEST`.
  - **`REQUEST (3'b001)`:** Asserts `request = 1`. Awaits single-bit `grant` acknowledgement from arbiter.
  - **`TRANSMIT (3'b010)`:** Drives `tx_en = 1` and `tx_data = 1`. Transmission is held active for the defined slot duration before transitioning to `DONE`.
  - **`DONE (3'b101)`:** Asserts local latch flag `sent <= 1'b1` to prevent starvation loops/continuous transmission while `start` remains high. De-asserts `tx_en` and returns to `IDLE`.

### 3. Shared Bus & Collision Detector (`bus.v`)
- **Collision Flag:** Dynamically calculates simultaneous drive conditions:
  $$\text{collision} = \sum_{i=0}^{3} tx\_en[i] > 1$$
- **Bus Data MUX:** Models transmission line propagation using priority selection based on physical node connection. Under normal grant-arbitrated operation, exactly one node transmits at any instant, ensuring `collision == 0`.

### 4. Top-Level Integration (`top.v`)
- Instantiates four parameterized instances of `Node` (`node0`, `node1`, `node2`, `node3`).
- Wires request buses, grant vectors, and driver channels to `arbiter` and `rs485_bus`.

---

## FSM State Diagram & Protocol Timing

```
          +-----------------------+
          |         IDLE          |<-------------------------+
          |  (req=0, tx_en=0)     |                          |
          +-----------------------+                          |
                      |                                      |
                      | (start && !sent)                     |
                      v                                      |
          +-----------------------+                          |
          |        REQUEST        |                          |
          |  (req=1, tx_en=0)     |                          |
          +-----------------------+                          |
                      |                                      |
                      | (grant == 1)                         |
                      v                                      |
          +-----------------------+                          |
          |       TRANSMIT        |                          |
          |  (req=0, tx_en=1)     |                          |
          +-----------------------+                          |
                      |                                      |
                      | (unconditional)                      |
                      v                                      |
          +-----------------------+                          |
          |         DONE          |--------------------------+
          |  (sent<=1, tx_en=0)   |
          +-----------------------+
```

---

## Directory Layout

```text
fixed_priority_bus/
├── rtl/
│   ├── Arbitration_fixed.v    # 4-input fixed priority arbiter
│   ├── bus.v                  # RS-485 bus model & collision detection
│   ├── node.v                 # Node FSM controller
│   └── top.v                  # Top-level DUT integration
├── tb/
│   └── tb_top.v               # Multi-scenario verification testbench
├── sim/                       # Simulation runs
├── wave.vcd                   # generated waveforms
└── README.md                  # Project documentation
```

---

## Simulation & Verification

The testbench (`tb/tb_top.v`) tests four distinct operational scenarios:
1. **TEST 1: Single Node Transaction (`Node 0`)** – Base functional path validation.
2. **TEST 2: Contention Resolution (`Node 0` vs `Node 1`)** – Ensures Node 0 preempts Node 1, and Node 1 transmits only after Node 0 completes.
3. **TEST 3: High-Contention Burst (`All 4 Nodes Asserted`)** – Confirms sequential cascade according to strict priority order ($N_0 \rightarrow N_1 \rightarrow N_2 \rightarrow N_3$).
4. **TEST 4: Randomized Traffic Stress Test** – Verifies system stability and absence of race conditions under pseudo-random excitation.

---

### Prerequisites
Install one of the following open-source or commercial toolchains:
- **Icarus Verilog (`iverilog`)** & **GTKWave**
- **Synopsys VCS**, **Cadence Xcelium**, or **Siemens ModelSim/QuestaSim**
- **AMD Xilinx Vivado (xsim)**

---

### Using Icarus Verilog & GTKWave

1. **Compile RTL and Testbench:**
   ```bash
   iverilog -g2012 -o sim/sim_top.vvp rtl/Arbitration_fixed.v rtl/bus.v rtl/node.v rtl/top.v tb/tb_top.v
   ```

2. **Run Simulation:**
   ```bash
   vvp sim/sim_top.vvp
   ```
   *Terminal Output:*
   ```text
   VCD info: dumpfile wave.vcd opened for output.
   TEST1 : Node0
   TEST2 : Node0 and Node1
   TEST3 : All Nodes
   TEST4 : Random Traffic
   ```

3. **Inspect Waveforms:**
   ```bash
   gtkwave wave.vcd &
   ```
   *Key signals to add in GTKWave:*
   - `tb_top.DUT.clk`, `tb_top.DUT.rst`
   - `tb_top.DUT.start[3:0]`
   - `tb_top.DUT.request[3:0]`
   - `tb_top.DUT.grant[3:0]`
   - `tb_top.DUT.tx_en[3:0]`
   - `tb_top.DUT.bus`
   - `tb_top.DUT.collision` (Must remain strictly `0` under arbitrated control)

---

### Using ModelSim / QuestaSim

```bash
# Create working library
vlib work
vmap work work

# Compile source files
vlog rtl/Arbitration_fixed.v rtl/bus.v rtl/node.v rtl/top.v tb/tb_top.v

# Launch CLI simulation
vsim -c -do "run -all; quit" tb_top

# Launch GUI simulation with waveforms
vsim -voptargs=+acc work.tb_top
# In ModelSim GUI: add wave -r /*; run -all
```

---

### Using Vivado Simulator (xsim)

```bash
# Parse design and testbench
xvlog rtl/Arbitration_fixed.v rtl/bus.v rtl/node.v rtl/top.v tb/tb_top.v

# Elaborate snapshot
xelab tb_top -s tb_top_snapshot -debug typical

# Execute batch simulation
xsim tb_top_snapshot -R

# Or open GUI waveform viewer
xsim tb_top_snapshot -gui
```

---
