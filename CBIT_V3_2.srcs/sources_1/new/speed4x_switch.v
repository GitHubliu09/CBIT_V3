//////////////////////////////////////////////////////////////////
// speed4x_switch.v,时钟一倍或四倍的选择
////////////////////////////////////////////////////////////////
module speed4x_switch(					// speed4x_switch.v
clk_system,
reset_n,
switch_on,
clk_4x,
clk_4x_fifo,
clk_1x,
clk_1x_fifo,
clk_data_out,
clk_fifo_out
);
input clk_system;
input reset_n;
input switch_on;
input clk_4x;//750kHz
input clk_4x_fifo;//23.43KHz
input clk_1x;//187.5KHz
input clk_1x_fifo;//5.86KHz

output reg clk_data_out;
output reg clk_fifo_out;

always@(posedge clk_system or negedge reset_n)
	if(!reset_n)
	begin
		clk_data_out <= clk_1x;
		clk_fifo_out <= clk_1x_fifo;
	end
	else
		if(switch_on)
		begin
			clk_data_out <= clk_4x;
			clk_fifo_out <= clk_4x_fifo;
		end
		else
		begin
			clk_data_out <= clk_1x;
			clk_fifo_out <= clk_1x_fifo;
		end
endmodule	
	