//==============================================================
// i2c_random_test.sv
// Runs the fully randomized sequence to close out functional
// coverage across matched/unmatched address, read/write, and
// ack/nack combinations.
//==============================================================
class i2c_random_test extends i2c_base_test;

    `uvm_component_utils(i2c_random_test)

    function new(string name = "i2c_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_random_seq seq = i2c_random_seq::type_id::create("seq");
        phase.raise_objection(this);

        if (!seq.randomize() with { num_txns == 40; })
            `uvm_fatal("I2C_RANDOM_TEST", "Randomization failed")
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass
