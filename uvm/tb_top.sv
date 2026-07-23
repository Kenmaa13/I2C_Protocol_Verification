//==============================================================
// tb_top.sv
// Top-level module:
//   - generates clk/rst_n
//   - instantiates i2c_if
//   - instantiates the DUT (i2c_top.v - master+slave RTL)
//   - registers both DRIVER and MONITOR modport handles into
//     uvm_config_db so the agent's driver/monitor can retrieve
//     them by name "vif"
//   - calls run_test()
//==============================================================
`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import i2c_pkg::*;
    `include "uvm_macros.svh"

    // ---- clock / reset ----
    logic clk;
    logic rst_n;

    initial clk = 0;
    always #10 clk = ~clk;   // 50MHz system clock -> matches CLK_FREQ=50_000_000 default

    initial begin
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
    end

    // ---- interface instance ----
    i2c_if vif (.clk(clk), .rst_n(rst_n));

    // ---- DUT ----
    i2c_top #(
        .CLK_FREQ   (50_000_000),
        .I2C_FREQ   (100_000),
        .SLAVE_ADDR (7'h50)
    ) dut (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .start_xfer             (vif.start_xfer),
        .slave_addr             (vif.slave_addr),
        .rw                     (vif.rw),
        .wdata                  (vif.wdata),
        .rdata                  (vif.rdata),
        .addr_ack_err           (vif.addr_ack_err),
        .data_ack_err           (vif.data_ack_err),
        .busy                   (vif.busy),
        .done                   (vif.done),
        .slave_last_write_data  (vif.slave_last_write_data),
        .slave_mem_dbg          (vif.slave_mem_dbg),
        .sda_dbg                (vif.sda_dbg),
        .scl_dbg                (vif.scl_dbg)
    );

    // ---- config_db registration ----
    initial begin
        uvm_config_db#(virtual i2c_if.DRIVER)::set(null, "*", "vif", vif);
        uvm_config_db#(virtual i2c_if.MONITOR)::set(null, "*", "vif", vif);
    end

    // ---- waveform dump (optional, handy for debug) ----
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end

    initial begin
        run_test();
    end

endmodule
