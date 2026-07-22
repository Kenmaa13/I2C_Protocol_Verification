//==============================================================
// i2c_master_top.v
// Top level of the I2C master. Wraps the clock divider, bit
// controller and byte controller, and drives the shared
// open-drain SDA/SCL bus.
//
// Simple external command interface:
//   pulse start_xfer with slave_addr / rw / wdata set
//   wait for "done" pulse, read rdata / addr_ack_err / data_ack_err
//==============================================================
module i2c_master_top #(
    parameter CLK_FREQ = 50_000_000,
    parameter I2C_FREQ = 100_000
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start_xfer,
    input  wire [6:0]  slave_addr,
    input  wire        rw,             // 0 = write, 1 = read
    input  wire [7:0]  wdata,
    output wire [7:0]  rdata,
    output wire        addr_ack_err,
    output wire        data_ack_err,
    output wire        busy,
    output wire        done,

    inout  wire        sda,
    inout  wire        scl
);

    wire tick;
    wire bc_cmd_start, bc_cmd_stop, bc_cmd_write, bc_cmd_read;
    wire bc_data_in, bc_data_out, bc_cmd_done;
    wire scl_oe, sda_oe;
    wire scl_i, sda_i;

    // open-drain: only drive low, otherwise release (pulled high externally)
    assign scl_i = scl;
    assign sda_i = sda;
    assign scl   = scl_oe ? 1'b0 : 1'bz;
    assign sda   = sda_oe ? 1'b0 : 1'bz;

    i2c_clk_div #(
        .CLK_FREQ (CLK_FREQ),
        .I2C_FREQ (I2C_FREQ)
    ) u_clk_div (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (busy),
        .tick   (tick)
    );

    i2c_bit_ctrl u_bit_ctrl (
        .clk       (clk),
        .rst_n     (rst_n),
        .cmd_start (bc_cmd_start),
        .cmd_stop  (bc_cmd_stop),
        .cmd_write (bc_cmd_write),
        .cmd_read  (bc_cmd_read),
        .data_in   (bc_data_in),
        .data_out  (bc_data_out),
        .cmd_done  (bc_cmd_done),
        .tick      (tick),
        .scl_oe    (scl_oe),
        .sda_oe    (sda_oe),
        .scl_i     (scl_i),
        .sda_i     (sda_i)
    );

    i2c_byte_ctrl u_byte_ctrl (
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
        .bc_cmd_start (bc_cmd_start),
        .bc_cmd_stop  (bc_cmd_stop),
        .bc_cmd_write (bc_cmd_write),
        .bc_cmd_read  (bc_cmd_read),
        .bc_data_in   (bc_data_in),
        .bc_data_out  (bc_data_out),
        .bc_cmd_done  (bc_cmd_done)
    );

endmodule
