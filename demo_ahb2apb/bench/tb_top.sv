`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"


    // === Clock Signals (去重) ===
    logic hclk;
    real  hclk_delay;

    // === Reset Signals (去重) ===
    logic hreset_n;
    real  hreset_n_delay;

    // === Clock Generation ===
    initial begin
        hclk = 0;
        hclk_delay = $urandom_range(0,100) / 100;
        #(hclk_delay * 1ns);
        forever begin
            #10ns;
            hclk = ~hclk;
        end
    end


    // === Reset Generation ===
    initial begin
        hreset_n = 0;
        hreset_n_delay = $urandom_range(10,100);
        #(hreset_n_delay * 1ns);
        hreset_n = 1;
    end

    // === Interface Instantiation ===

    ahb_master_if ahb_mst_vif(hclk, hreset_n);
    apb_slave_if apb_slv0_vif(hclk, hreset_n);
    apb_slave_if apb_slv1_vif(hclk, hreset_n);
    apb_slave_if apb_slv2_vif(hclk, hreset_n);
    apb_slave_if apb_slv3_vif(hclk, hreset_n);
    apb_slave_if apb_slv4_vif(hclk, hreset_n);
    apb_slave_if apb_slv5_vif(hclk, hreset_n);
    apb_slave_if apb_slv6_vif(hclk, hreset_n);
    apb_slave_if apb_slv7_vif(hclk, hreset_n);
    apb_slave_if apb_slv8_vif(hclk, hreset_n);

    // === DUT Instantiation ===
    ahb2apb DUT (
        .hclk ( hclk		 ), // clock
        .hreset_n ( hreset_n		 ), // reset
        .hsel ( ahb_mst_vif.hsel		 ), // interface
        .haddr ( ahb_mst_vif.haddr		 ), // interface
        .htrans ( ahb_mst_vif.htrans		 ), // interface
        .hwdata ( ahb_mst_vif.hwdata		 ), // interface
        .hwrite ( ahb_mst_vif.hwrite		 ), // interface
        .hrdata ( ahb_mst_vif.hrdata		 ), // interface
        .hready ( ahb_mst_vif.hready		 ), // interface
        .hresp ( ahb_mst_vif.hresp		 ), // interface
        .paddr ( /* TODO: connect paddr to one of: apb_slv0_vif, apb_slv1_vif, apb_slv2_vif, apb_slv3_vif, apb_slv4_vif, apb_slv5_vif, apb_slv6_vif, apb_slv7_vif, apb_slv8_vif */		 ), // interface_multi
        .penable ( /* TODO: connect penable to one of: apb_slv0_vif, apb_slv1_vif, apb_slv2_vif, apb_slv3_vif, apb_slv4_vif, apb_slv5_vif, apb_slv6_vif, apb_slv7_vif, apb_slv8_vif */		 ), // interface_multi
        .pwrite ( /* TODO: connect pwrite to one of: apb_slv0_vif, apb_slv1_vif, apb_slv2_vif, apb_slv3_vif, apb_slv4_vif, apb_slv5_vif, apb_slv6_vif, apb_slv7_vif, apb_slv8_vif */		 ), // interface_multi
        .pwdata ( /* TODO: connect pwdata to one of: apb_slv0_vif, apb_slv1_vif, apb_slv2_vif, apb_slv3_vif, apb_slv4_vif, apb_slv5_vif, apb_slv6_vif, apb_slv7_vif, apb_slv8_vif */		 ), // interface_multi
        .psel0 ( /* TODO: connect psel0 */		 ), // unknown
        .pready0 ( /* TODO: connect pready0 */		 ), // unknown
        .prdata0 ( /* TODO: connect prdata0 */		 ), // unknown
        .psel1 ( /* TODO: connect psel1 */		 ), // unknown
        .pready1 ( /* TODO: connect pready1 */		 ), // unknown
        .prdata1 ( /* TODO: connect prdata1 */		 ), // unknown
        .psel2 ( /* TODO: connect psel2 */		 ), // unknown
        .pready2 ( /* TODO: connect pready2 */		 ), // unknown
        .prdata2 ( /* TODO: connect prdata2 */		 ), // unknown
        .psel3 ( /* TODO: connect psel3 */		 ), // unknown
        .pready3 ( /* TODO: connect pready3 */		 ), // unknown
        .prdata3 ( /* TODO: connect prdata3 */		 ), // unknown
        .psel4 ( /* TODO: connect psel4 */		 ), // unknown
        .pready4 ( /* TODO: connect pready4 */		 ), // unknown
        .prdata4 ( /* TODO: connect prdata4 */		 ), // unknown
        .psel5 ( /* TODO: connect psel5 */		 ), // unknown
        .pready5 ( /* TODO: connect pready5 */		 ), // unknown
        .prdata5 ( /* TODO: connect prdata5 */		 ), // unknown
        .psel6 ( /* TODO: connect psel6 */		 ), // unknown
        .pready6 ( /* TODO: connect pready6 */		 ), // unknown
        .prdata6 ( /* TODO: connect prdata6 */		 ), // unknown
        .psel7 ( /* TODO: connect psel7 */		 ), // unknown
        .pready7 ( /* TODO: connect pready7 */		 ), // unknown
        .prdata7 ( /* TODO: connect prdata7 */		 ), // unknown
        .psel8 ( /* TODO: connect psel8 */		 ), // unknown
        .pready8 ( /* TODO: connect pready8 */		 ), // unknown
        .prdata8 ( /* TODO: connect prdata8 */		 ) // unknown
    );

    // === UVM Configuration ===
    initial begin
        // === Agent 实例接口配置 ===
        uvm_config_db#(virtual ahb_master_if)::set(null, "uvm_test_top.env_m.ahb_mst_agt_m*", "ahb_master_if_vif", ahb_mst_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv0_agt_m*", "apb_slave_if_vif", apb_slv0_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv1_agt_m*", "apb_slave_if_vif", apb_slv1_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv2_agt_m*", "apb_slave_if_vif", apb_slv2_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv3_agt_m*", "apb_slave_if_vif", apb_slv3_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv4_agt_m*", "apb_slave_if_vif", apb_slv4_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv5_agt_m*", "apb_slave_if_vif", apb_slv5_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv6_agt_m*", "apb_slave_if_vif", apb_slv6_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv7_agt_m*", "apb_slave_if_vif", apb_slv7_vif);
        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.apb_slv8_agt_m*", "apb_slave_if_vif", apb_slv8_vif);

        // === Coverage 接口配置 ===

        uvm_config_db#(virtual ahb_master_if)::set(null, "uvm_test_top.env_m.cov_m", "ahb_master_if_vif", ahb_mst_vif);

        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.cov_m", "apb_slave_if_vif", apb_slv0_vif);

        // === Reference Model 接口配置 (去重) ===


        uvm_config_db#(virtual ahb_master_if)::set(null, "uvm_test_top.env_m.rm_m", "ahb_master_if_vif", ahb_mst_vif);


        uvm_config_db#(virtual apb_slave_if)::set(null, "uvm_test_top.env_m.rm_m", "apb_slave_if_vif", apb_slv0_vif);










        run_test("tc_base_test");
    end
endmodule
