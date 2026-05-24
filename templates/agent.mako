`ifndef _${agent['name'].upper()}_AGENT_SV_
`define _${agent['name'].upper()}_AGENT_SV_

class ${agent['name']}_agent extends uvm_agent;
    `uvm_component_utils(${agent['name']}_agent)
    
    ${config['cfg']['name']} cfg_m;

    virtual ${agent['interface']} vif;

    ${agent['name']}_driver     driver;
    ${agent['name']}_sequencer  sequencer;
    ${agent['name']}_monitor    monitor;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);

        if (!uvm_config_db#(virtual ${agent['interface']})::get(this, "", "${agent['interface']}_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found!")
        end
        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end

        if(cfg_m.${agent['name']}_agt_is_active == UVM_ACTIVE) begin
            driver = ${agent['name']}_driver::type_id::create("driver", this);
            sequencer = ${agent['name']}_sequencer::type_id::create("sequencer", this);
        end

        monitor = ${agent['name']}_monitor::type_id::create("monitor", this);
    
        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction

    function void connect_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"connect_phase start",UVM_LOW);
        
        if(cfg_m.${agent['name']}_agt_is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end

        `uvm_info(get_type_name(),"connect_phase done",UVM_LOW);
    endfunction
endclass

`endif
