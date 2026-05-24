`ifndef _${agent['name'].upper()}_MONITOR_SV_
`define _${agent['name'].upper()}_MONITOR_SV_

class ${agent['name']}_monitor extends uvm_monitor;
    `uvm_component_utils(${agent['name']}_monitor)
    
    ${config['cfg']['name']} cfg_m;
    uvm_analysis_port#(${item_name}) ap;
    virtual ${agent['interface']} vif;

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
            ${item_name} tr = ${item_name}::type_id::create("tr");
            collect_transfer(tr);
            ap.write(tr);
        end
    
        `uvm_info(get_type_name(),"run_phase done",UVM_LOW);
    endtask

    virtual task collect_transfer(output ${item_name} tr);
        // Custom monitor logic here
        @(posedge vif.${intf['clock']});
        // tr.addr = vif.addr;
        // tr.data = vif.data;
    endtask
endclass

`endif
