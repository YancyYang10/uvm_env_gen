`ifndef _${agent['name'].upper()}_DRIVER_SV_
`define _${agent['name'].upper()}_DRIVER_SV_

class ${agent['name']}_driver extends uvm_driver #(${item_name});
    `uvm_component_utils(${agent['name']}_driver)

    ${config['cfg']['name']} cfg_m;
    virtual ${agent['interface']} vif;
    uvm_analysis_port#(${item_name}) ap;

    // === 最后一次驱动值存储 (用于 DRV_IDLE_LAST) ===
    % for sig in intf['signals']:
    % if 'dir' in sig and sig['dir'] in ["output", "inout"]:
<%
    sig_type = sig['type']
    # 处理位宽：logic -> 1位, logic[N:0] -> N+1位
    if '[' in sig_type:
        width_part = sig_type.split('[')[1].split(']')[0]
        width_decl = '[' + width_part + ']'
    else:
        width_decl = ''
%>
    logic${width_decl} ${sig['name']}_last;
    % endif
    % endfor

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

        // 初始化所有输出信号
        init_signals();

        // 等待复位释放
        wait(vif.${intf['reset']});
        @(vif.drv_cb);

        fork
            reset_task();
            drive_task();
        join

        `uvm_info(get_type_name(),"run_phase done",UVM_LOW);
    endtask

    // === 初始化所有输出信号 ===
    virtual task init_signals();
        `uvm_info(get_type_name(), "Initializing signals...", UVM_MEDIUM)
        % for sig in intf['signals']:
        % if 'dir' in sig and sig['dir'] in ["output", "inout"]:
        vif.drv_cb.${sig['name']} <= '0;
        ${sig['name']}_last = '0;
        % endif
        % endfor
    endtask

    // === 复位处理 ===
    virtual task reset_task();
        forever begin
            @(negedge vif.${intf['reset']});
            `uvm_info(get_type_name(), "Reset asserted", UVM_MEDIUM)
            init_signals();
            @(posedge vif.${intf['reset']});
            `uvm_info(get_type_name(), "Reset de-asserted", UVM_MEDIUM)
        end
    endtask

    // === 主驱动循环 ===
    virtual task drive_task();
        forever begin
            // 使用 try_next_item 非阻塞获取交易
            seq_item_port.try_next_item(req);

            if(req != null) begin
                `uvm_info(get_type_name(), $sformatf("Received transaction"), UVM_MEDIUM)
                drive_transfer(req);
                ap.write(req);
                seq_item_port.item_done();
            end else begin
                // 没有交易时进入 IDLE 状态
                drive_idle();
            end
        end
    endtask

    // === IDLE 状态驱动 ===
    virtual task drive_idle();
        @(vif.drv_cb);  // 等待一个时钟周期

        case(cfg_m.drv_idle_mode)
            DRV_IDLE_LAST: begin
                // 保持最后一次驱动值
                % for sig in intf['signals']:
                % if 'dir' in sig and sig['dir'] in ["output", "inout"]:
                vif.drv_cb.${sig['name']} <= ${sig['name']}_last;
                % endif
                % endfor
            end
            DRV_IDLE_0: begin
                // 驱动 0 值
                % for sig in intf['signals']:
                % if 'dir' in sig and sig['dir'] in ["output", "inout"]:
                vif.drv_cb.${sig['name']} <= '0;
                % endif
                % endfor
            end
            DRV_IDLE_X: begin
                // 驱动 X 值（释放总线）
                % for sig in intf['signals']:
                % if 'dir' in sig and sig['dir'] in ["output", "inout"]:
                vif.drv_cb.${sig['name']} <= 'x;
                % endif
                % endfor
            end
            default: begin
                % for sig in intf['signals']:
                % if 'dir' in sig and sig['dir'] in ["output", "inout"]:
                vif.drv_cb.${sig['name']} <= '0;
                % endif
                % endfor
            end
        endcase
    endtask

    // === 驱动交易 (用户需根据协议定制) ===
    virtual task drive_transfer(${item_name} tr);
        // 使用 drv_cb 非阻塞赋值示例:
        // @(vif.drv_cb);
        // vif.drv_cb.valid <= 1'b1;
        // vif.drv_cb.addr  <= tr.addr;
        // valid_last = 1'b1;  // 保存最后驱动值
        //
        // while(!vif.drv_cb.ready) @(vif.drv_cb);
        //
        // vif.drv_cb.valid <= 1'b0;
        // valid_last = 1'b0;

        // 默认：等待一个时钟周期
        @(vif.drv_cb);
    endtask
endclass

`endif
