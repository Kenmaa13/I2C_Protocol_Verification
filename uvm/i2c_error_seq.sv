//==============================================================
// i2c_error_seq.sv
// Directed negative-test sequence: deliberately targets
// addresses that do NOT match the slave, on both WRITE and
// READ, to exercise the address-NACK path explicitly (rather
// than relying on random_seq to eventually hit it).
//==============================================================
class i2c_error_seq extends i2c_base_seq;

    `uvm_object_utils(i2c_error_seq)

    i2c_seq_item rsp;

    function new(string name = "i2c_error_seq");
        super.new(name);
    endfunction

    task body();
        bit [6:0] bad_addr;

        // pick any address that is not the valid one
        bad_addr = i2c_seq_item::VALID_SLAVE_ADDR ^ 7'h01;

        do_transfer(bad_addr, 1'b0, 8'hAA, rsp);
        `uvm_info("I2C_ERR_SEQ",
            $sformatf("Bad-addr WRITE expected NACK: %s", rsp.convert2str()), UVM_MEDIUM)

        do_transfer(bad_addr, 1'b1, 8'h00, rsp);
        `uvm_info("I2C_ERR_SEQ",
            $sformatf("Bad-addr READ expected NACK: %s", rsp.convert2str()), UVM_MEDIUM)
    endtask

endclass
