//==============================================================
// i2c_byte_ctrl.v
// Byte layer of the master. Drives i2c_bit_ctrl to perform one
// complete single-byte transaction:
//
//   START -> 7-bit ADDR + R/W -> ADDR_ACK
//     write : 8-bit DATA -> DATA_ACK -> STOP
//     read  : 8-bit DATA -> master drives NACK -> STOP
//
// (Single-byte transfers only in this version - extend with a
//  repeated-START / multi-byte burst state if needed later.)
//==============================================================
module i2c_byte_ctrl (
    input  wire        clk,
    input  wire        rst_n,

    // simple command interface from master_top
    input  wire        start_xfer,     // 1-cycle pulse: begin transaction
    input  wire [6:0]  slave_addr,
    input  wire        rw,             // 0 = write, 1 = read
    input  wire [7:0]  wdata,
    output reg  [7:0]  rdata,
    output reg         addr_ack_err,   // 1 = slave did not ACK address
    output reg         data_ack_err,   // 1 = slave did not ACK write data
    output reg         busy,
    output reg         done,           // 1-cycle pulse when transaction completes

    // i2c_bit_ctrl interface
    output reg         bc_cmd_start,
    output reg         bc_cmd_stop,
    output reg         bc_cmd_write,
    output reg         bc_cmd_read,
    output reg         bc_data_in,
    input  wire        bc_data_out,
    input  wire        bc_cmd_done
);

    localparam S_IDLE           = 4'd0;
    localparam S_START          = 4'd1;
    localparam S_ADDR_WAIT      = 4'd2;
    localparam S_ADDR_ACK       = 4'd3;
    localparam S_ADDR_ACK_WAIT  = 4'd4;
    localparam S_WDATA_WAIT     = 4'd5;
    localparam S_WDATA_ACK      = 4'd6;
    localparam S_WDATA_ACK_WAIT = 4'd7;
    localparam S_RDATA_WAIT     = 4'd8;
    localparam S_RACK           = 4'd9;
    localparam S_RACK_WAIT      = 4'd10;
    localparam S_STOP_WAIT      = 4'd11;

    reg [3:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shreg;
    reg       rw_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            busy         <= 1'b0;
            done         <= 1'b0;
            addr_ack_err <= 1'b0;
            data_ack_err <= 1'b0;
            bc_cmd_start <= 1'b0;
            bc_cmd_stop  <= 1'b0;
            bc_cmd_write <= 1'b0;
            bc_cmd_read  <= 1'b0;
            bc_data_in   <= 1'b0;
            bit_idx      <= 3'd0;
            shreg        <= 8'd0;
            rdata        <= 8'd0;
            rw_r         <= 1'b0;
        end else begin
            // default: command pulses are single-cycle unless re-asserted below
            bc_cmd_start <= 1'b0;
            bc_cmd_stop  <= 1'b0;
            bc_cmd_write <= 1'b0;
            bc_cmd_read  <= 1'b0;
            done         <= 1'b0;

            case (state)

                S_IDLE: begin
                    if (start_xfer) begin
                        busy         <= 1'b1;
                        addr_ack_err <= 1'b0;
                        data_ack_err <= 1'b0;
                        shreg        <= {slave_addr, rw};
                        rw_r         <= rw;
                        bit_idx      <= 3'd7;
                        bc_cmd_start <= 1'b1;
                        state        <= S_START;
                    end
                end

                S_START: begin
                    if (bc_cmd_done) begin
                        bc_cmd_write <= 1'b1;
                        bc_data_in   <= shreg[7];
                        state        <= S_ADDR_WAIT;
                    end
                end

                S_ADDR_WAIT: begin
                    if (bc_cmd_done) begin
                        if (bit_idx == 0) begin
                            state <= S_ADDR_ACK;
                        end else begin
                            bit_idx      <= bit_idx - 1'b1;
                            shreg        <= shreg << 1;
                            bc_cmd_write <= 1'b1;
                            bc_data_in   <= shreg[6];
                            state        <= S_ADDR_WAIT;
                        end
                    end
                end

                S_ADDR_ACK: begin
                    bc_cmd_read <= 1'b1;
                    state       <= S_ADDR_ACK_WAIT;
                end

                S_ADDR_ACK_WAIT: begin
                    if (bc_cmd_done) begin
                        addr_ack_err <= bc_data_out;   // 1 = NACK
                        if (bc_data_out) begin
                            bc_cmd_stop <= 1'b1;
                            state       <= S_STOP_WAIT;
                        end else if (rw_r == 1'b0) begin
                            shreg        <= wdata;
                            bit_idx      <= 3'd7;
                            bc_cmd_write <= 1'b1;
                            bc_data_in   <= wdata[7];
                            state        <= S_WDATA_WAIT;
                        end else begin
                            bit_idx     <= 3'd7;
                            bc_cmd_read <= 1'b1;
                            state       <= S_RDATA_WAIT;
                        end
                    end
                end

                S_WDATA_WAIT: begin
                    if (bc_cmd_done) begin
                        if (bit_idx == 0) begin
                            state <= S_WDATA_ACK;
                        end else begin
                            bit_idx      <= bit_idx - 1'b1;
                            shreg        <= shreg << 1;
                            bc_cmd_write <= 1'b1;
                            bc_data_in   <= shreg[6];
                            state        <= S_WDATA_WAIT;
                        end
                    end
                end

                S_WDATA_ACK: begin
                    bc_cmd_read <= 1'b1;
                    state       <= S_WDATA_ACK_WAIT;
                end

                S_WDATA_ACK_WAIT: begin
                    if (bc_cmd_done) begin
                        data_ack_err <= bc_data_out;
                        bc_cmd_stop  <= 1'b1;
                        state        <= S_STOP_WAIT;
                    end
                end

                S_RDATA_WAIT: begin
                    if (bc_cmd_done) begin
                        rdata[bit_idx] <= bc_data_out;
                        if (bit_idx == 0) begin
                            state <= S_RACK;
                        end else begin
                            bit_idx     <= bit_idx - 1'b1;
                            bc_cmd_read <= 1'b1;
                            state       <= S_RDATA_WAIT;
                        end
                    end
                end

                S_RACK: begin
                    bc_cmd_write <= 1'b1;
                    bc_data_in   <= 1'b1;  // master sends NACK (single-byte read, no more data wanted)
                    state        <= S_RACK_WAIT;
                end

                S_RACK_WAIT: begin
                    if (bc_cmd_done) begin
                        bc_cmd_stop <= 1'b1;
                        state       <= S_STOP_WAIT;
                    end
                end

                S_STOP_WAIT: begin
                    if (bc_cmd_done) begin
                        busy  <= 1'b0;
                        done  <= 1'b1;
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
