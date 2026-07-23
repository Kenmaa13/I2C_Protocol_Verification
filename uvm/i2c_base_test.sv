//==============================================================
// i2c_base_test.sv
// Common base for all tests: builds env, sets up the sequencer
// virtual sequence handle, and sets a global timeout so a
// stuck DUT/testbench doesn't hang the regression forever.
//==============================================================
class i2c_base_test extends uvm_test;

    `uvm_component_utils(i2c_base_test)

    i2c_env env;

    function new(string name = "i2c_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = i2c_env::type_id::create("env", this);
        uvm_top.set_timeout(1ms, 0); // absolute safety net for a hung sim
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass
