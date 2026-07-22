//==============================================================
// i2c_sync.v
// Simple 2-flop synchronizer for bringing the asynchronous
// SDA / SCL bus lines into the local clock domain.
// Reset state = 1 because an idle I2C bus is pulled high.
//==============================================================
module i2c_sync (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output wire q
);

    reg ff1, ff2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ff1 <= 1'b1;
            ff2 <= 1'b1;
        end else begin
            ff1 <= d;
            ff2 <= ff1;
        end
    end

    assign q = ff2;

endmodule
