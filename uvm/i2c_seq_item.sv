//==============================================================
// i2c_seq_item.sv
// Transaction class carrying everything needed to drive one
// command-level I2C transfer and everything the DUT reports
// back once it completes.
//==============================================================
class i2c_seq_item extends uvm_sequence_item;

    // ---- stimulus fields (randomized, driven into DUT) ----
    rand bit [6:0] addr;
    rand bit       rw;          // 0 = WRITE, 1 = READ
    rand bit [7:0] wdata;

    // ---- response fields (filled in by driver/monitor after completion) ----
    bit [7:0] rdata;
    bit       addr_ack_err;
    bit       data_ack_err;

    // Convenience: list of "valid" addresses this env knows about.
    // Kept here so sequences/tests can reference it consistently.
    static bit [6:0] VALID_SLAVE_ADDR = 7'h50;

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_int(addr,         UVM_ALL_ON)
        `uvm_field_int(rw,           UVM_ALL_ON)
        `uvm_field_int(wdata,        UVM_ALL_ON)
        `uvm_field_int(rdata,        UVM_ALL_ON)
        `uvm_field_int(addr_ack_err, UVM_ALL_ON)
        `uvm_field_int(data_ack_err, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    // Bias randomization toward the valid address most of the time,
    // but still allow invalid addresses to exercise the NACK path.
    constraint c_addr_dist {
        addr dist { VALID_SLAVE_ADDR := 80, [0:127] :/ 20 };
    }

    function string convert2str();
        return $sformatf(
            "addr=0x%0h rw=%0s wdata=0x%0h rdata=0x%0h addr_ack_err=%0b data_ack_err=%0b",
            addr, rw ? "READ" : "WRITE", wdata, rdata, addr_ack_err, data_ack_err);
    endfunction

endclass
