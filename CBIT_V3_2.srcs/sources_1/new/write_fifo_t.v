`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////


module write_fifo_t(
    input clk,
    input rst,
    input empty,
    input full,
    output wr_clk,
    output wr_en,
    output [15:0] din
    );

reg [15:0]counter = 16'd0;
reg [15:0]data = 16'd0;
reg en = 1'b0;

assign wr_clk = clk;
assign wr_en = en;
assign din = data;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        en <= 1'b0;
        data <= 16'd0;
    end
    else if(!full)
    begin
        if(counter == 16'd9)
        begin
            en <= 1'b1;
            data <= 16'b1100_1000_0000_0011;//0xc803
        end
        if(counter == 16'd10)
        begin
            en <= 1'b1;
            data <= 16'h0004;//0xc803
        end
        if(counter == 16'd11)
        begin
            en <= 1'b1;
            data <= 16'b0001_0001_0001_0001;//0x1111;
        end
        if(counter == 16'd12)
        begin
            en <= 1'b1;
            data <= 16'b0010_0010_0010_0010;//0x2222;
        end
        if(counter == 16'd13)
        begin
            en <= 1'b1;
            data <= 16'b0011_0011_0011_0011;//0x3333
        end
        if(counter == 16'd14)
        begin
            en <= 1'b1;
            data <= 16'b0100_0100_0100_0100;//0x4444
        end
        if(counter == 16'd15)
        begin
            en <= 1'b1;
            data <= 16'b0101_0101_0101_0101;//0x5555
        end
        if(counter == 16'd16)
        begin
            en <= 1'b1;
            data <= 16'b0110011001100110;//0x3333
        end
        if(counter == 16'd17)
        begin
            en <= 1'b1;
            data <= 16'b0111011101110111;//0x3333
        end
        if(counter == 16'd18)
        begin
            en <= 1'b1;
            data <= 16'b1000100010001000;//0x3333
        end
        if(counter == 16'd19)
        begin
            en <= 1'b1;
            data <= 16'h9999;//0x3333
        end
        if(counter == 16'd20)
        begin
            en <= 1'b1;
            data <= 16'haaaa;//0x3333
        end
        if(counter == 16'd21)
        begin
            en <= 1'b1;
            data <= 16'hbbbb;//0x3333
        end
        if(counter == 16'd22)
        begin
            en <= 1'b1;
            data <= 16'hcccc;//0x3333
        end
        if(counter == 16'd23)
        begin
            en <= 1'b1;
            data <= 16'hdddd;//0x3333
        end
        if(counter == 16'd24)
        begin
            en <= 1'b1;
            data <= 16'heeee;//0x3333
        end
        if(counter == 16'd25)
        begin
            en <= 1'b1;
            data <= 16'hffff;//0x3333
        end
        if(counter == 16'd26)
        begin
            en <= 1'b1;
            data <= 16'h5555;//0x3333
        end
        if(counter == 16'd27)
        begin
            en <= 1'b1;
            data <= 16'haaaa;//0x3333
        end
        if(counter == 16'd28)
        begin
            en <= 1'b1;
            data <= 16'ha5a5;//0x3333
        end
        if(counter == 16'd29)
        begin
            en <= 1'b1;
            data <= 16'h5a5a;//0x3333
        end
        if(counter == 16'd30)
        begin
            en <= 1'b1;
            data <= 16'h0101;//0x3333
        end
   
        if(counter == 16'd31)
        begin
            en <= 1'b0;
        end
//        if(counter < 16'd1000)
//        begin
            counter <= counter + 1'b1;
//        end
//        else
//            counter <= 16'd0;
    end
end


endmodule
