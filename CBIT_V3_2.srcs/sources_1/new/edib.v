`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//  edib发送到上位机
//////////////////////////////////////////////////////////////////////////////////


module edib(
    input CLK60M,
    input CLK20M,
    input clk_1m,
    input clk_2m,
    input clk_24m,
    input clk_750k,
    input clk_23p43k,
    input clk_187p5k,
    input clk_5p86k,
    input clk_41p667k,
    input clk_83p33k,
    input rst,
    input collectmark,
    input bodymark,
//    input stopmark,
    input we,
    input [13:0]wadd,
    input [7:0]data_time,
    input [11:0]data_peak,
    input calculate_achieve,
    input now_num,
    input sweep_en,
    input [13:0]sweep_add,
    input [15:0]sweep_data,
    input change_message,
    input [15:0]message1,
    input [15:0]message2,
    input [15:0]message3,
    input [15:0]message4,
    input [15:0]message5,
    input [15:0]message6,
    input [15:0]message7,
    input [15:0]message8,
    input [15:0]message9,
    input [15:0]message10,
    input [15:0]message11,
    input self_version,
    input speed,
    input m5m7_switch,
    input send_m2,
    input [2:0]send_cmd,
    
    
    output stop_message,
    output m5_bzo,
    output m5_boo,
    output m2_bzo,
    output m2_boo
    );

/******************** inside connect wire **************************************/
wire write_en , clk_fifo_out , ren_m5 , wr_n , cs , speed4x_on , clk_57;
wire [13:0]write_add , rd_add_m5;
wire [15:0]write_data_m , rd_m5 , db;
wire [11:0]dsp_ma , ma;


up_send up_send(
    .clk(clk_83p33k ),
    .clk_2m( clk_187p5k ),
    .CLK20M(CLK20M),
    .rst(rst),
    .self_version(self_version),
    .speed(speed),
    .m5m7_switch(m5m7_switch),
    .send_m2(send_m2),
    .send_cmd(send_cmd),
    .m2_bzo( m2_bzo ),
    .m2_boo( m2_boo )
);

write_to_ram write_to_ram(
    .clk( CLK60M),
    .clk_20m(CLK20M),
    .rst(rst),
    .collectmark(collectmark),
    .bodymark(bodymark),
//    .stopmark(stopmark),
    .we_time(we),
    .we_peak(we),
    .add_time(wadd),
    .add_peak(wadd),
    .data_time(data_time),
    .data_peak(data_peak),
    .calculate_achieve(calculate_achieve),
    .now_num(now_num),
    .sweep_en(sweep_en),
    .sweep_add(sweep_add ),
    .sweep_data(sweep_data ),
    .change_message(change_message),
    .message1(message1),
    .message2(message2),
    .message3(message3),
    .message4(message4),
    .message5(message5),
    .message6(message6),
    .message7(message7),
    .message8(message8),
    .message9(message9),
    .message10(message10),
    .message11(message11),
    
    .stop_message(stop_message),
    .write_en(write_en),
    .write_add(write_add),
    .write_data(write_data_m)
    );
 
 time_data_ram ram1(
    .wclk( ~CLK60M ),
    .waddr( write_add ),
    .din_sync( write_en ),
    .din( write_data_m ),
    .rclk( ~clk_fifo_out ),
    .re( ren_m5 ),
    .ra( rd_add_m5 ),
    .dout( rd_m5 )
    );
    
peak_data_ram ram2(

);

write_data write_data
(
    .rst(~rst),
    .clk_60m(CLK60M),
    .clk_w(clk_1m),
    .clk_1m( clk_2m),
//    .testint(testint),
    .calculate_achieve( calculate_achieve ),
    .dsp_data(db),
    .dsp_ma(dsp_ma),
    .wr_n(wr_n),
    .xz6_cs(cs),
    .speed4x_on(speed4x_on)
);
    
address_latch address_latch
(
	.XZ6_CS(cs), 
    .DSP_MA(dsp_ma), 
    .MA(ma),
    .rst_ctrl(~rst)
); 
    
interface_m5 interface_m5
(
    .XZ6_CS(cs),
    .wr_(wr_n),
    .clock_32x57(clk_fifo_out),
    .clock_system(clk_24m),
    .reset_(~rst),
    .db(db),
    .ma(ma),
    .rden(ren_m5),
    .rd_address(rd_add_m5)
);


speed4x_switch speed4x_switch
(
    .clk_system(clk_24m),
    .reset_n( ~rst),
    .switch_on(speed4x_on),
    .clk_4x(clk_750k),
    .clk_4x_fifo(clk_23p43k),
    .clk_1x(clk_187p5k),
    .clk_1x_fifo(clk_5p86k),
    .clk_data_out(clk_57),
    .clk_fifo_out(clk_fifo_out)
);

trans_m5m7 trans_m5(
    .reset_( ~rst),
    .clock_57(clk_57),
    .rden5(ren_m5),
    .clock_32x57(clk_fifo_out),
    .q5(rd_m5),
    .address5(rd_add_m5),
    .m5_bzo(m5_bzo),
    .m5_boo(m5_boo),
    .low_flag(m5_low),
    .high_flag(m5_high)
);













endmodule
