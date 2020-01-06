`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  test change_ram module
//////////////////////////////////////////////////////////////////////////////////


module test_change_ram(
    input clk,
    input rst,
    output write_ram_done,
    output write_en,
    output [13:0]write_add,
    output [15:0]write_data
    );

reg [15:0]cnt;
reg [13:0]add;
reg [15:0]data;
reg en , done;

assign write_ram_done = done;
assign write_en = en;
assign write_data = data;
assign write_add = add;

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        cnt <= 16'd0;
        add <= 14'd0;
        data <= 16'd0;
        en <= 1'b0;
        done <= 1'b0;
    end
    else
    begin
        cnt <= cnt + 1'b1;
        if(cnt < 16'd453)
        begin
            en <= 1'b1;
            add <= cnt;
            data <= cnt;
        end
        else if( cnt >= 16'd32768 && cnt <= 16'd33221)
        begin
            en <= 1'b1;
            add <= cnt - 16'd32768;
            data <= cnt;
        end
        else
        begin
            en <= 1'b0;
            add <= 13'd0;
            data <= 16'd0;
        end
        
        if(cnt == 16'd300)
            done <= 1'b1;
        else if(cnt == 16'd454)
            done <= 1'b0;
        else if( cnt == 16'd33100)
            done <= 1'b1;
        else if(cnt == 16'd33222)
            done <= 1'b0;
    end
end


endmodule
