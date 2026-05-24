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

    % if item.get('constraints'):
    // === 约束块 ===
    % for c in item['constraints']:
    constraint ${c['name']} {
        ${c['expr']};
    }
    % endfor
    % endif

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

    // === do_compare: 字段级比对 ===
    function bit do_compare(uvm_object rhs, uvm_comparer comparer=null);
        ${item['name']} _rhs;
        if(!$cast(_rhs, rhs)) return 0;
        % for field in item['fields']:
        if(${field['name']} !== _rhs.${field['name']}) return 0;
        % endfor
        return 1;
    endfunction

    // === do_pack: 打包为字节流 ===
    function void do_pack(uvm_packer packer);
        super.do_pack(packer);
        % for field in item['fields']:
        packer.pack_field(${field['name']}, $bits(${field['name']}));
        % endfor
    endfunction

    // === do_unpack: 从字节流解包 ===
    function void do_unpack(uvm_packer packer);
        super.do_unpack(packer);
        % for field in item['fields']:
        ${field['name']} = packer.unpack_field_int($bits(${field['name']}));
        % endfor
    endfunction

    // === do_print: 打印详细信息 ===
    function void do_print(uvm_printer printer);
        super.do_print(printer);
        % for field in item['fields']:
        printer.print_field("${field['name']}", ${field['name']}, $bits(${field['name']}));
        % endfor
    endfunction
endclass

`endif
