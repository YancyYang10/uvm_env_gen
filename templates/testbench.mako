`timescale ${config['testbench']['timescale']}

module ${config['testbench']['name']};
    import uvm_pkg::*;
    `include "uvm_macros.svh"

<%
    # 收集唯一的 clock 和 reset 信号，避免重复声明
    unique_clocks = {}
    unique_resets = {}
    for intf in interfaces:
        clk = intf.get('clock', 'clk')
        rst = intf.get('reset', 'rst_n')
        clk_period = intf.get('clk_period', '10ns')
        if clk not in unique_clocks:
            unique_clocks[clk] = clk_period
        if rst not in unique_resets:
            unique_resets[rst] = True
%>
    // === Clock Signals (去重) ===
% for clk, period in unique_clocks.items():
    logic ${clk};
    real  ${clk}_delay;
% endfor

    // === Reset Signals (去重) ===
% for rst in unique_resets.keys():
    logic ${rst};
    real  ${rst}_delay;
% endfor

    // === Clock Generation ===
% for clk, period in unique_clocks.items():
    initial begin
        ${clk} = 0;
        ${clk}_delay = $urandom_range(0,100) / 100;
        #(${clk}_delay * 1ns);
        forever begin
            #${period};
            ${clk} = ~${clk};
        end
    end

% endfor

    // === Reset Generation ===
% for rst in unique_resets.keys():
    initial begin
        ${rst} = 0;
        ${rst}_delay = $urandom_range(10,100);
        #(${rst}_delay * 1ns);
        ${rst} = 1;
    end
% endfor

    // === Interface Instantiation ===
% for interface in interfaces:
    ${interface['name']} ${interface['name']}_vif(${interface['clock']}, ${interface['reset']});
% endfor

    // === DUT Instantiation ===
% if rtl_ports:
    ${config['rtl']['top_module']} ${config['testbench']['dut_instance']} (
% for port in rtl_ports:
        .${port['name']} ( ${"\t\t"} )${"," if not loop.last else ""} // ${port['direction']} ${port['width']}
% endfor
    );
% else:
    ${config['rtl']['top_module']} ${config['testbench']['dut_instance']}();
% endif

    // === UVM Configuration ===
    initial begin
% for interface in interfaces:
        uvm_config_db#(virtual ${interface['name']})::set(null, "uvm_test_top.env*", "${interface['name']}_vif", ${interface['name']}_vif);
% endfor

        run_test("${config['test']['base_name']}");
    end
endmodule