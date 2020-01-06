`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  m2上传模块
// 
//////////////////////////////////////////////////////////////////////////////////


module up_send(
    input clk,
    input clk_2m,
    input CLK20M,
    input rst,
    input self_version,
    input speed,
    input m5m7_switch,
    input send_m2,
    input [2:0]send_cmd,
    output m2_bzo,
    output m2_boo
    );

wire m2_boo,m2_bzo;
wire wr_clk , get_clk , wr_rst_busy , rd_rst_busy , wr_en , rd_en , full , empty;
wire [15:0]din , dout;

assign get_clk = clk;
assign cmd_out = m2_bzo;

fifo_generator_0 fifo_0(
    .wr_clk(wr_clk),
    .rd_clk(get_clk),
    .wr_rst_busy(wr_rst_busy ),
    .rd_rst_busy(rd_rst_busy ),
    .rst(rst),
    .din(din),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .dout(dout),
    .full(full),
    .empty(empty)
    );

write_fifo write_fifo(
    .clk(clk_2m),
    .clk_20m(CLK20M),
    .rst( rst),
    .self_version(self_version),
    .speed(speed),
    .m5m7_switch(m5m7_switch),
    .send_m2(send_m2),
    .send_cmd(send_cmd),
    .empty(empty),
    .full(full),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .din(din)
    );





m2_send m2_send (
		.empty(empty), 
		.rstn(~rst), 
		.clock_41p766k(clk), 
		.data(dout), 
		.rd_en(rd_en), 
		.m2_bzo(m2_bzo), 
		.m2_boo(m2_boo)
    );



endmodule
