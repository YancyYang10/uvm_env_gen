`ifndef _AHB2APB_SCOREBOARD_SV_
`define _AHB2APB_SCOREBOARD_SV_

class ahb2apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ahb2apb_scoreboard)

    // === 每个 output item 独立的 imp 声明 ===
    `uvm_analysis_imp_decl(_apb_slave_item_exp)

    `uvm_analysis_imp_decl(_apb_slave_item_act)

    // === 每个 output item 独立的 imp 实例 ===
    uvm_analysis_imp_apb_slave_item_exp#(apb_slave_item, ahb2apb_scoreboard) apb_slave_item_exp_imp;

    uvm_analysis_imp_apb_slave_item_act#(apb_slave_item, ahb2apb_scoreboard) apb_slave_item_act_imp;

    // === 每个 output item 独立的队列 ===
    apb_slave_item apb_slave_item_expected_q[$];

    apb_slave_item apb_slave_item_actual_q[$];

    // === 每个 output item 独立的统计 ===
    int apb_slave_item_total_cnt;
    int apb_slave_item_passed_cnt;
    int apb_slave_item_failed_cnt;

    top_cfg cfg_m;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        apb_slave_item_exp_imp = new("apb_slave_item_exp_imp", this);
        apb_slave_item_act_imp = new("apb_slave_item_act_imp", this);
        apb_slave_item_total_cnt   = 0;
        apb_slave_item_passed_cnt  = 0;
        apb_slave_item_failed_cnt  = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);

        if (!uvm_config_db#(top_cfg)::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end

        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            apb_slave_item_compare_task();
        join
    endtask

    // ==================== Expected Write Functions ====================
    function void write_apb_slave_item_exp(apb_slave_item pkt);
        apb_slave_item expected;
        if(pkt == null) begin
            `uvm_warning(get_type_name(), "Received null expected item, skipping")
            return;
        end
        expected = apb_slave_item::type_id::create("expected");
        expected.copy(pkt);
        apb_slave_item_expected_q.push_back(expected);
        `uvm_info(get_type_name(), $sformatf("apb_slave_item_exp: q_size=%0d", apb_slave_item_expected_q.size()), UVM_HIGH)
    endfunction


    // ==================== Actual Write Functions ====================
    function void write_apb_slave_item_act(apb_slave_item pkt);
        apb_slave_item actual;
        if(pkt == null) begin
            `uvm_warning(get_type_name(), "Received null actual item, skipping")
            return;
        end
        actual = apb_slave_item::type_id::create("actual");
        actual.copy(pkt);
        apb_slave_item_actual_q.push_back(actual);
        `uvm_info(get_type_name(), $sformatf("apb_slave_item_act: q_size=%0d", apb_slave_item_actual_q.size()), UVM_HIGH)
    endfunction


    // ==================== Compare Tasks (每个 output item 独立比对) ====================
    task apb_slave_item_compare_task();
        apb_slave_item exp_tr;
        apb_slave_item act_tr;
        bit match;

        forever begin
            // 等待两个队列都有数据
            wait(apb_slave_item_expected_q.size() > 0 && apb_slave_item_actual_q.size() > 0);

            exp_tr = apb_slave_item_expected_q.pop_front();
            act_tr = apb_slave_item_actual_q.pop_front();

            apb_slave_item_total_cnt++;
            match = 1;

            // === 比对逻辑 (使用 do_compare) ===
            if(!exp_tr.compare(act_tr)) begin
                `uvm_error("APB_SLAVE_ITEM_MISMATCH",
                    $sformatf("\n  EXP: %s\n  ACT: %s",
                        exp_tr.convert2string(), act_tr.convert2string()))
                match = 0;
            end

            if(match) begin
                apb_slave_item_passed_cnt++;
                `uvm_info(get_type_name(), $sformatf("apb_slave_item PASSED: total=%0d", apb_slave_item_total_cnt), UVM_HIGH)
            end else begin
                apb_slave_item_failed_cnt++;
            end
        end
    endtask


    // ==================== Report Phase (统计报告) ====================
    function void report_phase(uvm_phase phase);
        string report_str;
        int total_all = 0;
        int passed_all = 0;
        int failed_all = 0;
        bit has_mismatch = 0;

        super.report_phase(phase);

        report_str = "\n";
        report_str = {report_str, "========================================\n"};
        report_str = {report_str, "Scoreboard Report\n"};
        report_str = {report_str, "========================================\n"};

        report_str = {report_str, $sformatf("  apb_slave_item: Total=%0d  Passed=%0d  Failed=%0d  Rate=%.2f%%\n",
            apb_slave_item_total_cnt, apb_slave_item_passed_cnt, apb_slave_item_failed_cnt,
            (apb_slave_item_total_cnt > 0) ? (real'(apb_slave_item_passed_cnt) / real'(apb_slave_item_total_cnt) * 100.0) : 0.0)};

        total_all  += apb_slave_item_total_cnt;
        passed_all += apb_slave_item_passed_cnt;
        failed_all += apb_slave_item_failed_cnt;

        // === 数量检查：期望和实际队列必须都为空 ===
        if(apb_slave_item_expected_q.size() > 0) begin
            report_str = {report_str, $sformatf("  WARNING: apb_slave_item_expected_q not empty! size=%0d\n", apb_slave_item_expected_q.size())};
            has_mismatch = 1;
        end
        if(apb_slave_item_actual_q.size() > 0) begin
            report_str = {report_str, $sformatf("  WARNING: apb_slave_item_actual_q not empty! size=%0d\n", apb_slave_item_actual_q.size())};
            has_mismatch = 1;
        end

        report_str = {report_str, "----------------------------------------\n"};
        report_str = {report_str, $sformatf("  TOTAL: %0d  Passed: %0d  Failed: %0d  Rate: %.2f%%\n",
            total_all, passed_all, failed_all,
            (total_all > 0) ? (real'(passed_all) / real'(total_all) * 100.0) : 0.0)};
        report_str = {report_str, "========================================\n"};

        `uvm_info(get_type_name(), report_str, UVM_LOW)

        // === 杜绝假 PASS：任何失败都报 ERROR ===
        if(failed_all > 0 || has_mismatch) begin
            `uvm_error(get_type_name(), "TEST FAILED - Mismatches detected!")
        end else if(total_all > 0) begin
            `uvm_info(get_type_name(), "TEST PASSED - All transactions matched!", UVM_LOW)
        end else begin
            `uvm_warning(get_type_name(), "No transactions were compared!")
        end
    endfunction

endclass

`endif
