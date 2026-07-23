//==============================================================
// i2c_random_seq.sv
// Fully randomized sequence: relies on i2c_seq_item's own
// c_addr_dist constraint (80% valid address / 20% random,
// which includes invalid addresses) plus random rw/wdata.
// Good for driving functional coverage closure.
//==============================================================
class i2c_random_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_random_seq)

    rand int unsigned num_txns = 20;

    constraint c_num_txns { num_txns inside {[10:50]}; }

    function new(string name = "i2c_random_seq");
        super.new(name);
    endfunction

    task body();
        repeat (num_txns) begin
            i2c_seq_item req = i2c_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize())
                `uvm_fatal("I2C_RAND_SEQ", "Randomization failed")
            finish_item(req);
            `uvm_info("I2C_RAND_SEQ", $sformatf("Sent: %s", req.convert2str()), UVM_HIGH)
        end
    endtask

endclass
