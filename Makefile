RTL_SRC_DIR = src/rtl
RTL_SRCS = \
	$(RTL_SRC_DIR)/tube_tracker.sv \
	$(RTL_SRC_DIR)/reg_file.sv \
	$(RTL_SRC_DIR)/reg_group.sv \
	$(RTL_SRC_DIR)/tube_0c.sv \
	$(RTL_SRC_DIR)/tube_4c.sv \
	$(RTL_SRC_DIR)/tube_8c.sv \
	$(RTL_SRC_DIR)/fetch.sv \
	$(RTL_SRC_DIR)/decode.sv \
	$(RTL_SRC_DIR)/exec.sv \
	$(RTL_SRC_DIR)/memrw.sv \
	$(RTL_SRC_DIR)/regwr.sv \
	$(RTL_SRC_DIR)/pipeline.sv \
	$(RTL_SRC_DIR)/core.sv

RVMODEL_SRC_DIR = src/rvmodel
RVMODEL_SRCS = \
	$(RVMODEL_SRC_DIR)/rv.cpp
RVMODEL_OBJ_DIR = build/rvmodel_obj
RVMODEL_OBJS = $(subst $(RVMODEL_SRC_DIR),$(RVMODEL_OBJ_DIR),$(patsubst %.cpp,%.o,$(RVMODEL_SRCS)))

VSCTB_SRC_DIR = src/vsctb
VSCTB_SRCS = \
	$(VSCTB_SRC_DIR)/vsctb_core_main.cpp
VSCTB_OBJ_DIR = build/vsctb_obj
VSCTB_OBJS = $(subst $(VSCTB_SRC_DIR),$(VSCTB_OBJ_DIR),$(patsubst %.cpp,%.o,$(VSCTB_SRCS)))
VSCTB_EXE_DIR = build/vsctb_exe
VSCTB_EXE = $(VSCTB_EXE_DIR)/vsctb_core.out

VRLLIB_SRC_DIR = /usr/share/verilator/include
VRLLIB_SRCS = \
	$(VRLLIB_SRC_DIR)/verilated.cpp \
	$(VRLLIB_SRC_DIR)/verilated_vcd_c.cpp \
	$(VRLLIB_SRC_DIR)/verilated_vcd_sc.cpp
VRLLIB_OBJ_DIR = build/vrllib_obj
VRLLIB_OBJS = $(subst $(VRLLIB_SRC_DIR),$(VRLLIB_OBJ_DIR),$(patsubst %.cpp,%.o,$(VRLLIB_SRCS)))

SC_INC_DIR = /usr/local/systemc-2.3.3/include
SC_LIB_DIR = /usr/local/systemc-2.3.3/lib-linux64
SC_LIBS = $(SC_LIB_DIR)/libsystemc.a

VRLGEN_SRC_DIR = build/vrlgen_src
VRLGEN_SRCS = \
	$(VRLGEN_SRC_DIR)/vrl_core.cpp \
	$(VRLGEN_SRC_DIR)/vrl_core__Slow.cpp \
	$(VRLGEN_SRC_DIR)/vrl_core__Syms.cpp \
	$(VRLGEN_SRC_DIR)/vrl_core__Trace.cpp \
	$(VRLGEN_SRC_DIR)/vrl_core__Trace__Slow.cpp
VRLGEN_OBJ_DIR = build/vrlgen_obj
VRLGEN_OBJS = $(subst $(VRLGEN_SRC_DIR),$(VRLGEN_OBJ_DIR),$(patsubst %.cpp,%.o,$(VRLGEN_SRCS)))

ASTEST_SRC_DIR = src/astest
ASTEST_SRCS = \
	$(ASTEST_SRC_DIR)/test001.s
ASTEST_OBJ_DIR = build/astest_obj
ASTEST_OBJS = $(subst $(ASTEST_SRC_DIR),$(ASTEST_OBJ_DIR),$(patsubst %.s,%.o,$(ASTEST_SRCS)))
ASTEST_DIS_DIR = build/astest_dis
ASTEST_DISS = $(subst $(ASTEST_OBJ_DIR),$(ASTEST_DIS_DIR),$(patsubst %.o,%.txt,$(ASTEST_OBJS)))

VRL_SIM_DIR = sim/vrl

.PHONY: lint genv gensim genastest sim clean debug

lint: $(RTL_SRCS)
	verilator --lint-only -Wall $(RTL_SRCS)

