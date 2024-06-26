
SRCS = rtl/i2c_master.sv \
			 tb/tb.sv \
			 tb/test.sv

all: format

format:
	verible-verilog-format --inplace $(SRCS)
