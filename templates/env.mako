`ifndef _${config['env']['name'].upper()}_SV_
`define _${config['env']['name'].upper()}_SV_

class ${config['env']['name']} extends uvm_env;
    `uvm_component_utils(${config['env']['name']})
  
    ${config['cfg']['name']} cfg_m;

    % for agent in config['agents']:
    ${agent['name']}_agent ${agent['name']}_agt;
    % endfor
    
    % if config['env']['has_ref_model']:
    ${config['ref_model']['name']} ref_model;
    % endif
    % if config['env']['has_scoreboard']:
    ${config['scoreboard']['name']} scoreboard;
    % endif
    % if config['env']['has_coverage']:
    ${config['coverage']['name']} coverage;
    % endif
    virtual_sequencer v_sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal("get_type_name()", "Top cfg not found!")
        end

        % for agent in config['agents']:
        ${agent['name']}_agt = ${agent['name']}_agent::type_id::create("${agent['name']}_agt", this);
        % endfor
        
        % if config['env']['has_ref_model']:
        ref_model = ${config['ref_model']['name']}::type_id::create("ref_model", this);
        % endif
        % if config['env']['has_scoreboard']:
        scoreboard = ${config['scoreboard']['name']}::type_id::create("scoreboard", this);
        % endif
        % if config['env']['has_coverage']:
        coverage = ${config['coverage']['name']}::type_id::create("coverage", this);
        % endif
        
        v_sqr = virtual_sequencer::type_id::create("v_sqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        % for agent in config['agents']:
        if(cfg_m.${agent['name']}_agt_is_active == UVM_ACTIVE) begin
            v_sqr.${agent['name']}_sqr = ${agent['name']}_agt.sequencer;
        end
        % endfor
        
        % if config['env']['has_ref_model']:
        % for agent in config['agents']:
        % if agent['type'] == "in":
        ${agent['name']}_agt.monitor.ap.connect(ref_model.${agent['item']}_mon_imp);
        % endif
        % if agent['type'] == "out":
        ${agent['name']}_agt.monitor.ap.connect(scoreboard.${agent['item']}_act_imp);
        % endif
        % endfor
        % endif
        
        % if config['env']['has_ref_model'] and config['env']['has_scoreboard']:
        % for pred_item in config['ref_model']['predicted_type']:
        ref_model.${pred_item}_pred_port.connect(scoreboard.${pred_item}_exp_imp);
        % endfor
        % endif
    endfunction
endclass

`endif
