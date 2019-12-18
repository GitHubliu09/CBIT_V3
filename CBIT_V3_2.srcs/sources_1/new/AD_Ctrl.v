`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/06/20 15:32:36
// Design Name: 
// Module Name: ad_control
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


module AD_Ctrl(
ad_clk,
rst,
//conv_start,
ad_data,
shdn,
//acq_num,
//reg_model,
wr_ram_data0,
wr_ram_data1,
waddr0,
waddr1,
wr_sync,
//oe_n,
ch_done
    );
    
input ad_clk,rst;
//input conv_start;
reg conv_start = 1;
input [13:0]ad_data;
//input [13:0]acq_num;
//input [1:0] reg_model;
output wire [7:0]wr_ram_data0;
output wire [7:0]wr_ram_data1;
output wire [13:0]waddr0;
output wire [13:0]waddr1;
output reg wr_sync;
output shdn;
//output oe_n; 
output reg ch_done;  
reg [13:0] acq_cnt;
reg [1:0] state;
reg [2:0] delay_cnt;
parameter IDLE = 2'b00;
parameter DELAY = 2'b01;
parameter ACQ = 2'b10;
parameter DONE = 2'b11;
reg [13:0] ad_data_reg;
reg [1:0] wait_done;

parameter acq_num = 9'd400;
parameter reg_model = 2'b00;
assign waddr0 = acq_cnt;
assign waddr1 = acq_cnt;
assign shdn = 1'b0;
//assign oe_n = 1'b0;
assign wr_ram_data0 = ad_data_reg[7:0];
assign wr_ram_data1 = {reg_model,ad_data_reg[13:8]};

always @(negedge ad_clk or posedge rst)
begin
    if(rst)
        ad_data_reg <= 14'b0;
    else
        ad_data_reg <= ad_data;
end

always@(posedge ad_clk or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
        acq_cnt <= 14'b0;
        delay_cnt <= 3'd0;
        wr_sync <= 1'b0;
        ch_done <= 1'b0;
        conv_start <= 1'b1;
    end
    else
        case(state)
            IDLE:                                                    
            begin
                acq_cnt <= 14'b0;
                delay_cnt <= 3'd0;
                wr_sync <= 1'b0;
                ch_done <= 1'b0;
                if(conv_start)
                    state <= DELAY;
                else
                    state <= IDLE;
            end
            DELAY:
            begin
                 delay_cnt <=delay_cnt + 1'b1;
                 if(delay_cnt == 3'd4)
                 begin
                     state <= ACQ;
                     delay_cnt <= 3'd0;
                     wr_sync <= 1'b1;
                 end
                 else
                     state <= DELAY;
             end
             ACQ:
             begin
                acq_cnt <= acq_cnt + 1'b1;
                if(acq_cnt == acq_num)
                begin
                    state <= DONE;
                    ch_done <= 1'b1;
                    conv_start <= 1'b0;             ///////////////////////
                 end 
                 else
                 begin
                    state <= ACQ;
                 end  
             end
              DONE:                                              
           begin
                state <= IDLE;
                wr_sync <= 1'b0;
                acq_cnt <= 14'b0; 
                ch_done <= 1'b0;
           end
           default: 
           begin
                state <= IDLE;
                wr_sync <= 1'b0;
                acq_cnt <= 14'b0; 
                ch_done <= 1'b0;
           end                                
        endcase
 end      
endmodule
