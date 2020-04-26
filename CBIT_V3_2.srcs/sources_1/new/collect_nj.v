`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////


module collect_nj(
    input CLK20M,
    input rst,
    input collect_achieve,
    input fire_once,
    input [13:0]adc_data,
    
    output [15:0]nj_data,
    output [11:0]nj_add,
    output nj_w_en,
    output [1:0]select,
    output nj_doing,
    output  nj_collect_once
    );

reg [3:0]state , next_state;
parameter IDLE = 4'b0001;
parameter WAITFIRE = 4'b0010;
parameter CLCTNJ = 4'b0100;
parameter NJDONE = 4'b1000;

parameter num = 12'd800;
parameter select_t = 2'b01;

reg[11:0] cnt;
reg w_en_t,nj_c_t , nj_c_o1 , nj_c_o2 , nj_c_o3;

assign nj_doing = nj_c_t;
assign select = nj_c_t ? 2'b11 : select_t;
assign nj_w_en = w_en_t;
assign nj_add = cnt;
assign nj_data =  adc_data;
assign nj_collect_once = nj_c_o2 | nj_c_o3;

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
    end
    else
    begin
        state <= next_state;
    end
end

always@(collect_achieve,fire_once,cnt)
begin
    next_state = state;
    case(state)
    IDLE:
    begin
        if(collect_achieve)
            next_state = WAITFIRE;
    end
    WAITFIRE:
    begin
        if(fire_once)
            next_state = CLCTNJ;
    end
    CLCTNJ:
    begin
        if(cnt == num)
            next_state = NJDONE;
    end
    NJDONE:
    begin
        next_state = IDLE;
    end
    default:
    begin
        next_state = IDLE;
    end
    
    endcase
end

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        cnt <= 12'd0;
        w_en_t <= 1'b0;
        nj_c_t <= 1'b0;
        nj_c_o1 <= 1'b0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
            cnt <= 12'd0;
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b0;
        end
        WAITFIRE:
        begin
            nj_c_t <= 1'b1;
            w_en_t <= 1'b0;
        end
        CLCTNJ:
        begin
            cnt <= cnt + 1'b1;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b1;
        end
        NJDONE:
        begin
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b1;
        end
        endcase
    end
    
end

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        nj_c_o2 <= 1'b0;
        nj_c_o3 <= 1'b0;
    end
    else
    begin
        nj_c_o2 <= nj_c_o1;
        nj_c_o3 <= nj_c_o2;
    end
end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////


module collect_nj(
    input CLK20M,
    input rst,
    input collect_achieve,
    input fire_once,
    input [13:0]adc_data,
    
    output [15:0]nj_data,
    output [11:0]nj_add,
    output nj_w_en,
    output [1:0]select,
    output nj_doing,
    output  nj_collect_once
    );

reg [3:0]state , next_state;
parameter IDLE = 4'b0001;
parameter WAITFIRE = 4'b0010;
parameter CLCTNJ = 4'b0100;
parameter NJDONE = 4'b1000;

parameter num = 12'd800;
parameter select_t = 2'b01;

reg[11:0] cnt;
reg w_en_t,nj_c_t , nj_c_o1 , nj_c_o2 , nj_c_o3;

assign nj_doing = nj_c_t;
assign select = nj_c_t ? 2'b11 : select_t;
assign nj_w_en = w_en_t;
assign nj_add = cnt;
assign nj_data =  adc_data;
assign nj_collect_once = nj_c_o2 | nj_c_o3;

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
    end
    else
    begin
        state <= next_state;
    end
end

always@(collect_achieve,fire_once,cnt)
begin
    next_state = state;
    case(state)
    IDLE:
    begin
        if(collect_achieve)
            next_state = WAITFIRE;
    end
    WAITFIRE:
    begin
        if(fire_once)
            next_state = CLCTNJ;
    end
    CLCTNJ:
    begin
        if(cnt == num)
            next_state = NJDONE;
    end
    NJDONE:
    begin
        next_state = IDLE;
    end
    default:
    begin
        next_state = IDLE;
    end
    
    endcase
end

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        cnt <= 12'd0;
        w_en_t <= 1'b0;
        nj_c_t <= 1'b0;
        nj_c_o1 <= 1'b0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
            cnt <= 12'd0;
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b0;
        end
        WAITFIRE:
        begin
            nj_c_t <= 1'b1;
            w_en_t <= 1'b0;
        end
        CLCTNJ:
        begin
            cnt <= cnt + 1'b1;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b1;
        end
        NJDONE:
        begin
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b1;
        end
        endcase
    end
    
end

always@(posedge CLK20M or posedge rst)
begin
    if(rst)
    begin
        nj_c_o2 <= 1'b0;
        nj_c_o3 <= 1'b0;
    end
    else
    begin
        nj_c_o2 <= nj_c_o1;
        nj_c_o3 <= nj_c_o2;
    end
end

endmodule
