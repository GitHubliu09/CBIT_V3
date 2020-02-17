`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  fire all 
//  发射
//////////////////////////////////////////////////////////////////////////////////


module fire_all(
    input CLK20M,
    input rst,
//    input collectmark,
    input bodymark,
    input oncemark,
//    input stopmark,
    input collect_achieve,
    input [7:0] now_num,
    
    output oe_15,
    output oe_20,
    output oe_nj,
    output fire_a,
    output fire_b,
    output fire_c,
    output fire_d,
    output fire_once,
    output fire_achieve,
    output error_fire,
    output [1:0]state
    );




fire fire(
    .rst(rst),
    .clk_20m(CLK20M),
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
//    .stopmark(stopmark),
    .collect_achieve(collect_achieve),
    .now_num(now_num),
    .oe_15(oe_15),
    .oe_20(oe_20),
    .oe_nj(oe_nj),
    .fire_a(fire_a),
    .fire_b(fire_b),
    .fire_c(fire_c),
    .fire_d(fire_d),
    .fire_once(fire_once),
    .fire_achieve(fire_achieve),
//    .pulse_num(pulse_num),
    .error_fire(error_fire)

);


endmodule
