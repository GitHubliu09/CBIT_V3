`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  cmd_store.v
// 将上位机发送的命令存入两个ram，等待pic读取
//////////////////////////////////////////////////////////////////////////////////


module cmd_store(
    input wclk,
    input rclk,
    input rst,
    input rcv_cmd,
 //   input testpoint,
    input [15:0]rcvd_datareg,
    input ren,
    input [5:0]add,
    output [7:0]data_out,
    input stopint,
    output reg int

    );

//wire wclk;
wire [7:0]data_low,data_high;

wire sbiterr1,dbiterr1;
wire [13:0]rdaddrecc1;
wire sbiterr2,dbiterr2;
wire [13:0]rdaddrecc2;

reg [7:0]din_high,din_low;
reg wen;
reg rcv_c;
reg int_t;
reg [4:0]waddr;
reg [4:0]counter;
reg [1:0]state;
reg test_cnt;

parameter IDLE = 2'b00;
parameter SAVE = 2'b01;
parameter DONE = 2'b10;

parameter num23 = 5'b10101;
parameter num3 = 5'b00010;
parameter num4 = 5'b00011;

assign data_out = add[5] ? data_high : data_low;

//test ---  change wclk to rclk
//assign wclk = rclk;

always@(posedge wclk or posedge rst)
begin
    if(rst)
    begin
        int_t <= 1'b0;
        wen <= 1'b0;
        waddr <= 5'd0;
        counter <= 5'd0;
        state <= IDLE;
        din_high <= 8'd0;
        din_low <= 8'd0;
        rcv_c <= 1'b0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
            int_t <= 1'b0;
            waddr <= 5'd0;
            rcv_c <= 1'b0;
            test_cnt <= 1'b1;
            //test
//            if(testpoint)
//            begin
//                state <= SAVE;
//                counter <= num23;
//                din_high <= 8'b0001_0001;
//                din_low <= 8'b0001_0001;
//                wen <= 1'b1;
//            end
//            else
//                state <= IDLE;
                
            
            
            //  usefull
            if(rcv_cmd)
            begin
                state <= SAVE;
                din_high <= rcvd_datareg[15:8];
                din_low <= rcvd_datareg[7:0];
                rcv_c <= 1'b1;
                wen <= 1'b1;
                if(rcvd_datareg[7:0] == 8'b0000_0011)
                    counter <= num23;
                else if(rcvd_datareg[7:0] == 8'b0000_1010)
                    counter <= num3;
                else if(rcvd_datareg[7:0] == 8'b0011_0011 || rcvd_datareg[7:0] == 8'b0011_0100)
                    counter <= num4;
                else counter <= 5'd0;
            end
            else
                state <= IDLE;
        end
        
        SAVE:
        begin
        //  test
//        if(counter == 5'd0)
//            state <= DONE;
//        else
//        begin
//            wen <= 1'b1;
//            test_cnt = test_cnt + 1'b1;
//            if(test_cnt)
//            begin
//                counter <= counter - 1'b1;
//                waddr <= waddr + 1'b1;
//                din_high <= din_high + 8'b0001_0001;
//                din_low <= din_low + 8'b0001_0001;
//            end
//        end
        
        
        
            //      usefull
            if(counter == 5'd0)
                state <= DONE;
            else
            begin
                wen <= 1'b1;
                rcv_c <= 1'b0;
                if(rcv_cmd)
                begin
                    counter <= counter - 1'b1;
                    waddr <= waddr + 1'b1;
                    din_high <= rcvd_datareg[15:8];
                    din_low <= rcvd_datareg[7:0];
                    rcv_c <= 1'b1;
                end
            end
        end
        
        DONE:
        begin
            int_t <= 1'b1;
            wen <= 1'b0;
            state <= IDLE;
            rcv_c <= 1'b0;
        end
        
        default:
        begin
            int_t <= 1'b0;
            wen <= 1'b0;
            waddr <= 5'd0;
            counter <= 5'd0;
            state <= IDLE;
        end
        endcase
    end 
end

always@(posedge wclk or posedge rst)
begin
    if(rst)
        int <= 1'b0;
    else 
    begin
    if(int_t)
        int <= 1'b1;
    if(stopint)
        int <= 1'b0;
//    if(int)
//        int <= 1'b0;
    end
end



blk_mem_gen_3 ram3(
.clka(~wclk),
.ena(wen),
.wea(wen),
.addra(waddr),
.dina(din_high),
.clkb(rclk),
.enb(ren),
.addrb(add[4:0]),
.doutb(data_high),
.sbiterr( sbiterr1),
.dbiterr( dbiterr1),
.rdaddrecc(rdaddrecc1 )
);

blk_mem_gen_4 ram4(
.clka(~wclk),
.ena(wen),
.wea(wen),
.addra(waddr),
.dina(din_low),
.clkb(rclk),
.enb(ren),
.addrb(add[4:0]),
.doutb(data_low),
.sbiterr( sbiterr2),
.dbiterr( dbiterr2),
.rdaddrecc( rdaddrecc2)
);

endmodule
