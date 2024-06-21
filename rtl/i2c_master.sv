
module i2c_master (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] din,
    input  logic [15:0] dvsr,
    input  logic [ 2:0] cmd,
    input  logic        wr_i2c,
    inout  tri          scl,        // serial data
    inout  tri          sda,        // serial clock
    output logic        ready,
    output logic        done_tick,
    output logic        ack,
    output logic [ 7:0] dout
);

  localparam START_CMD   = 3'b000;
  localparam WR_CMD      = 3'b001;
  localparam RD_CMD      = 3'b010;
  localparam STOP_CMD    = 3'b011;
  localparam RESTART_CMD = 3'b100;

  typedef enum {
    idle, hold, start1, start2, data1, data2, data3, data4,
    data_end, restart, stop1, stop2
  } state_type;

  state_type state_reg, state_next;
  logic [15:0] c_reg, c_next;           // Counter for I2C frequency
  logic [15:0] qutr, half;              // qutr, half: Constants to detect 1/4 and 1/2 of I2C frequency
  logic [8:0] tx_reg, tx_next;          // TX shift register, LSB is the ACK bit
  logic [8:0] rx_reg, rx_next;          // RX shift register, LSB is the ACK bit
  logic [2:0] cmd_reg, cmd_next;        // Store the current command
  logic [3:0] bit_reg, bit_next;        // Keep track of the number of bits processed
  logic sda_out, sda_reg;               // FSM variable SDA, register SDA
  logic scl_out, scl_reg;               // FSM variable SCL, register SCL
  logic data_phase;                     // FSM variable to check if in state data1, data2, data3, or data4
  logic done_tick_i;                    // FSM varible asserted for one cycle post controller completion
  logic ready_i;                        // FSM variable indicates if state is idle and hold
  logic into;                           // Detect if the data flows into the controller
  logic nack;                           // LSB of din acknowledge bit

  // Output control logic
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      sda_reg <= 1'b1;
      scl_reg <= 1'b1;
    end else begin
      sda_reg <= sda_out;
      scl_reg <= scl_out;
    end
  end

  assign scl = (scl_reg) ? 1'bz : 1'b0;
  assign into = (data_phase && cmd_reg == RD_CMD && bit_reg < 8) || 
                (data_phase && cmd_reg == WR_CMD && bit_reg == 8);

  assign sda = (into || sda_reg) ? 1'bz : 1'b0;
  assign dout = rx_reg[8:1];
  assign ack = rx_reg[0];
  assign nack = din[0];

  // Registers
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      state_reg <= idle;
      c_reg <= 0;
      bit_reg <= 0;
      cmd_reg <= 0;
      tx_reg <= 0;
      rx_reg <= 0;
    end else begin
      state_reg <= state_next;
      c_reg <= c_next;
      bit_reg <= bit_next;
      cmd_reg <= cmd_next;
      tx_reg <= tx_next;
      rx_reg <= rx_next;
    end
  end

  assign qutr = dvsr;
  assign half = {qutr[14:0], 1'b0};

  // Next-state logic
  always_comb begin
    state_next = state_reg;
    c_next = c_reg + 1;
    bit_next = bit_reg;
    tx_next = tx_reg;
    rx_next = rx_reg;
    cmd_next = cmd_reg;
    done_tick_i = 1'b0;
    ready_i = 1'b0;
    scl_out = 1'b1;
    sda_out = 1'b1;
    data_phase = 1'b0;
    case (state_reg)
      idle: begin
        ready_i = 1'b1;
        if (wr_i2c && cmd == START_CMD) begin
          state_next = start1;
          c_next = 0;
        end
      end
      start1: begin
        sda_out = 1'b0;
        if (c_reg == half) begin
          c_next = 0;
          state_next = start2;
        end
      end
      start2: begin
        sda_out = 1'b0;
        scl_out = 1'b0;
        if (c_reg == half) begin
          c_next = 0;
          state_next = hold;
        end
      end
      hold: begin
        ready_i = 1'b1;
        sda_out = 1'b0;
        scl_out = 1'b0;
        if (wr_i2c) begin
          cmd_next = cmd;
          c_next   = 0;
          case (cmd)
            RESTART_CMD, START_CMD: begin
              state_next = restart;
            end
            STOP_CMD: begin
              state_next = stop1;
            end
            default: begin
              bit_next = 0;
              state_next = data1;
              tx_next = {din, nack};
            end
          endcase
        end
      end
      data1: begin
        sda_out = tx_reg[8];
        scl_out = 1'b0;
        data_phase = 1'b1;
        if (c_reg == qutr) begin
          c_next = 0;
          state_next = data2;
        end
      end
      data2: begin
        sda_out = tx_reg[8];
        data_phase = 1'b1;
        if (c_reg == qutr) begin
          c_next = 0;
          state_next = data3;
          rx_next = {rx_reg[7:0], sda};
        end
      end
      data3: begin
        sda_out = tx_reg[8];
        data_phase = 1'b1;
        if (c_reg == qutr) begin
          c_next = 0;
          state_next = data4;
        end
      end
      data4: begin
        sda_out = tx_reg[8];
        scl_out = 1'b0;
        data_phase = 1'b1;
        if (c_reg == qutr) begin
          c_next = 0;
          if (bit_reg == 8) begin
            state_next = data_end;
            done_tick_i = 1'b1;
          end else begin
            tx_next = {tx_reg[7:0], 1'b0};
            bit_next = bit_reg + 1;
            state_next = data1;
          end
        end
      end
      data_end: begin
        sda_out = 1'b0;
        scl_out = 1'b0;
        if (c_reg == qutr) begin
          c_next = 0;
          state_next = hold;
        end
      end
      restart: begin
        if (c_reg == half) begin
          c_next = 0;
          state_next = start1;
        end
      end
      stop1: begin
        sda_out = 1'b0;
        if (c_reg == half) begin
          c_next = 0;
          state_next = stop2;
        end
      end
      default: begin // stop2
        if (c_reg == half) begin
          state_next = idle;
        end
      end
    endcase
  end

  assign done_tick = done_tick_i;
  assign ready = ready_i;

endmodule

