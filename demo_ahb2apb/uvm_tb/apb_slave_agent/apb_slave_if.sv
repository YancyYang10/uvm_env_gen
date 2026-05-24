`ifndef _APB_SLAVE_IF_SV_
`define _APB_SLAVE_IF_SV_

interface apb_slave_if(input bit hclk, hreset_n);
    logic[31:0] paddr;
    logic penable;
    logic pwrite;
    logic[31:0] pwdata;
    logic pready;
    logic[31:0] prdata;
    logic pslverr;

    // Clocking blocks
    clocking drv_cb @(posedge hclk);
        default input #1ps output #1ps;
        input hreset_n;
        input paddr;
        input penable;
        input pwrite;
        input pwdata;
        output pready;
        output prdata;
        output pslverr;
    endclocking

    clocking mon_cb @(posedge hclk);
        default input #1ps output #1ps;
        input hreset_n;
        input paddr;
        input penable;
        input pwrite;
        input pwdata;
        input pready;
        input prdata;
        input pslverr;
    endclocking

endinterface

`endif
