
SRCS = tb/tb.sv

all: format

format:
	verible-verilog-format --inplace $(SRCS)
