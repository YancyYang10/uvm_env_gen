simSetSimulator "-vcssv" -exec \
           "/home/IC_verify/script/uvm_gen/demo_ahb2apb/rsim/out/default/simv_default" \
           -args \
           "+UVM_TESTNAME=tc_sanity +vcs+initreg+0 +UVM_VERBOSITY=UVM_MEDIUM -cm line+cond+fsm+branch+tgl+assert -cm_name tc_sanity_20260405151255 -cm_hier cm.cfg +ntb_random_seed=20260405151255 +UVM_NO_RELNOTES +licp -ucli +UVM_VERDI_TRACE=UVM_AWARE+HIER"
debImport "-dbdir" \
          "/home/IC_verify/script/uvm_gen/demo_ahb2apb/rsim/out/default/simv_default.daidir"
debLoadSimResult \
           /home/IC_verify/script/uvm_gen/demo_ahb2apb/rsim/out/default/sim_tc_sanity_20260405151255.fsdb
wvCreateWindow
verdiDockWidgetSetCurTab -dock widgetDock_<Decl._Tree>
verdiDockWidgetSetCurTab -dock widgetDock_<Inst._Tree>
srcHBSelect "uvm_custom_install_verdi_recording" -win $_nTrace1
srcSetScope -win $_nTrace1 "uvm_custom_install_verdi_recording" -delim "."
srcHBSelect "uvm_custom_install_verdi_recording" -win $_nTrace1
srcHBSelect "uvm_custom_install_verdi_recording" -win $_nTrace1
srcSetScope -win $_nTrace1 "uvm_custom_install_verdi_recording" -delim "."
srcHBSelect "uvm_custom_install_verdi_recording" -win $_nTrace1
srcHBSelect "uvm_custom_install_verdi_recording" -win $_nTrace1
srcTBTBHTogg
verdiDockWidgetSetCurTab -dock widgetDock_<Decl._Tree>
verdiDockWidgetSetCurTab -dock widgetDock_<Inst._Tree>
verdiDockWidgetSetCurTab -dock widgetDock_<OVM/UVM_Hier.>
srcTBHier -treeSel "uvm_test_top"
srcTBHier -treeSel "uvm_test_top"
srcTBHier -showTreeDef
srcTBHier -treeSel "uvm_test_top.env_m"
srcTBHier -showTreeDef
verdiDockWidgetSetCurTab -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_top.apb_slv4_vif" -win $_nTrace1
srcSetScope -win $_nTrace1 "tb_top.apb_slv4_vif" -delim "."
srcHBSelect "tb_top.apb_slv4_vif" -win $_nTrace1
srcHBSelect "tb_top.ahb_mst_vif" -win $_nTrace1
srcSetScope -win $_nTrace1 "tb_top.ahb_mst_vif" -delim "."
srcHBSelect "tb_top.ahb_mst_vif" -win $_nTrace1
srcHBSelect "tb_top.DUT" -win $_nTrace1
srcSetScope -win $_nTrace1 "tb_top.DUT" -delim "."
srcHBSelect "tb_top.DUT" -win $_nTrace1
srcDeselectAll -win $_nTrace1
verdiSetFont -monoFont "Courier" -monoFontSize "14"
simSetInteractiveFsdbFile inter.fsdb
simSetSvtbMode off
srcSetPreference -filterPowerAwareInstruments off -profileTime off
tbvSetPreference -dynamicDumpMDA 1 -dynamicDumpStruct 1 -dynamicDumpSystemCStruct \
           1 -dynamicDumpSystemCPlain 1 -dynamicDumpSystemCFIFO 1
srcHBSelect "tb_top.ahb_mst_vif" -win $_nTrace1
srcSetScope -win $_nTrace1 "tb_top.ahb_mst_vif" -delim "."
srcHBSelect "tb_top.ahb_mst_vif" -win $_nTrace1
srcHBSelect "tb_top.apb_slv0_vif" -win $_nTrace1
srcSetScope -win $_nTrace1 "tb_top.apb_slv0_vif" -delim "."
srcHBSelect "tb_top.apb_slv0_vif" -win $_nTrace1
verdiDockWidgetSetCurTab -dock widgetDock_<OVM/UVM_Hier.>
srcTBHier -treeSel "uvm_test_top.env_m"
srcTBHier -treeSel "uvm_test_top.env_m"
srcTBHier -showTreeDef
srcDeselectAll -win $_nTrace1
srcTBHier -treeSel "uvm_test_top.env_m.ahb_mst_agt_m"
srcTBHier -showTreeDef
srcTBHier -treeSel "uvm_test_top.env_m.ahb_mst_agt_m.drv_m"
srcTBHier -showTreeDef
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "hwrite_last" -line 21 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "hsel_last" -line 13 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "hwdata_last" -line 19 -pos 1 -win $_nTrace1
debExit
