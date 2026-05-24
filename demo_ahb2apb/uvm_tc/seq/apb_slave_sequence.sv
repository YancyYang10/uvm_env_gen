`ifndef _APB_SLAVE_SEQUENCE_SV_
`define _APB_SLAVE_SEQUENCE_SV_

class apb_slave_sequence extends uvm_sequence #(apb_slave_item);
    `uvm_object_utils(apb_slave_sequence)
    
    function new(string name = "apb_slave_sequence");
        super.new(name);
    endfunction

    task body();
        apb_slave_item tr;
        repeat(10) begin
            tr = apb_slave_item::type_id::create("tr");
            start_item(tr);
            finish_item(tr);
        end
    endtask
endclass

`endif
