`ifndef _${config['cfg']['name'].upper()}_SV_
`define _${config['cfg']['name'].upper()}_SV_

// === DRV_IDLE 枚举定义 ===
typedef enum bit [1:0] {
    DRV_IDLE_LAST = 2'b00,  // 保持最后一次驱动值
    DRV_IDLE_0    = 2'b01,  // 驱动 0 值
    DRV_IDLE_X    = 2'b10   // 驱动 X 值（释放总线）
} drv_idle_enum;

class ${config['cfg']['name']} extends uvm_object;

    // === 全局驱动 IDLE 模式配置 ===
    drv_idle_enum drv_idle_mode = DRV_IDLE_LAST;

    // === Agent instance active/passive config ===
    % for inst in agent_instances:
    % if inst['mode'] == 'passive':
    uvm_active_passive_enum ${inst['inst_name']}_is_active = UVM_PASSIVE;
    % else:
    uvm_active_passive_enum ${inst['inst_name']}_is_active = UVM_ACTIVE;
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
