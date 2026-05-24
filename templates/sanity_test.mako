`ifndef _${config['test']['sanity_name'].upper()}_SV_
`define _${config['test']['sanity_name'].upper()}_SV_

`define tc ${config['test']['sanity_name']}
`define tc_cfg ${config['test']['sanity_name']}_cfg

class `tc_cfg extends ${config['cfg']['name']};
    `uvm_object_utils(`tc_cfg)

    function new(string name="`tc_cfg");
        super.new(name);
    endfunction
endclass

class `tc extends ${config['test']['base_name']};
    `uvm_component_utils(`tc)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "build_phase start", UVM_LOW);
        set_type_override_by_type(${config['cfg']['name']}::get_type(), `tc_cfg::get_type());
        super.build_phase(phase);
        `uvm_info(get_type_name(), "build_phase done", UVM_LOW);
    endfunction

endclass

`undef tc
`undef tc_cfg
`endif
