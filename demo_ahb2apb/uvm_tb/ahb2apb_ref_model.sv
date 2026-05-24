`ifndef _AHB2APB_REF_MODEL_SV_
`define _AHB2APB_REF_MODEL_SV_

class ahb2apb_ref_model extends uvm_component;
    `uvm_component_utils(ahb2apb_ref_model)

    `uvm_analysis_imp_decl(_ahb_master_item_mon)
    
    uvm_analysis_imp_ahb_master_item_mon#(ahb_master_item, ahb2apb_ref_model) ahb_master_item_mon_imp;
    uvm_analysis_port#(apb_slave_item) apb_slave_item_pred_port;

    ahb_master_item ahb_master_item_mon_q[$];
    
    top_cfg cfg_m;
    virtual ahb_master_if ahb_master_if_vif;
    virtual apb_slave_if apb_slave_if_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ahb_master_item_mon_imp = new("ahb_master_item_mon_imp", this);
        apb_slave_item_pred_port = new("apb_slave_item_pred_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual ahb_master_if)::get(this, "", "ahb_master_if_vif", ahb_master_if_vif)) begin
            `uvm_fatal(get_type_name(), "Interface not found!")
        end
        if(!uvm_config_db#(virtual apb_slave_if)::get(this, "", "apb_slave_if_vif", apb_slave_if_vif)) begin
            `uvm_fatal(get_type_name(), "Interface not found!")
        end
        if (!uvm_config_db#(top_cfg)::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end
    endfunction

    function void wr2scb_apb_slave_item(apb_slave_item tr);
        apb_slave_item pkt;
        assert($cast(pkt, tr.clone()));
        // Prediction logic
        // pkt.addr = tr.addr;
        // pkt.data = tr.data << 2;
        apb_slave_item_pred_port.write(pkt);
    endfunction


    function void write_ahb_master_item_mon(ahb_master_item pkt);
        ahb_master_item_mon_q.push_back(pkt);
    endfunction


endclass

`endif
