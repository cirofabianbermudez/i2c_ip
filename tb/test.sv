module test (i2c_if.dvr vif);

  localparam Divisor = 10'd20;
  localparam START_CMD   = 3'b000;
  localparam WR_CMD      = 3'b001;
  localparam RD_CMD      = 3'b010;
  localparam STOP_CMD    = 3'b011;
  localparam RESTART_CMD = 3'b100;
   
  initial begin
    $display("Begin Of Simulation.");
    fork
      begin
        reset();
        start();
        write(8'hfa);
        write(8'd12);
        stop();
        start();
        write(8'hfa);
        restart();
        write(8'd21);
        write(8'd22);
        stop();
      end
      begin
        check_start();
      end
    join
   
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
  
  task check_start();
    forever begin

        // negedge SDA
        wait(vif.cb.sda != 0);
        @(vif.cb iff( vif.cb.sda == 0 ) );
        $display("[INFO] %4t: negedge SDA", $realtime);

        if (vif.cb.scl == 0) begin
          continue;
        end

        // negedge SCL
        wait(vif.cb.scl != 0);
        @(vif.cb iff( vif.cb.scl == 0) );
        $display("[INFO] %4t: negedge SCL", $realtime);
        
        if (vif.cb.scl == 1'b0 &&  vif.cb.scl == 1'b0) begin
          $display("[INFO] %4t: START CONDITION detected", $realtime);
        end else begin
          continue;
        end

        forever begin
          // posedge SCL
          wait(vif.cb.scl != 1);
          @(vif.cb iff( vif.cb.scl == 1) );
          $display("[INFO] %4t: posedge SCL", $realtime);

          if (vif.cb.sda == 1) begin
            continue;
          end

          // posedge SDA
          wait(vif.cb.sda != 1);
          @(vif.cb iff( vif.cb.sda == 1 ) );
          $display("[INFO] %4t: posedge SDA", $realtime);

          if (vif.cb.scl == 1'b1 &&  vif.cb.scl == 1'b1) begin
            $display("[INFO] %4t: STOP CONDITION detected", $realtime);
            break;
          end else begin
            continue;
          end

        end

        
    end
  endtask : check_start
  
endmodule : test
