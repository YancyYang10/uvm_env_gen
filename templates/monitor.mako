`ifndef _${agent['name'].upper()}_MONITOR_SV_
`define _${agent['name'].upper()}_MONITOR_SV_

class ${agent['name']}_monitor extends uvm_monitor;
    `uvm_component_utils(${agent['name']}_monitor)

    ${config['cfg']['name']} cfg_m;
    uvm_analysis_port#(${item_name}) ap;
    virtual ${agent['interface']} vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);

        if(!uvm_config_db#(virtual ${agent['interface']})::get(this, "", "${agent['interface']}_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found!")
        end
        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end

        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"run_phase start",UVM_LOW);

        // 等待复位释放
        wait(vif.${intf['reset']});
        @(vif.mon_cb);

        forever begin
            ${item_name} tr = ${item_name}::type_id::create("tr");
            collect_transfer(tr);
            // 仅发送有效交易
            if(tr != null) begin
                ap.write(tr);
            end
        end

        `uvm_info(get_type_name(),"run_phase done",UVM_LOW);
    endtask

    // === 采样交易 (用户需根据协议定制) ===
    virtual task collect_transfer(output ${item_name} tr);
        // 使用 mon_cb 采样示例:
        // @(vif.mon_cb);
        // if(vif.mon_cb.valid && vif.mon_cb.ready) begin
        //     tr.addr  = vif.mon_cb.addr;
        //     tr.data  = vif.mon_cb.data;
        //     tr.write = vif.mon_cb.write;
        // end

        // 默认：每周期采样
        @(vif.mon_cb);
    endtask
endclass

`endif
