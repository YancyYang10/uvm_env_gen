`ifndef _VIRTUAL_SEQUENCER_SV_
`define _VIRTUAL_SEQUENCER_SV_

class virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(virtual_sequencer)

    top_cfg cfg_m;
    // === Sequencer handles for each agent instance ===
    ahb_master_sequencer ahb_mst_sqr;
    apb_slave_sequencer apb_slv0_sqr;
    apb_slave_sequencer apb_slv1_sqr;
    apb_slave_sequencer apb_slv2_sqr;
    apb_slave_sequencer apb_slv3_sqr;
    apb_slave_sequencer apb_slv4_sqr;
    apb_slave_sequencer apb_slv5_sqr;
    apb_slave_sequencer apb_slv6_sqr;
    apb_slave_sequencer apb_slv7_sqr;
    apb_slave_sequencer apb_slv8_sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(),"build_phase start",UVM_LOW);
        if (!uvm_config_db#(top_cfg)::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end
        `uvm_info(get_type_name(),"build_phase done",UVM_LOW);
    endfunction
endclass

`endif