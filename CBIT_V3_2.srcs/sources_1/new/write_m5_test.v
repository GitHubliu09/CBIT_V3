`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/30 10:05:05
// Design Name: 
// Module Name: write_m5_test
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


module write_m5_test(
    input clk,
    input rst,
    input int,
    input [7:0]data_in,
    output reg[15:0]data_out,
    output reg wen,
    output reg ren,
    output reg [5:0]add,
    output start_send
    
    );

reg [5:0]add_cnt;
reg[1:0]state;
reg start_sendt = 0;
reg start_send1 = 0;

parameter IDLE = 2'b00;
parameter READ = 2'b01;
parameter SEND = 2'b10;
parameter DONE = 2'b11;

assign start_send = start_send1;

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        add_cnt <= 6'd0;
        state <= IDLE;
        data_out <= 16'd0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
            start_sendt <= 1'b0;
            wen <= 1'b0;
            ren <= 1'b0;
            add <= 6'd0;
            data_out <= 16'd0;
            if(int)
            begin
                state <= READ;
                ren <= 1'b1;
                wen <= 1'b1;
                data_out <= {2'b00,add,data_in};
            end
            else
                state <= IDLE;
        end
        
        READ:
        begin
            wen <= 1'b1;
            ren <= 1'b1;
            if(add == 6'b111111)
                state <= SEND;
            else
            begin
                if( add < 6'd24 | (add > 6'b100000 & add <= 6'b110111))
                    data_out <= {2'b00,add,data_in};
                else data_out <= {2'b00,add,8'h0f};
                add <= add + 1'b1;
            end
        end
        
        SEND:
        begin
            start_sendt <= 1'b1;
            wen <= 1'b0;
            ren <= 1'b0;
            add <= 6'd0;
            data_out <= 16'd0;
            state <= DONE;
        end
        
        DONE:
        begin
            start_sendt <= 1'b1;
            state <= IDLE;
        end
        default:
        begin
            start_sendt <= 1'b0;
            wen <= 1'b0;
            ren <= 1'b0;
            add <= 6'd0;
            data_out <= 16'd0;
            state <= IDLE;
        end
        endcase
    end
end

always@(posedge clk or posedge rst)
begin
    if(rst)
    start_send1 <= 1'b0;
    else 
    begin
    if(start_sendt)
        start_send1 <= 1'b1;
    if(start_send1)
        start_send1 <= 1'b0;
    end
end

endmodule
