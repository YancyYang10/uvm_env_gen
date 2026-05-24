`ifndef _APB_SLAVE_ITEM_SV_
`define _APB_SLAVE_ITEM_SV_

class apb_slave_item extends uvm_sequence_item;
    `uvm_object_utils(apb_slave_item)
    
    logic[31:0] addr;
    logic[31:0] data;
    logic write;
    logic[3:0] strb;
    logic slverr;
    logic[3:0] slave_id;


    function new(string name = "apb_slave_item");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        apb_slave_item _rhs;
        if(!$cast(_rhs, rhs)) begin
            `uvm_fatal("CASTERR", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        addr = _rhs.addr;
        data = _rhs.data;
        write = _rhs.write;
        strb = _rhs.strb;
        slverr = _rhs.slverr;
        slave_id = _rhs.slave_id;
    endfunction

    function string convert2string();
        return $sformatf("            addr=0x%h ,\
            data=0x%h ,\
            write=0x%h ,\
            strb=0x%h ,\
            slverr=0x%h ,\
            slave_id=0x%h ",
            addr ,
            data ,
            write ,
            strb ,
            slverr ,
            slave_id 
        );
    endfunction

    // === do_compare: 字段级比对 ===
    function bit do_compare(uvm_object rhs, uvm_comparer comparer=null);
        apb_slave_item _rhs;
        if(!$cast(_rhs, rhs)) return 0;
        if(addr !== _rhs.addr) return 0;
        if(data !== _rhs.data) return 0;
        if(write !== _rhs.write) return 0;
        if(strb !== _rhs.strb) return 0;
        if(slverr !== _rhs.slverr) return 0;
        if(slave_id !== _rhs.slave_id) return 0;
        return 1;
    endfunction

    // === do_pack: 打包为字节流 ===
    function void do_pack(uvm_packer packer);
        super.do_pack(packer);
        packer.pack_field(addr, $bits(addr));
        packer.pack_field(data, $bits(data));
        packer.pack_field(write, $bits(write));
        packer.pack_field(strb, $bits(strb));
        packer.pack_field(slverr, $bits(slverr));
        packer.pack_field(slave_id, $bits(slave_id));
    endfunction

    // === do_unpack: 从字节流解包 ===
    function void do_unpack(uvm_packer packer);
        super.do_unpack(packer);
        addr = packer.unpack_field_int($bits(addr));
        data = packer.unpack_field_int($bits(data));
        write = packer.unpack_field_int($bits(write));
        strb = packer.unpack_field_int($bits(strb));
        slverr = packer.unpack_field_int($bits(slverr));
        slave_id = packer.unpack_field_int($bits(slave_id));
    endfunction

    // === do_print: 打印详细信息 ===
    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("addr", addr, $bits(addr));
        printer.print_field("data", data, $bits(data));
        printer.print_field("write", write, $bits(write));
        printer.print_field("strb", strb, $bits(strb));
        printer.print_field("slverr", slverr, $bits(slverr));
        printer.print_field("slave_id", slave_id, $bits(slave_id));
    endfunction
endclass

`endif
