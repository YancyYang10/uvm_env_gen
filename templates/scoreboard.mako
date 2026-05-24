`ifndef _${config['scoreboard']['name'].upper()}_SV_
`define _${config['scoreboard']['name'].upper()}_SV_

class ${config['scoreboard']['name']} extends uvm_scoreboard;
    `uvm_component_utils(${config['scoreboard']['name']})
    
    % for imp in config['scoreboard']['expected_type']:
    `uvm_analysis_imp_decl(_${imp}_exp)
    %endfor

    % for imp in config['scoreboard']['actual_type']:
    `uvm_analysis_imp_decl(_${imp}_act)
    %endfor

    % for imp in config['scoreboard']['expected_type']:
    uvm_analysis_imp_${imp}_exp#(${imp}, ${config['scoreboard']['name']}) ${imp}_exp_imp;
    % endfor

    % for imp in config['scoreboard']['actual_type']:
    uvm_analysis_imp_${imp}_act#(${imp}, ${config['scoreboard']['name']}) ${imp}_act_imp;
    % endfor
    
    % for imp in config['scoreboard']['expected_type']:
    ${imp} ${imp}_expected_q[$];
    % endfor

    % for imp in config['scoreboard']['actual_type']:
    ${imp} ${imp}_actual_q[$];
    % endfor

    ${config['cfg']['name']} cfg_m;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    % for imp in config['scoreboard']['expected_type']:
        ${imp}_exp_imp = new("${imp}_exp_imp", this);
    % endfor
    % for imp in config['scoreboard']['actual_type']:
        ${imp}_act_imp = new("${imp}_act_imp", this);
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

    % for imp in config['scoreboard']['expected_type']:
    function void write_${imp}_exp(${imp} pkt);
        ${imp}_expected_q.push_back(pkt);
    endfunction

    % endfor

    % for imp in config['scoreboard']['actual_type']:
    function void write_${imp}_act(${imp} pkt);
        ${imp}_actual_q.push_back(pkt);
    endfunction
    
    % endfor


    % for imp in config['scoreboard']['actual_type']:
    task ${imp}_compare_data();
        wait(${imp}_actual_q.size() > 0 && ${imp}_expected_q.size() > 0); begin
            ${imp} act = ${imp}_actual_q.pop_front();
            ${imp} exp = ${imp}_expected_q.pop_front();
          
            //case("${config['scoreboard']['compare_method']}")
            //    "byte_compare": if(act.data !== exp.data) `uvm_error("SB", $sformatf("Data mismatch Act:0x%h vs Exp:0x%h", act.data, exp.data))
            //    "full_compare": if(!act.compare(exp)) `uvm_error("SB", "Full packet mismatch")
            //    default: `uvm_error("SB", "Invalid compare method")
            //endcase
        end
    endtask

    % endfor
endclass

`endif
