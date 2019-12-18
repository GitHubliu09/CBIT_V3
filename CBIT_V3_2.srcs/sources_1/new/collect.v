`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// adc work mode
// adc nap mode , 15mW , 100 clock cycles
// adc sleep mode , 1mW , 9ms
//////////////////////////////////////////////////////////////////////////////////


 module collect(
    input rst,
    input clk,
    input collectmark,
    input bodymark,
    input fire_once,
    input fire_achieve,
    
    input adc_ovr,//when adc_ovr = 1 , overranged or underranged
    input [13:0]adc_data,
    output shdn,//shdn=0,oe=0 -> enalbe ... shdn=1,oe=0 -> nap mode ... shdn=1,oe=1 -> sleep mode
    output oe,// adc IC output enable pin
    output adc_clk_ttl,//adc clk
    output adc_clk_oe,// adc clk enable, =1 -> eanble
    output [4:0]gain,
    output reg we_un,
    output [13:0] wadd_un,
    output [15:0] data_un,
    output [13:0]collect_num,
    output collect_once,
    output collect_achieve
    );

reg [1:0] state;
parameter IDLE = 2'b00;
parameter WAIT = 2'b01;
parameter DELAY = 2'b10;
parameter ACQ = 2'b11;

parameter delay_time = 6'd32;//delay time us
parameter acq_num = 13'd2440;//colect number

/**************** control wire **********************/
reg achieve;
reg c_achieve;
reg c_once;
reg c_achieve1 , c_achieve2 , c_once1 , c_once2;
/**************** conter *****************************/
reg [4:0] count_us;
reg [5:0] count_delay;
reg [13:0] acq_cnt;

assign gain[4:2] = 3'b000;    
assign shdn = 1'b0;
assign oe = 1'b0;
assign adc_clk_ttl = clk;
assign adc_clk_oe = 1'b1;
assign collect_achieve = c_achieve1 | c_achieve2;
assign collect_once = c_once1 | c_once2;
assign wadd_un = acq_cnt;
assign data_un = { 2'b00 , adc_data };
assign collect_num = acq_num;

assign gain[0] = clk;
assign gain[1] = clk;

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
        achieve <= 1'b0;
        count_us <= 5'd0;
        count_delay <= 6'd0;
        acq_cnt <= 14'd0;
        c_achieve <= 1'b0;
        c_once <= 1'b0;
        we_un <= 1'b0;
    end
    else
        case(state)
            IDLE:
            begin
                achieve <= 1'b0;
                acq_cnt <= 14'd0;
                c_achieve <= 1'b0;
                c_once <= 1'b0;
                we_un <= 1'b0;
                if(collectmark)
                    state <= WAIT;
                else
                    state <= IDLE;
            end
            
            WAIT:
            begin
                achieve <= 1'b0;
                count_delay <= 6'b0;
                count_us <= 5'b0;
                acq_cnt <= 14'd0;
                we_un <= 1'b0;
                c_achieve <= 1'b0;
                c_once <= 1'b0;
                if(fire_once == 1 && fire_achieve == 1)
                begin
                    state <= DELAY;
                    achieve <= 1'b1;
                end
                else if(fire_once == 1)
                    state <= DELAY;
                else
                begin
                    state <= WAIT;
                    c_achieve <= 1'b0;
                    c_once <= 1'b0;
                end
            end
            
            DELAY:
            begin
                if(count_delay == delay_time)
                begin
                    state <= ACQ;
                    count_delay <= 6'd0;
                    count_us <= 5'd0;
                    we_un <= 1'b1;
                end
                else if(count_us == 5'd19)
                begin
                    count_us <= 5'd0;
                    count_delay <= count_delay + 1'b1;
                end
                else
                    count_us <= count_us + 1'b1;
            end
            
            ACQ:
            begin
                acq_cnt <= acq_cnt + 1'b1;
                if(acq_cnt == acq_num && achieve == 1'b1)
                begin
                    state <= WAIT;
                    achieve <= 1'b0;
                    c_achieve <= 1'b1;
                    c_once <= 1'b1;
                 end 
                 else if(acq_cnt == acq_num)
                 begin
                    state <= WAIT;
                    c_once <= 1'b1;
                 end
                 else
                    state <= ACQ;
            end
            
            default:
            begin
                state <= IDLE;
            end
        endcase
end

always@ (posedge clk or posedge rst)
begin
    if(rst)
    begin
        c_achieve1 <= 1'b0;
        c_achieve2 <= 1'b0;
        c_once1 <= 1'b0;
        c_once2 <= 1'b0;
    end
    else
    begin
        c_achieve1 <= c_achieve;
        c_achieve2 <= c_achieve1;
        c_once1 <= c_once;
        c_once2 <= c_once1;
    end
end

endmodule
