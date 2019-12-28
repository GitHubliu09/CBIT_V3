`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// cmd_pic.v
// 处理上位机发来的命令和PIC发来的命令
//////////////////////////////////////////////////////////////////////////////////


module cmd_pic(
    input clk_24m,
    input clk_1m,
    input CLK60M,
    input CLK20M,
    input rst,
    input cmd_in,
    input [14:0]pic_add,
    input stop_message,
    
    inout [7:0]pic_data,
    
    output int,
//    output collectmark,
    output bodymark,
    output oncemark,
//    output stopmark,
    output [7:0]sweep_num,
    output reg change_message,
    output [15:0]message1,
    output [15:0]message2,
    output [15:0]message3,
    output [15:0]message4,
    output [15:0]message5,
    output [15:0]message6,
    output [15:0]message7,
    output [15:0]message8,
    output [15:0]message9,
    output [15:0]message10,
    output [15:0]message11,    
    output write_message_en,
    output send_m2,
    output [2:0]send_cmd,
    output speed,
    output m5m7_switch
    );
/******************* outside connect wire & reg *********************************/
reg send_m2 , send_m2_t1,send_m2_t2,send_m2_t3;
reg [2:0]send_cmd;
/******************* state reg ******************************/
reg [15:0]message1,message2,message3,message4,message5,message6,message7,message8,message9,message10,message11;
reg speed_t,m5m7_switch_t;
reg speed , m5m7_switch;//speed  0 -> 单倍速  1->   四倍速  ; switch 0 - > m5  , 1 -> m7
reg [15:0]ram_version , rom_version , self_test;
/******************* test wire ********************************************/
wire testpoint;
wire [7:0]data_t;
wire [14:0]add_t;
/******************* inside connect wire ******************************/
wire[15:0]rcvd_datareg;
wire rcv_cmd ,r_cmd_en  , stopint , write_message_en;
wire [7:0]pmd_t , data_pmd;
wire [5:0]r_cmd_add , write_message_add;

assign pic_data =  (pic_add[14:6] == 9'b000_1111_00) ? data_pmd : 8'bz;//0x0fxx
assign pmd_t = pic_data;


cmd_decoder cmd_decoder
(
    .md2udi( cmd_in ),// m2_cmd_in
    .reset_(~rst),
    .clock_m2rx24(clk_1m),
    .clock_system(clk_24m),
    .rcvd_datareg(rcvd_datareg),
    .wr_fifo_en(rcv_cmd)
//    .send_cmd(send_cmd),
//    .test(test)
);

cmd_store cmd_store(
    .wclk(clk_1m),
    .rclk(CLK60M ),
    .rst(rst),
    .rcv_cmd( rcv_cmd),
 //   .testpoint(testpoint),
    .rcvd_datareg(rcvd_datareg),
    .ren(r_cmd_en ),//r_cmd_en_test
    .add(r_cmd_add ),//r_cmd_add_test
    .data_out( data_pmd),//data_pmd_test
    .int( int),
    .stopint(stopint)
);

add_test add_test(
    .rst(rst),
    .clk_1m(clk_1m),
    
    .data(data_t),
    .add(add_t)
    );

add_decode add_decode(
    .rst(rst),
    .clk(CLK20M),
    .data_in(pmd_t ),//test  pmd_t
    .read_cmd_en(r_cmd_en),
    .read_cmd_add(r_cmd_add),
    .write_message_en( write_message_en),
    .write_message_add(write_message_add),
    .add_in( add_t),//test  pic_add
//    .collectmark(collectmark),
    .bodymark(bodymark),
    .oncemark(oncemark),
//    .stopmark(stopmark),
    .stopint(stopint),
    .testpoint(testpoint),
    .sweep_num(sweep_num)
);

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        message1 <= 16'h0000;
        message2 <= 16'h0000;
        message3 <= 16'h0000;
        message4 <= 16'h0000;
        message5 <= 16'h0000;
        message6 <= 16'h0000;
        message7 <= 16'h0000;
        message8 <= 16'h0000;
        message9 <= 16'h0000;
        message10 <= 16'h0000;
        message11 <= 16'h0000;
        speed_t <= 1'b1;
        m5m7_switch_t <= 1'b0;
        send_m2 <= 1'b0;
        send_cmd <= 3'd0;
    end
    else
    begin
         if(pic_add == 15'h0e00)
            message1[7:0] <= pmd_t;
         if(pic_add == 15'h0e01)
            message1[15:8] <= pmd_t;
         if(pic_add == 15'h0e02)
            message2[7:0] <= pmd_t;
         if(pic_add == 15'h0e03)
            message2[15:8] <= pmd_t;
         if(pic_add == 15'h0e04)
            message3[7:0] <= pmd_t;
         if(pic_add == 15'h0e05)
            message3[15:8] <= pmd_t;
         if(pic_add == 15'h0e06)
            message4[7:0] <= pmd_t;
         if(pic_add == 15'h0e07)
            message4[15:8] <= pmd_t;
         if(pic_add == 15'h0e08)
            message5[7:0] <= pmd_t;
         if(pic_add == 15'h0e09)
            message5[15:8] <= pmd_t;
         if(pic_add == 15'h0e0a)
            message6[7:0] <= pmd_t;
         if(pic_add == 15'h0e0b)
            message6[15:8] <= pmd_t;
         if(pic_add == 15'h0e0c)
            message7[7:0] <= pmd_t;
         if(pic_add == 15'h0e0d)
            message7[15:8] <= pmd_t;
         if(pic_add == 15'h0e0e)
            message8[7:0] <= pmd_t;
         if(pic_add == 15'h0e0f)
            message8[15:8] <= pmd_t;
         if(pic_add == 15'h0e10)
            message9[7:0] <= pmd_t;
         if(pic_add == 15'h0e11)
            message9[15:8] <= pmd_t;
         if(pic_add == 15'h0e12)
            message10[7:0] <= pmd_t;
         if(pic_add == 15'h0e13)
            message10[15:8] <= pmd_t;
         if(pic_add == 15'h0e14)
            message11[7:0] <= pmd_t;
         if(pic_add == 15'h0e15)
            message11[15:8] <= pmd_t;
         if(pic_add == 15'h0e16)
            speed_t <= pmd_t;
         if(pic_add == 15'h0e17)
            m5m7_switch_t <= pmd_t;
         
         if(pic_add == 15'h0e18)
         begin
            send_m2 <= 1'b1;
            send_cmd <= 3'd1 ; //test pmd_t
         end
         else if(send_m2_t2)
            send_m2 <= 1'b0;
    end
end

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        send_m2_t1 <= 1'b0;
        send_m2_t2 <= 1'b0;
        send_m2_t3 <= 1'b0;
    end
    else
    begin
        send_m2_t1 <= send_m2;
        send_m2_t2 <= send_m2_t1;
        send_m2_t3 <= send_m2_t2;
    end
end

always@(posedge bodymark or posedge rst)
begin
    if(rst)
    begin
        speed <= 1'b1;
        m5m7_switch <= 1'b0;
    end
    else
    begin
        speed <= speed_t;
        m5m7_switch <= m5m7_switch_t;
    end
end


endmodule
