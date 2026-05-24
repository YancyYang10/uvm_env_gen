`ifndef _AHB_MASTER_SEQUENCE_SV_
`define _AHB_MASTER_SEQUENCE_SV_

class ahb_master_sequence extends uvm_sequence #(ahb_master_item);
    `uvm_object_utils(ahb_master_sequence)
    
    function new(string name = "ahb_master_sequence");
        super.new(name);
    endfunction

    task body();
        ahb_master_item tr;
        repeat(10) begin
            tr = ahb_master_item::type_id::create("tr");
            start_item(tr);
            if(!tr.randomize()) 
                `uvm_error("RANDERR", "Randomization failed")
            finish_item(tr);
        end
    endtask
endclass

`endif
