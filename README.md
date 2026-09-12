# FPGA Ping Pong Game (VHDL — Spartan-3E)

A cycle-accurate, CPU-free Ping Pong game implemented in synthesizable VHDL for the Xilinx Spartan-3E FPGA. All video timing generation, ball trajectory physics, boundary/paddle collisions, input debouncing, and on-the-fly pixel rendering are executed directly in hardware using synchronous finite-state machines and combinational logic.

Developed as part of **COE758: Digital Systems Engineering**.

---

## Key Highlights & Features

- **Standard 640×480 @ 60 Hz VGA Output:** Cycle-accurate sync generation targeting standard desktop monitors.
- **Pure RTL Architecture (CPU-Free):** Zero soft-cores (no MicroBlaze/PicoBlaze) or instruction overhead—every game loop is deterministic and parallel.
- **Hardware Physics & Collision Engine:** Real-time velocity sign-reversal, corner handling, and paddle collision detection.
- **On-the-Fly Video Multiplexing:** Generates court markings, dashed net lines, paddles, and the ball directly by comparing raster beam coordinates against object bounding boxes without an external frame buffer.
- **Debounced Control:** Clamped paddle movement driven by on-board tactile push buttons and slide switches.

---

## System Architecture

The design uses a structural top-level module (`pong_top.vhd`) to tie together clock synthesis, video timing, player I/O, physical simulation, and video output.

```text
                  +-------------------------------------------------------------+
                  |                        pong_top.vhd                         |
                  |                                                             |
[50 MHz Clock] -> | +-------------------+                                       |
                  | |  refresh_divider  | ---> [25 MHz Pixel Clock]             |
                  | +-------------------+ ---> [Game Physics Tick]              |
                  |          |                      |                           |
                  |          v                      v                           |
[Buttons / Sw] -> | +-------------------+  +-------------------+                |
                  | |  player_movement  |  |   ball_physics    |                |
                  | +-------------------+  +-------------------+                |
                  |          | (Y_pos)              | (X_pos, Y_pos)            |
                  |          +--------+   +---------+                           |
                  |                   |   |                                     |
                  |                   v   v                                     |
                  |          +-------------------+                              |
                  |          |  field_renderer   | ---> [VGA RGB (3-bit DAC)]   |
                  |          +-------------------+                              |
                  |                   ^ (X, Y beam)                             |
                  |                   |                                         |
                  |          +-------------------+                              |
                  |          |    vga_timing     | ---> [HSYNC, VSYNC]          |
                  |          +-------------------+                              |
                  +-------------------------------------------------------------+
```

---

## Repository Structure

```text
.
├── src/                      # Synthesizable VHDL design files
│   ├── pong_top.vhd          # Top-level structural integration
│   ├── vga_timing.vhd        # 640x480 @ 60 Hz timing & blanking generator
│   ├── refresh_divider.vhd   # 50 MHz-to-25 MHz pixel clock & game tick divider
│   ├── field_renderer.vhd    # Combinational beam coordinate comparator & color generator
│   ├── player_movement.vhd   # Paddle position update & boundary clamping
│   └── ball_physics.vhd      # Velocity vector computation & collision detection
├── constraints/              # FPGA constraint files
│   └── spartan3e.ucf         # Pin assignments (clock, switches, buttons, VGA DAC)
├── sim/                      # Testbench and simulation harnesses
│   └── pong_top_tb.vhd       # Top-level behavioral testbench
├── docs/                     # Schematics, block diagrams, and waveforms
│   └── architecture.png
├── .gitignore                # Filters ISE/Vivado intermediate build artifacts
└── README.md
```

---

## Module Breakdown

| Module | Design Style | Description |
| :--- | :--- | :--- |
| **`pong_top.vhd`** | Structural | Top-level wiring harness linking clocks, user inputs, physics updates, and video signals. |
| **`vga_timing.vhd`** | Synchronous FSM | Horizontal and vertical counters generating active video windows, porch intervals, and `HSYNC`/`VSYNC` pulses. |
| **`refresh_divider.vhd`** | Clock Pre-scaler | Divides the 50 MHz system clock down to 25 MHz for video rastering and ~60 Hz for physics/game ticks. |
| **`player_movement.vhd`** | Sequential / Logic | Debounces push-button inputs and updates paddle vertical offsets while enforcing upper and lower court bounds. |
| **`ball_physics.vhd`** | Sequential Logic | Updates $(X, Y)$ ball coordinates based on velocity vectors $(\Delta X, \Delta Y)$, inverting signs upon collision with boundaries or paddle edges. |
| **`field_renderer.vhd`** | Combinational Logic | Evaluates current beam scan coordinates against object bounding boxes to multiplex court, net, paddle, and ball colors. |

---

## VGA Video Timing (640 × 480 @ 60 Hz)

The timing controller approximates the standard 25.175 MHz pixel clock using a 50 MHz $\div$ 2 synchronous counter:

- **Horizontal Timing (Pixels):**
  - Active Display: 640
  - Front Porch: 16
  - Sync Pulse (`HSYNC`, Active Low): 96
  - Back Porch: 48
  - Total Line Width: 800

- **Vertical Timing (Lines):**
  - Active Display: 480
  - Front Porch: 10
  - Sync Pulse (`VSYNC`, Active Low): 2
  - Back Porch: 33
  - Total Frame Height: 525

---

## Verification & Simulation

Behavioral verification can be performed using **ModelSim**, **GHDL**, or **Xilinx ISim**:

```bash
# Example compilation order using GHDL:
ghdl -a --std=08 src/vga_timing.vhd
ghdl -a --std=08 src/refresh_divider.vhd
ghdl -a --std=08 src/player_movement.vhd
ghdl -a --std=08 src/ball_physics.vhd
ghdl -a --std=08 src/field_renderer.vhd
ghdl -a --std=08 src/pong_top.vhd
ghdl -a --std=08 sim/pong_top_tb.vhd

# Run simulation and inspect waveforms
ghdl -e --std=08 pong_top_tb
ghdl -r --std=08 pong_top_tb --vcd=sim/wave.vcd
```

Key verification checks include:
1. Exact cycle durations for `HSYNC` and `VSYNC` active-low pulses.
2. Sign-flip assertion on ball delta registers when $(X_{\text{ball}}, Y_{\text{ball}})$ intersects $(X_{\text{paddle}}, Y_{\text{paddle}})$.
3. Clamping behavior when paddle position values reach vertical bounds ($Y_{\text{min}}, Y_{\text{max}}$).

---

## Build & Synthesis (Xilinx ISE)

1. Open **Xilinx ISE Design Suite**.
2. Create a new project targeting your device (e.g., `Spartan-3E XC3S500E-4FG320`).
3. Add all `.vhd` files from the `src/` directory.
4. Add the pin configuration file `constraints/spartan3e.ucf`.
5. Set `pong_top` as the **Top-Level Module**.
6. Run **Synthesize - XST** followed by **Implement Design** (Translate, Map, Place & Route).
7. Run **Generate Programming File** to produce the `.bit` bitstream.
8. Connect your board over JTAG, launch **iMPACT**, and program the FPGA.
9. Connect a standard VGA monitor to the board's 15-pin D-sub connector.

---

## Future Enhancements

- [ ] On-screen hardware 7-segment / pixel scoreboard display.
- [ ] Automated FSM-based single-player AI opponent.
- [ ] PWM sound synthesis for paddle strikes and boundary bounces via an audio jack.
- [ ] Increased color resolution utilizing an external resistor-ladder VGA DAC.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
