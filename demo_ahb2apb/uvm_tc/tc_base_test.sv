`ifndef _TC_BASE_TEST_SV_
`define _TC_BASE_TEST_SV_

class tc_base_test extends uvm_test;
    `uvm_component_utils(tc_base_test)
    
    top_cfg cfg_m;
    ahb2apb_env env_m;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "build_phase start", UVM_LOW);
        super.build_phase(phase);
        env_m = ahb2apb_env::type_id::create("env_m", this);
        cfg_m = top_cfg::type_id::create("cfg_m", this);
        uvm_config_db#(top_cfg)::set(this, "env_m*", "cfg_m", cfg_m);
        uvm_root::get().set_timeout(3ms);
        `uvm_info(get_type_name(), "build_phase done", UVM_LOW);
    endfunction

    virtual task main_phase(uvm_phase phase);
        ahb_master_sequence ahb_mst_seq;
        apb_slave_sequence apb_slv0_seq;
        apb_slave_sequence apb_slv1_seq;
        apb_slave_sequence apb_slv2_seq;
        apb_slave_sequence apb_slv3_seq;
        apb_slave_sequence apb_slv4_seq;
        apb_slave_sequence apb_slv5_seq;
        apb_slave_sequence apb_slv6_seq;
        apb_slave_sequence apb_slv7_seq;
        apb_slave_sequence apb_slv8_seq;
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "main_phase start", UVM_LOW);
        ahb_mst_seq = ahb_master_sequence::type_id::create("ahb_mst_seq");
//        ahb_mst_seq.start(env_m.v_sqr);
        apb_slv0_seq = apb_slave_sequence::type_id::create("apb_slv0_seq");
//        apb_slv0_seq.start(env_m.v_sqr);
        apb_slv1_seq = apb_slave_sequence::type_id::create("apb_slv1_seq");
//        apb_slv1_seq.start(env_m.v_sqr);
        apb_slv2_seq = apb_slave_sequence::type_id::create("apb_slv2_seq");
//        apb_slv2_seq.start(env_m.v_sqr);
        apb_slv3_seq = apb_slave_sequence::type_id::create("apb_slv3_seq");
//        apb_slv3_seq.start(env_m.v_sqr);
        apb_slv4_seq = apb_slave_sequence::type_id::create("apb_slv4_seq");
//        apb_slv4_seq.start(env_m.v_sqr);
        apb_slv5_seq = apb_slave_sequence::type_id::create("apb_slv5_seq");
//        apb_slv5_seq.start(env_m.v_sqr);
        apb_slv6_seq = apb_slave_sequence::type_id::create("apb_slv6_seq");
//        apb_slv6_seq.start(env_m.v_sqr);
        apb_slv7_seq = apb_slave_sequence::type_id::create("apb_slv7_seq");
//        apb_slv7_seq.start(env_m.v_sqr);
        apb_slv8_seq = apb_slave_sequence::type_id::create("apb_slv8_seq");
//        apb_slv8_seq.start(env_m.v_sqr);
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
