//==============================================================
// i2c_slave_top.v
// Single-block reactive I2C slave (100kHz / 7-bit address).
// The slave never generates SCL - it reacts to master edges.
// SDA/SCL are first synchronized into the local clock domain,
// then START/STOP conditions and rising/falling edges are
// detected from the synchronized signals.
//
// Each 9-clock group (8 data bits + 1 ack bit) is tracked with
// pulse_cnt so ADDR / WDATA / RDATA phases share one pattern:
//   scl_rise -> sample (write) or shift (read setup)
//   scl_fall -> drive next bit / drive or release ACK
//
// Exposes a simple 1-byte internal register (mem) that acts as
// the "device" the master talks to - handy for UVM scoreboard
// backdoor checks.
//==============================================================
module i2c_slave_top #(
    parameter [6:0] SLAVE_ADDR = 7'h50
)(
    input  wire       clk,
    input  wire       rst_n,

    inout  wire        sda,
    inout  wire        scl,

    output wire [7:0]  last_write_data,     // last byte written by master
    output wire [7:0]  read_reg_value_dbg   // current value of internal mem
);

    // ---- synchronize async bus into local clock domain ----
    wire scl_s, sda_s;
    i2c_sync u_sync_scl (.clk(clk), .rst_n(rst_n), .d(scl), .q(scl_s));
    i2c_sync u_sync_sda (.clk(clk), .rst_n(rst_n), .d(sda), .q(sda_s));

    reg scl_s_d, sda_s_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_s_d <= 1'b1;
            sda_s_d <= 1'b1;
        end else begin
            scl_s_d <= scl_s;
            sda_s_d <= sda_s;
        end
    end

    wire scl_rise   =  scl_s &  ~scl_s_d;
    wire scl_fall   = ~scl_s &   scl_s_d;
    wire start_cond =  scl_s &  scl_s_d &  sda_s_d & ~sda_s;  // SDA falls, SCL high
    wire stop_cond  =  scl_s &  scl_s_d & ~sda_s_d &  sda_s;  // SDA rises, SCL high

    reg sda_oe;
    assign sda = sda_oe ? 1'b0 : 1'bz;   // slave never drives scl in this simple model

    localparam S_IDLE  = 2'd0;
    localparam S_ADDR  = 2'd1;
    localparam S_WDATA = 2'd2;
    localparam S_RDATA = 2'd3;

    reg [1:0] state;
    reg [3:0] pulse_cnt;      // 0..9  (8 data bits + 1 ack bit)
    reg [7:0] shreg;          // shift-in register (address / write data)
    reg [7:0] tx_shreg;       // shift-out register (read data)
    reg       rw_bit;
    reg       addr_matched;
    reg [7:0] mem;            // demo internal register the slave "contains"
    reg [7:0] last_write_r;

    assign last_write_data    = last_write_r;
    assign read_reg_value_dbg = mem;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            pulse_cnt    <= 4'd0;
            shreg        <= 8'd0;
            tx_shreg     <= 8'd0;
            rw_bit       <= 1'b0;
            addr_matched <= 1'b0;
            sda_oe       <= 1'b0;
            mem          <= 8'hA5;   // arbitrary power-up value
            last_write_r <= 8'd0;
        end else if (stop_cond) begin
            state     <= S_IDLE;
            pulse_cnt <= 4'd0;
            sda_oe    <= 1'b0;
        end else if (start_cond) begin
            state     <= S_ADDR;
            pulse_cnt <= 4'd0;
            sda_oe    <= 1'b0;
        end else begin
            case (state)

                S_IDLE: begin
                    sda_oe <= 1'b0;
                end

                // ---- address phase: 7-bit addr + R/W, then ACK ----
                S_ADDR: begin
                    if (scl_rise) begin
                        if (pulse_cnt < 4'd8) begin
                            shreg     <= {shreg[6:0], sda_s};
                            pulse_cnt <= pulse_cnt + 1'b1;
                        end else begin
                            pulse_cnt <= pulse_cnt + 1'b1; // 9th rise: master reads ACK
                        end
                    end
                    if (scl_fall) begin
                        if (pulse_cnt == 4'd8) begin
                            addr_matched <= (shreg[7:1] == SLAVE_ADDR);
                            rw_bit       <= shreg[0];
                            sda_oe       <= (shreg[7:1] == SLAVE_ADDR);
                        end else if (pulse_cnt == 4'd9) begin
                            pulse_cnt <= 4'd0;
                            if (addr_matched) begin
                                if (rw_bit) begin
                                    tx_shreg <= mem;
                                    sda_oe   <= ~mem[7]; // drive first read bit now, not one period late
                                    state    <= S_RDATA;
                                end else begin
                                    sda_oe <= 1'b0;
                                    state  <= S_WDATA;
                                end
                            end else begin
                                sda_oe <= 1'b0;
                                state  <= S_IDLE;   // not addressed to us
                            end
                        end
                    end
                end

                // ---- write-data phase: 8 bits in, then ACK ----
                S_WDATA: begin
                    if (scl_rise) begin
                        if (pulse_cnt < 4'd8) begin
                            shreg     <= {shreg[6:0], sda_s};
                            pulse_cnt <= pulse_cnt + 1'b1;
                        end else begin
                            pulse_cnt <= pulse_cnt + 1'b1;
                        end
                    end
                    if (scl_fall) begin
                        if (pulse_cnt == 4'd8) begin
                            mem          <= shreg;
                            last_write_r <= shreg;
                            sda_oe       <= 1'b1;      // ACK the byte
                        end else if (pulse_cnt == 4'd9) begin
                            sda_oe    <= 1'b0;
                            pulse_cnt <= 4'd0;
                            state     <= S_IDLE;       // wait for repeated START or STOP
                        end
                    end
                end

                // ---- read-data phase: 8 bits out, then sample master's ACK/NACK ----
                S_RDATA: begin
                    if (scl_fall) begin
                        if (pulse_cnt < 4'd8) begin
                            sda_oe <= ~tx_shreg[7];     // drive '0' actively, release for '1'
                        end else if (pulse_cnt == 4'd8) begin
                            sda_oe <= 1'b0;             // release, master drives ACK/NACK
                        end else if (pulse_cnt == 4'd9) begin
                            pulse_cnt <= 4'd0;
                            state     <= S_IDLE;
                        end
                    end
                    if (scl_rise) begin
                        if (pulse_cnt < 4'd8) begin
                            tx_shreg  <= tx_shreg << 1;
                            pulse_cnt <= pulse_cnt + 1'b1;
                        end else begin
                            pulse_cnt <= pulse_cnt + 1'b1; // sample master ack/nack (not stored here)
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
