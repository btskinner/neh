# ==============================================================================
#
# [ PROJ ] NEH
# [ FILE ] makefile
# [ AUTH ] Benjamin Skinner (GitHub: @btskinner)
# [ INIT ] 16 September 2023
#
# ==============================================================================

# --- directories --------------------------------

DAT_DIR := data
FIG_DIR := figures
SCR_DIR := scripts

# --- variables ----------------------------------

# data vars
analysis_data := $(DAT_DIR)/clean/analysis.csv

# output vars
fig_output := $(FIG_DIR)/US.png

# --- build targets ------------------------------

all: data analysis

data: $(analysis_data)
analysis: $(fig_output)
.PHONY: all data analysis

# --- make data ----------------------------------

$(analysis_data): $(SCR_DIR)/make_data.R
	@echo "Creating analysis data"
	Rscript $< .

# --- analysis -----------------------------------

$(fig_output): $(SCR_DIR)/analyze.R $(analysis_data)
	@echo "Running analyses"
	Rscript $< .

# ------------------------------------------------------------------------------
# end makefile
# ==============================================================================
