`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////


module write_fifo(
    input clk,
    input clk_20m,
    input rst,
    input [15:0]self_version,
    input speed,
    input m5m7_switch,
    input [2:0]send_cmd,
    input send_m2,
    input empty,
    input full,
    output wr_clk,
    output wr_en,
    output [15:0] din
    );

reg [15:0]counter = 16'd0;
reg [15:0]data = 16'd0;
reg en = 1'b0;
reg start , stop;
reg [3:0] send_cmd_t1,send_cmd_t2;

assign wr_clk = clk;
assign wr_en = en;
assign din = data;

always@(posedge clk_20m or posedge rst)
begin
    if(rst)
    begin
        send_cmd_t1 <= 4'd0;
        send_cmd_t2 <= 4'd0;
        start <= 1'b0;
    end
    else
    begin
        send_cmd_t1 <= send_cmd;
        send_cmd_t2 <= send_cmd_t1;
        if(send_m2)
        begin
            start <= 1'b1;
        end
        else if(stop)
            start <= 1'b0;
    end
end

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        en <= 1'b0;
        data <= 16'd0;
        stop <= 1'b0;
    end
    else
    begin
        if(stop)
            stop <= 1'b0;
        else
        if(!full && start)
        begin
        case(send_cmd)
        4'd1:
        begin
            if(counter == 16'd2)
            begin
                en <= 1'b1;
                data <= 16'hc891;//0xc891
            end
            if(counter == 16'd3)
            begin
                en <= 1'b1;
                if(speed == 1'b0 && m5m7_switch == 1'b0)
                    data <= 16'h0105;
                else if(speed == 1'b1 && m5m7_switch == 1'b0)
                    data <= 16'h0405;
                else if(speed == 1'b0 && m5m7_switch == 1'b1)
                    data <= 16'h0107;
                else if(speed == 1'b1 && m5m7_switch == 1'b1)
                    data <= 16'h0407;
            end
            if(counter == 16'd4)
            begin
                en <= 1'b0;
                counter <= 16'd0;
                stop <= 1'b1;
            end
            else
                counter <= counter + 1'b1;
        end
        
        4'd2:
         begin
            if(counter == 16'd2)
            begin
                en <= 1'b1;
                data <= 16'hc894;//0xc894
            end
            if(counter == 16'd3)
            begin
                en <= 1'b1;
                if(speed == 1'b0 && m5m7_switch == 1'b0)
                    data <= 16'h0105;
                else if(speed == 1'b1 && m5m7_switch == 1'b0)
                    data <= 16'h0405;
                else if(speed == 1'b0 && m5m7_switch == 1'b1)
                    data <= 16'h0107;
                else if(speed == 1'b1 && m5m7_switch == 1'b1)
                    data <= 16'h0407;
            end
            if(counter == 16'd4)
            begin
                en <= 1'b0;
                counter <= 16'd0;
                stop <= 1'b1;
            end
            else
                counter <= counter + 1'b1;
        end
        
        4'd3:
         begin
            if(counter == 16'd2)
            begin
                en <= 1'b1;
                data <= 16'hc895;//0xc895
            end
            if(counter == 16'd3)
            begin
                en <= 1'b1;
                if(speed == 1'b0 && m5m7_switch == 1'b0)
                    data <= 16'h0105;
                else if(speed == 1'b1 && m5m7_switch == 1'b0)
                    data <= 16'h0405;
                else if(speed == 1'b0 && m5m7_switch == 1'b1)
                    data <= 16'h0107;
                else if(speed == 1'b1 && m5m7_switch == 1'b1)
                    data <= 16'h0407;
            end
            if(counter == 16'd4)
            begin
                en <= 1'b0;
                counter <= 16'd0;
                stop <= 1'b1;
            end
            else
                counter <= counter + 1'b1;
        end
        
        4'd4:
         begin
            if(counter == 16'd2)
            begin
                en <= 1'b1;
                data <= 16'hc897;//0xc897
            end
            if(counter == 16'd3)
            begin
                en <= 1'b1;
                if(speed == 1'b0 && m5m7_switch == 1'b0)
                    data <= 16'h0105;
                else if(speed == 1'b1 && m5m7_switch == 1'b0)
                    data <= 16'h0405;
                else if(speed == 1'b0 && m5m7_switch == 1'b1)
                    data <= 16'h0107;
                else if(speed == 1'b1 && m5m7_switch == 1'b1)
                    data <= 16'h0407;
            end
            if(counter == 16'd4)
            begin
                en <= 1'b0;
                counter <= 16'd0;
                stop <= 1'b1;
            end
            else
                counter <= counter + 1'b1;
        end
        
        4'd5:
        begin
            if(counter == 16'd2)
            begin
                en <= 1'b1;
                data <= self_version;
            end
            if(counter == 16'd3)
            begin
                en <= 1'b0;
                counter <= 16'd0;
                stop <= 1'b1;
            end
            else
                counter <= counter + 1'b1;
        end
        
        4'd6:
        begin
            if(counter == 16'd2)
            begin
                en <= 1'b1;
                data <= 16'hc8c8;
            end
            if(counter == 16'd3)
            begin
                en <= 1'b1;
                data <= 16'hc0aa;
            end
            if(counter == 16'd4)
            begin
                en <= 1'b1;
                data <= 16'h3f55;
            end
            if(counter == 16'd5)
            begin
                en <= 1'b1;
                data <= 16'hf731;
            end
            if(counter == 16'd6)
            begin
                en <= 1'b1;
                data <= 16'h8000;
            end
            if(counter == 16'd7)
            begin
                en <= 1'b1;
                data <= 16'h0000;
            end
            if(counter == 16'd8)
            begin
                en <= 1'b1;
                data <= 16'hffff;
            end
            if(counter == 16'd9)
            begin
                en <= 1'b1;
                data <= 16'h08ce;
            end
            
            if(counter == 16'd10)
            begin
                en <= 1'b0;
                counter <= 16'd0;
                stop <= 1'b1;
            end
            else
                counter <= counter + 1'b1;
        end
        
        endcase
     
        end
    end
end


endmodule
