//==============================================================
// i2c_agent.sv
// Standard active agent: sequencer + driver + monitor.
// is_active can be set to UVM_PASSIVE from the test if you ever
// want a monitor-only instance (e.g. a second agent watching a
// second slave in a future multi-slave env) without a driver.
//==============================================================
class i2c_agent extends uvm_agent;

    `uvm_component_utils(i2c_agent)

    i2c_sequencer sequencer;
    i2c_driver    driver;
    i2c_monitor   monitor;

    uvm_analysis_port #(i2c_seq_item) agent_ap;

    function new(string name = "i2c_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor = i2c_monitor::type_id::create("monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = i2c_sequencer::type_id::create("sequencer", this);
            driver    = i2c_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end

        // pass monitor's observations straight through the agent
        agent_ap = monitor.mon_ap;
    endfunction

endclass
