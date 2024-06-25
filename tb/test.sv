module test (i2c_if.dvr vif);

  localparam Divisor = 10'd20;
  localparam START_CMD   = 3'b000;
  localparam WR_CMD      = 3'b001;
  localparam RD_CMD      = 3'b010;
  localparam STOP_CMD    = 3'b011;
  localparam RESTART_CMD = 3'b100;
   
  initial begin
    $display("Begin Of Simulation.");
    reset();
    start();
    write(8'd11);
    write(8'd12);
    stop();
    start();
    restart();
    $display("End Of Simulation.");
    $finish;
  end

  task reset();
    vif.rst  = 1'b1;            // Assert async reset
    vif.dvsr = Divisor;         // 20 clock cycles
    vif.cb.din    <= 8'd10;     // Default din value
    vif.cb.cmd    <= START_CMD;  
    vif.cb.wr_i2c <= 1'b0;      // Default wr
    repeat(2) @(vif.cb);
    vif.cb.rst    <= 1'b0;      // Deassert reset
    repeat ((Divisor+1)*4) @(vif.cb);
  endtask : reset

  task start();
    vif.cb.cmd    <= START_CMD;  
    vif.cb.wr_i2c <= 1'b1;        // Start write
    @(vif.cb);
    vif.cb.wr_i2c <= 1'b0;        // Deassert
    wait(vif.cb.ready != 0);
    @(vif.cb iff( vif.cb.ready == 1 ) );
    @(vif.cb);
  endtask : start

  task write(input logic [7:0] value);
    vif.cb.din    <= value;    // Default din value
    vif.cb.cmd    <= WR_CMD;
    vif.cb.wr_i2c <= 1'b1;     // Start write
    @(vif.cb);
    vif.cb.wr_i2c <= 1'b0;     // Deassert
    wait(vif.cb.ready != 0);
    @(vif.cb iff( vif.cb.ready == 1 ) );
    @(vif.cb);
  endtask : write
  
  task stop();
    vif.cb.cmd    <= STOP_CMD;
    vif.cb.wr_i2c <= 1'b1;     // Start write
    @(vif.cb);
    vif.cb.wr_i2c <= 1'b0;     // Deassert
    wait(vif.cb.ready != 0);
    @(vif.cb iff( vif.cb.ready == 1 ) );
    @(vif.cb);
  endtask : stop
  
  task restart();
    vif.cb.cmd    <= RESTART_CMD;
    vif.cb.wr_i2c <= 1'b1;     // Start write
    @(vif.cb);
    vif.cb.wr_i2c <= 1'b0;     // Deassert
    wait(vif.cb.ready != 0);
    @(vif.cb iff( vif.cb.ready == 1 ) );
    @(vif.cb);
  endtask : restart
  
endmodule : test
