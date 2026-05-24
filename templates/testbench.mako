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

    # 收集所有需要的接口（按 agent_instances）
    agent_interfaces = {}
    for inst in agent_instances:
        if_name = inst.get('interface', '')
        if if_name and if_name not in agent_interfaces:
            agent_interfaces[if_name] = []
        if if_name:
            agent_interfaces[if_name].append(inst['name'])

    # 收集 coverage 需要的接口
    coverage_interfaces = []
    if 'coverage' in config and 'groups' in config['coverage']:
        for group in config['coverage']['groups']:
            if 'interface' in group and len(group['interface']) > 0:
                if_name = group['interface'][0]
                if if_name not in coverage_interfaces:
                    coverage_interfaces.append(if_name)
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
<%
    # 收集所有实例的 vif_name 和对应的 interface 类型
    vif_instances = {}
    for inst in agent_instances:
        vif_name = inst.get('vif_name', '')
        if_name = inst.get('interface', '')
        if vif_name and if_name and vif_name not in vif_instances:
            vif_instances[vif_name] = {
                'if_name': if_name,
                'inst_name': inst.get('inst_name', ''),
                'clock': '',
                'reset': ''
            }
            # 从 if_map 获取 clock 和 reset
            if if_name in if_map:
                vif_instances[vif_name]['clock'] = if_map[if_name].get('clock', 'clk')
                vif_instances[vif_name]['reset'] = if_map[if_name].get('reset', 'rst_n')

    # 收集 coverage 需要的接口 vif_name
    coverage_vifs = []
    if 'coverage' in config and 'groups' in config['coverage']:
        for group in config['coverage']['groups']:
            if 'interface' in group and len(group['interface']) > 0:
                if_name = group['interface'][0]
                # 找到该接口对应的一个 vif_name
                for inst in agent_instances:
                    if inst.get('interface') == if_name:
                        coverage_vifs.append(inst.get('vif_name', if_name + '_vif'))
                        break
%>
% for vif_name, vif_info in vif_instances.items():
    ${vif_info['if_name']} ${vif_name}(${vif_info['clock']}, ${vif_info['reset']});
% endfor

    // === DUT Instantiation ===
% if port_mapping:
    ${config['rtl']['top_module']} ${config['testbench']['dut_instance']} (
% for port in port_mapping:
        .${port['name']} ( ${port['connection']}${"\t\t"} )${"," if not loop.last else ""} // ${port['type']}
% endfor
    );
% else:
    ${config['rtl']['top_module']} ${config['testbench']['dut_instance']}();
% endif

    // === UVM Configuration ===
    initial begin
        // === Agent 实例接口配置 ===
% for inst in agent_instances:
        uvm_config_db#(virtual ${inst['interface']})::set(null, "uvm_test_top.env_m.${inst['inst_name']}*", "${inst['interface']}_vif", ${inst['vif_name']});
% endfor

        // === Coverage 接口配置 ===
% for vif_name in coverage_vifs:
<%
    # 从 vif_name 推断 interface 类型
    if_type = ''
    for inst in agent_instances:
        if inst.get('vif_name') == vif_name:
            if_type = inst.get('interface', '')
            break
%>
        uvm_config_db#(virtual ${if_type})::set(null, "uvm_test_top.env_m.cov_m", "${if_type}_vif", ${vif_name});
% endfor

        // === Reference Model 接口配置 (去重) ===
<%
    # 去重：每种接口类型只配置一次
    ref_model_if_configured = set()
%>
% for inst in agent_instances:
<%
    if_name = inst.get('interface', '')
    vif_name = inst.get('vif_name', '')
%>
% if if_name and vif_name and if_name not in ref_model_if_configured:
        uvm_config_db#(virtual ${if_name})::set(null, "uvm_test_top.env_m.rm_m", "${if_name}_vif", ${vif_name});
<%
    ref_model_if_configured.add(if_name)
%>
% endif
% endfor

        run_test("${config['test']['base_name']}");
    end
endmodule
