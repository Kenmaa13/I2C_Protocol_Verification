//==============================================================
// i2c_write_seq.sv
// Directed sequence: single WRITE to the valid slave address.
// wdata is a class member so tests can set it explicitly, or
// leave it randomized.
//==============================================================
class i2c_write_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_write_seq)

    rand bit [7:0] wdata;
    bit [6:0] addr = i2c_seq_item::VALID_SLAVE_ADDR;

    i2c_seq_item rsp;

    function new(string name = "i2c_write_seq");
        super.new(name);
    endfunction

    task body();
        do_transfer(addr, 1'b0, wdata, rsp);
        `uvm_info("I2C_WRITE_SEQ", $sformatf("Write complete: %s", rsp.convert2str()), UVM_MEDIUM)
    endtask

endclass
