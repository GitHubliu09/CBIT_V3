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
    input [7:0]now_num,  //count_mod计算出来
//    input stopmark,
    input adc_ovr,//adc输入进来的信号，代表adc输入电压超过或者不到量程
    input [13:0]adc_data,
    input [7:0]sweep_num,//*********要上传的波形的位置
    input [13:0]collect_num,/*once collect number*/
    input [7:0]delay_time,//delay time
    
    output [1:0]select,//00->GND , 01->1.5  , 10->2.0 , 11->mud
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
    output [15:0]nj_data_time,
 //   output calculate_once,
    output calculate_achieve,
    output collect_achieve,
    output test,
    output test2
    
    );

/******************* inside connect wire ************************************************/
wire we_un , re_un , collect_once , collect_achieve , nj_w_en , re_nj , nj_collect_once;
wire[13:0]wadd_un , radd_un , collect_num/*once collect number*/,collect_num_nj , nj_add , radd_nj;
wire[15:0]data_un , rdata_un , nj_data , rdata_nj;
wire sweep_write_en_t , nj_doing , sweep_write_en_nj;
wire adc_clk_ttl_t;
wire upload_nj;
/********************* test wire ****************************************************************/
wire test_collect,test_collect2;
reg [15:0]data_un_test,data_un_test2,data_un_test3,data_un_test4;

//test
//assign upload_nj = 1'b1;

assign sweep_add = upload_nj ? radd_nj[0] : radd_un[0];
assign sweep_data = upload_nj ? rdata_nj : rdata_un;
assign sweep_write_en = upload_nj ? sweep_write_en_nj : sweep_write_en_t;
assign test = upload_nj;
assign test2 = sweep_write_en_nj;


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

always@(negedge CLK20M or posedge rst)
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

assign adc_clk_ttl = nj_doing ? CLK20M : adc_clk_ttl_t;

collect_nj collect_nj(
    .CLK20M(CLK20M),
    .rst(rst),
    .collect_achieve(collect_achieve),
    .fire_once(fire_once),
    .adc_data(adc_data),
    .collect_num_nj(collect_num_nj),
    
    .nj_data(nj_data ),
    .nj_add(nj_add),
    .nj_w_en(nj_w_en),
    .select(select),
    .nj_doing( nj_doing),
    .nj_collect_once( nj_collect_once)
);

nj_ram nj_ram(
    .wclk(CLK20M ),
    .waddr(nj_add ),
    .din_sync(nj_w_en ),
    .din(nj_data ),
    .rclk( CLK60M ),
    .re( re_nj ),
    .ra( radd_nj ),
    .dout( rdata_nj )
);

calculate_nj calculate_nj(
    .clk(CLK60M),
    .clk_20m(CLK20M),
    .rst(rst),
    .en_read(re_nj),
    .add_r(radd_nj),
    .data_r(rdata_nj),
    .collect_num( collect_num_nj),
//    .collectmark(collectmark),
    .bodymark( ),
//    .stopmark(stopmark),
    .fire_once( ),
    .now_num( now_num ), 
    .collect_once(collect_once),
    .collect_once_nj( nj_collect_once),
    .collect_achieve_nj(nj_collect_once ),
    .sweep_num( sweep_num), //test  sweep_num
    .sweep_en( sweep_write_en_nj ),
    .we_time(  ),
 //   .we_peak( we_peak),
    .add_time(  ),
//    .add_peak( add_peak),
    .data_time( nj_data_time ),
    .data_peak(  ),
 //   .calculate_once(calculate_once),
    .calculate_achieve( nj_calculate_achieve  ),
    .upload_nj( upload_nj )
);

collect collect(
    .rst(rst),
    .clk(CLK20M),
    .clk_smp(clk_adc_sample),
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .fire_once(fire_once),
    .nj_doing(nj_doing),
    .fire_achieve(fire_achieve),
    .now_num(now_num),
    .collect_num(collect_num),
    .delay_time(delay_time),
    
    .adc_ovr(adc_ovr),//when adc_ovr = 1 , overranged or underranged
    .adc_data(adc_data),
    .shdn(adc_shdn),//shdn=0,oe=0 -> enalbe ... shdn=1,oe=0 -> nap mode ... shdn=1,oe=1 -> sleep mode
    .oe(adc_oe),// adc IC output enable pin
    .adc_clk_ttl(adc_clk_ttl_t),//adc clk
    .adc_clk_oe(adc_clk_oe),// adc clk enable, =1 -> eanble
    .gain(gain),
    .we_un(we_un ),
    .wadd_un(wadd_un ),
    .data_un(data_un ),
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
    .sweep_num( sweep_num),//test sweep_num
    .sweep_en(sweep_write_en_t),
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
    input [7:0]now_num,  //count_mod计算出来
//    input stopmark,
    input adc_ovr,//adc输入进来的信号，代表adc输入电压超过或者不到量程
    input [13:0]adc_data,
    input [7:0]sweep_num,//*********要上传的波形的位置
    input [13:0]collect_num,/*once collect number*/
    input [7:0]delay_time,//delay time
    
    output [1:0]select,//00->GND , 01->1.5  , 10->2.0 , 11->mud
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
    output [15:0]nj_data_time,
 //   output calculate_once,
    output calculate_achieve,
    output collect_achieve,
    output test,
    output test2
    
    );

