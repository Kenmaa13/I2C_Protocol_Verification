//==============================================================
// i2c_bit_ctrl.v
// Lowest layer of the master. Executes ONE bit-level command
// per invocation: START condition, STOP condition, write one
// bit, or read one bit. Uses a 4-phase (quarter period) scheme
// driven by "tick" from i2c_clk_div:
//
//   PH0 : SCL held low   -> change SDA (setup time)
//   PH1 : SCL low->high  -> release SCL, wait for it to actually
//                           read back high (supports slave
//                           clock-stretching)
//   PH2 : SCL high       -> stable point: START/STOP edge is
//                           generated here, or read-bit is sampled
//   PH3 : SCL high->low  -> pull SCL low again, command done
//==============================================================
module i2c_bit_ctrl (
    input  wire clk,
    input  wire rst_n,

    // command pulses (exactly one asserted per new command)
    input  wire cmd_start,
    input  wire cmd_stop,
    input  wire cmd_write,
    input  wire cmd_read,
    input  wire data_in,     // bit value to drive (cmd_write)
    output reg  data_out,    // bit value sampled (cmd_read)
    output reg  cmd_done,    // 1-cycle pulse when command completes

    input  wire tick,        // quarter-period tick from i2c_clk_div

    // open-drain bus control
    output reg  scl_oe,      // 1 = actively pull SCL low
    output reg  sda_oe,      // 1 = actively pull SDA low
    input  wire scl_i,       // synchronized bus level (post pull-up)
    input  wire sda_i
);

    localparam PH0 = 2'd0;
    localparam PH1 = 2'd1;
    localparam PH2 = 2'd2;
    localparam PH3 = 2'd3;

    reg [1:0] phase;
    reg       busy;
    reg       active_start, active_stop, active_write, active_read;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase        <= PH0;
            busy         <= 1'b0;
            scl_oe       <= 1'b0;
            sda_oe       <= 1'b0;
            data_out     <= 1'b0;
            cmd_done     <= 1'b0;
            active_start <= 1'b0;
            active_stop  <= 1'b0;
            active_write <= 1'b0;
            active_read  <= 1'b0;
        end else begin
            cmd_done <= 1'b0;

            if (!busy) begin
                if (cmd_start || cmd_stop || cmd_write || cmd_read) begin
                    busy         <= 1'b1;
                    phase        <= PH0;
                    active_start <= cmd_start;
                    active_stop  <= cmd_stop;
                    active_write <= cmd_write;
                    active_read  <= cmd_read;
                end
            end else if (tick) begin
                case (phase)

                    PH0: begin
                        scl_oe <= 1'b1;  // hold SCL low while SDA changes
                        if (active_start)
                            sda_oe <= 1'b0;              // release high, ready for START edge
                        else if (active_stop)
                            sda_oe <= 1'b1;               // pull low, ready for STOP edge
                        else if (active_write)
                            sda_oe <= ~data_in;            // 0=drive low, 1=release (bus pulled high)
                        else if (active_read)
                            sda_oe <= 1'b0;                 // release so slave/master partner can drive
                        phase <= PH1;
                    end

                    PH1: begin
                        scl_oe <= 1'b0;              // release SCL, let pull-up bring it high
                        if (scl_i)
                            phase <= PH2;             // proceed once SCL actually reads high
                        // else: stay here -> slave clock-stretching
                    end

                    PH2: begin
                        if (active_start)
                            sda_oe <= 1'b1;            // SDA falls while SCL high -> START condition
                        else if (active_stop)
                            sda_oe <= 1'b0;             // SDA rises while SCL high -> STOP condition
                        else if (active_read)
                            data_out <= sda_i;           // sample bit at stable high phase
                        phase <= PH3;
                    end

                    PH3: begin
                        scl_oe       <= 1'b1;  // pull SCL low, end of this bit period
                        busy         <= 1'b0;
                        cmd_done     <= 1'b1;
                        active_start <= 1'b0;
                        active_stop  <= 1'b0;
                        active_write <= 1'b0;
                        active_read  <= 1'b0;
                        phase        <= PH0;
                    end

                endcase
            end
        end
    end

endmodule
