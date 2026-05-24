`ifndef _${config['test']['base_name'].upper()}_SV_
`define _${config['test']['base_name'].upper()}_SV_

class ${config['test']['base_name']} extends uvm_test;
    `uvm_component_utils(${config['test']['base_name']})
    
    ${config['cfg']['name']} cfg_m;
    ${config['env']['name']} env_m;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "build_phase start", UVM_LOW);
        super.build_phase(phase);
        env_m = ${config['env']['name']}::type_id::create("env_m", this);
        cfg_m = ${config['cfg']['name']}::type_id::create("cfg_m", this);
        uvm_config_db#(${config['cfg']['name']})::set(this, "env_m*", "cfg_m", cfg_m);
        uvm_root::get().set_timeout(3ms);
        `uvm_info(get_type_name(), "build_phase done", UVM_LOW);
    endfunction

    task main_phase(uvm_phase phase);
    % for agent in config['agents']:
        ${agent['name']}_sequence ${agent['name']}_seq;
    % endfor
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "main_phase start", UVM_LOW);
    % for agent in config['agents']:
        ${agent['name']}_seq = ${agent['name']}_sequence::type_id::create("${agent['name']}_seq");
//        ${agent['name']}_seq.start(env_m.v_sqr);
    % endfor
        phase.phase_done.set_drain_time(this,5us);
        phase.drop_objection(this);
        `uvm_info(get_type_name(), "main_phase done", UVM_LOW);
    endtask
endclass

`endif
