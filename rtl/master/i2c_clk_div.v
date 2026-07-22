//==============================================================
// i2c_clk_div.v
// Generates a single-cycle "tick" pulse 4 times per SCL period
// (quarter-bit-period resolution) so the bit controller can
// implement SCL low / rising / high / falling phases.
//
//   DIV_COUNT = CLK_FREQ / (I2C_FREQ * 4)
//
// Example: 50MHz clk, 100kHz I2C -> DIV_COUNT = 125
//==============================================================
module i2c_clk_div #(
    parameter CLK_FREQ = 50_000_000,
    parameter I2C_FREQ = 100_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,   // count only while a transaction is active
    output reg  tick
);

    localparam integer DIV_COUNT = CLK_FREQ / (I2C_FREQ * 4);
    localparam integer CNT_WIDTH = $clog2(DIV_COUNT);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= {CNT_WIDTH{1'b0}};
            tick <= 1'b0;
        end else if (!enable) begin
            cnt  <= {CNT_WIDTH{1'b0}};
            tick <= 1'b0;
        end else if (cnt == DIV_COUNT-1) begin
            cnt  <= {CNT_WIDTH{1'b0}};
            tick <= 1'b1;
        end else begin
            cnt  <= cnt + 1'b1;
            tick <= 1'b0;
        end
    end

endmodule
