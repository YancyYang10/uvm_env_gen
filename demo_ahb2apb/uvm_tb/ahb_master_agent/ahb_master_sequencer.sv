`ifndef _AHB_MASTER_SEQUENCER_SV_
`define _AHB_MASTER_SEQUENCER_SV_

class ahb_master_sequencer extends uvm_sequencer #(ahb_master_item);
    `uvm_component_utils(ahb_master_sequencer)
  
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
