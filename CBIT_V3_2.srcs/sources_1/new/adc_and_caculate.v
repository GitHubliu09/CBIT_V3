`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// adc采集和计算
//////////////////////////////////////////////////////////////////////////////////


module adc_and_caculate(
    input CLK20M,
    input CLK60M,
    input clk_adc_sample,
    input rst,
    input collectmark,
    input bodymark,
    input fire_once,
    input fire_achieve,
    input [7:0]now_num,
//    input stopmark,
    input adc_ovr,
    input [13:0]adc_data,
    input [7:0]sweep_num,
    
    output adc_shdn,
    output adc_oe,
    output adc_clk_ttl,
    output adc_clk_oe,
    output [4:0]gain,
    output we_out,
    output [13:0]wadd_out,
    output [15:0]data_time,
    output [15:0]data_peak,
    output  sweep_write_en,
    output  sweep_add,
    output [15:0]sweep_data,
 //   output calculate_once,
    output calculate_achieve,
    output collect_achieve,
    output test,
    output test2
    
    );

/******************* inside connect wire ************************************************/
wire we_un , re_un , collect_once , collect_achieve;
wire[13:0]wadd_un , radd_un , collect_num/*once collect number*/;
wire[15:0]data_un , rdata_un;
wire sweep_write_en_t;
/********************* test wire ****************************************************************/
wire test_collect,test_collect2;
reg [15:0]data_un_test,data_un_test2,data_un_test3,data_un_test4;

assign sweep_add = radd_un[0];
assign sweep_data = rdata_un;
assign test = data_un_test2 == data_un_test ? 1'b1:1'b0;
assign test2 = we_un ? 1'b1:1'b0;

always@(negedge CLK60M or posedge rst)
begin
    if(rst)
    begin
        data_un_test <= 16'd0;
        data_un_test2 <= 16'd0;
    end
    else
    begin
        data_un_test <= rdata_un;
        if(data_un_test == 16'd0)
            data_un_test2 <= 16'd1;
        else
            data_un_test2 <= data_un_test;
    end
end

always@(negedge CLK60M or posedge rst)
begin
    if(rst)
    begin
        data_un_test3 <= 16'd0;
        data_un_test4 <= 16'd0;
    end
    else
    begin
        data_un_test3 <= data_un;
        if(data_un_test3 == 16'd0)
            data_un_test4 <= 16'd1;
        else
            data_un_test4 <= data_un_test3;
    end
end



collect collect(
    .rst(rst),
    .clk(CLK20M),
    .clk_smp(clk_adc_sample),
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .fire_once(fire_once),
    .fire_achieve(fire_achieve),
    .now_num(now_num),
    
    .adc_ovr(adc_ovr),//when adc_ovr = 1 , overranged or underranged
    .adc_data(adc_data),
    .shdn(adc_shdn),//shdn=0,oe=0 -> enalbe ... shdn=1,oe=0 -> nap mode ... shdn=1,oe=1 -> sleep mode
    .oe(adc_oe),// adc IC output enable pin
    .adc_clk_ttl(adc_clk_ttl),//adc clk
    .adc_clk_oe(adc_clk_oe),// adc clk enable, =1 -> eanble
    .gain(gain),
    .we_un(we_un ),
    .wadd_un(wadd_un ),
    .data_un(data_un ),
    .collect_num(collect_num),
    .collect_achieve(collect_achieve),
    .collect_once (collect_once),
    .test(test_collect),
    .test2(test_collect2)
);

untreated_data_ram untreated_data_ram(
    .wclk(clk_adc_sample ),
    .waddr(wadd_un ),
    .din_sync(we_un ),
    .din(data_un ),
    .rclk(~CLK60M ),
    .re(re_un ),
    .ra(radd_un ),
    .dout(rdata_un )
    );
    
 calculate calculate(
    .clk(CLK60M),
    .clk_20m(CLK20M),
    .rst(rst),
    .en_read(re_un),
    .add_r(radd_un),
    .data_r(rdata_un),
    .collect_num(collect_num),
//    .collectmark(collectmark),
    .bodymark(bodymark),
//    .stopmark(stopmark),
    .fire_once(fire_once),
    .collect_once(collect_once),
    .collect_achieve(collect_achieve),
    .sweep_num(sweep_num),
    .sweep_en(sweep_write_en),
    .we_time( we_out),
 //   .we_peak( we_peak),
    .add_time( wadd_out),
//    .add_peak( add_peak),
    .data_time( data_time),
    .data_peak( data_peak),
 //   .calculate_once(calculate_once),
    .calculate_achieve( calculate_achieve )
 );





endmodule
