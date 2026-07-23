//==============================================================
// i2c_pkg.sv
// Package wrapping every UVM class in this testbench. Include
// order matters: base classes before derived, sequence items
// before sequences/driver/monitor that use them, env components
// before the env, env before tests.
//==============================================================
package i2c_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ---- agent ----
    `include "i2c_seq_item.sv"
    `include "i2c_sequencer.sv"
    `include "i2c_driver.sv"
    `include "i2c_monitor.sv"
    `include "i2c_agent.sv"

    // ---- env ----
    `include "i2c_scoreboard.sv"
    `include "i2c_coverage.sv"
    `include "i2c_env.sv"

    // ---- sequence library ----
    `include "i2c_base_seq.sv"
    `include "i2c_write_seq.sv"
    `include "i2c_read_seq.sv"
    `include "i2c_random_seq.sv"
    `include "i2c_error_seq.sv"

    // ---- test library ----
    `include "i2c_base_test.sv"
    `include "i2c_write_test.sv"
    `include "i2c_read_test.sv"
    `include "i2c_random_test.sv"
    `include "i2c_error_test.sv"

endpackage
