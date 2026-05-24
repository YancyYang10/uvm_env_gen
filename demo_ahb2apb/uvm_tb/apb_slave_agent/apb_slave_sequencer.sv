`ifndef _APB_SLAVE_SEQUENCER_SV_
`define _APB_SLAVE_SEQUENCER_SV_

class apb_slave_sequencer extends uvm_sequencer #(apb_slave_item);
    `uvm_component_utils(apb_slave_sequencer)
  
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
