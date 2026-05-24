`ifndef _AHB_MASTER_IF_SV_
`define _AHB_MASTER_IF_SV_

interface ahb_master_if(input bit hclk, hreset_n);
    logic hsel;
    logic[31:0] haddr;
    logic[1:0] htrans;
    logic[31:0] hwdata;
    logic hwrite;
    logic[31:0] hrdata;
    logic hready;
    logic[1:0] hresp;

    // Clocking blocks
    clocking drv_cb @(posedge hclk);
        default input #1ps output #1ps;
        input hreset_n;
        output hsel;
        output haddr;
        output htrans;
        output hwdata;
        output hwrite;
        input hrdata;
        input hready;
        input hresp;
    endclocking

    clocking mon_cb @(posedge hclk);
        default input #1ps output #1ps;
        input hreset_n;
        input hsel;
        input haddr;
        input htrans;
        input hwdata;
        input hwrite;
        input hrdata;
        input hready;
        input hresp;
    endclocking

endinterface

`endif
