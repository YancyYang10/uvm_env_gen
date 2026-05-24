######################################################################
#### 	for setting
TB_TOP 					?= tb_top
#VERDI_HOME 				?= /opt/synopsys/verdi/verdi/Verdi_O-2018.09-SP2
#VCS_HOME 				?= /opt/synopsys/vcs/vcs-mx/O-2018.09-SP2
#UVM_HOME 				?= /opt/synopsys/vcs/vcs-mx/O-2018.09-SP2/etc/uvm-1.1

######################################################################
#### 	file lists
RTL_FLIST 				?= rtl.f
TB_FLIST 				?= tb.f

tc 						?= tc_sanity
seed 					:= $(shell date +%Y%m%d%H%M%S)
pl 						?= UVM_MEDIUM
wave 					?= 1
cov 					?= 1

export wave
export tc
export seed 


######################################################################
#### 	generic simulation control
VCS_OPTS 				+= vcs -sverilog -full64 -kdb -DVCS -lca -ntb_opts uvm-1.2 +vpi +lint=TFIPC,PCWM +vcs+lic+wait +debug_region=cell+lib +vcs+initreg+random 
VCS_OPTS_VERDI 			=  -debug_access+all \
						   -P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab \
						   $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a 
VCS_OPTS_UVM 			=  +incdir+$(UVM_HOME)/src \
						   $(UVM_HOME)/src/uvm.sv \
						   $(UVM_HOME)/src/uvm_pkg.sv 
						   #$(UVM_HOME)/src/dpi/uvm_dpi.cc 
						   #-CFLAGS -DVCS

#default options
VCS_COMP_LOG 			?= compile.log
VCS_SIMV_NAME 			?= simv
VCS_TIMESCALE 			?= 1ns/1ps
VCS_TB_DEFINES 			?=
VCS_TB_ARGS 			?=
VCS_TIMING_MODE 		?= +notimingcheck +nospecify

SIM_LOG 				?= $(tc)_$(seed).log
SIM_OTHERS 				?= +UVM_NO_RELNOTES
SIM_STRIP_SEL 			?= 
COV_DB_NAME 			?= $(tc)_$(seed)


######################################################################
#### UPF_FILE
LP_SIM 					?= 0
ifeq ($(LP_SIM),1)
	UPF_FILE            =  ../../sim_rtl/bench/test_upf/top.upf
else
	UPF_FILE            =  ../../../upf/tsmc12_top.upf
endif

#### debug control
DEBUG 					?= 0
ifeq ($(DEBUG),1)
	DVE_DEBUG           =  -gui
else
	DVE_DEBUG           =
endif


#### COV setting
ifeq ($(cov),1)
	VCS_OPTS_COV 		=  -lca -cm line+cond+fsm+branch+tgl+assert -cm_name $(COV_DB_NAME) -cm_hier cm.cfg
	SIM_OPTS_COV 		=  -cm line+cond+fsm+branch+tgl+assert =cm_name $(COV_DB_NAME) -cm_hier cm.cfg
else
	VCS_OPTS_COV 		=
	SIM_OPTS_COV 		=
endif

COV_RPT 				?= 0
ifeq ($(COV_RPT),1)
	URG_OPTS 			=  urg -dir $(VCS_SIMV_NAME).vdb -report $(VCS_SIMV_NAME)_cov_rpt
else
	URG_OPTS 			=
endif

#### SEED setting
ifdef seed
	SIM_OPTS_SEED 		=  +ntb_random_seed=$(seed)
else
	SIM_OPTS_SEED 		=  +ntb_random_seed_automatic
endif

#### lp control


######################################################################
#### local variables and final compilation/simulation option
COMPOPTS 				=  $(VCS_OPTS) $(VCS_OPTS_VERDI) $(VCS_OPTS_UVM) $(VCS_OPTS_VIP) 
COMPOPTS 				+= $(VCS_TIMING_MODE)
COMPOPTS 				+= -o ./out/$(VCS_SIMV_NAME)
COMPOPTS 				+= -timescale=$(VCS_TIMESCALE)
COMPOPTS 				+= +define+$(VCS_TB_DEFINES)
COMPOPTS 				+= -top $(TB_TOP)
COMPOPTS 				+= -f $(RTL_FLIST) -f $(TB_FLIST)
COMPOPTS 				+= $(DVE_DEBUG)
COMPOPTS 				+= $(VCS_OPTS_COV)
COMPOPTS 				+= $(UPF_OPTS)
COMPOPTS 				+= +define+TSMC_CM_NO_WARNING+TSMC_DISABLE_CONTENTION_MESSAGE

SIMOPTS 				=  ./out/$(VCS_SIMV_NAME)
SIMOPTS 				+= +UVM_TESTNAME=$(tc) +vcs+initreg+0
SIMOPTS 				+= $(SIM_STRIP_SEL)
SIMOPTS 				+= +UVM_VERBOSITY=$(pl)
SIMOPTS 				+= +$(DVE_DEBUG) $(SIM_OPTS_WAVE) $(SIM_OPTS_COV) $(SIM_OPTS_SEED)
SIMOPTS 				+= $(VCS_TB_ARGS)
SIMOPTS 				+= $(SIM_OTHERS)
SIMOPTS 				+= +licp
SIMOPTS 				+= -ucli -i run.tcl

#### VCS LOG setting
VCS_LOG 				?= 1
ifeq ($(VCS_LOG),1)
	COMPOPTS 			+= -l ./out/$(VCS_COMP_LOG)
	SIMOPTS 			+= -l ./out/$(SIM_LOG)
else
	COMPOPTS 			+= 
	SIMOPTS 			+= 
endif

######################################################################
#### global rule
all : compile sim urg

prepare:
	mkdir -p out
	cp Makefile run.tcl cm.cfg rtl.f tb.f out

compile : prepare
	$(COMPOPTS)

sim : prepare
	@	echo "=================================================";
	@ 	echo "          Current test: $(tc)";
	@ 	echo "          Current seed: $(seed)";
	@	echo "=================================================";
	$(SIMOPTS)

urg : prepare
	$(URG_OPTS)

clean:
	rm -rf *log csrc *key 
