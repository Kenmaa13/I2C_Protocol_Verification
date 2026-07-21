`timescale 1ns / 1ps

module i2c_clk_divider #
(
    parameter CLK_FREQ = 50000000,    // System Clock (Hz)
    parameter I2C_FREQ = 100000       // I2C Clock (Hz)
)
(
    input  wire clk,

    output reg  clk_100khz,
    output reg  scl_tick
);

    // Divider Calculation
    localparam integer DIVIDER = CLK_FREQ / (2 * I2C_FREQ);

    // Registers

    reg [15:0] counter;

    // Clock Divider

    always @(posedge clk or posedge rst)
    begin
        if(counter == DIVIDER-1) begin
            counter  <= 16'd0;
            clk_100khz      <= ~clk_100khz;
            scl_tick <= 1'b1;
        end

        else begin
            counter <= counter + 1'b1;
        end
    end

endmodule