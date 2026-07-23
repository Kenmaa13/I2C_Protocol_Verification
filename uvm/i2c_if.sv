//==============================================================
// i2c_if.sv
// Bundles:
//   (a) the master's simple command-level interface (used by
//       the ACTIVE driver to issue transactions)
//   (b) the raw SDA/SCL bus wires (used by the PASSIVE monitor
//       to check real protocol behavior - START/STOP/ACK/NACK
//       timing on the actual wires, not just the command ports)
//
// Clocking blocks separate driver-timing from monitor-timing so
// races between driving and sampling are avoided.
//==============================================================
interface i2c_if (input logic clk, input logic rst_n);

    // ---- master command-level interface ----
    logic        start_xfer;
    logic [6:0]  slave_addr;
    logic        rw;             // 0 = write, 1 = read
    logic [7:0]  wdata;
    logic [7:0]  rdata;
    logic        addr_ack_err;
    logic        data_ack_err;
    logic        busy;
    logic        done;

    // ---- raw shared I2C bus (mirrored out from DUT for observation only -
    //      the monitor never drives these, it only samples them) ----
    logic        sda_dbg;
    logic        scl_dbg;

    // ---- slave-side debug/backdoor observation ----
    logic [7:0]  slave_last_write_data;
    logic [7:0]  slave_mem_dbg;

    // Driver clocking block: drives command inputs on clk, small
    // input skew for busy/done so driver logic sees stable values.
    clocking drv_cb @(posedge clk);
        output start_xfer, slave_addr, rw, wdata;
        input  rdata, addr_ack_err, data_ack_err, busy, done;
    endclocking

    // Monitor clocking block: sample-only, no drives.
    clocking mon_cb @(posedge clk);
        input start_xfer, slave_addr, rw, wdata;
        input rdata, addr_ack_err, data_ack_err, busy, done;
        input sda_dbg, scl_dbg;
        input slave_last_write_data, slave_mem_dbg;
    endclocking

    modport DRIVER  (clocking drv_cb, input rst_n);
    modport MONITOR (clocking mon_cb, input rst_n);

endinterface
