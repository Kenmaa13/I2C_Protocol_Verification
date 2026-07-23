//==============================================================
// i2c_coverage.sv
// Functional coverage collector, subscribed to the same monitor
// analysis port as the scoreboard. Tracks the corner cases that
// actually matter for I2C: matched vs unmatched address, R/W
// direction, and ACK/NACK outcomes, plus their cross.
//==============================================================
class i2c_coverage extends uvm_subscriber #(i2c_seq_item);

    `uvm_component_utils(i2c_coverage)

    i2c_seq_item cur;

    covergroup cg_i2c_txn;
        option.per_instance = 1;

        cp_addr_match: coverpoint (cur.addr == i2c_seq_item::VALID_SLAVE_ADDR) {
            bins matched   = {1};
            bins unmatched = {0};
        }

        cp_rw: coverpoint cur.rw {
            bins write = {0};
            bins read  = {1};
        }

        cp_addr_ack_err: coverpoint cur.addr_ack_err {
            bins acked  = {0};
            bins nacked = {1};
        }

        cp_data_ack_err: coverpoint cur.data_ack_err {
            bins acked  = {0};
            bins nacked = {1};
        }

        cp_wdata_extremes: coverpoint cur.wdata {
            bins zero    = {8'h00};
            bins all_one = {8'hFF};
            bins mid     = {[8'h01:8'hFE]};
        }

        // the interesting cross: does every combination of
        // (match/mismatch) x (read/write) x (ack/nack) get hit?
        cx_match_rw_ack: cross cp_addr_match, cp_rw, cp_addr_ack_err;

    endgroup

    function new(string name = "i2c_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_i2c_txn = new();
    endfunction

    function void write(i2c_seq_item t);
        cur = t;
        cg_i2c_txn.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("I2C_COV",
            $sformatf("Functional coverage: %0.2f%%", cg_i2c_txn.get_coverage()),
            UVM_LOW)
    endfunction

endclass
