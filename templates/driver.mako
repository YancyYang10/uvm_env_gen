`ifndef _${agent['name'].upper()}_DRIVER_SV_
`define _${agent['name'].upper()}_DRIVER_SV_

class ${agent['name']}_driver extends uvm_driver #(${item_name});
    `uvm_component_utils(${agent['name']}_driver)
    
    ${config['cfg']['name']} cfg_m;
    virtual ${agent['interface']} vif;
    uvm_analysis_port#(${item_name}) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);

        if(!uvm_config_db#(virtual ${agent['interface']})::get(this, "", "${agent['interface']}_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found!")
        end
        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end

        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"run_phase start",UVM_LOW);

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            ap.write(req);
            seq_item_port.item_done();
        end

        `uvm_info(get_type_name(),"run_phase done",UVM_LOW);
    endtask

    virtual task drive_transfer(${item_name} tr);
      // Custom drive logic here
        @(posedge vif.${intf['clock']});
      //  vif.addr <= tr.addr;
      //  vif.data <= tr.data;
    endtask
endclass

`endif
