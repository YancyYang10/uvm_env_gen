`ifndef AHB2APB_COVERAGE_SV
`define AHB2APB_COVERAGE_SV


class ahb2apb_coverage extends uvm_component;
    `uvm_component_utils(ahb2apb_coverage)

    virtual ahb_master_if ahb_master_if_vif;
    virtual apb_slave_if apb_slave_if_vif;

    covergroup ahb_cov_cg;
        addr_cp: coverpoint ahb_master_if_vif.haddr {
            // === bins 定义 ===
            bins slave0 = {[0:'h0FFF]};
            bins slave1 = {['h1000:'h1FFF]};
            bins other = default;
        }
        trans_cp: coverpoint ahb_master_if_vif.htrans {
            // === bins 定义 ===
            bins idle = {0};
            bins busy = {1};
            bins nonseq = {2};
            bins seq = {3};
        }
        write_cp: coverpoint ahb_master_if_vif.hwrite {
            // === bins 定义 ===
            bins read = {0};
            bins write = {1};
        }
        addr_x_write: cross addr_cp, write_cp{
        }
    endgroup
    covergroup apb_cov_cg;
        pwrite_cp: coverpoint apb_slave_if_vif.pwrite {
            // === bins 定义 ===
            bins read = {0};
            bins write = {1};
        }
        penable_cp: coverpoint apb_slave_if_vif.penable {
            // === bins 定义 ===
            bins setup = {0};
            bins access = {1};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ahb_cov_cg = new();
        apb_cov_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_master_if)::get(this, "", "ahb_master_if_vif", ahb_master_if_vif)) begin
            `uvm_fatal(get_type_name(), $sformatf("Virtual interface for %s not found!", "ahb_master_if"))
        end
        if (!uvm_config_db#(virtual apb_slave_if)::get(this, "", "apb_slave_if_vif", apb_slave_if_vif)) begin
            `uvm_fatal(get_type_name(), $sformatf("Virtual interface for %s not found!", "apb_slave_if"))
        end
    endfunction

    task run_phase(uvm_phase phase);
        fork
            do_sample_ahb_cov_cg();
            do_sample_apb_cov_cg();
        join
    endtask

    task do_sample_ahb_cov_cg();
        forever begin
            @(ahb_master_if_vif.mon_cb);
            if(ahb_master_if_vif.mon_cb.hreset_n) begin
                ahb_cov_cg.sample();
            end
        end
    endtask

    task do_sample_apb_cov_cg();
        forever begin
            @(apb_slave_if_vif.mon_cb);
            if(apb_slave_if_vif.mon_cb.hreset_n) begin
                apb_cov_cg.sample();
            end
        end
    endtask


    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info(get_type_name(), $sformatf("Coverage group %0s: %.2f%%", "ahb_cov", ahb_cov_cg.get_coverage()), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("Coverage group %0s: %.2f%%", "apb_cov", apb_cov_cg.get_coverage()), UVM_LOW)
    endfunction

endclass

`endif