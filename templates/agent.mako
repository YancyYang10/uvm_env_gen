`ifndef _${agent['name'].upper()}_AGENT_SV_
`define _${agent['name'].upper()}_AGENT_SV_

class ${agent['name']}_agent extends uvm_agent;
    `uvm_component_utils(${agent['name']}_agent)

    ${config['cfg']['name']} cfg_m;

    virtual ${agent['interface']} vif;

    ${agent['name']}_driver     drv_m;
    ${agent['name']}_sequencer  sqr_m;
    ${agent['name']}_monitor    mon_m;

    // 动态获取实例名对应的配置字段
    protected uvm_active_passive_enum is_active;


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

        // 根据实例名获取对应的 is_active 配置
        case(get_name())
        % for inst in agent_instances:
        % if inst['type'] == agent['name']:
            "${inst['inst_name']}": is_active = cfg_m.${inst['inst_name']}_is_active;
        % endif
        % endfor
            default: is_active = UVM_PASSIVE;  // 默认 passive
        endcase

        if(is_active == UVM_ACTIVE) begin
            drv_m = ${agent['name']}_driver::type_id::create("drv_m", this);
            sqr_m = ${agent['name']}_sequencer::type_id::create("sqr_m", this);
        end

        mon_m = ${agent['name']}_monitor::type_id::create("mon_m", this);

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