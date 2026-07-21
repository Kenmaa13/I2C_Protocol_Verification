module i2c_master(
	input clk, // 50Mhz
	input address,
	output wire clk_100khz,
	output reg sda_in,
	output reg sda_out,
);

	localparam idle = 3'd0;
	localparam start = 3'd1;
	localparam send_add = 3'd2;
	localparam wait_ack = 3'd3;
	localparam write_data = 3'd4;
	localparam stop = 3'd5;
	localparam done = 3'd6;
	
	parameter counter_limit = 9'd500;
	reg [8:0]clk_counter;
	
	reg [2:0]state;
	reg ack;
	reg [7:0]data_reg;
	
	initial begin
		sda_in <= 1'b1;
		sda_out <= 1'b1;
		state <= idle;
		ack <= 1'b0;
		clk_counter <= 9'd0;
		clk_100khz <= 1'b0;
	end
	
	always @(posedge clk) begin
		if(clk_counter == counter_limit) begin
			clk_100khz <= ~clk_100khz;
			clk_counter <= 1'd0;
		end
		else begin
			clk_counter = clk_counter + 1;
		end
	end
	
	
endmodule