/******************* inside connect wire ************************************************/
wire we_un , re_un , collect_once , collect_achieve , nj_w_en , re_nj , nj_collect_once;
wire[13:0]wadd_un , radd_un , collect_num/*once collect number*/,collect_num_nj , nj_add , radd_nj;
wire[15:0]data_un , rdata_un , nj_data , rdata_nj;
wire sweep_write_en_t , nj_doing , sweep_write_en_nj;
wire adc_clk_ttl_t;
wire upload_nj;
/********************* test wire ****************************************************************/
wire test_collect,test_collect2;
reg [15:0]data_un_test,data_un_test2,data_un_test3,data_un_test4;

//test
//assign upload_nj = 1'b1;

assign sweep_add = upload_nj ? radd_nj[0] : radd_un[0];
assign sweep_data = upload_nj ? rdata_nj : rdata_un;
assign sweep_write_en = upload_nj ? sweep_write_en_nj : sweep_write_en_t;
assign test = upload_nj;
assign test2 = sweep_write_en_nj;


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

always@(negedge CLK20M or posedge rst)
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

assign adc_clk_ttl = nj_doing ? CLK20M : adc_clk_ttl_t;

collect_nj collect_nj(
    .CLK20M(CLK20M),
    .rst(rst),
    .collect_achieve(collect_achieve),
    .fire_once(fire_once),
    .adc_data(adc_data),
    .collect_num_nj(collect_num_nj),
    
    .nj_data(nj_data ),
    .nj_add(nj_add),
    .nj_w_en(nj_w_en),
    .select(select),
    .nj_doing( nj_doing),
    .nj_collect_once( nj_collect_once)
);

nj_ram nj_ram(
    .wclk(CLK20M ),
    .waddr(nj_add ),
    .din_sync(nj_w_en ),
    .din(nj_data ),
    .rclk( CLK60M ),
    .re( re_nj ),
    .ra( radd_nj ),
    .dout( rdata_nj )
);

calculate_nj calculate_nj(
    .clk(CLK60M),
    .clk_20m(CLK20M),
    .rst(rst),
    .en_read(re_nj),
    .add_r(radd_nj),
    .data_r(rdata_nj),
    .collect_num( collect_num_nj),
//    .collectmark(collectmark),
    .bodymark( ),
//    .stopmark(stopmark),
    .fire_once( ),
    .now_num( now_num ), 
    .collect_once(collect_once),
    .collect_once_nj( nj_collect_once),
    .collect_achieve_nj(nj_collect_once ),
    .sweep_num( sweep_num), //test  sweep_num
    .sweep_en( sweep_write_en_nj ),
    .we_time(  ),
 //   .we_peak( we_peak),
    .add_time(  ),
//    .add_peak( add_peak),
    .data_time( nj_data_time ),
    .data_peak(  ),
 //   .calculate_once(calculate_once),
    .calculate_achieve( nj_calculate_achieve  ),
    .upload_nj( upload_nj )
);

collect collect(
    .rst(rst),
    .clk(CLK20M),
    .clk_smp(clk_adc_sample),
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .fire_once(fire_once),
    .nj_doing(nj_doing),
    .fire_achieve(fire_achieve),
    .now_num(now_num),
    .collect_num(collect_num),
    .delay_time(delay_time),
    
    .adc_ovr(adc_ovr),//when adc_ovr = 1 , overranged or underranged
    .adc_data(adc_data),
    .shdn(adc_shdn),//shdn=0,oe=0 -> enalbe ... shdn=1,oe=0 -> nap mode ... shdn=1,oe=1 -> sleep mode
    .oe(adc_oe),// adc IC output enable pin
    .adc_clk_ttl(adc_clk_ttl_t),//adc clk
    .adc_clk_oe(adc_clk_oe),// adc clk enable, =1 -> eanble
    .gain(gain),
    .we_un(we_un ),
    .wadd_un(wadd_un ),
    .data_un(data_un ),
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
    .sweep_num( sweep_num),//test sweep_num
    .sweep_en(sweep_write_en_t),
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