genv: $(VRLGEN_SRCS)
$(VRLGEN_SRCS)&: $(RTL_SRCS) | $(VRLGEN_SRC_DIR)
	export SYSTEMC_INCLUDE=$(SC_INC_DIR);\
	export SYSTEMC_LIBDIR=$(SC_LIB_DIR);\
	verilator --sc --pins-sc-uint --trace --trace-structs $(RTL_SRCS) --top-module core -Mdir $(VRLGEN_SRC_DIR) --prefix vrl_core

$(VRLGEN_SRC_DIR):
	mkdir -p $@

gensim: $(VSCTB_EXE)
$(VSCTB_EXE): $(VSCTB_OBJS) $(RVMODEL_OBJS) $(VRLGEN_OBJS) $(VRLLIB_OBJS) $(SC_LIBS) | $(VSCTB_EXE_DIR)
	g++ -o $@ $^

$(VSCTB_EXE_DIR):
	mkdir -p $@

$(RVMODEL_OBJ_DIR)/%.o: $(RVMODEL_SRC_DIR)/%.cpp $(RVMODEL_SRC_DIR)/*.h | $(RVMODEL_OBJ_DIR)
	g++ -O0 -c -std=c++14 -pedantic -Wall -Wextra -Wshadow -o $@ $< -I$(RVMODEL_SRC_DIR)

$(RVMODEL_OBJ_DIR):
	mkdir -p $@

$(VSCTB_OBJ_DIR)/%.o: $(VSCTB_SRC_DIR)/%.cpp $(VSCTB_SRC_DIR)/*.hpp $(RVMODEL_SRC_DIR)/*.h $(VRLGEN_SRCS) | $(VSCTB_OBJ_DIR)
	g++ -O0 -c -std=c++14 -pedantic -Wall -Wextra -Wshadow -o $@ $< \
		-I$(RVMODEL_SRC_DIR) -I$(VRLLIB_SRC_DIR) -I$(VRLGEN_SRC_DIR) -I$(SC_INC_DIR)

$(VSCTB_OBJ_DIR):
	mkdir -p $@

$(VRLGEN_OBJ_DIR)/%.o: $(VRLGEN_SRC_DIR)/%.cpp | $(VRLGEN_OBJ_DIR)
	g++ -O0 -c -std=c++14 -pedantic -faligned-new -Wall -o $@ $< -I$(VRLLIB_SRC_DIR) -I$(SC_INC_DIR)

$(VRLGEN_OBJ_DIR):
	mkdir -p $@

$(VRLLIB_OBJ_DIR)/%.o: $(VRLLIB_SRC_DIR)/%.cpp $(VRLLIB_SRC_DIR)/*.h | $(VRLLIB_OBJ_DIR)
	g++ -O0 -c -std=c++14 -Wall -o $@ $< -I$(VRLLIB_SRC_DIR) -I$(SC_INC_DIR)

$(VRLLIB_OBJ_DIR):
	mkdir -p $@

$(VRL_SIM_DIR):
	mkdir -p $@

genastest: $(ASTEST_DISS)
$(ASTEST_DIS_DIR)/%.txt: $(ASTEST_OBJ_DIR)/%.o | $(ASTEST_DIS_DIR)
	riscv64-linux-gnu-objdump -d $< | grep -e'^ .*' > $@

$(ASTEST_DIS_DIR):
	mkdir -p $@

$(ASTEST_OBJ_DIR)/%.o: $(ASTEST_SRC_DIR)/%.s | $(ASTEST_OBJ_DIR)
	riscv64-linux-gnu-as -o $@ $<

$(ASTEST_OBJ_DIR):
	mkdir -p $@

sim: $(VSCTB_EXE) genastest | $(VRL_SIM_DIR)
	export VSCTB_EXE_REAL=`realpath $(VSCTB_EXE)` && cd $(VRL_SIM_DIR) && $$VSCTB_EXE_REAL

clean:
	rm -rf build sim

debug:
	@echo RTL_SRCS='"'$(RTL_SRCS)'"'
	@echo VSCTB_SRCS='"'$(VSCTB_SRCS)'"'
	@echo VSCTB_OBJS='"'$(VSCTB_OBJS)'"'
	@echo VSCTB_EXE='"'$(VSCTB_EXE)'"'
	@echo VRLGEN_OBJS='"'$(VRLGEN_OBJS)'"'
	@echo VRLLIB_OBJS='"'$(VRLLIB_OBJS)'"'
	@echo SC_LIBS='"'$(SC_LIBS)'"'
	@echo ASTEST_SRCS='"'$(ASTEST_SRCS)'"'
	@echo ASTEST_OBJS='"'$(ASTEST_OBJS)'"'
	@echo ASTEST_DISS='"'$(ASTEST_DISS)'"'
