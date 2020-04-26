`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// 
//////////////////////////////////////////////////////////////////////////////////


module cmd_test(
    input clk,
    input rst,
    output cmd_out
    );

wire m2_boo,m2_bzo;
wire wr_clk , get_clk , wr_rst_busy , rd_rst_busy , wr_en , rd_en , full , empty;
wire [15:0]din , dout;

assign get_clk = clk;
assign cmd_out = m2_bzo;

fifo_generator_1 fifo_1(
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

write_fifo_t write_fifo_t(
    .clk(clk),
    .rst( rst),
    .empty(empty),
    .full(full),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .din(din)
    );





m2_send_t m2_send_t (
		.empty(empty), 
		.rstn(~rst), 
		.clock_41p766k(clk), 
		.data(dout), 
		.rd_en(rd_en), 
		.m2_bzo(m2_bzo), 
		.m2_boo(m2_boo)
    );



endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// 
//////////////////////////////////////////////////////////////////////////////////


module cmd_test(
    input clk,
    input rst,
    output cmd_out
    );

wire m2_boo,m2_bzo;
wire wr_clk , get_clk , wr_rst_busy , rd_rst_busy , wr_en , rd_en , full , empty;
wire [15:0]din , dout;

assign get_clk = clk;
assign cmd_out = m2_bzo;

fifo_generator_1 fifo_1(
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

write_fifo_t write_fifo_t(
    .clk(clk),
    .rst( rst),
    .empty(empty),
    .full(full),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .din(din)
    );





m2_send_t m2_send_t (
		.empty(empty), 
		.rstn(~rst), 
		.clock_41p766k(clk), 
		.data(dout), 
		.rd_en(rd_en), 
		.m2_bzo(m2_bzo), 
		.m2_boo(m2_boo)
    );



endmodule
