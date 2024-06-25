`timescale 1ns / 100ps

module tb;

  // Clock signal
  parameter CLK_PERIOD = 10ns;
  logic clk = 0;
  always #(CLK_PERIOD / 2) clk = ~clk;

  // Interface
  i2c_if vif(clk);

  // Test
  test top_test(vif);
  //pullup(vif.scl);
  //pullup(vif.sda);

  // Instantiation
  i2c_master dut (
    .clk(vif.clk),
    .rst(vif.rst),
    .din(vif.din),
    .dvsr(vif.dvsr),
    .cmd(vif.cmd),
    .wr_i2c(vif.wr_i2c),
    .scl(vif.scl),
    .sda(vif.sda),
    .ready(vif.ready),
    .done_tick(vif.done_tick),
    .ack(vif.ack),
    .dout(vif.dout)
  );

  initial begin
    $timeformat(-9, 0, "ns", 10);
  end

endmodule : tb
