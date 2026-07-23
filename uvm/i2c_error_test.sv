//==============================================================
// i2c_error_test.sv
// Directed negative test: explicitly drives transactions to a
// non-existent slave address and confirms the master correctly
// reports addr_ack_err (NACK) on both WRITE and READ attempts.
//==============================================================
class i2c_error_test extends i2c_base_test;

    `uvm_component_utils(i2c_error_test)

    function new(string name = "i2c_error_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_error_seq seq = i2c_error_seq::type_id::create("seq");
        phase.raise_objection(this);

        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass
