//==============================================================
// i2c_read_test.sv
// Writes a known value, then reads it back and checks in the
// test itself (in addition to the scoreboard) that the two
// values match - a classic write/read-back data-integrity test.
//==============================================================
class i2c_read_test extends i2c_base_test;

    `uvm_component_utils(i2c_read_test)

    function new(string name = "i2c_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_write_seq wseq = i2c_write_seq::type_id::create("wseq");
        i2c_read_seq  rseq = i2c_read_seq::type_id::create("rseq");
        bit [7:0] expected_data = 8'h7E;

        phase.raise_objection(this);

        if (!wseq.randomize() with { wdata == expected_data; })
            `uvm_fatal("I2C_READ_TEST", "Randomization failed")
        wseq.start(env.agent.sequencer);

        rseq.start(env.agent.sequencer);

        if (rseq.rsp.rdata !== expected_data)
            `uvm_error("I2C_READ_TEST",
                $sformatf("Write/read-back mismatch: wrote 0x%0h, read 0x%0h",
                           expected_data, rseq.rsp.rdata))
        else
            `uvm_info("I2C_READ_TEST",
                $sformatf("Write/read-back matched: 0x%0h", rseq.rsp.rdata), UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass
