`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/25 15:20:02
// Design Name: 
// Module Name: sim1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sim1(

    );

reg rst , clk , bodymark , oncemark, test1;

initial rst = 1'b1;
initial #10 rst = 1'b0;
initial clk = 1'b0;
initial bodymark = 1'b0;
initial oncemark = 1'b0;
initial test1 = 1'b0;

initial #200 bodymark = 1'b1;
initial #202 bodymark = 1'b0;
always #7 clk = ~clk;
always
begin
    #1 oncemark = 1'b0;
    #30 oncemark = 1'b1;
    #32 oncemark = 1'b0;
    #300 oncemark = 1'b0;
end

always
begin
    #100 test1 = 1'b1;
    #2 test1 = 1'b0;
    #300 test1 = 1'b0;
end




//collect collect(
//    .rst(rst),
//    .clk(clk),
//    .clk_smp(clk),
////    .collectmark(collectmark),
//    .bodymark(bodymark),
//    .fire_once(test1),
//    .fire_achieve( ),
//    .now_num( ),
    
//    .adc_ovr( ),//when adc_ovr = 1 , overranged or underranged
//    .adc_data( ),
//    .shdn( ),//shdn=0,oe=0 -> enalbe ... shdn=1,oe=0 -> nap mode ... shdn=1,oe=1 -> sleep mode
//    .oe( ),// adc IC output enable pin
//    .adc_clk_ttl( ),//adc clk
//    .adc_clk_oe( ),// adc clk enable, =1 -> eanble
//    .gain( ),
//    .we_un(  ),
//    .wadd_un(  ),
//    .data_un(  ),
//    .collect_num( ),
//    .collect_achieve( ),
//    .collect_once ( )
//);


Ultrasonic_TOP top(
    .clk( clk),
//    input rst,
    .m2_cmd_in(1'b1),
    .pma(),
    .pmd(), 
    .adc_data(),
    .adc_ovr(),
    .adc_shdn(),
    .adc_oe(),
    .adc_clk_ttl(),
    .adc_clk_oe(),
    .m5_bzo(),
    .m5_boo(),
    .m7_bzo(),
    .m7_boo(), 
    .gain(),
    .m2_bzo(),
    .m2_boo(),

    .int_0(),
    .uart_rx(),
    .uart_tx(),
    
    .oe_15(),
    .oe_20(),
    .oe_nj(),
    .fire_a(),
    .fire_b(),
    .fire_c(),
    .fire_d()
    );

//count_mod count_mod(
//    .clk(clk),
//    .rst(rst),
//    .bodymark(bodymark),
//    .oncemark(oncemark),
//    .num()
//);


//fire fire(
//    .rst( rst),
//    .clk_20m(clk ),
//    .bodymark( bodymark),
//    .oncemark( oncemark),
//    .oe( ),
//    .fire_a( ),
//    .fire_b( ),
//    .fire_c( ),
//    .fire_d( ),
//    .fire_once( ),
//    .fire_achieve( ),
//    .pulse_num( ),
//    .error_fire( )
//    );


//reg clk_1ns , ren_m5 , send_m2 ;
//reg [2:0] send_cmd;
//reg [13:0]rd_add_m5;
//initial clk_1ns = 1'b0;
//always #1 clk_1ns = ~clk_1ns;
//initial ren_m5 = 1'b0;
//initial send_m2 = 1'b1;
//initial rd_add_m5 = 14'd0;

//always
//begin
//    #1 send_cmd = 3'd0;
//    #200 send_cmd = 3'd7;
//    #2 send_cmd  = 3'd0;
//    #40 ren_m5 = 1'b1;
//    #1 rd_add_m5 = 14'd0;
//    #2 rd_add_m5 = 14'd1;
//    #2 rd_add_m5 = 14'd2;
//    #2 rd_add_m5 = 14'd3;
//    #2 rd_add_m5 = 14'd4;
//    #2 rd_add_m5 = 14'd5;
//    #2 rd_add_m5 = 14'd6;
//    #2 rd_add_m5 = 14'd7;
//    #2 rd_add_m5 = 14'd8;
//    #2 rd_add_m5 = 14'd9;
//    #2 rd_add_m5 = 14'd10;
//    #2 rd_add_m5 = 14'd11;
//    #2 rd_add_m5 = 14'd12;
//    #2 rd_add_m5 = 14'd13;
//    #2 rd_add_m5 = 14'd14;
//    #2 rd_add_m5 = 14'd15;
//    #2 rd_add_m5 = 14'd16;
//    #2 ren_m5 = 1'b0;
//    #2 rd_add_m5 = 14'd0;
//end

//send_subsete_m5 send_subsete_m5(
//    .clk( clk_1ns ),
//    .rst( rst ),
//    .clk_fifo_out( clk_1ns ),//读时钟
//    .ren_m5(ren_m5 ),//读使能
//    .rd_add_m5( rd_add_m5),//读地址
//    .send_m2( send_m2),
//    .send_cmd( send_cmd),//当为7时，上传m5，m7
    
//    .rd_m5( ),
//    .m5m7_all_send( ),//当为高时，代表此时上传subsetE，测试数据，m5和m7同时上传
//    .send( ),//开始上传
//    .test( )
//    );


endmodule
