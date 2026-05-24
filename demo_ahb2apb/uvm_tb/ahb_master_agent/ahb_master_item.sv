`ifndef _AHB_MASTER_ITEM_SV_
`define _AHB_MASTER_ITEM_SV_

class ahb_master_item extends uvm_sequence_item;
    `uvm_object_utils(ahb_master_item)
    
    rand logic[31:0] addr;
    rand logic[31:0] data;
    rand logic[1:0] trans;
    rand logic write;

    // === 约束块 ===
    constraint trans_c {
        trans inside {[0:3]};
    }

    function new(string name = "ahb_master_item");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        ahb_master_item _rhs;
        if(!$cast(_rhs, rhs)) begin
            `uvm_fatal("CASTERR", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        addr = _rhs.addr;
        data = _rhs.data;
        trans = _rhs.trans;
        write = _rhs.write;
    endfunction

    function string convert2string();
        return $sformatf("            addr=0x%h ,\
            data=0x%h ,\
            trans=0x%h ,\
            write=0x%h ",
            addr ,
            data ,
            trans ,
            write 
        );
    endfunction

    // === do_compare: 字段级比对 ===
    function bit do_compare(uvm_object rhs, uvm_comparer comparer=null);
        ahb_master_item _rhs;
        if(!$cast(_rhs, rhs)) return 0;
        if(addr !== _rhs.addr) return 0;
        if(data !== _rhs.data) return 0;
        if(trans !== _rhs.trans) return 0;
        if(write !== _rhs.write) return 0;
        return 1;
    endfunction

    // === do_pack: 打包为字节流 ===
    function void do_pack(uvm_packer packer);
        super.do_pack(packer);
        packer.pack_field(addr, $bits(addr));
        packer.pack_field(data, $bits(data));
        packer.pack_field(trans, $bits(trans));
        packer.pack_field(write, $bits(write));
    endfunction

    // === do_unpack: 从字节流解包 ===
    function void do_unpack(uvm_packer packer);
        super.do_unpack(packer);
        addr = packer.unpack_field_int($bits(addr));
        data = packer.unpack_field_int($bits(data));
        trans = packer.unpack_field_int($bits(trans));
        write = packer.unpack_field_int($bits(write));
    endfunction

    // === do_print: 打印详细信息 ===
    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("addr", addr, $bits(addr));
        printer.print_field("data", data, $bits(data));
        printer.print_field("trans", trans, $bits(trans));
        printer.print_field("write", write, $bits(write));
    endfunction
endclass

`endif
