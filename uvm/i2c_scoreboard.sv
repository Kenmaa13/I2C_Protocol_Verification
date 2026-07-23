//==============================================================
// i2c_scoreboard.sv
// Reference model + checker.
//
// Models exactly what your i2c_slave_top.v does internally:
//   - one internal register "mem", reset value 8'hA5
//   - WRITE to the matching address updates mem
//   - READ from the matching address returns mem
//   - any transaction to a non-matching address must NACK on
//     the address phase (addr_ack_err = 1) and touch nothing
//
// Checks performed per transaction:
//   1. addr_ack_err matches expectation (matched vs unmatched addr)
//   2. for matched WRITE: data_ack_err == 0, and rdata not checked
//   3. for matched READ : rdata == expected mem value
//   4. for unmatched addr: no side effects, nothing else checked
//==============================================================
class i2c_scoreboard extends uvm_subscriber #(i2c_seq_item);

    `uvm_component_utils(i2c_scoreboard)

    // shadow model of the slave's single internal register
    bit [7:0] expected_mem;
    bit [6:0] valid_addr;

    int unsigned num_checked;
    int unsigned num_errors;

    function new(string name = "i2c_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        expected_mem = 8'hA5;              // matches i2c_slave_top.v reset value
        valid_addr   = i2c_seq_item::VALID_SLAVE_ADDR;
        num_checked  = 0;
        num_errors   = 0;
    endfunction

    // called automatically whenever the monitor's analysis port writes an item
    function void write(i2c_seq_item t);
        bit expect_addr_ack_err;

        num_checked++;
        expect_addr_ack_err = (t.addr != valid_addr);

        if (t.addr_ack_err !== expect_addr_ack_err) begin
            num_errors++;
            `uvm_error("I2C_SB",
                $sformatf("ADDR ACK mismatch: %s (expected addr_ack_err=%0b)",
                           t.convert2str(), expect_addr_ack_err))
            return; // downstream fields are meaningless if addr phase itself was wrong
        end

        if (expect_addr_ack_err) begin
            // correctly NACKed an unknown address - nothing else to check
            `uvm_info("I2C_SB",
                $sformatf("Correct NACK for unmatched addr: %s", t.convert2str()),
                UVM_MEDIUM)
            return;
        end

        if (t.rw == 1'b0) begin
            // ---- WRITE ----
            if (t.data_ack_err !== 1'b0) begin
                num_errors++;
                `uvm_error("I2C_SB",
                    $sformatf("Unexpected data NACK on WRITE: %s", t.convert2str()))
            end else begin
                expected_mem = t.wdata;   // update shadow model
                `uvm_info("I2C_SB",
                    $sformatf("WRITE checked OK, expected_mem now 0x%0h", expected_mem),
                    UVM_MEDIUM)
            end
        end else begin
            // ---- READ ----
            if (t.rdata !== expected_mem) begin
                num_errors++;
                `uvm_error("I2C_SB",
                    $sformatf("READ data mismatch: got 0x%0h, expected 0x%0h (%s)",
                               t.rdata, expected_mem, t.convert2str()))
            end else begin
                `uvm_info("I2C_SB",
                    $sformatf("READ checked OK: 0x%0h", t.rdata), UVM_MEDIUM)
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("I2C_SB",
            $sformatf("Scoreboard summary: %0d checked, %0d errors",
                       num_checked, num_errors),
            UVM_LOW)
        if (num_errors == 0)
            `uvm_info("I2C_SB", "*** ALL SCOREBOARD CHECKS PASSED ***", UVM_LOW)
        else
            `uvm_error("I2C_SB", $sformatf("*** %0d SCOREBOARD CHECKS FAILED ***", num_errors))
    endfunction

endclass
