`ifndef _${config['env']['name'].upper()}_SV_
`define _${config['env']['name'].upper()}_SV_

class ${config['env']['name']} extends uvm_env;
    `uvm_component_utils(${config['env']['name']})

    ${config['cfg']['name']} cfg_m;

    // === Agent 实例声明 ===
    % for inst in agent_instances:
    ${inst['type']}_agent ${inst['inst_name']};
    % endfor

    % if config['env']['has_ref_model']:
    ${config['ref_model']['name']} rm_m;
    % endif
    % if config['env']['has_scoreboard']:
    ${config['scoreboard']['name']} scb_m;
    % endif
    % if config['env']['has_coverage']:
    ${config['coverage']['name']} cov_m;
    % endif
    virtual_sequencer vsqr_m;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal("get_type_name()", "Top cfg not found!")
        end

        // === Agent 实例化 ===
        % for inst in agent_instances:
        ${inst['inst_name']} = ${inst['type']}_agent::type_id::create("${inst['inst_name']}", this);
        % endfor

        % if config['env']['has_ref_model']:
        rm_m = ${config['ref_model']['name']}::type_id::create("rm_m", this);
        % endif
        % if config['env']['has_scoreboard']:
        scb_m = ${config['scoreboard']['name']}::type_id::create("scb_m", this);
        % endif
        % if config['env']['has_coverage']:
        cov_m = ${config['coverage']['name']}::type_id::create("cov_m", this);
        % endif

        vsqr_m = virtual_sequencer::type_id::create("vsqr_m", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        `uvm_info(get_type_name(), "=== TLM Connection Start ===", UVM_LOW)

        // ==================== Virtual Sequencer 连接 ====================
        % for inst in agent_instances:
        if(cfg_m.${inst['inst_name']}_is_active == UVM_ACTIVE) begin
            vsqr_m.${inst['sqr_name']} = ${inst['inst_name']}.sqr_m;
            `uvm_info(get_type_name(), $sformatf("TLM: vsqr_m.${inst['sqr_name']} <- ${inst['inst_name']}.sqr_m"), UVM_HIGH)
        end
        % endfor

<%
    # 收集 input agents 和 output agents
    input_agents = []
    output_agents = []
    for inst in agent_instances:
        if inst.get('type_role') == 'in':
            input_agents.append(inst)
        elif inst.get('type_role') == 'out':
            output_agents.append(inst)
%>
    % if config['env']['has_ref_model']:
        // ==================== Ref Model 输入连接 ====================
        % for inst in input_agents:
        ${inst['inst_name']}.mon_m.ap.connect(rm_m.${inst['item']}_mon_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: rm_m.${inst['item']}_mon_imp <- ${inst['inst_name']}.mon_m.ap [INPUT]"), UVM_LOW)
        % endfor

        % if config['env']['has_scoreboard']:
        // ==================== Ref Model 输出 -> Scoreboard Expected ====================
        % for pred_item in config['ref_model']['predicted_type']:
        rm_m.${pred_item}_pred_port.connect(scb_m.${pred_item}_exp_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.${pred_item}_exp_imp <- rm_m.${pred_item}_pred_port [EXPECTED]"), UVM_LOW)
        % endfor
        % endif
    % endif

    % if config['env']['has_scoreboard']:
        // ==================== Output Agent -> Scoreboard Actual ====================
        // 每个 out_agent 必须独立连接到 scoreboard，确保独立比对
        // 注意：当前配置中所有 out_agent 使用相同的 item 类型，需合并到同一个队列
        // 如需独立比对，请为每个 slave 配置独立的 scoreboard imp
        % if len(output_agents) > 0:
        % for inst in output_agents:
        ${inst['inst_name']}.mon_m.ap.connect(scb_m.${inst['item']}_act_imp);
        `uvm_info(get_type_name(), $sformatf("TLM: scb_m.${inst['item']}_act_imp <- ${inst['inst_name']}.mon_m.ap [ACTUAL]"), UVM_LOW)
        % endfor
        // 输出 Agent 数量: ${len(output_agents)}
        `uvm_info(get_type_name(), $sformatf("TLM CHECK: %0d output agents connected to scoreboard", ${len(output_agents)}), UVM_LOW)
        % endif
    % endif

    % if config['env']['has_coverage']:
        // ==================== Coverage 连接 ====================
        // TODO: 根据需要连接各 agent monitor 到 coverage
    % endif

        `uvm_info(get_type_name(), "=== TLM Connection Done ===", UVM_LOW)
    endfunction

    // ==================== End of Test 检查 ====================
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);

        % if config['env']['has_scoreboard']:
        // 检查 Scoreboard 是否有未比对的交易
        // 详细检查在 scoreboard.report_phase 中完成
        % endif
    endfunction

endclass

`endif