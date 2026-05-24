`ifndef _${agent['name'].upper()}_SEQUENCER_SV_
`define _${agent['name'].upper()}_SEQUENCER_SV_

class ${agent['name']}_sequencer extends uvm_sequencer #(${item_name});
    `uvm_component_utils(${agent['name']}_sequencer)
  
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
