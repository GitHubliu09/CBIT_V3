`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//m2是双向数据通道主要用于下传命令和控制参数
//m2下行 20.883kbs，上传 41.666kbs
//m5与m7是单向数据传输通道，井下数据上传，4倍模式速度 375kbs，单倍速模式 速度93.75kbs
//
//////////////////////////////////////////////////////////////////////////////////

module Ultrasonic_TOP(
    input clk,
//    input rst,
    input m2_cmd_in,
    input [14:0]pma,        //PMP地址总线
    inout [7:0]pmd,         //pmp数据总线
    input [13:0]adc_data,
    input adc_ovr,
    output adc_shdn,
    output adc_oe,
    output adc_clk_ttl,
    output adc_clk_oe,
    output [1:0]sig_mux,    //模拟通道选择
    output m5_bzo,          //m5上传通道的正负信号
    output m5_boo,
    output m7_bzo,
    output m7_boo, 
    output [4:0]gain,
    output m2_bzo,
    output m2_boo,

    output int_0,//中断信号
    output uart_rx,//串口，pic与fpga通信
    output uart_tx,
    
    output oe_15,//15通道使能信号
    output oe_20,//20通道使能信号
    output oe_nj,//泥浆通道使能信号
    output fire_a,//发射控制信号
    output fire_b,
    output fire_c,
    output fire_d
    );
    
wire rst;
/******************* error wire *******************************/
wire error_fire;
/****************** clock wire *******************************/
wire CLK20M,CLK60M,CLK24M,clk_24m,CLK10M;
wire clk_1m;                      //downgoing sampling clock
wire clk_2m;
wire clk_83p33k;                    //m2 upgoing encoding clock
wire clk_41p667k;                 //downgoing decoding clock
wire clk_187p5k;                  //upgoing slow encoding clock
wire clk_750k;                       //upgoing fast encoding clock
wire clk_100k;
wire clk_5p86k;
wire clk_23p43k;
wire clk_12m;
/********************* fire wire *************************/
wire fire_a,fire_b,fire_c,fire_d;
///******************* connect wire **************************/
wire sendmark,bodymark,oncemark , fire_once , fire_achieve , calculate_once , calculate_achieve , sweep_write_en , we , change_message , stop_message , send_m2;
wire [7:0]sweep_num;
wire [13:0]wadd ;
wire sweep_add;
wire [15:0]data_time , data_peak , sweep_data;//到时、幅值、扫描数据
wire [2:0]send_cmd;
wire clk_adc_sample;
wire [15:0]nj_data_time;
/******************** state wire ***************************/
wire speed , m5m7_switch , trans;
wire [15:0]message1,message2,message3,message4,message5,message6,message7,message8,message9,message10,message11;
parameter self_version = 16'h0000;
wire [7:0]now_num,now_num_d;
/******************** test wire ****************************************/
wire test1 , test2 , cmd_t;
wire [1:0]state;
reg test_reg = 1'b0;
wire collect_achieve;
wire test_cmd,test_fire,test_edib,test_edib2,test_count,test_adc,test_adc2;
reg testtest;
/******************* test output ********************************/
//assign uart_rx = bodymark;
//assign uart_tx = oncemark;
/********************** connect between modules***************************************/
assign clk_24m = CLK24M;
//assign fire_a = collectmark;
//assign fire_b = bodymark;
//assign fire_c = oncemark;
//assign fire_d = stopmark;
/************************* control wire ***************************/

/************************* test wire ****************************/
assign test1 = wadd == 13'd100 ? 1'b1:1'b0;
assign test2 = now_num_d == 8'd250 ? 1'b1:1'b0;
/*********************** 需要放到module里面 *****************************************************/
assign gain[0] = CLK20M;
assign gain[1] = oe_15;
assign gain[2] = bodymark;
assign gain[3] = oncemark;
assign gain[4] = sweep_write_en;
//assign sig_mux = 2'b01;//00->GND , 01->1.5  , 10->2.0 , 11->mud
/************************* parameter ***********************************************************/
parameter delay_time = 8'd100;//delay time us //35//124//
parameter collect_num = 14'd2000;//colect number 一次回波ADC采集的点数//2440
parameter extract_num = 8'd2; //抽取位数
parameter send_data_num = 16'd452;//上传数据个数
assign clk_adc_sample = CLK20M;


clk_wiz_0 pll (.reset(0), .clk_in1(clk), .clk_out1(CLK20M), .clk_out2( CLK60M ),.clk_out3(CLK24M),.clk_out4(CLK10M),
 .locked(lock)
);//閿佺浉鐜骇鐢熸椂閽?

clk_div clk_div(
    .clock_24m(clk_24m),
    .rst( rst),
    .clk_1m(clk_1m),
    .clk_2m(clk_2m),
    .clk_5p86k(clk_5p86k),
    .clk_41p667k(clk_41p667k),
    .clk_187p5k(clk_187p5k),
    .clock_100k(clk_100k),
    .clk_83p3k(clk_83p33k),
    .clk_750k(clk_750k),
    .clk_23p43k(clk_23p43k),
    .clk_12m(clk_12m)
);//鍒嗛

cmd_test cmd_test(
    .clk(clk_41p667k ),
    .rst(rst),
    .cmd_out(cmd_t)
);

cmd_pic cmd_pic(
    .clk_24m ( clk_24m),
    .clk_1m ( clk_1m),
    .CLK60M(CLK60M),
    .CLK20M(CLK20M),
    .rst(rst),
    .cmd_in(~m2_cmd_in),//test   ~m2_cmd_in  //因为电路图设计原因，需要将输入信号反向输入到该模块中。  //此时输入电平正好与规定电平相反  //姝ゆ椂杈撳叆鐢靛钩姝ｅソ涓庤瀹氱數骞崇浉鍙?
    .pic_add(pma),
    .stop_message(stop_message),
    .nj_data_time(nj_data_time),
    
    .pic_data(pmd),
    
    .int(int_0),
    .sendmark( sendmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
//    .stopmark(stopmark),
    .sweep(sweep_num),
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
    .write_message_en( ),
    .send_m2( send_m2),
    .send_cmd( send_cmd),
    .speed(speed),
    .m5m7_switch(m5m7_switch),
    .trans(trans),
    .test(test_cmd)
);

count_mod count_mod(
    .clk(CLK20M),
    .rst(rst),
    .bodymark(bodymark),
    .oncemark(oncemark),
    .num(now_num),
    .num_d(now_num_d),
    .test(test_count)
    );

fire_all fire_all(
    .CLK20M(CLK20M),
    .rst(rst),
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
//    .stopmark(stopmark),
    .collect_achieve(collect_achieve),
    .now_num(now_num_d),
    .trans(trans),
    
    .oe_15(oe_15),
    .oe_20(oe_20),
    .oe_nj(oe_nj),
    .fire_a(fire_a),
    .fire_b(fire_b),
    .fire_c(fire_c),
    .fire_d(fire_d),
    .fire_once(fire_once),
    .fire_achieve(fire_achieve),
    .error_fire(error_fire),
    .state(state),
    .test_fire(test_fire)
);

adc_and_caculate adc_and_caculate(
    .CLK20M(CLK20M),
    .CLK60M(CLK60M),
    .clk_adc_sample(clk_adc_sample),
    .rst(rst),
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .fire_once(fire_once),
    .fire_achieve(fire_achieve),
    .now_num(now_num_d),
//    .stopmark(stopmark),
    .adc_ovr(adc_ovr),
    .adc_data(adc_data),
    .sweep_num(sweep_num),
    .collect_num(collect_num),
    .delay_time(delay_time),
    
    .select(sig_mux ),
    .adc_shdn(adc_shdn),
    .adc_oe(adc_oe),
    .adc_clk_ttl(adc_clk_ttl),
    .adc_clk_oe(adc_clk_oe),
//    .gain(gain),      //test
    .we_out( we),
    .wadd_out( wadd),
    .data_time(data_time ),
    .data_peak(data_peak ),
    .sweep_write_en( sweep_write_en),
    .sweep_add(sweep_add ),
    .sweep_data( sweep_data),
    .nj_data_time(nj_data_time),
//    .calculate_once(calculate_once),
    .collect_achieve(collect_achieve),
    .calculate_achieve(calculate_achieve),
    .test(test_adc),
    .test2(test_adc2)
    
);

edib edib(
    .CLK60M(CLK60M),
    .CLK20M(CLK20M),
    .clk_1m(clk_1m),
    .clk_2m(clk_2m),
    .clk_24m(clk_24m),
    .clk_750k(clk_750k),
    .clk_23p43k(clk_23p43k),
    .clk_187p5k(clk_187p5k),
    .clk_5p86k(clk_5p86k),
    .clk_41p667k(clk_41p667k),
    .clk_83p33k(clk_83p33k),
    .rst(rst),
    .sendmark(sendmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
//    .stopmark(stopmark),
    .we(we),
    .wadd(wadd),
    .data_time( data_time),
    .data_peak(data_peak),
    .calculate_achieve(calculate_achieve),
    .now_num(now_num_d),
    .sweep_en(sweep_write_en),
    .sweep_add(sweep_add),
    .sweep_data(sweep_data),
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
    .self_version(self_version),
    .speed(speed),
    .m5m7_switch(m5m7_switch),
    .send_m2(send_m2),
    .send_cmd(send_cmd),
    .extract_num(extract_num),
    .send_data_num(send_data_num),
    
    .stop_message(stop_message),
    .m5_bzo(m5_bzo),
    .m5_boo(m5_boo),
    .m7_bzo( m7_bzo),
    .m7_boo( m7_boo),
    .m2_bzo(m2_bzo),
    .m2_boo(m2_boo),
    .test(test_edib),
    .test2(test_edib2)
);


endmodule
