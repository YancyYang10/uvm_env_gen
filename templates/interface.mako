`ifndef _${interface['name'].upper()}_SV_
`define _${interface['name'].upper()}_SV_

interface ${interface['name']}(input bit ${interface['clock']}, ${interface['reset']});
  % for sig in interface['signals']:
    ${sig['type']} ${sig['name']};
  % endfor

    // Clocking blocks
    clocking drv_cb @(posedge ${interface['clock']});
        default input #1ps output #1ps;
    % for sig in interface['signals']:
    % if "dir" in sig and sig['dir'] in ["input", "inout"]:
        input ${sig['name']};
    % endif
    % if "dir" in sig and sig['dir'] in ["output", "inout"]:
        output ${sig['name']};
    % endif
    % endfor
    endclocking

    clocking mon_cb @(posedge ${interface['clock']});
        default input #1ps output #1ps;
    % for sig in interface['signals']:
        input ${sig['name']};
    % endfor
    endclocking

endinterface

`endif
