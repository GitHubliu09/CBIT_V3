`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/28 10:29:46
// Design Name: 
// Module Name: add_test
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


module add_test(
    input rst,
    input clk_1m,
    
    output [7:0]data,
    output [14:0]add
    );


reg [7:0]data_t = 8'b0;
reg [14:0]add_t = 15'd0;

reg [5:0]cnt_t = 6'd0;
reg [11:0]cnt = 12'd0;

reg start = 1'b0;

assign data = data_t;
assign add = add_t;

always @(posedge clk_1m or posedge rst)
begin
    if(rst)
    begin
        start <= 1'b0;
        cnt_t <= 6'b0;
    end
    else
    begin
        if(cnt_t == 6'd50)
        begin
            start <= 1'b1;
            cnt_t <= 6'd50;
        end
        else
            cnt_t <= cnt_t + 1'b1;
    end
end

always@(posedge clk_1m or posedge rst)
begin
    if(rst)
    begin
        data_t <= 8'd0;
        add_t <= 15'd0;
        cnt <= 12'd0;
    end
    else
    begin
    if(start)
        if(cnt == 12'd300)
            cnt <= 12'd0;
        else
        begin
            cnt <= cnt + 1'b1;
            if(cnt == 12'd100)
                add_t <= 15'h0804;
            if(cnt == 12'd101)
                add_t <= 15'h0801;
            if(cnt == 12'd102)
                add_t <= 15'h0802;
            if(cnt == 12'd103)
                add_t <= 15'h0000;
            
        end
    end
end


endmodule
