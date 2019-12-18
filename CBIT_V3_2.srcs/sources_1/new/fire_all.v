`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  fire all 
//  ·¢Éä
//////////////////////////////////////////////////////////////////////////////////


module fire_all(
    input CLK20M,
    input rst,
    input collectmark,
    input bodymark,
    input oncemark,
    input stopmark,
    
    output fire_oe,
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
    .collectmark(collectmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
    .stopmark(stopmark),
    .oe(fire_oe),
    .fire_a(fire_a),
    .fire_b(fire_b),
    .fire_c(fire_c),
    .fire_d(fire_d),
    .fire_once(fire_once),
    .fire_achieve(fire_achieve),
    .pulse_num(pulse_num),
    .error_fire(error_fire),
    .state(state)
);


endmodule
