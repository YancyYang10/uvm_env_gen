`ifndef _APB_SLAVE_DRIVER_SV_
`define _APB_SLAVE_DRIVER_SV_

class apb_slave_driver extends uvm_driver #(apb_slave_item);
    `uvm_component_utils(apb_slave_driver)

    top_cfg cfg_m;
    virtual apb_slave_if vif;
    uvm_analysis_port#(apb_slave_item) ap;

    // === 最后一次驱动值存储 (用于 DRV_IDLE_LAST) ===

    logic pready_last;

    logic[31:0] prdata_last;

    logic pslverr_last;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);

        if(!uvm_config_db#(virtual apb_slave_if)::get(this, "", "apb_slave_if_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found!")
        end
        if (!uvm_config_db#(top_cfg)::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end

        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"run_phase start",UVM_LOW);

        // 初始化所有输出信号
        init_signals();

        // 等待复位释放
        wait(vif.hreset_n);
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
        vif.drv_cb.pready <= '0;
        pready_last = '0;
        vif.drv_cb.prdata <= '0;
        prdata_last = '0;
        vif.drv_cb.pslverr <= '0;
        pslverr_last = '0;
    endtask

    // === 复位处理 ===
    virtual task reset_task();
        forever begin
            @(negedge vif.hreset_n);
            `uvm_info(get_type_name(), "Reset asserted", UVM_MEDIUM)
            init_signals();
            @(posedge vif.hreset_n);
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
                vif.drv_cb.pready <= pready_last;
                vif.drv_cb.prdata <= prdata_last;
                vif.drv_cb.pslverr <= pslverr_last;
            end
            DRV_IDLE_0: begin
                // 驱动 0 值
                vif.drv_cb.pready <= '0;
                vif.drv_cb.prdata <= '0;
                vif.drv_cb.pslverr <= '0;
            end
            DRV_IDLE_X: begin
                // 驱动 X 值（释放总线）
                vif.drv_cb.pready <= 'x;
                vif.drv_cb.prdata <= 'x;
                vif.drv_cb.pslverr <= 'x;
            end
            default: begin
                vif.drv_cb.pready <= '0;
                vif.drv_cb.prdata <= '0;
                vif.drv_cb.pslverr <= '0;
            end
        endcase
    endtask

    // === 驱动交易 (用户需根据协议定制) ===
    virtual task drive_transfer(apb_slave_item tr);
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
