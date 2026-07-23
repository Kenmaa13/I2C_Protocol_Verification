//==============================================================
// i2c_read_seq.sv
// Directed sequence: single READ from the valid slave address.
// Exposes the returned data via "rsp" so the test can check it
// against a value it wrote earlier.
//==============================================================
class i2c_read_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_read_seq)

    bit [6:0] addr = i2c_seq_item::VALID_SLAVE_ADDR;
    i2c_seq_item rsp;

    function new(string name = "i2c_read_seq");
        super.new(name);
    endfunction

    task body();
        do_transfer(addr, 1'b1, 8'h00, rsp);
        `uvm_info("I2C_READ_SEQ", $sformatf("Read complete: %s", rsp.convert2str()), UVM_MEDIUM)
    endtask

endclass
