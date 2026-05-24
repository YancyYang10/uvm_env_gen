`timescale ${config['testbench']['timescale']}

module ${config['testbench']['name']};
    import uvm_pkg::*;
    `include "uvm_macros.svh"  

    % for intf in interfaces:
    logic ${intf['clock']};
    real  ${intf['clock']}_delay;
    logic ${intf['reset']};
    real  ${intf['reset']}_delay;
    % endfor

    % for intf in interfaces:
    initial begin
        ${intf['clock']} = 0;
        ${intf['clock']}_delay = $urandom_range(0,100) / 100;
        #(${intf['clock']}_delay * 1ns);
        forever begin
            #${intf['clk_period']};
            ${intf['clock']} = ~${intf['clock']};
        end
    end

    % endfor

    % for intf in interfaces:
    initial begin
        //${intf['reset']} = 1;
        //#10ns;
        ${intf['reset']} = 0;
        ${intf['reset']}_delay = $urandom_range(10,100);
        #(${intf['reset']}_delay * 1ns);
        ${intf['reset']} = 1;
    end
    % endfor

    // Interfaces
    % for interface in interfaces:
    ${interface['name']} ${interface['name']}_vif(${interface['clock']}, ${interface['reset']});
    % endfor

    // DUT instantiation
    % if rtl_ports:
    ${config['rtl']['top_module']} ${config['testbench']['dut_instance']} (
    % for port in rtl_ports:
        .${port['name']} ( ${"\t\t"} )${"," if not loop.last else ""} // ${port['direction']} ${port['width']}
    % endfor
    );
    % else:
    ${config['rtl']['top_module']} ${config['testbench']['dut_instance']}();
    % endif


    initial begin
      // Interface configuration
      % for interface in interfaces:
        uvm_config_db#(virtual ${interface['name']})::set(null, "uvm_test_top.env*", "${interface['name']}_vif", ${interface['name']}_vif);
      % endfor
      
        run_test("${config['test']['base_name']}");
    end
endmodule

