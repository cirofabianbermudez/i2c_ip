interface i2c_if(
  input logic clk_i
);

  logic        rst_i;
  logic [ 7:0] din_i;
  logic [15:0] dvsr_i;
  logic [ 2:0] cmd_i;
  logic        wr_i2c_i;
  wire         scl_io;
  wire         sda_io;
  logic        ready_o;
  logic        done_tick_o;
  logic        ack_o;
  logic [ 7:0] dout_o;

  // https://prbs23.com/blog/posts/drive-strength-detection-in-system-verilog/
  assign (pull1, highz0) scl_io = 1'b1;
  assign (pull1, highz0) sda_io = 1'b1;

  clocking cb @(posedge clk_i);
    default input #1ns output #5ns;
    output rst_i;
    output din_i;
    output dvsr_i;
    output cmd_i;
    output wr_i2c_i;
    inout  scl_io;
    inout  sda_io;
    input  ready_o;
    input  done_tick_o;
    input  ack_o;
    input  dout_o;
  endclocking : cb

  modport dvr (clocking cb, output rst_i, output dvsr_i);

endinterface : i2c_if

