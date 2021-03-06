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
    input sendmark,
    input bodymark,
    input oncemark,
//    input stopmark,
    input we,
    input [13:0]wadd,
    input [7:0]data_time,
    input [11:0]data_peak,
    input calculate_achieve,
    input [7:0]now_num,
    input sweep_en,
    input sweep_add,
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
    input [7:0]extract_num,//抽取位数
    input [15:0]send_data_num,
    
    
    output stop_message,
    output m5_bzo,
    output m5_boo,
    output m7_bzo,
    output m7_boo,
    output m2_bzo,
    output m2_boo,
    output test,
    output test2
    );

/********************* test wire ************************************/
wire test,test_c_ram,test_w_t_ram,test_w_t_ram2;
/******************** inside connect wire **************************************/
wire write_en , clk_fifo_out , ren_m5 , wr_n , cs , speed4x_on , clk_57 ,write_ram_done , m5m7_all_send , start_send_subsete;
wire [13:0]write_add , rd_add_m5;
wire [15:0]write_data_m , rd_m5 ,rd_m5_1 , rd_m5_2 , db;
wire [11:0]dsp_ma , ma;
wire m5_bzo_t , m5_boo_t , ren_m5_1 , ren_m5_2;
reg m5m7_switch_t , speed_t;

assign m5_bzo = m5m7_all_send ? m5_bzo_t : (!m5m7_switch_t ? m5_bzo_t : 1'b1);
assign  m5_boo = m5m7_all_send ? m5_boo_t : (!m5m7_switch_t ? m5_boo_t : 1'b1);
assign m7_bzo = m5m7_all_send ? m5_bzo_t : (m5m7_switch_t ? m5_bzo_t : 1'b1);
assign  m7_boo = m5m7_all_send ? m5_boo_t : (m5m7_switch_t ? m5_boo_t : 1'b1);
assign rd_m5 = m5m7_all_send ? rd_m5_2 : rd_m5_1;
assign ren_m5_1 = m5m7_all_send ? 1'b0 : ren_m5;
assign ren_m5_2 = m5m7_all_send ? ren_m5 : 1'b0;

assign test = rd_add_m5 == 16'd1998 ? 1'b1:1'b0;
assign test2 = rd_m5 == 16'd1998 ? 1'b1:1'b0;

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        m5m7_switch_t <= 1'b0;
        speed_t <= 1'b1;
    end
    else
    begin
        if(!ren_m5)
            begin
                m5m7_switch_t <= m5m7_switch;
                speed_t <= speed;
            end
    end
end

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
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
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
    .extract_num(extract_num),
    
    .write_ram_done(write_ram_done),
    .stop_message(stop_message),
    .write_en(write_en),
    .write_add(write_add),
    .write_data(write_data_m),
    .test(test_w_t_ram)
    );

//write_to_ram_send_data write_to_ram_send_data(
//    .clk( CLK60M),
//    .clk_20m(CLK20M),
//    .rst(rst),
////    .collectmark(collectmark),
//    .bodymark(bodymark),
//    .oncemark(oncemark),
////    .stopmark(stopmark),
//    .we_time(we),
//    .we_peak(we),
//    .add_time(wadd),
//    .add_peak(wadd),
//    .data_time(data_time),
//    .data_peak(data_peak),
//    .calculate_achieve(calculate_achieve),
//    .now_num(now_num),
//    .sweep_en(sweep_en),
//    .sweep_add(sweep_add ),
//    .sweep_data(sweep_data ),
//    .change_message(change_message),
//    .message1(message1),
//    .message2(message2),
//    .message3(message3),
//    .message4(message4),
//    .message5(message5),
//    .message6(message6),
//    .message7(message7),
//    .message8(message8),
//    .message9(message9),
//    .message10(message10),
//    .message11(message11),
//    .extract_num(extract_num),
    
//    .write_ram_done(write_ram_done),
//    .stop_message(stop_message),
//    .write_en(write_en),
//    .write_add(write_add),
//    .write_data(write_data_m),
//    .test(test_w_t_ram),
//    .test2(test_w_t_ram2)
//    );

//test_change_ram test1(
//    .clk(CLK60M),
//    .rst(rst),
//    .write_ram_done(write_ram_done),
//    .write_en(write_en),
//    .write_add(write_add),
//    .write_data(write_data_m)
//);
 
//  test_ram test_ram(
//    .clk( ~CLK60M ),
//    .rst(rst),
//    .write_ram_done(write_ram_done),
//    .write_add( write_add ),
//    .write_en( write_en ),
//    .write_data( write_data_m ),
//    .clk_fifo_out( ~clk_fifo_out ),
//    .ren_m5( ren_m5 ),
//    .rd_add_m5( rd_add_m5 ),
//    .send_data_num(send_data_num),
    
//    .rd_m5( rd_m5 ),
//    .test(test_c_ram )
// );
 
 change_ram change_ram(
    .clk( ~CLK60M ),
    .rst(rst),
    .write_ram_done(write_ram_done),
    .write_add( write_add ),
    .write_en( write_en ),
    .write_data( write_data_m ),
    .clk_fifo_out( ~clk_fifo_out ),
    .ren_m5( ren_m5_1 ),
    .rd_add_m5( rd_add_m5 ),
    
    .rd_m5( rd_m5_1 ),
    .test(test_c_ram )
 );
 
 send_subsete_m5 send_subsete_m5(
    .clk(  CLK20M  ),
    .rst( rst ),
    .clk_fifo_out( ~clk_fifo_out  ),//读时钟
    .ren_m5( ren_m5_2 ),//读使能
    .rd_add_m5( rd_add_m5 ),//读地址
    .send_m2( send_m2 ),
    .send_cmd( send_cmd ),//当为7时，上传m5，m7
    
    .rd_m5(rd_m5_2 ),
    .m5m7_all_send( m5m7_all_send),//当为高时，代表此时上传subsetE，测试数据，m5和m7同时上传
    .send( start_send_subsete),//开始上传
    .test( )
    );

write_data write_data
(
    .rst(~rst),
    .clk_60m(CLK60M),
    .clk_w(clk_1m),
    .clk_1m( clk_2m),
//    .testint(testint),
    .start_send( sendmark ),
    .start_send_subsete( start_send_subsete),
    .send_data_num(send_data_num),
    .m5m7_all_send(m5m7_all_send),
    .dsp_data(db),
    .dsp_ma(dsp_ma),
    .wr_n(wr_n),
    .xz6_cs(cs)
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
    .switch_on(speed_t),
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
    .m5_bzo(m5_bzo_t),
    .m5_boo(m5_boo_t),
    .low_flag(m5_low),
    .high_flag(m5_high)
);













endmodule
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
    input sendmark,
    input bodymark,
    input oncemark,
//    input stopmark,
    input we,
    input [13:0]wadd,
    input [7:0]data_time,
    input [11:0]data_peak,
    input calculate_achieve,
    input [7:0]now_num,
    input sweep_en,
    input sweep_add,
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
    input [7:0]extract_num,//抽取位数
    input [15:0]send_data_num,
    
    
    output stop_message,
    output m5_bzo,
    output m5_boo,
    output m7_bzo,
    output m7_boo,
    output m2_bzo,
    output m2_boo,
    output test,
    output test2
    );

/********************* test wire ************************************/
wire test,test_c_ram,test_w_t_ram,test_w_t_ram2;
/******************** inside connect wire **************************************/
wire write_en , clk_fifo_out , ren_m5 , wr_n , cs , speed4x_on , clk_57 ,write_ram_done , m5m7_all_send , start_send_subsete;
wire [13:0]write_add , rd_add_m5;
wire [15:0]write_data_m , rd_m5 ,rd_m5_1 , rd_m5_2 , db;
wire [11:0]dsp_ma , ma;
wire m5_bzo_t , m5_boo_t , ren_m5_1 , ren_m5_2;
reg m5m7_switch_t , speed_t;

assign m5_bzo = m5m7_all_send ? m5_bzo_t : (!m5m7_switch_t ? m5_bzo_t : 1'b1);
assign  m5_boo = m5m7_all_send ? m5_boo_t : (!m5m7_switch_t ? m5_boo_t : 1'b1);
assign m7_bzo = m5m7_all_send ? m5_bzo_t : (m5m7_switch_t ? m5_bzo_t : 1'b1);
assign  m7_boo = m5m7_all_send ? m5_boo_t : (m5m7_switch_t ? m5_boo_t : 1'b1);
assign rd_m5 = m5m7_all_send ? rd_m5_2 : rd_m5_1;
assign ren_m5_1 = m5m7_all_send ? 1'b0 : ren_m5;
assign ren_m5_2 = m5m7_all_send ? ren_m5 : 1'b0;

assign test = rd_add_m5 == 16'd1998 ? 1'b1:1'b0;
assign test2 = rd_m5 == 16'd1998 ? 1'b1:1'b0;

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        m5m7_switch_t <= 1'b0;
        speed_t <= 1'b1;
    end
    else
    begin
        if(!ren_m5)
            begin
                m5m7_switch_t <= m5m7_switch;
                speed_t <= speed;
            end
    end
end

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
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
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
    .extract_num(extract_num),
    
    .write_ram_done(write_ram_done),
    .stop_message(stop_message),
    .write_en(write_en),
    .write_add(write_add),
    .write_data(write_data_m),
    .test(test_w_t_ram)
    );

//write_to_ram_send_data write_to_ram_send_data(
//    .clk( CLK60M),
//    .clk_20m(CLK20M),
//    .rst(rst),
////    .collectmark(collectmark),
//    .bodymark(bodymark),
//    .oncemark(oncemark),
////    .stopmark(stopmark),
//    .we_time(we),
//    .we_peak(we),
//    .add_time(wadd),
//    .add_peak(wadd),
//    .data_time(data_time),
//    .data_peak(data_peak),
//    .calculate_achieve(calculate_achieve),
//    .now_num(now_num),
//    .sweep_en(sweep_en),
//    .sweep_add(sweep_add ),
//    .sweep_data(sweep_data ),
//    .change_message(change_message),
//    .message1(message1),
//    .message2(message2),
//    .message3(message3),
//    .message4(message4),
//    .message5(message5),
//    .message6(message6),
//    .message7(message7),
//    .message8(message8),
//    .message9(message9),
//    .message10(message10),
//    .message11(message11),
//    .extract_num(extract_num),
    
//    .write_ram_done(write_ram_done),
//    .stop_message(stop_message),
//    .write_en(write_en),
//    .write_add(write_add),
//    .write_data(write_data_m),
//    .test(test_w_t_ram),
//    .test2(test_w_t_ram2)
//    );

//test_change_ram test1(
//    .clk(CLK60M),
//    .rst(rst),
//    .write_ram_done(write_ram_done),
//    .write_en(write_en),
//    .write_add(write_add),
//    .write_data(write_data_m)
//);
 
//  test_ram test_ram(
//    .clk( ~CLK60M ),
//    .rst(rst),
//    .write_ram_done(write_ram_done),
//    .write_add( write_add ),
//    .write_en( write_en ),
//    .write_data( write_data_m ),
//    .clk_fifo_out( ~clk_fifo_out ),
//    .ren_m5( ren_m5 ),
//    .rd_add_m5( rd_add_m5 ),
//    .send_data_num(send_data_num),
    
//    .rd_m5( rd_m5 ),
//    .test(test_c_ram )
// );
 
 change_ram change_ram(
    .clk( ~CLK60M ),
    .rst(rst),
    .write_ram_done(write_ram_done),
    .write_add( write_add ),
    .write_en( write_en ),
    .write_data( write_data_m ),
    .clk_fifo_out( ~clk_fifo_out ),
    .ren_m5( ren_m5_1 ),
    .rd_add_m5( rd_add_m5 ),
    
    .rd_m5( rd_m5_1 ),
    .test(test_c_ram )
 );
 
 send_subsete_m5 send_subsete_m5(
    .clk(  CLK20M  ),
    .rst( rst ),
    .clk_fifo_out( ~clk_fifo_out  ),//读时钟
    .ren_m5( ren_m5_2 ),//读使能
    .rd_add_m5( rd_add_m5 ),//读地址
    .send_m2( send_m2 ),
    .send_cmd( send_cmd ),//当为7时，上传m5，m7
    
    .rd_m5(rd_m5_2 ),
    .m5m7_all_send( m5m7_all_send),//当为高时，代表此时上传subsetE，测试数据，m5和m7同时上传
    .send( start_send_subsete),//开始上传
    .test( )
    );

write_data write_data
(
    .rst(~rst),
    .clk_60m(CLK60M),
    .clk_w(clk_1m),
    .clk_1m( clk_2m),
//    .testint(testint),
    .start_send( sendmark ),
    .start_send_subsete( start_send_subsete),
    .send_data_num(send_data_num),
    .m5m7_all_send(m5m7_all_send),
    .dsp_data(db),
    .dsp_ma(dsp_ma),
    .wr_n(wr_n),
    .xz6_cs(cs)
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
    .switch_on(speed_t),
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
    .m5_bzo(m5_bzo_t),
    .m5_boo(m5_boo_t),
    .low_flag(m5_low),
    .high_flag(m5_high)
);













endmodule
