//==============================================================
// i2c_base_seq.sv
// Common base for all I2C sequences. Provides a helper to send
// a single fully-specified transaction and return it (with the
// response fields filled in) to the caller.
//==============================================================
class i2c_base_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_base_seq)

    function new(string name = "i2c_base_seq");
        super.new(name);
    endfunction

    // Sends one transaction with explicit fields (no randomization).
    // Returns the completed item so the caller can inspect rdata/errs.
    task automatic do_transfer(bit [6:0] addr, bit rw, bit [7:0] wdata,
                                output i2c_seq_item rsp);
        i2c_seq_item req = i2c_seq_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with {
                req.addr  == addr;
                req.rw    == rw;
                req.wdata == wdata;
            })
            `uvm_fatal("I2C_SEQ", "Randomization failed in do_transfer")
        finish_item(req);
        rsp = req;
    endtask

endclass
