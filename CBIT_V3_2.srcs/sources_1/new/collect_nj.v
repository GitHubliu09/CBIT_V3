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
    
    output [13:0]collect_num_nj,
    
    output [15:0]nj_data,
    output [11:0]nj_add,
    output nj_w_en,
    output [1:0]select,//00->GND , 01->1.5  , 10->2.0 , 11->mud
    output nj_doing,
    output  nj_collect_once
    );

reg [4:0]state , next_state;
parameter IDLE = 5'b00001;
parameter WAITFIRE = 5'b00010;
parameter WAITNJ = 5'b00100;
parameter CLCTNJ = 5'b01000;
parameter NJDONE = 5'b10000;

parameter num = 12'd800;
parameter select_t = 2'b01;
parameter select_nj = 2'b11;
parameter select_15 = 2'b01;
parameter select_20 = 2'b10;
parameter select_gnd = 2'b00;

parameter delay_time = 10'd400;//0.05us

reg[11:0] cnt;
reg [9:0]delay_cnt;
reg w_en_t,nj_c_t , nj_c_o1 , nj_c_o2 , nj_c_o3 , s_t;
wire delay_c;

assign delay_c = delay_cnt == delay_time ? 1'b1:1'b0;
assign nj_doing = nj_c_t;
assign select = s_t ? select_15 : select_gnd;
assign nj_w_en = w_en_t;
assign nj_add = cnt;
assign nj_data =  adc_data;
assign nj_collect_once = nj_c_o2 | nj_c_o3;
assign collect_num_nj = num;

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

always@(collect_achieve,fire_once,cnt,delay_c)
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
            next_state = WAITNJ;
    end
    WAITNJ:
    begin
        if(delay_c )
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
            s_t <= 1'b0;
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b0;
            delay_cnt <= 8'd0;
        end
        WAITFIRE:
        begin
            s_t <= 1'b0;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b0;
            delay_cnt <= 8'd0;
        end
        WAITNJ:
        begin
            s_t <= 1'b0;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b0;
            delay_cnt <= delay_cnt + 1'b1;
        end
        CLCTNJ:
        begin
            s_t <= 1'b1;
            cnt <= cnt + 1'b1;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b1;
            delay_cnt <= 8'd0;
        end
        NJDONE:
        begin
            s_t <= 1'b0;
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b1;
            delay_cnt <= 8'd0;
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
    
    output [13:0]collect_num_nj,
    
    output [15:0]nj_data,
    output [11:0]nj_add,
    output nj_w_en,
    output [1:0]select,//00->GND , 01->1.5  , 10->2.0 , 11->mud
    output nj_doing,
    output  nj_collect_once
    );

reg [4:0]state , next_state;
parameter IDLE = 5'b00001;
parameter WAITFIRE = 5'b00010;
parameter WAITNJ = 5'b00100;
parameter CLCTNJ = 5'b01000;
parameter NJDONE = 5'b10000;

parameter num = 12'd800;
parameter select_t = 2'b01;
parameter select_nj = 2'b11;
parameter select_15 = 2'b01;
parameter select_20 = 2'b10;
parameter select_gnd = 2'b00;

parameter delay_time = 10'd400;//0.05us

reg[11:0] cnt;
reg [9:0]delay_cnt;
reg w_en_t,nj_c_t , nj_c_o1 , nj_c_o2 , nj_c_o3 , s_t;
wire delay_c;

assign delay_c = delay_cnt == delay_time ? 1'b1:1'b0;
assign nj_doing = nj_c_t;
assign select = s_t ? select_15 : select_gnd;
assign nj_w_en = w_en_t;
assign nj_add = cnt;
assign nj_data =  adc_data;
assign nj_collect_once = nj_c_o2 | nj_c_o3;
assign collect_num_nj = num;

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

always@(collect_achieve,fire_once,cnt,delay_c)
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
            next_state = WAITNJ;
    end
    WAITNJ:
    begin
        if(delay_c )
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
            s_t <= 1'b0;
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b0;
            delay_cnt <= 8'd0;
        end
        WAITFIRE:
        begin
            s_t <= 1'b0;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b0;
            delay_cnt <= 8'd0;
        end
        WAITNJ:
        begin
            s_t <= 1'b0;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b0;
            delay_cnt <= delay_cnt + 1'b1;
        end
        CLCTNJ:
        begin
            s_t <= 1'b1;
            cnt <= cnt + 1'b1;
            nj_c_t <= 1'b1;
            w_en_t <= 1'b1;
            delay_cnt <= 8'd0;
        end
        NJDONE:
        begin
            s_t <= 1'b0;
            nj_c_t <= 1'b0;
            w_en_t <= 1'b0;
            nj_c_o1 <= 1'b1;
            delay_cnt <= 8'd0;
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
