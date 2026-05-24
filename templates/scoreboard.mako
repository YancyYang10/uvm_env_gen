`ifndef _${config['scoreboard']['name'].upper()}_SV_
`define _${config['scoreboard']['name'].upper()}_SV_

class ${config['scoreboard']['name']} extends uvm_scoreboard;
    `uvm_component_utils(${config['scoreboard']['name']})

    // === 每个 output item 独立的 imp 声明 ===
    % for imp in config['scoreboard']['expected_type']:
    `uvm_analysis_imp_decl(_${imp}_exp)
    % endfor

    % for imp in config['scoreboard']['actual_type']:
    `uvm_analysis_imp_decl(_${imp}_act)
    % endfor

    // === 每个 output item 独立的 imp 实例 ===
    % for imp in config['scoreboard']['expected_type']:
    uvm_analysis_imp_${imp}_exp#(${imp}, ${config['scoreboard']['name']}) ${imp}_exp_imp;
    % endfor

    % for imp in config['scoreboard']['actual_type']:
    uvm_analysis_imp_${imp}_act#(${imp}, ${config['scoreboard']['name']}) ${imp}_act_imp;
    % endfor

    // === 每个 output item 独立的队列 ===
    % for imp in config['scoreboard']['expected_type']:
    ${imp} ${imp}_expected_q[$];
    % endfor

    % for imp in config['scoreboard']['actual_type']:
    ${imp} ${imp}_actual_q[$];
    % endfor

    // === 每个 output item 独立的统计 ===
    % for imp in config['scoreboard']['actual_type']:
    int ${imp}_total_cnt;
    int ${imp}_passed_cnt;
    int ${imp}_failed_cnt;
    % endfor

    ${config['cfg']['name']} cfg_m;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    % for imp in config['scoreboard']['expected_type']:
        ${imp}_exp_imp = new("${imp}_exp_imp", this);
    % endfor
    % for imp in config['scoreboard']['actual_type']:
        ${imp}_act_imp = new("${imp}_act_imp", this);
        ${imp}_total_cnt   = 0;
        ${imp}_passed_cnt  = 0;
        ${imp}_failed_cnt  = 0;
    % endfor
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);

        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end

        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction

    task run_phase(uvm_phase phase);
        fork
    % for imp in config['scoreboard']['actual_type']:
            ${imp}_compare_task();
    % endfor
        join
    endtask

    // ==================== Expected Write Functions ====================
    % for imp in config['scoreboard']['expected_type']:
    function void write_${imp}_exp(${imp} pkt);
        ${imp} expected;
        if(pkt == null) begin
            `uvm_warning(get_type_name(), "Received null expected item, skipping")
            return;
        end
        expected = ${imp}::type_id::create("expected");
        expected.copy(pkt);
        ${imp}_expected_q.push_back(expected);
        `uvm_info(get_type_name(), $sformatf("${imp}_exp: q_size=%0d", ${imp}_expected_q.size()), UVM_HIGH)
    endfunction

    % endfor

    // ==================== Actual Write Functions ====================
    % for imp in config['scoreboard']['actual_type']:
    function void write_${imp}_act(${imp} pkt);
        ${imp} actual;
        if(pkt == null) begin
            `uvm_warning(get_type_name(), "Received null actual item, skipping")
            return;
        end
        actual = ${imp}::type_id::create("actual");
        actual.copy(pkt);
        ${imp}_actual_q.push_back(actual);
        `uvm_info(get_type_name(), $sformatf("${imp}_act: q_size=%0d", ${imp}_actual_q.size()), UVM_HIGH)
    endfunction

    % endfor

    // ==================== Compare Tasks (每个 output item 独立比对) ====================
    % for imp in config['scoreboard']['actual_type']:
    task ${imp}_compare_task();
        ${imp} exp_tr;
        ${imp} act_tr;
        bit match;

        forever begin
            // 等待两个队列都有数据
            wait(${imp}_expected_q.size() > 0 && ${imp}_actual_q.size() > 0);

            exp_tr = ${imp}_expected_q.pop_front();
            act_tr = ${imp}_actual_q.pop_front();

            ${imp}_total_cnt++;
            match = 1;

            // === 比对逻辑 (使用 do_compare) ===
            if(!exp_tr.compare(act_tr)) begin
                `uvm_error("${imp.upper()}_MISMATCH",
                    $sformatf("\n  EXP: %s\n  ACT: %s",
                        exp_tr.convert2string(), act_tr.convert2string()))
                match = 0;
            end

            if(match) begin
                ${imp}_passed_cnt++;
                `uvm_info(get_type_name(), $sformatf("${imp} PASSED: total=%0d", ${imp}_total_cnt), UVM_HIGH)
            end else begin
                ${imp}_failed_cnt++;
            end
        end
    endtask

    % endfor

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

    % for imp in config['scoreboard']['actual_type']:
        report_str = {report_str, $sformatf("  ${imp}: Total=%0d  Passed=%0d  Failed=%0d  Rate=%.2f%%\n",
            ${imp}_total_cnt, ${imp}_passed_cnt, ${imp}_failed_cnt,
            (${imp}_total_cnt > 0) ? (real'(${imp}_passed_cnt) / real'(${imp}_total_cnt) * 100.0) : 0.0)};

        total_all  += ${imp}_total_cnt;
        passed_all += ${imp}_passed_cnt;
        failed_all += ${imp}_failed_cnt;

        // === 数量检查：期望和实际队列必须都为空 ===
        if(${imp}_expected_q.size() > 0) begin
            report_str = {report_str, $sformatf("  WARNING: ${imp}_expected_q not empty! size=%0d\n", ${imp}_expected_q.size())};
            has_mismatch = 1;
        end
        if(${imp}_actual_q.size() > 0) begin
            report_str = {report_str, $sformatf("  WARNING: ${imp}_actual_q not empty! size=%0d\n", ${imp}_actual_q.size())};
            has_mismatch = 1;
        end
    % endfor

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
