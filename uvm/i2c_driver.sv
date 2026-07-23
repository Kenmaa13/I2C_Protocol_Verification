//==============================================================
// i2c_driver.sv
// Drives one i2c_seq_item at a time onto the master's simple
// command-level interface:
//   1) wait until DUT is not busy
//   2) apply slave_addr / rw / wdata
//   3) pulse start_xfer for exactly one clock
//   4) wait for the "done" pulse
//   5) capture rdata / addr_ack_err / data_ack_err back into
//      the item before signalling item_done
//==============================================================
class i2c_driver extends uvm_driver #(i2c_seq_item);

    `uvm_component_utils(i2c_driver)

    virtual i2c_if.DRIVER vif;

    function new(string name = "i2c_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual i2c_if.DRIVER)::get(this, "", "vif", vif))
            `uvm_fatal("I2C_DRV", "Virtual interface (DRIVER modport) not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // idle defaults out of reset
        vif.drv_cb.start_xfer  <= 1'b0;
        vif.drv_cb.slave_addr  <= '0;
        vif.drv_cb.rw          <= 1'b0;
        vif.drv_cb.wdata       <= '0;

        wait (vif.rst_n === 1'b1);

        forever begin
            i2c_seq_item req;
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(i2c_seq_item req);
        // 1) Wait for DUT to be idle before issuing a new command
        do begin
            @(vif.drv_cb);
        end while (vif.drv_cb.busy);

        // 2) Apply command fields one cycle ahead of the pulse
        vif.drv_cb.slave_addr <= req.addr;
        vif.drv_cb.rw         <= req.rw;
        vif.drv_cb.wdata      <= req.wdata;

        // 3) Pulse start_xfer for exactly one clock
        @(vif.drv_cb);
        vif.drv_cb.start_xfer <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.start_xfer <= 1'b0;

        `uvm_info("I2C_DRV",
            $sformatf("Issued: addr=0x%0h rw=%0s wdata=0x%0h",
                       req.addr, req.rw ? "READ" : "WRITE", req.wdata),
            UVM_MEDIUM)

        // 4) Wait for completion
        do begin
            @(vif.drv_cb);
        end while (!vif.drv_cb.done);

        // 5) Capture response fields
        req.rdata        = vif.drv_cb.rdata;
        req.addr_ack_err = vif.drv_cb.addr_ack_err;
        req.data_ack_err = vif.drv_cb.data_ack_err;

        `uvm_info("I2C_DRV",
            $sformatf("Completed: %s", req.convert2str()), UVM_MEDIUM)
    endtask

endclass
