//==============================================================
// i2c_sequencer.sv
// Standard UVM sequencer - no custom arbitration needed for
// this simple single-master command interface.
//==============================================================
class i2c_sequencer extends uvm_sequencer #(i2c_seq_item);

    `uvm_component_utils(i2c_sequencer)

    function new(string name = "i2c_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
