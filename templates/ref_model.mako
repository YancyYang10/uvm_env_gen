`ifndef _${config['ref_model']['name'].upper()}_SV_
`define _${config['ref_model']['name'].upper()}_SV_

class ${config['ref_model']['name']} extends uvm_component;
    `uvm_component_utils(${config['ref_model']['name']})

    % for imp in config['ref_model']['input_item']:
    `uvm_analysis_imp_decl(_${imp}_mon)
    %endfor
    
    % for imp in config['ref_model']['input_item']:
    uvm_analysis_imp_${imp}_mon#(${imp}, ${config['ref_model']['name']}) ${imp}_mon_imp;
    % endfor
    % for ap in config['ref_model']['predicted_type']:
    uvm_analysis_port#(${ap}) ${ap}_pred_port;
    % endfor

    % for imp in config['ref_model']['input_item']:
    ${imp} ${imp}_mon_q[$];
    % endfor
    
    ${config['cfg']['name']} cfg_m;
    % for interface in config['interfaces']:
    virtual ${interface['name']} ${interface['name']}_vif;
    % endfor

    function new(string name, uvm_component parent);
        super.new(name, parent);
    % for imp in config['ref_model']['input_item']:
        ${imp}_mon_imp = new("${imp}_mon_imp", this);
    % endfor
    % for ap in config['ref_model']['predicted_type']:
        ${ap}_pred_port = new("${ap}_pred_port", this);
    % endfor
    endfunction

    function void build_phase(uvm_phase phase);
        % for interface in config['interfaces']:
        if(!uvm_config_db#(virtual ${interface['name']})::get(this, "", "${interface['name']}_vif", ${interface['name']}_vif)) begin
            `uvm_fatal(get_type_name(), "Interface not found!")
        end
        % endfor
        if (!uvm_config_db#(${config['cfg']['name']})::get(this, "", "cfg_m", cfg_m)) begin
            `uvm_fatal(get_type_name(), "Top cfg not found!")
        end
    endfunction

    % for ap in config['ref_model']['predicted_type']:
    function void wr2scb_${ap}(${ap} tr);
        ${ap} pkt;
        assert($cast(pkt, tr.clone()));
        // Prediction logic
        // pkt.addr = tr.addr;
        // pkt.data = tr.data << 2;
        ${ap}_pred_port.write(pkt);
    endfunction

    % endfor

    % for imp in config['ref_model']['input_item']:
    function void write_${imp}_mon(${imp} pkt);
        ${imp}_mon_q.push_back(pkt);
    endfunction

    % endfor

endclass

`endif
