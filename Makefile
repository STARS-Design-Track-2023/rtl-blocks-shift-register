###########################################################################################
# STARS 2023 General Makefile
# 
# Set tab spacing to 2 spaces per tab for best viewing results
###########################################################################################

##############################################################################
# VARIABLES
##############################################################################

# Source

# Specify the name of the top level file (do not include the source folder in the name)
# NOTE: YOU WILL NEED TO SET THIS VARIABLE'S VALUE WHEN WORKING WITH HEIRARCHICAL DESIGNS
TOP_FILE         := 

# List internal component/block files here (separate the filenames with spaces)
# NOTE: YOU WILL NEED TO SET THIS VARIABLE'S VALUE WHEN WORKING WITH HEIRARCHICAL DESIGNS
COMPONENT_FILES  := 

# Specify the filepath of the test bench you want to use (ie. tb_top_level.sv)
# (do not include the source folder in the name)
TB               := tb_$(TOP_FILE)

# Get the top level design and test_bench module names
TB_MODULE		 := $(notdir $(basename $(TB)))
TOP_MODULE	     := $(notdir $(basename $(TOP_FILE)))

# Simulation

# Directries where the source and mapped code is located
SRC              := source
MAP              := mapped

# Simulation Targerts
BUILD            := sim_build
SIM_SOURCE       := sim_source

SIM_MAPPED       := sim_mapped
DUMP             := dump

# Compiler
VC               := iverilog
CFLAGS           := -g2012 -v

# Design Compiler
DC               := yosys

# Cell libraries
ICETIME          := timing/cells_map_timing.v timing/cells_sim_timing.v

##############################################################################
# RULES
##############################################################################


##############################################################################
# Administrative Targets
##############################################################################

###########################################################################################
# Make the default target (the one called when no specific one is invoked) to
# output the proper usage of this makefile
###########################################################################################
help:
	@echo "----------------------------------------------------------------"
	@echo "|                       Makefile Targets                       |"
	@echo "----------------------------------------------------------------"
	@echo "Administrative targets:"
	@echo "  all           - compiles the source version of a full"
	@echo "                  design including its top level test bench"
	@echo "  help          - makefile targets explanation"
	@echo "  clean         - removes the temporary files"
	@echo "  print_vars    - prints the contents of the variables"
	@echo
	@echo "Compilation targets:"
	@echo "  source       - compiles the source version of a full"
	@echo "                 design including its top level test bench"
	@echo "  mapped       - compiles and synthesizes the mapped version"
	@echo "                 of a full design including its top level" 
	@echo "                 test bench"
	@echo
	@echo "Simulation targets:"
	@echo "  sim_source   - compiles and simulates the source version"
	@echo "                 of a full design including its top level"
	@echo "                 test bench"
	@echo "  sim_mapped   - compiles and simulates the mapped version"
	@echo "                 of a full design including its top level"
	@echo "                 test bench"
	@echo 
	@echo "Miscellaneous targets:"
	@echo "  lint         - checks syntax for source files with the"
	@echo "                 Verilator linter"
	@echo "  verify       - view traces with gtkwave"
	@echo "  view         - view the gate level circuit"
	@echo "----------------------------------------------------------------"

all: $(SIM_SOURCE)

clean:
	@echo "Removing temporary files, build files and log files"
	@rm -rf $(BUILD)/* 
	@rm -rf $(MAP)/*
	@rm -f *.log
	@rm -f *.show
	@echo "Done\n\n"

print_vars:
	@echo "Component Files: \n $(foreach file, $(COMPONENT_FILES), $(file)\n)"
	@echo "Top level File: $(TOP_FILE)"
	@echo "Testbench: $(TB)"
	@echo "Top level module: $(TOP_MODULE)"
	@echo "Testbench module: $(TB_MODULE)"
	@echo "Gate Library: '$(ICETIME)'"
	@echo "Source work library: '$(SRC)'"
	@echo "Mapped work library: '$(MAP)'"


##############################################################################
# Compilation Targets
##############################################################################

# Define a pattern rule to automatically compile updated source files for a design
$(SRC): $(addprefix $(SRC)/, $(TOP_FILE) $(COMPONENT_FILES) $(TB))
	@echo "----------------------------------------------------------------"
	@echo "Creating executable for source compilation ....."
	@echo "----------------------------------------------------------------\n\n"
	@mkdir -p ./$(BUILD)
	@$(VC) $(CFLAGS) -o $(BUILD)/$(SIM_SOURCE).vvp $^
	@echo "\n\n"
	@echo "Compilation complete\n\n"

$(MAP): $(addprefix $(SRC)/, $(TOP_FILE) $(COMPONENT_FILES) $(TB))
	@echo "----------------------------------------------------------------"
	@echo "Creating executable for mapped compilation ....."
	@echo "----------------------------------------------------------------\n\n"
	@mkdir -p ./$(MAP)
	@mkdir -p ./$(BUILD)
	@touch -c $(TOP).log
	@$(DC) -p 'read_verilog -sv -noblackbox $(addprefix $(SRC)/, $(TOP_FILE) $(COMPONENT_FILES)); synth_ice40 -top $(TOP_MODULE); write_verilog $@/$(TOP_MODULE).v' > $(TOP_MODULE).log
	@echo "Synthesis complete .....\n\n"
	@$(VC) $(CFLAGS) -o $(BUILD)/$(SIM_MAPPED).vvp $@/$(TOP_MODULE).v $(SRC)/$(TB) $(ICETIME)
	@echo "\n\n"
	@echo "Compilation complete\n\n"


##############################################################################
# Simulation Targets
##############################################################################

# This rule defines how to simulate the source form of the full design
$(SIM_SOURCE): $(SRC)
	@echo "----------------------------------------------------------------"
	@echo "Simulating source ....."
	@echo "----------------------------------------------------------------\n\n"
	@vvp -s $(BUILD)/$@.vvp
	@echo "\n\n"

# This rule defines how to simulate the mapped form of the full design
$(SIM_MAPPED): $(MAP)
	@echo "----------------------------------------------------------------"
	@echo "Simulating mapped ....."
	@echo "----------------------------------------------------------------\n\n"
	@vvp -s $(BUILD)/$@.vvp
	@echo "\n\n"


##############################################################################
# Miscellaneous Targets
##############################################################################

# Define a pattern rule to lint source code with verilator
lint: $(addprefix $(SRC)/, $(TOP_FILE) $(COMPONENT_FILES) $(TB))
	@echo "----------------------------------------------------------------"
	@echo "Checking Syntax ....."
	@echo "----------------------------------------------------------------\n\n"
	@verilator --lint-only --timing -Wno-MULTITOP -Wno-TIMESCALEMOD $^
	@echo "\n\n"
	@echo "Done linting"

verify: $(BUILD)/$(DUMP).vcd 
	@open -a gtkwave $^

view: $(addprefix $(SRC)/, $(TOP_FILE) $(COMPONENT_FILES))
	@echo "----------------------------------------------------------------"
	@echo "Making Gate Level Schematic ....."
	@echo "----------------------------------------------------------------\n\n"
	@$(DC) -p 'read_verilog -sv $^; hierarchy -check -top $(TOP_MODULE); proc; opt; fsm; opt; memory; opt; techmap; opt; show' > log_mapping.show
	@echo "Done creating Schematic"	

###########################################################################################
# Designate targets that do not correspond directly to files so that they are
# run every time they are called
###########################################################################################
.PHONY: all help clean print_vars
.PHONY: $(SRC) $(MAP)
.PHONY: $(SIM_SOURCE) $(SIM_MAPPED)
.PHONY: lint verify
