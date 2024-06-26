`timescale 1ns / 100ps

module tb;

  // Clock signal
  parameter CLK_PERIOD = 10ns;
  logic clk_i = 0;
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  // Interface
  i2c_if vif (clk_i);

  // Test
  test top_test (vif);
  //pullup(vif.scl);
  //pullup(vif.sda);

  // Instantiation
  i2c_master dut (
      .clk_i(vif.clk_i),
      .rst_i(vif.rst_i),
      .din_i(vif.din_i),
      .dvsr_i(vif.dvsr_i),
      .cmd_i(vif.cmd_i),
      .wr_i2c_i(vif.wr_i2c_i),
      .scl_io(vif.scl_io),
      .sda_io(vif.sda_io),
      .ready_o(vif.ready_o),
      .done_tick_o(vif.done_tick_o),
      .ack_o(vif.ack_o),
      .dout_o(vif.dout_o)
  );

  initial begin
    $timeformat(-9, 0, "ns", 10);
  end

endmodule : tb
