//==============================================================
// i2c_top.v
// Connects the master and the slave using ONLY the two shared
// I2C bus wires (sda, scl) - exactly like a real I2C bus.
// Pull-ups model the external bus resistors.
//==============================================================
module i2c_top #(
    parameter CLK_FREQ         = 50_000_000,
    parameter I2C_FREQ         = 100_000,
    parameter [6:0] SLAVE_ADDR = 7'h50
)(
    input  wire        clk,
    input  wire        rst_n,

    // master command interface (driven by testbench / UVM driver)
    input  wire        start_xfer,
    input  wire [6:0]  slave_addr,
    input  wire        rw,
    input  wire [7:0]  wdata,
    output wire [7:0]  rdata,
    output wire        addr_ack_err,
    output wire        data_ack_err,
    output wire        busy,
    output wire        done,

    // slave-side observation ports (useful for scoreboard/backdoor checks)
    output wire [7:0]  slave_last_write_data,
    output wire [7:0]  slave_mem_dbg,

    // raw bus observation ports (for UVM monitor / waveform debug only -
    // do NOT drive these externally, they mirror the internal open-drain bus)
    output wire        sda_dbg,
    output wire        scl_dbg
);

    // ---- the entire I2C bus is just these two wires ----
    wire sda;
    wire scl;

    assign sda_dbg = sda;
    assign scl_dbg = scl;

    // model the external pull-up resistors present on a real I2C bus
    pullup(sda);
    pullup(scl);

    i2c_master_top #(
        .CLK_FREQ (CLK_FREQ),
        .I2C_FREQ (I2C_FREQ)
    ) u_master (
        .clk          (clk),
        .rst_n        (rst_n),
        .start_xfer   (start_xfer),
        .slave_addr   (slave_addr),
        .rw           (rw),
        .wdata        (wdata),
        .rdata        (rdata),
        .addr_ack_err (addr_ack_err),
        .data_ack_err (data_ack_err),
        .busy         (busy),
        .done         (done),
        .sda          (sda),
        .scl          (scl)
    );

    i2c_slave_top #(
        .SLAVE_ADDR (SLAVE_ADDR)
    ) u_slave (
        .clk                (clk),
        .rst_n              (rst_n),
        .sda                (sda),
        .scl                (scl),
        .last_write_data    (slave_last_write_data),
        .read_reg_value_dbg (slave_mem_dbg)
    );

endmodule
