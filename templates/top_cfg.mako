`ifndef _${config['cfg']['name'].upper()}_SV_
`define _${config['cfg']['name'].upper()}_SV_

class ${config['cfg']['name']} extends uvm_object;

    // === Agent instance active/passive config ===
    % for inst in agent_instances:
    % if inst['mode'] == 'passive':
    uvm_active_passive_enum ${inst['name']}_agt_is_active = UVM_PASSIVE;
    % else:
    uvm_active_passive_enum ${inst['name']}_agt_is_active = UVM_ACTIVE;
    % endif
    % endfor

    % for field in config['cfg']['fields']:
    % if field['rand']:
    rand ${field['type']} ${field['name']};
    % else:
    ${field['type']} ${field['name']};
    % endif
    % endfor

    `uvm_object_utils_begin(${config['cfg']['name']})
//        `uvm_field_string(xxx, UVM_DEFAULT)
//        `uvm_field_sarray_int(xxx, UVM_DEFAULT)
//        `uvm_field_array_int(xxx, UVM_DEFAULT)
//        `uvm_field_queue_int(xxx, UVM_DEFAULT)
//        `uvm_field_aa_int_string(xxx, UVM_DEFAULT)
//        `uvm_field_aa_int_int(xxx, UVM_DEFAULT)

    % for field in config['cfg']['fields']:
//        `uvm_field_int(${field['name']}, UVM_DEFAULT)
    % endfor
    `uvm_object_utils_end

    function new(string name = "${config['cfg']['name']}");
        super.new(name);
    endfunction

endclass

`endif
