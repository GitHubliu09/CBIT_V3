`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// address[13:11] control wire
// 
//////////////////////////////////////////////////////////////////////////////////


module add_decode(
    input rst,
    input clk,
    input [8:0] data_in,//data input
    input [14:0] add_in,//address input
    output read_cmd_en,//读命令使能
    output [5:0]read_cmd_add,//读命令地址
    output write_message_en,//写数据使能
    output [5:0]write_message_add,//写数据地址
    output bodymark,
    output oncemark,        //齿牙信号
    output collectmark,      //上传数据命令
//    output stopmark,         //停止采集信号
    output stopint,          //停止中断
    output testpoint,       //测试地址
    output [7:0]sweep_num        //上传哪个波形，=0 -》上传泥浆波
    );

reg bodymark,oncemark,collectmark,stopint,testpoint,read_cmd_en,write_message_en;
reg [5:0]read_cmd_add,write_message_add;
wire bodymark_t,oncemark_t,collectmark_t,stopint_t,testpoint_t,read_cmd_en_t,write_message_en_t;
wire [5:0]read_cmd_add_t,write_message_add_t;



//    reg stop = 1'b0;
    reg[7:0] sweep_num_t = 8'd1;
    
/********************************* control wire ***************************************************/    
assign   collectmark_t =  rst ? 1'b0 : ( add_in == 15'b000_1000_0000_0100 ? 1'b1 : 1'b0);//0x0804s
assign   bodymark_t = rst ? 1'b0 : (add_in == 15'b000_1000_0000_0001 ? 1'b1 : 1'b0);  //0x0801
assign   oncemark_t =  rst ? 1'b0 : (add_in == 15'b000_1000_0000_0010 ? 1'b1 : 1'b0);//0x0802
//assign   stopmark = stop;//0x0808
assign   stopint_t = rst ? 1'b0 :(add_in == 15'b000_1001_0000_1111 ? 1'b1 : 1'b0);//0x090f

assign   read_cmd_en_t = rst ? 1'b0 : (add_in[14:6] == 9'b000_1111_00 ? 1'b1 : 1'b0);//0x0fxx 当高9位为3C时，读取命令ram，低6位中，最高一位为选择位，选择读取命令的高八位还是第八位，剩下5位为地址
assign   read_cmd_add_t = rst ? 6'd0 : ( read_cmd_en ? add_in[5:0] : 6'bz);

assign   testpoint_t = rst ? 1'b0 :(add_in == 15'b111_1111_1111_1111 ? 1'b1 : 1'b0);//0xffff

assign   write_message_en_t =  rst ? 1'b0 : (add_in[14:6] == 9'b000_1110_00 ? 1'b1 : 1'b0);//0x0exx 当高9位为0exx时，代表开始写messege数据。
assign   write_message_add_t = rst ? 6'b0 : (write_message_en ? add_in[5:0] : 6'bz);
/********************************* parameter wire **************************************************************/
assign sweep_num = sweep_num_t;//0x0817 

always@(posedge clk or posedge rst)
begin
    if(rst)
        sweep_num_t <= 8'd1;
    else 
    begin
        if(add_in == 15'b000_1000_0001_0111)//sweep_num  8bits 0x0817
            sweep_num_t <= data_in;
    end
end

always@(negedge clk or posedge rst)
begin
    if(rst)
    begin
        bodymark <= 1'b0;
        oncemark <= 1'b0;
        collectmark <= 1'b0;
        stopint <= 1'b0;
        testpoint <= 1'b0;
        read_cmd_en <= 1'b0;
        read_cmd_add <= 6'd0;
        write_message_en <= 1'b0;
        write_message_add <= 6'd0;
    end
    else
    begin
        bodymark <= bodymark_t;
        oncemark <= oncemark_t;
        collectmark <= collectmark_t;
        stopint <= stopint_t;
        testpoint <= testpoint_t;
        read_cmd_en <= read_cmd_en_t;
        read_cmd_add <= read_cmd_add_t;
        write_message_en <= write_message_en_t;
        write_message_add <= write_message_add_t;
    end
end
    
endmodule
