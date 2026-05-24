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

    virtual task main_phase(uvm_phase phase);
    % for inst in agent_instances:
        ${inst['type']}_sequence ${inst['name']}_seq;
    % endfor
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "main_phase start", UVM_LOW);
    % for inst in agent_instances:
        ${inst['name']}_seq = ${inst['type']}_sequence::type_id::create("${inst['name']}_seq");
//        ${inst['name']}_seq.start(env_m.v_sqr);
    % endfor
        phase.phase_done.set_drain_time(this,5us);
        phase.drop_objection(this);
        `uvm_info(get_type_name(), "main_phase done", UVM_LOW);
    endtask

    function void report_phase(uvm_phase phase);
	int num_uvm_errors;
	uvm_report_server server;

        super.report_phase(phase);
	if(server==null) server = get_report_server();
    	num_uvm_errors = server.get_severity_count(UVM_ERROR)+server.get_severity_count(UVM_FATAL);
        if(num_uvm_errors==0)begin
            `uvm_info(get_type_name(),"================",UVM_NONE)
            `uvm_info(get_type_name(),"=TEST_CASE_PASS=",UVM_NONE)
            `uvm_info(get_type_name(),"================\n",UVM_NONE)
    	end
    	else begin
            `uvm_info(get_type_name(),"\n================",UVM_NONE)
            `uvm_info(get_type_name(),"=TEST_CASE_FAIL=",UVM_NONE)
            `uvm_info(get_type_name(),"================\n",UVM_NONE)
    	end
    endfunction

endclass

`endif
