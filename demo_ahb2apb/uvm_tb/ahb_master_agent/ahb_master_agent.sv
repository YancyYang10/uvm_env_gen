`ifndef _AHB_MASTER_AGENT_SV_
`define _AHB_MASTER_AGENT_SV_

class ahb_master_agent extends uvm_agent;
    `uvm_component_utils(ahb_master_agent)

    top_cfg cfg_m;

    virtual ahb_master_if vif;

    ahb_master_driver     drv_m;
    ahb_master_sequencer  sqr_m;
    ahb_master_monitor    mon_m;

    // 动态获取实例名对应的配置字段
    protected uvm_active_passive_enum is_active;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);

        if (!uvm_config_db#(virtual ahb_master_if)::get(this, "", "ahb_master_if_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found!")
        end
        if (!uvm_config_db#(top_cfg)::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end

        // 根据实例名获取对应的 is_active 配置
        case(get_name())
            "ahb_mst_agt_m": is_active = cfg_m.ahb_mst_agt_m_is_active;
            default: is_active = UVM_PASSIVE;  // 默认 passive
        endcase

        if(is_active == UVM_ACTIVE) begin
            drv_m = ahb_master_driver::type_id::create("drv_m", this);
            sqr_m = ahb_master_sequencer::type_id::create("sqr_m", this);
        end

        mon_m = ahb_master_monitor::type_id::create("mon_m", this);

        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction

    function void connect_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"connect_phase start",UVM_LOW);

        if(is_active == UVM_ACTIVE) begin
            drv_m.seq_item_port.connect(sqr_m.seq_item_export);
        end

        `uvm_info(get_type_name(),"connect_phase done",UVM_LOW);
    endfunction
endclass

`endif