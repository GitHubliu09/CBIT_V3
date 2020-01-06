`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 改变不同ram，使得随时间响应上传数据命令
// 每当写完一块ram时，将转换到写另一块ram
// 当检测到写完一块ram时，就会检测此时是否没有上传数据，等待到没有上传数据时，将写完的这块ram写入待上传ram（ram3）中
// 上传数据只能从ram3中取得。
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

wire w_en1,w_en2,r_en1,r_en2,w_en3;
reg read_en;
wire [13:0]w_add1,w_add2 ,r_add,w_add3,r_add3;
reg [13:0]cnt;
wire [15:0]w_data1,w_data2,r_data1,r_data2,w_data3;

reg [2:0]state;
parameter IDLE = 3'b001;
parameter WAIT = 3'b010;
parameter CHANGE = 3'b100;

reg ctrl_change , send_done , start_send;

reg ctrl;
// ctrl = 1 时，写ram1，读ram2
assign w_en1 = rst ? 1'b0 : ( ctrl ? write_en : 1'b0 );
assign w_add1 = write_add;
assign w_data1 = write_data;
//assign r_en1 = rst ? 1'b0 : ( ~ctrl ? ren_m5 : 1'b0 );
//assign r_add1 = rst ? 14'd0 : ( ~ctrl ? rd_add_m5 : 14'd0 );
//ctrl = 0 时，写ram2，读ram1
assign w_en2 = rst ? 1'b0 : ( ~ctrl ? write_en : 1'b0 );
assign w_add2 = write_add ;
assign w_data2 = write_data ;
assign w_en3 = rst ? 1'b0 : read_en;
assign r_en1 = rst ? 1'b0 : ( ~ctrl ? read_en : 1'b0 );
assign r_en2 = rst ? 1'b0 : ( ctrl ? read_en : 1'b0 );
assign w_data3 = rst ? 16'd0 : ( ctrl ? r_data2 : r_data1);

assign r_add = cnt;
assign w_add3 = cnt - 14'd2;
assign r_add3 = rd_add_m5 ;

assign test = ctrl;

always@(negedge clk or posedge rst)
begin
    if(rst)
    begin
        state <= IDLE;
        ctrl <= 1'b0;
        ctrl_change <= 1'b0;
    end
    else
    begin
        if(send_done)
            ctrl_change <= 1'b0;
            
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
            ctrl_change <= 1'b1;
        end
        default:
        begin
            state <= IDLE;
        end
        endcase
    end
end

always@(negedge clk or posedge rst)
begin
    if(rst)
    begin
        send_done <= 1'b0;
        start_send <= 1'b0;
        cnt <= 14'hffff;
        read_en <= 1'b0;
    end
    else
    begin
        if(ctrl_change && ren_m5 == 1'b0)
        begin
            start_send <= 1'b1;
            send_done <= 1'b1;
        end
        
        if(start_send)
        begin
            cnt <= cnt + 1'b1;
            read_en <= 1'b1;
        end
        
        if(cnt == 14'd455)///// 455
        begin
            start_send <= 1'b0;
            cnt <= 14'hffff;
            read_en <= 1'b0;
            send_done <= 1'b0;
        end
        
    end
end

 time_data_ram ram1(
    .wclk( clk ),
    .waddr( w_add1 ),
    .din_sync( w_en1 ),
    .din( w_data1 ),
    .rclk( clk ),
    .re( r_en1 ),
    .ra( r_add ),
    .dout( r_data1 )
    );
    
peak_data_ram ram2(
    .wclk( clk ),
    .waddr( w_add2 ),
    .din_sync( w_en2 ),
    .din( w_data2 ),
    .rclk( clk ),
    .re( r_en2 ),
    .ra( r_add ),
    .dout( r_data2 )
);

//peak_data_ram testram2(
//    .wclk( ~clk ),
//    .waddr( w_add2 ),
//    .din_sync( w_en2 ),
//    .din( w_data2 ),
//    .rclk( ~clk_fifo_out ),
//    .re( ren_m5 ),
//    .ra( rd_add_m5+1'b1 ),
//    .dout( rd_m5 )
//);

send_ram ram3(
    .wclk( clk ),
    .waddr( w_add3 ),
    .din_sync( w_en3 ),
    .din( w_data3 ),
    .rclk( clk_fifo_out ),
    .re( ren_m5 ),
    .ra( r_add3 ),
    .dout( rd_m5 )
);

endmodule
