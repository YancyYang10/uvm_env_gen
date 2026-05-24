`ifndef _${agent['name'].upper()}_SEQUENCE_SV_
`define _${agent['name'].upper()}_SEQUENCE_SV_

class ${agent['name']}_sequence extends uvm_sequence #(${item_name});
    `uvm_object_utils(${agent['name']}_sequence)
    
    function new(string name = "${agent['name']}_sequence");
        super.new(name);
    endfunction

    task body();
        ${item_name} tr;
        repeat(10) begin
            tr = ${item_name}::type_id::create("tr");
            start_item(tr);
            % if any(field['rand']for field in item['fields']):
            if(!tr.randomize()) 
                `uvm_error("RANDERR", "Randomization failed")
            % endif
            finish_item(tr);
        end
    endtask
endclass

`endif
