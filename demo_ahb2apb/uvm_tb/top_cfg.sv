`ifndef _TOP_CFG_SV_
`define _TOP_CFG_SV_

// === DRV_IDLE 枚举定义 ===
typedef enum bit [1:0] {
    DRV_IDLE_LAST = 2'b00,  // 保持最后一次驱动值
    DRV_IDLE_0    = 2'b01,  // 驱动 0 值
    DRV_IDLE_X    = 2'b10   // 驱动 X 值（释放总线）
} drv_idle_enum;

class top_cfg extends uvm_object;

    // === 全局驱动 IDLE 模式配置 ===
    drv_idle_enum drv_idle_mode = DRV_IDLE_LAST;

    // === Agent instance active/passive config ===
    uvm_active_passive_enum ahb_mst_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv0_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv1_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv2_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv3_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv4_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv5_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv6_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv7_agt_m_is_active = UVM_ACTIVE;
    uvm_active_passive_enum apb_slv8_agt_m_is_active = UVM_ACTIVE;

    int is_active;
    int scb_en;

    `uvm_object_utils_begin(top_cfg)
//        `uvm_field_string(xxx, UVM_DEFAULT)
//        `uvm_field_sarray_int(xxx, UVM_DEFAULT)
//        `uvm_field_array_int(xxx, UVM_DEFAULT)
//        `uvm_field_queue_int(xxx, UVM_DEFAULT)
//        `uvm_field_aa_int_string(xxx, UVM_DEFAULT)
//        `uvm_field_aa_int_int(xxx, UVM_DEFAULT)

//        `uvm_field_int(is_active, UVM_DEFAULT)
//        `uvm_field_int(scb_en, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "top_cfg");
        super.new(name);
    endfunction

endclass

`endif
