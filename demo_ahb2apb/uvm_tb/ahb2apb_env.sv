`ifndef _AHB2APB_ENV_SV_
`define _AHB2APB_ENV_SV_

class ahb2apb_env extends uvm_env;
    `uvm_component_utils(ahb2apb_env)

    top_cfg cfg_m;

    // === Agent 实例声明 ===
    ahb_master_agent ahb_mst_agt_m;
    apb_slave_agent apb_slv0_agt_m;
    apb_slave_agent apb_slv1_agt_m;
    apb_slave_agent apb_slv2_agt_m;
    apb_slave_agent apb_slv3_agt_m;
    apb_slave_agent apb_slv4_agt_m;
    apb_slave_agent apb_slv5_agt_m;
    apb_slave_agent apb_slv6_agt_m;
    apb_slave_agent apb_slv7_agt_m;
    apb_slave_agent apb_slv8_agt_m;

    ahb2apb_ref_model rm_m;
    ahb2apb_scoreboard scb_m;
    ahb2apb_coverage cov_m;
    virtual_sequencer vsqr_m;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(top_cfg)::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal("get_type_name()", "Top cfg not found!")
        end

        // === Agent 实例化 ===
        ahb_mst_agt_m = ahb_master_agent::type_id::create("ahb_mst_agt_m", this);
        apb_slv0_agt_m = apb_slave_agent::type_id::create("apb_slv0_agt_m", this);
        apb_slv1_agt_m = apb_slave_agent::type_id::create("apb_slv1_agt_m", this);
        apb_slv2_agt_m = apb_slave_agent::type_id::create("apb_slv2_agt_m", this);
        apb_slv3_agt_m = apb_slave_agent::type_id::create("apb_slv3_agt_m", this);
        apb_slv4_agt_m = apb_slave_agent::type_id::create("apb_slv4_agt_m", this);
        apb_slv5_agt_m = apb_slave_agent::type_id::create("apb_slv5_agt_m", this);
        apb_slv6_agt_m = apb_slave_agent::type_id::create("apb_slv6_agt_m", this);
        apb_slv7_agt_m = apb_slave_agent::type_id::create("apb_slv7_agt_m", this);
        apb_slv8_agt_m = apb_slave_agent::type_id::create("apb_slv8_agt_m", this);

        rm_m = ahb2apb_ref_model::type_id::create("rm_m", this);
        scb_m = ahb2apb_scoreboard::type_id::create("scb_m", this);
        cov_m = ahb2apb_coverage::type_id::create("cov_m", this);

        vsqr_m = virtual_sequencer::type_id::create("vsqr_m", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        `uvm_info(get_type_name(), "=== TLM Connection Start ===", UVM_LOW)

        // ==================== Virtual Sequencer 连接 ====================
        if(cfg_m.ahb_mst_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.ahb_mst_sqr = ahb_mst_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.ahb_mst_sqr <- ahb_mst_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv0_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv0_sqr = apb_slv0_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv0_sqr <- apb_slv0_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv1_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv1_sqr = apb_slv1_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv1_sqr <- apb_slv1_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv2_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv2_sqr = apb_slv2_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv2_sqr <- apb_slv2_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv3_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv3_sqr = apb_slv3_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv3_sqr <- apb_slv3_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv4_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv4_sqr = apb_slv4_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv4_sqr <- apb_slv4_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv5_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv5_sqr = apb_slv5_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv5_sqr <- apb_slv5_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv6_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv6_sqr = apb_slv6_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv6_sqr <- apb_slv6_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv7_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv7_sqr = apb_slv7_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv7_sqr <- apb_slv7_agt_m.sqr_m"), UVM_HIGH)
        end
        if(cfg_m.apb_slv8_agt_m_is_active == UVM_ACTIVE) begin
            vsqr_m.apb_slv8_sqr = apb_slv8_agt_m.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.apb_slv8_sqr <- apb_slv8_agt_m.sqr_m"), UVM_HIGH)
        end


        // ==================== Ref Model 输入连接 ====================

        // ==================== Ref Model 输出 -> Scoreboard Expected ====================
        rm_m.apb_slave_item_pred_port.connect(scb_m.apb_slave_item_exp_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_exp_imp <- rm_m.apb_slave_item_pred_port [EXPECTED]"), UVM_LOW)

        // ==================== Output Agent -> Scoreboard Actual ====================
        // 每个 out_agent 必须独立连接到 scoreboard，确保独立比对
        // 注意：当前配置中所有 out_agent 使用相同的 item 类型，需合并到同一个队列
        // 如需独立比对，请为每个 slave 配置独立的 scoreboard imp
        apb_slv0_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv0_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv1_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv1_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv2_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv2_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv3_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv3_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv4_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv4_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv5_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv5_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv6_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv6_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv7_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv7_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        apb_slv8_agt_m.mon_m.ap.connect(scb_m.apb_slave_item_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.apb_slave_item_act_imp <- apb_slv8_agt_m.mon_m.ap [ACTUAL]"), UVM_LOW)
        // 输出 Agent 数量: 9
        `uvm_info(get_type_name(), $sformatf("TLM CHECK: %0d output agents connected to scoreboard", 9), UVM_LOW)

        // ==================== Coverage 连接 ====================
        // TODO: 根据需要连接各 agent monitor 到 coverage

        `uvm_info(get_type_name(), "=== TLM Connection Done ===", UVM_LOW)
    endfunction

    // ==================== End of Test 检查 ====================
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);

        // 检查 Scoreboard 是否有未比对的交易
        // 详细检查在 scoreboard.report_phase 中完成
    endfunction

endclass

`endif