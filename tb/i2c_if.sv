interface i2c_if(
  input logic clk
);

  logic        rst;
  logic [ 7:0] din;
  logic [15:0] dvsr;
  logic [ 2:0] cmd;
  logic        wr_i2c;
  wire          scl;
  wire          sda;
  logic        ready;
  logic        done_tick;
  logic        ack;
  logic [ 7:0] dout;

  clocking cb @(posedge clk);
    default input #1ns output #1ns;
    output rst;
    output din;
    output dvsr;
    output cmd;
    output wr_i2c;
    inout  scl;
    inout  sda;
    input  ready;
    input  done_tick;
    input  ack;
    input  dout;
  endclocking : cb

  modport dvr (clocking cb, output rst, output dvsr);

endinterface : i2c_if

