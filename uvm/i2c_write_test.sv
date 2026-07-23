//==============================================================
// i2c_write_test.sv
// Runs a single directed WRITE to the valid slave address.
// Scoreboard checks addr_ack_err==0, data_ack_err==0, and that
// the shadow model matches whatever the RTL slave stored.
//==============================================================
class i2c_write_test extends i2c_base_test;

    `uvm_component_utils(i2c_write_test)

    function new(string name = "i2c_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_write_seq seq = i2c_write_seq::type_id::create("seq");
        phase.raise_objection(this);

        if (!seq.randomize() with { wdata == 8'h3C; })
            `uvm_fatal("I2C_WRITE_TEST", "Randomization failed")
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass
