///////////////////////////////////////////////////////////////////////////////////
// [Filename]       i2c_master.sv
// [Project]        i2c_ip
// [Author]         Ciro Bermudez
// [Language]       SystemVerilog 2017 [IEEE Std. 1800-2017]
// [Created]        2024.06.22
// [Description]    Module I2C master
// [Notes]          
// [Status]         Draft -> Under Development -> Testing
///////////////////////////////////////////////////////////////////////////////////

module i2c_master (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [ 7:0] din_i,
    input  logic [15:0] dvsr_i,
    input  logic [ 2:0] cmd_i,
    input  logic        wr_i2c_i,
    inout  tri          scl_io,       // serial data
    inout  tri          sda_io,       // serial clock
    output logic        ready_o,
    output logic        done_tick_o,
    output logic        ack_o,
    output logic [ 7:0] dout_o
);

  localparam START_CMD = 3'b000;
  localparam WR_CMD = 3'b001;
  localparam RD_CMD = 3'b010;
  localparam STOP_CMD = 3'b011;
  localparam RESTART_CMD = 3'b100;

  typedef enum {
    Idle, Hold, Start1, Start2, Data1, Data2, Data3, Data4, DataEnd,
    Restart, Stop1, Stop2
  } state_type_e;

  state_type_e state_reg, state_next;
  logic [15:0] tick_counter_q, tick_counter_d;       // Counter for I2C frequency
  logic [15:0] qutr, half;                           // qutr, half: Constants to detect 1/4 and 1/2 of I2C frequency
  logic [8:0] tx_shift_buffer_q, tx_shift_buffer_d;  // TX shift register, LSB is the ACK bit
  logic [8:0] rx_shift_buffer_q, rx_shift_buffer_d;  // RX shift register, LSB is the ACK bit
  logic [2:0] cmd_reg_q, cmd_reg_d;                  // Store the current command
  logic [3:0] data_counter_q, data_counter_d;        // Keep track of the number of bits processed
  logic sda_temp_q, sda_temp_d;                      // FSM variable SDA, register SDA
  logic scl_temp_q, scl_temp_d;                      // FSM variable SCL, register SCL
  logic data_phase;                                  // FSM variable to check if in state Data1, Data2, Data3, or Data4
  logic done_tick;                                   // FSM varible asserted for one cycle post controller completion
  logic ready;                                       // FSM variable indicates if state is Idle and Hold
  logic into;                                        // Detect if the data flows into the controller
  logic nack;                                        // LSB of din_i acknowledge bit

  always_ff @(posedge clk_i, posedge rst_i) begin
    if (rst_i) begin
      sda_temp_d <= 1'b1;
      scl_temp_d <= 1'b1;
    end else begin
      sda_temp_d <= sda_temp_q;
      scl_temp_d <= scl_temp_q;
    end
  end

  assign scl_io = (scl_temp_d) ? 1'bz : 1'b0;
  assign into = (data_phase && cmd_reg_q == RD_CMD && data_counter_q < 8) || 
                (data_phase && cmd_reg_q == WR_CMD && data_counter_q == 8);

  assign sda_io = (into || sda_temp_d) ? 1'bz : 1'b0;
  assign dout_o = rx_shift_buffer_q[8:1];
  assign ack_o = rx_shift_buffer_q[0];
  assign nack = din_i[0];

  always_ff @(posedge clk_i, posedge rst_i) begin
    if (rst_i) begin
      state_reg         <= Idle;
      tick_counter_q    <= 'd0;
      data_counter_q    <= 'd0;
      cmd_reg_q         <= 'd0;
      tx_shift_buffer_q <= 'd0;
      rx_shift_buffer_q <= 'd0;
    end else begin
      state_reg         <= state_next;
      tick_counter_q    <= tick_counter_d;
      data_counter_q    <= data_counter_d;
      cmd_reg_q         <= cmd_reg_d;
      tx_shift_buffer_q <= tx_shift_buffer_d;
      rx_shift_buffer_q <= rx_shift_buffer_d;
    end
  end

  assign qutr = dvsr_i;
  assign half = {qutr[14:0], 1'b0};

  always_comb begin
    state_next        = state_reg;
    tick_counter_d    = tick_counter_q + 'd1;
    data_counter_d    = data_counter_q;
    tx_shift_buffer_d = tx_shift_buffer_q;
    rx_shift_buffer_d = rx_shift_buffer_q;
    cmd_reg_d         = cmd_reg_q;
    scl_temp_q        = 1'b1;
    sda_temp_q        = 1'b1;
    data_phase        = 1'b0;
    done_tick         = 1'b0;
    ready             = 1'b0;
    case (state_reg)
      Idle: begin
        ready = 1'b1;
        if (wr_i2c_i && cmd_i == START_CMD) begin
          state_next     = Start1;
          tick_counter_d = 'd0;
        end
      end
      Start1: begin
        sda_temp_q = 1'b0;
        if (tick_counter_q == half) begin
          tick_counter_d = 'd0;
          state_next     = Start2;
        end
      end
      Start2: begin
        sda_temp_q = 1'b0;
        scl_temp_q = 1'b0;
        if (tick_counter_q == half) begin
          tick_counter_d = 'd0;
          state_next     = Hold;
        end
      end
      Hold: begin
        ready      = 1'b1;
        sda_temp_q = 1'b0;
        scl_temp_q = 1'b0;
        if (wr_i2c_i) begin
          cmd_reg_d      = cmd_i;
          tick_counter_d = 'd0;
          case (cmd_i)
            RESTART_CMD, START_CMD: begin
              state_next = Restart;
            end
            STOP_CMD: begin
              state_next = Stop1;
            end
            default: begin
              data_counter_d    = 'd0;
              state_next        = Data1;
              tx_shift_buffer_d = {din_i, nack};
            end
          endcase
        end
      end
      Data1: begin
        sda_temp_q = tx_shift_buffer_q[8];
        scl_temp_q = 1'b0;
        data_phase = 1'b1;
        if (tick_counter_q == qutr) begin
          tick_counter_d = 'd0;
          state_next     = Data2;
        end
      end
      Data2: begin
        sda_temp_q = tx_shift_buffer_q[8];
        data_phase = 1'b1;
        if (tick_counter_q == qutr) begin
          tick_counter_d    = 'd0;
          state_next        = Data3;
          rx_shift_buffer_d = {rx_shift_buffer_q[7:0], sda_io};
        end
      end
      Data3: begin
        sda_temp_q = tx_shift_buffer_q[8];
        data_phase = 1'b1;
        if (tick_counter_q == qutr) begin
          tick_counter_d = 'd0;
          state_next     = Data4;
        end
      end
      Data4: begin
        sda_temp_q = tx_shift_buffer_q[8];
        scl_temp_q = 1'b0;
        data_phase = 1'b1;
        if (tick_counter_q == qutr) begin
          tick_counter_d = 0;
          if (data_counter_q == 8) begin
            state_next = DataEnd;
            done_tick  = 1'b1;
          end else begin
            tx_shift_buffer_d = {tx_shift_buffer_q[7:0], 1'b0};
            data_counter_d    = data_counter_q + 1;
            state_next        = Data1;
          end
        end
      end
      DataEnd: begin
        sda_temp_q = 1'b0;
        scl_temp_q = 1'b0;
        if (tick_counter_q == qutr) begin
          tick_counter_d = 'd0;
          state_next     = Hold;
        end
      end
      Restart: begin
        if (tick_counter_q == half) begin
          tick_counter_d = 'd0;
          state_next     = Start1;
        end
      end
      Stop1: begin
        sda_temp_q = 1'b0;
        if (tick_counter_q == half) begin
          tick_counter_d = 'd0;
          state_next     = Stop2;
        end
      end
      Stop2: begin
        if (tick_counter_q == half) begin
          state_next = Idle;
        end
      end
      default: begin
        if (tick_counter_q == half) begin
          state_next = Idle;
        end
      end
    endcase
  end

  assign done_tick_o = done_tick;
  assign ready_o = ready;

endmodule

