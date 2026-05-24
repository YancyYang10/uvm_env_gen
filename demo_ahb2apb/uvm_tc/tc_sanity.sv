`ifndef _TC_SANITY_SV_
`define _TC_SANITY_SV_

`define tc tc_sanity
`define tc_cfg tc_sanity_cfg

class `tc_cfg extends top_cfg;
    `uvm_object_utils(`tc_cfg)

    function new(string name="`tc_cfg");
        super.new(name);
    endfunction
endclass

class `tc extends tc_base_test;
    `uvm_component_utils(`tc)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "build_phase start", UVM_LOW);
        set_type_override_by_type(top_cfg::get_type(), `tc_cfg::get_type());
        super.build_phase(phase);
        `uvm_info(get_type_name(), "build_phase done", UVM_LOW);
    endfunction

endclass

`undef tc
`undef tc_cfg
`endif
