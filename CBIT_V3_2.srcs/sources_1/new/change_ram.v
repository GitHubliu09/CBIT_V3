`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/28 16:46:20
// Design Name: 
// Module Name: change_ram
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


module change_ram(
    input clk,
    input rst,
    input write_ram_done,
    input [13:0]write_add,
    input write_en,
    input [15:0]write_data,
    input clk_fifo_out,
    input ren_m5,
    input [13:0]rd_add_m5,
    
    output [15:0]rd_m5,
    output test
    );

wire w_en1,w_en2,r_en1,r_en2;
wire [13:0]w_add1,w_add2,r_add1,r_add2;
wire [15:0]w_data1,w_data2,r_data1,r_data2;

reg [2:0]state;
parameter IDLE = 3'b001;
parameter WAIT = 3'b010;
parameter CHANGE = 3'b100;

reg ctrl;
// ctrl = 1 时，写ram1，读ram2
assign w_en1 = rst ? 1'b0 : ( ctrl ? write_en : 1'b0 );
assign w_add1 = rst ? 14'b0 : ( ctrl ? write_add : 14'b0 );
assign w_data1 = rst ? 8'b0 : ( ctrl ? write_data : 8'b0 );
assign r_en1 = rst ? 1'b0 : ( ~ctrl ? ren_m5 : 1'b0 );
assign r_add1 = rst ? 14'b0 : ( ~ctrl ? rd_add_m5 : 14'b0 );
//ctrl = 0 时，写ram2，读ram1
assign w_en2 = rst ? 1'b0 : ( ~ctrl ? write_en : 1'b0 );
assign w_add2 = rst ? 14'b0 : ( ~ctrl ? write_add : 14'b0 );
assign w_data2 = rst ? 8'b0 : ( ~ctrl ? write_data : 8'b0 );
assign r_en2 = rst ? 1'b0 : ( ctrl ? ren_m5 : 1'b0 );
assign r_add2 = rst ? 14'b0 : ( ctrl ? rd_add_m5 : 14'b0 );

assign rd_m5 = rst ? 8'bz : ( ctrl ? r_data2 : r_data1 );

assign test = ctrl;

always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
        ctrl <= 1'b0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
            if(write_ram_done)
                state <= WAIT;
        end
        WAIT:
        begin
            if( !write_ram_done )
                state <= CHANGE;
        end
        CHANGE:
        begin
            state <= IDLE;
            ctrl <= ~ctrl;
        end
        default:
        begin
            state <= IDLE;
        end
        endcase
    end
end

 time_data_ram ram1(
    .wclk( ~clk ),
    .waddr( w_add1 ),
    .din_sync( w_en1 ),
    .din( w_data1 ),
    .rclk( ~clk_fifo_out ),
    .re( r_en1 ),
    .ra( r_add1 ),
    .dout( r_data1 )
    );
    
peak_data_ram ram2(
    .wclk( ~clk ),
    .waddr( w_add2 ),
    .din_sync( w_en2 ),
    .din( w_data2 ),
    .rclk( ~clk_fifo_out ),
    .re( r_en2 ),
    .ra( r_add2 ),
    .dout( r_data2 )
);


endmodule
