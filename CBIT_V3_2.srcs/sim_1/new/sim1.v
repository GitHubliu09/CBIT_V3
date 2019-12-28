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

reg rst , clk , bodymark , oncemark;

initial rst = 1'b1;
initial #10 rst = 1'b0;
initial clk = 1'b0;
initial bodymark = 1'b0;
initial oncemark = 1'b0;

initial #200 bodymark = 1'b1;
initial #202 bodymark = 1'b0;
always #1 clk = ~clk;
always
begin
    #1 oncemark = 1'b0;
    #30 oncemark = 1'b1;
    #32 oncemark = 1'b0;
    #300 oncemark = 1'b0;
end


Ultrasonic_TOP top(
    .clk( clk),
//    input rst,
    .m2_cmd_in(),
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




endmodule
