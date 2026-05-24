`ifndef ${config['coverage']['name'].upper()}_SV
`define ${config['coverage']['name'].upper()}_SV

class ${config['coverage']['name']} extends uvm_component;
    `uvm_component_utils(${config['coverage']['name']})
    
    % for intf in interfaces:
    virtual ${intf['name']} ${intf['name']}_vif;
    % endfor
    
    % for group in config['coverage']['groups']:
    covergroup ${group['name']}_cg;
      % for cp in group['coverpoints']:
        ${cp['name']}: coverpoint ${group['interface'][0]}_vif.${cp['expr']} {
        }
      % endfor
      % if group.get('crosses'):
      % for cross in group['crosses']:
        ${cross['name']}: cross ${", ".join(cross['points'])}{
        }
      % endfor
      % endif
    endgroup
    % endfor

    function new(string name, uvm_component parent);
        super.new(name, parent);
      % for group in config['coverage']['groups']:
        ${group['name']}_cg = new();
      % endfor
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
      % for intf in interfaces:
        if (!uvm_config_db#(virtual ${intf['name']})::get(this, "", "${intf['name']}_vif", ${intf['name']}_vif)) begin
            `uvm_fatal(get_type_name(), $sformatf("Virtual interface for %s not found!", "${intf['name']}"))
        end
      % endfor
    endfunction

    task run_phase(uvm_phase phase);
        fork
        % for group in config['coverage']['groups']:
            do_sample_${group['name']}_cg();
        % endfor
        join
    endtask

    % for group in config['coverage']['groups']:
    task do_sample_${group['name']}_cg();
        forever begin
            @(posedge ${group['interface'][0]}_vif.${group['interface'][1]});
            if(${group['interface'][0]}_vif.${group['interface'][2]}) begin
                ${group['name']}_cg.sample();
            end
        end
    endtask

    % endfor

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      % for group in config['coverage']['groups']:
      `uvm_info(get_type_name(), $sformatf("Coverage group %0s: %.2f%%", "${group['name']}", ${group['name']}_cg.get_coverage()), UVM_LOW)
      % endfor
    endfunction

endclass

`endif
