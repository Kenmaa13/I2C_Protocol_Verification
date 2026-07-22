`timescale 1ns/1ps
module tb_smoke;

    reg clk = 0;
    reg rst_n = 0;

    reg        start_xfer;
    reg [6:0]  slave_addr;
    reg        rw;
    reg [7:0]  wdata;
    wire [7:0] rdata;
    wire       addr_ack_err, data_ack_err, busy, done;
    wire [7:0] slave_last_write_data, slave_mem_dbg;

    // clean integer divider ratio for fast simulation: 2MHz sys clk, 100kHz I2C -> quarter=5 cycles
    i2c_top #(
        .CLK_FREQ (2_000_000),
        .I2C_FREQ (100_000),
        .SLAVE_ADDR (7'h50)
    ) dut (
        .clk (clk), .rst_n (rst_n),
        .start_xfer (start_xfer), .slave_addr (slave_addr), .rw (rw), .wdata (wdata),
        .rdata (rdata), .addr_ack_err (addr_ack_err), .data_ack_err (data_ack_err),
        .busy (busy), .done (done),
        .slave_last_write_data (slave_last_write_data), .slave_mem_dbg (slave_mem_dbg)
    );

    always #250 clk = ~clk; // 2MHz

    initial begin
        start_xfer = 0; slave_addr = 7'h50; rw = 0; wdata = 8'h00;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        // ---- WRITE 0x3C to slave 0x50 ----
        @(posedge clk);
        start_xfer <= 1; slave_addr <= 7'h50; rw <= 1'b0; wdata <= 8'h3C;
        @(posedge clk);
        start_xfer <= 0;
        wait (done);
        @(posedge clk);
        $display("[%0t] WRITE done. addr_ack_err=%b data_ack_err=%b slave_mem=0x%02h",
                   $time, addr_ack_err, data_ack_err, slave_mem_dbg);
        if (addr_ack_err !== 0 || data_ack_err !== 0 || slave_mem_dbg !== 8'h3C) begin
            $display("*** WRITE TEST FAILED ***");
        end else begin
            $display("*** WRITE TEST PASSED ***");
        end

        repeat (20) @(posedge clk);

        // ---- READ back from slave 0x50 ----
        @(posedge clk);
        start_xfer <= 1; slave_addr <= 7'h50; rw <= 1'b1;
        @(posedge clk);
        start_xfer <= 0;
        wait (done);
        @(posedge clk);
        $display("[%0t] READ done. addr_ack_err=%b rdata=0x%02h", $time, addr_ack_err, rdata);
        if (addr_ack_err !== 0 || rdata !== 8'h3C) begin
            $display("*** READ TEST FAILED ***");
        end else begin
            $display("*** READ TEST PASSED ***");
        end

        repeat (20) @(posedge clk);
        $finish;
    end

    reg trace_on = 0;

    initial begin
        #5_000_000; // safety timeout (5ms, plenty for two 100kHz single-byte transactions)
        $display("*** TIMEOUT - simulation did not finish ***");
        $display("busy=%b state_byte=%0d state_bit_busy=%b sda=%b scl=%b",
                   busy, dut.u_master.u_byte_ctrl.state, dut.u_master.u_bit_ctrl.busy,
                   dut.sda, dut.scl);
        $finish;
    end

endmodule
