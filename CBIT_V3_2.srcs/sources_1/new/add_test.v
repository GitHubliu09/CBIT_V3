`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 测试接受PIC命令，
//////////////////////////////////////////////////////////////////////////////////


module add_test(
    input rst,
    input clk_1m,
    
    output [7:0]data,
    output [14:0]add
    );

reg [5:0]state;
parameter IDLE = 6'b000001;
parameter SEND = 6'b000010;
parameter BODY = 6'b000100;
parameter ONCE = 6'b001000;
parameter SENDOTHERS = 6'b010000;
parameter WAIT = 6'b100000;

reg [7:0]data_t = 8'b0;
reg [14:0]add_t = 15'd0;

reg [5:0]cnt_t = 6'd0;
reg [11:0]cnt = 12'd0;
reg [7:0]num = 8'd0;

assign data = data_t;
assign add = add_t;

always@(posedge clk_1m or posedge rst)
begin
    if(rst)
    begin
        data_t <= 8'd0;
        add_t <= 15'd0;
        cnt <= 12'd0;
        num <= 8'd0;
        state <= IDLE;
    end
    else
    begin
    case(state)
        IDLE:
        begin
            add_t <= 15'd0;
            state <= BODY;
        end
        SEND:
        begin
            add_t <= 15'h0804;
            state <= BODY;
        end
        BODY:
        begin
            add_t <= 15'h0801;
            num <= 8'd0;
            state <= ONCE;
        end
        ONCE:
        begin
            add_t <= 15'h0802;
            num <= num + 1'b1;
            state <= SENDOTHERS;
        end
        SENDOTHERS:
        begin
            state <= WAIT;
            if(num == 8'd3)
                add_t <= 15'h0000;
            else
                add_t <= 15'h0000;
        end
        WAIT:
        begin
            add_t <= 15'd0;
            if(cnt == 12'd400)
            begin
                cnt <= 12'd0;
                if(num == 8'd250) // test /////////// test
                    state <= SEND;
                else
                    state <= ONCE;
            end
            else
                cnt <= cnt + 1'b1;
        end
        default:
        begin
            state <= IDLE;
        end
    endcase
    end
end


endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 测试接受PIC命令，
//////////////////////////////////////////////////////////////////////////////////


module add_test(
    input rst,
    input clk_1m,
    
    output [7:0]data,
    output [14:0]add
    );

reg [5:0]state;
parameter IDLE = 6'b000001;
parameter SEND = 6'b000010;
parameter BODY = 6'b000100;
parameter ONCE = 6'b001000;
parameter SENDOTHERS = 6'b010000;
parameter WAIT = 6'b100000;

reg [7:0]data_t = 8'b0;
reg [14:0]add_t = 15'd0;

reg [5:0]cnt_t = 6'd0;
reg [11:0]cnt = 12'd0;
reg [7:0]num = 8'd0;

assign data = data_t;
assign add = add_t;

always@(posedge clk_1m or posedge rst)
begin
    if(rst)
    begin
        data_t <= 8'd0;
        add_t <= 15'd0;
        cnt <= 12'd0;
        num <= 8'd0;
        state <= IDLE;
    end
    else
    begin
    case(state)
        IDLE:
        begin
            add_t <= 15'd0;
            state <= BODY;
        end
        SEND:
        begin
            add_t <= 15'h0804;
            state <= BODY;
        end
        BODY:
        begin
            add_t <= 15'h0801;
            num <= 8'd0;
            state <= ONCE;
        end
        ONCE:
        begin
            add_t <= 15'h0802;
            num <= num + 1'b1;
            state <= SENDOTHERS;
        end
        SENDOTHERS:
        begin
            state <= WAIT;
            if(num == 8'd3)
                add_t <= 15'h0000;
            else
                add_t <= 15'h0000;
        end
        WAIT:
        begin
            add_t <= 15'd0;
            if(cnt == 12'd400)
            begin
                cnt <= 12'd0;
                if(num == 8'd250) // test /////////// test
                    state <= SEND;
                else
                    state <= ONCE;
            end
            else
                cnt <= cnt + 1'b1;
        end
        default:
        begin
            state <= IDLE;
        end
    endcase
    end
end


endmodule
