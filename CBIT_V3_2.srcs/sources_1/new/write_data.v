//write_data.v


module write_data
(
    input rst,
    input clk_60m,
    input clk_w,
    input clk_1m,
	input start_send,
    output [15:0]dsp_data,//需要上传的数据的个数
    output reg[11:0]dsp_ma,//控制m5和m7通道的
    output reg wr_n,
    output xz6_cs,
    output speed4x_on
);

reg [15:0]dsp_data;
reg m5_w_flag,m7_w_flag,m5_r_flag,m7_r_flag,delay_flag;
reg start = 1'b1; 
reg stop;

reg [3:0]counter = 4'd0;

//assign send_cmd = 4'he;//test command
assign speed4x_on = 1'b1;//
assign xz6_cs = 1'b0;
//assign dsp_data = 16'haa55;

always@(posedge clk_60m , negedge rst)
begin
    if(!rst)
    begin
        start <= 1'b0;//  test
        stop <= 1'b0;
    end
    else
    begin
       
        if(start_send)
        begin
            start <= 1'b1;
            stop <= 1'b0;
        end
        if(counter == 4'd4)
        begin
            start <= 1'b0;
            stop <= 1'b1;
        end
    end
end

always @(posedge clk_w , negedge rst)
begin
	if(!rst)
    begin
		counter <= 17'd0;
		m5_w_flag <= 1'b0;
		m7_w_flag <= 1'b0;
		m5_r_flag <= 1'b0;
		m7_r_flag <= 1'b0;
		delay_flag <= 1'b0;
    end
	else
	begin
		if(start)
			counter <= counter + 1'b1;
		
		if(stop)
			counter <= 4'd0;
			
		if(counter == 4'd1)
		begin
			m5_r_flag <= 1'b1;
		end
		
		if(counter == 4'd2)
		begin 
			m5_r_flag <= 1'b0;
			m7_r_flag <= 1'b1;
		end
		
		if(counter == 4'd3)
		begin
			m7_r_flag <= 1'b0;
			delay_flag <= 1'b1;
		end
		
		if(counter == 4'd4)
		begin
			delay_flag <= 1'b0;
			counter <= 4'd0;
		end
		
		
	end

end

always @(posedge clk_w , negedge rst)
begin 
	if(!rst)
	begin
		dsp_data <= 16'd0;
		dsp_ma <= 12'd0;
 
	end
	else
	begin
	
		if(m5_r_flag)
		begin
			dsp_ma <= 12'b0000_0101_0000;
			dsp_data <= 16'd452;
         
		end
		
		if(m7_r_flag)
		begin
			dsp_ma <= 12'b0000_0111_0000;
			dsp_data <= 16'd60;
      
		end
		
		if(delay_flag)
		begin
			dsp_ma <= 12'd0;
			dsp_data <= 16'd0;
        
		end
		
	end
end

always@(posedge clk_1m, negedge rst)
begin
    if(!rst)
    wr_n <= 1'b1;
    else
    begin
         if(counter >0 && counter <4)
            wr_n <= 1'b0;
        else wr_n <= 1'b1;
    end

end


endmodule

