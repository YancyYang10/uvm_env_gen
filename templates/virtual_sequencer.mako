`ifndef _VIRTUAL_SEQUENCER_SV_
`define _VIRTUAL_SEQUENCER_SV_

class virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(virtual_sequencer)

    ${config['cfg']['name']} cfg_m;
    // === Sequencer handles for each agent instance ===
    % for inst in agent_instances:
    ${inst['type']}_sequencer ${inst['sqr_name']};
    % endfor

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);
        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end
        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction
endclass

`endif