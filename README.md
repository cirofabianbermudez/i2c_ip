# i2c_ip
I2C ip FPGA verilog/systemverilog

# I2C UVC

## Introduction


## Specification

This is the specification of the RTL

- `clk`: is the clock signal.
- `rst`: the reset is asynchronous active high.

- `sda`: is the serial data port, is defined as an input / output port.
- `scl`: is the serial clk, is defined as an input / output port.

**Inputs**

- `din`: is a 8 bit port for the input data. In write operation, it is the data byte to be transmitted. In the read operation, the LSB `din[0]` is the acknowledge bit to be transmitted by the I2C master.
- `dvsr`: is a 16 bit port, it is the clock divisor to obtain a quarters of an I2C clock period and should be equal to the frequency of the system divided by four times the I2C frequency.
- `cmd`: is a 3 bit port that specifies the desired action, which can be start (`000`), write (`001`), read (`010`), stop (`011`), or restart (`100`).
- `wr_i2c`: is a 1 bit port, is a control signal that writes the data and command into the registers and starts the action.

**Outputs**

- `dout`: is a 8 bit port, is the received data byte from a read operation.
- `ack`: is a 1 bit port, is the received acknowledge bit from a write operation, and it should be 0.
- `ready`: 1 bit port, indicates that the controller is idle and ready to take a new command.
- `done_tick`: 1 bit port, is asserted for one click cycle after the controller completes processing nine bits in a read or write action.


### Start condition

- In the idle state SDA and SCL are both high
- The **start condition** occurs when a node:
    - First pulls SDA low
    = Then pulls SCL low
- This "claims the bus"
    - Node is now the master
    - Prevents any other nodes from taking control of the bus
    - Reduces the risk of contention
- Master that has sized the bus also starts the clock

### Slave address

- Each I2C node on a bus must have a unique, fixed address
    - Normally 7 bits long, MSB first
    - 10 bit addresses also supported, but these are uncommon
- Address may be (partially) configurable via external address lines or jumpers

### Aside: timing relationship between SDA and SCL

- SDA does not change between clock rising edge and clock falling edge
- Data is alwaus read during the middle of the clock pulse
- During data transmission, SDA only transitions while SCL is low
    - An SDA transiton when SCL is high, indicates a start or stop condition

### Read / Write bit

- Read / Write bit follows the slave address
- Set bu master to indicate desired operation
    - `0` means master wants to write data to slave
    - `1` master wants to read data from slave
- Often interpreted and/or decoded as part of the address byte

### Acknowledge bit

- Sent by the receiver of a byte of data
    - `0` means acknowledge (ACK)
    - `1` means negative acknowledge (NACK)
- Recall the I2C is idle high
    - Lack of response is equal to NACK
- Used after slave address and each data byte
- ACK after data byte(s) confirms receipt of data
- ACK after slave address confirms that 
    - A slave with that address is on the bus
    - The slave is ready to read / write data (depending on R/W bit)


### Data byte(s)

- Data byte contains the information being transferred between master and slave
    - Memory or register contents, addresses, etc.
- Always 8 bit long. MSB first
- Always followed bu an acknowledgment bit
    - Set to zero by the receiver if data has been received properly

### Multiple data bytes

- In many cases, multiple data bytes are sent in one I2C frame
    - Each data byte is followed by an ACK bit
- Bytes may be all "data" or some may represent an internal address, etc
    - Ex: first byte is a register location and second byte is the data to be written to that register

### Stop condition

- Stop condition indicates the end of data bytes
    - First, SCL returns (and remains) high
    - Then, SDA returns (and remains) high
- Recall that for data bytes, SDA only transitions when clock is low
    - SDA transition when SCL high unambiguously indicates the stop condition.
- Bus becomes idle
    - No clock signal
    - Any node can now use the start condition to claim the bus and begin a new communication

### About open drain

- Each line (SDA and SCL) is connected to voltage via a "pull up" resistor
    - One resistor per line (not per device)
- Each I2C device contains logic that can open and close a drain
- When drains is "closed", the line is pulled low (connected to ground)
- When drain in "open", the line is pulled high (connected to voltage)
- I2C lines are high in the idle state
    - Sometimes called an "open drain" system

### Pull up resistor values

- Pulling down a line is usually much faster that pulling up a line
    - Pull-up time is a function of bus capacitance and values of pull-up resistors
- Values of pull up resistors are a compromise
    - Higher resistances increase the time needed to pull up the line and this limit bus speed
    - Lower resistances allow faster communications, but require higher power
- Typical pull-up resistor values are in the range of 1k - 10k


### Modes / Speeds

- I2C can operate at different bus speeds
    -   Referred to as "modes"
- Table shows max speeds for each mode

| I2C Mode        | Speed    |
| --------------- | -------- |
| Standard Mode   | 100 kbps |
| Fast Mode       | 400 kbps |
| Fast Mode Plus  | 1 Mbps   |
| High Speed Mode | 3.4 Mbps |
| Ultra Fast Mode | 5 Mbps   |








## References

- [1] "Wayback Machine." Accessed: Jun. 20, 2024. [Online]. Available: <https://web.archive.org/web/20210426060837/https://www.nxp.com/docs/en/user-guide/UM10204.pdf>

- [2] "I2C Master Mode." Accessed: Jun. 20, 2024. [Online]. Available: <https://onlinedocs.microchip.com/pr/GUID-04DAA7D3-9FC2-45F2-B757-157190106490-en-US-2/index.html?GUID-F595810F-000E-485E-8198-456CE81C6107>

- [3] Understanding I2C, (Apr. 18, 2023). Accessed: Jun. 20, 2024. [Online Video]. Available: <https://www.youtube.com/watch?v=CAvawEcxoPU>







FPGA Period = 10 ns
dvsr = 20

then from 0 to 20 is 21 clock cycles
21 * 10 ns = 210 ns
because this is repeated 4 times
210 ns * 4 = 840 ns


half = dvrs * 2 = 40
then from 0 to 40 is 41 clock cycles
41 * 10 ns = 410 ns
because this is repeated 2 times
410 ns * 2 = 820 ns



=========================================
=========================================
=========================================

FPGA Period = 10 ns
dvsr = 19

then from 0 to 19 is 20 clock cycles
20 * 10 ns = 200 ns
because this is repeated 4 times
200 ns * 4 = 800 ns


half = (dvrs * 2) + 1 = 39
then from 0 to 39 is 40 clock cycles
40 * 10 ns = 400 ns
because this is repeated 2 times
400 ns * 2 = 800 ns