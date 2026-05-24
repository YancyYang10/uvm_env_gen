`ifndef _${item['name'].upper()}_SV_
`define _${item['name'].upper()}_SV_

class ${item['name']} extends uvm_sequence_item;
    `uvm_object_utils(${item['name']})
    
    % for field in item['fields']:
    % if field['rand']:
    rand ${field['type']} ${field['name']};
    % else:
    ${field['type']} ${field['name']};
    % endif
    % endfor

    function new(string name = "${item['name']}");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        ${item['name']} _rhs;
        if(!$cast(_rhs, rhs)) begin
            `uvm_fatal("CASTERR", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        % for field in item['fields']:
        ${field['name']} = _rhs.${field['name']};
        % endfor
    endfunction

    function string convert2string();
        return $sformatf("\
            % for field in item['fields']:
            ${field['name']}=0x%h ${",\\" if not loop.last else "\","}
            % endfor,
            % for field in item['fields']:
            ${field['name']} ${"," if not loop.last else ""}
            % endfor
        );
    endfunction
endclass

`endif
