// trans_m5m7.v
//the block data = 8bits "0" (manchester) + 3bits sync head + data
//when it's free , m5 m7 = high
//data format: m5_head + the number of data + data
module trans_m5m7
(

	reset_, clock_57, q5, rden5, clock_32x57, address5, m5_bzo, 
	m5_boo, low_flag,high_flag

);

parameter width_double_word =6'b100000;  
//32
parameter width_byte=4'b1000;
//8
parameter number_state=2'b11;
//3
//mc5_head:8 "01" + 6 sync head(000111) 
parameter mc5_head=32'b11111111111010101010101010000111;
//mc5_headno:opposite
parameter mc5_headno=32'b11111111110101010101010101111000;

parameter idle=3'b001;
parameter sending_head=3'b010;
parameter sending_data=3'b100;

	input reset_;
	input clock_57;//187.5K
	input [15:0] q5;//data from RAM
	input rden5;//read enable
	input clock_32x57;//5.86KHz
	input [9:0] address5;//read adress of RAM
	output m5_bzo;//
	output m5_boo;//
	output low_flag;// I have send low 512Bytes , you can write in
    output high_flag;// I have send high 512 Bytes

reg [width_double_word-1:0] m5_t_mc_shiftreg;
reg [width_double_word-1:0] m5_t_no_shiftreg;
reg bit_counter_clear,bit_counter_inc,shift;
reg [5:0] bit_count;
reg [width_double_word-1:0] m5_t_mc_reg;
reg load_head_shiftreg;
reg load_data_shiftreg;
reg [number_state-1:0] state,next_state;
reg mcoutdisable;
reg low_flag;
reg high_flag;
reg rden55;
reg rden555;
//reg [15:0]data_temp , data_temp_t;
wire [15:0]data_temp;
assign data_temp = q5;

assign m5_boo=m5_t_mc_shiftreg[31];//send manchester data
assign m5_bzo=m5_t_no_shiftreg[31];//send manchester data

//delay 1 cycle
//always @(posedge clock_57 , negedge reset_)
//begin
//    if(!reset_)
//    begin
//        data_temp <= 16'd0;
//        data_temp_t <= 16'd0;
//    end
//    else
//    begin
//        data_temp_t <= q5;
//        data_temp <= data_temp_t;
//    end
//end

always @(negedge clock_57,negedge reset_)
begin
   if(!reset_)
   state <= idle;
   else
   state <= next_state;
end

always @(state,bit_count,m5_t_mc_reg,rden5,rden55)
begin

	bit_counter_clear = 1'b0 ;
	bit_counter_inc = 1'b0 ;
	load_head_shiftreg = 1'b0 ;
	load_data_shiftreg = 1'b0 ;
	shift = 1'b0 ;
	mcoutdisable = 1'b1;//clear m5_t_mc_shiftreg and m5_t_no_shiftreg

	case(state)
		idle:
        begin
		if(rden55==1'b1)//when read enable of RAM , -> next state = sending_head
				begin
					mcoutdisable = 1'b0 ;//enalbe shiftreg
					load_head_shiftreg=1'b1;//load head reg , send data head
					bit_counter_clear = 1'b1 ;//clear counter bit_count
					next_state=sending_head;
				end
        else
                    next_state = idle;
		end				
		sending_head:
			begin
				mcoutdisable =1'b0 ;
				
				if(bit_count != 6'd31)
					begin
						shift=1'b1;//shift m5_t_mc_shiftreg
						bit_counter_inc = 1'b1;//bit_count++
                        next_state = sending_head;
					end
				else//complete sending head data
					begin
						next_state=sending_data;
						load_data_shiftreg=1'b1;//load data into shiftreg
						bit_counter_clear=1'b1;//clear bit_count
					end
			end	              
		sending_data:
		    begin
				if(bit_count!=6'd31)
					begin
						mcoutdisable= 1'b0 ;
						shift=1'b1;
						bit_counter_inc = 1'b1 ;
                        next_state = sending_data;
					end
				else if(rden55==1'b0)//read RAM enable
					begin
						bit_counter_clear=1'b1;
						next_state=idle;
						
					end
				else					
					begin
						mcoutdisable = 1'b0 ;
						bit_counter_clear=1'b1;
						load_data_shiftreg=1'b1;
                        next_state = sending_data;
					end
		      end
		default:
			next_state=idle;
	endcase

end


always @(negedge clock_57,negedge reset_)
   begin 
      if(reset_==1'b0)
          begin
             m5_t_mc_reg=32'b00000000000000000000000000000000;
          end
      else if(rden5==1'b0)
          begin
             m5_t_mc_reg=32'b00000000000000000000000000000000;
          end
	 //???RAM???,???????? 
     else if((bit_count==6'd15)&&(rden5==1'b1)&&(rden55==1'b1))
		  begin//1?????:??????????,??????????
			   //0?????:??????????,??????????
		    m5_t_mc_reg[1:0]=data_temp[0]?2'b10:2'b01;
			m5_t_mc_reg[3:2]=data_temp[1]?2'b10:2'b01;
			m5_t_mc_reg[5:4]=data_temp[2]?2'b10:2'b01;
			m5_t_mc_reg[7:6]=data_temp[3]?2'b10:2'b01;
			m5_t_mc_reg[9:8]=data_temp[4]?2'b10:2'b01;
			m5_t_mc_reg[11:10]=data_temp[5]?2'b10:2'b01;
			m5_t_mc_reg[13:12]=data_temp[6]?2'b10:2'b01;
			m5_t_mc_reg[15:14]=data_temp[7]?2'b10:2'b01;
			m5_t_mc_reg[17:16]=data_temp[8]?2'b10:2'b01;
			m5_t_mc_reg[19:18]=data_temp[9]?2'b10:2'b01;
			m5_t_mc_reg[21:20]=data_temp[10]?2'b10:2'b01;
			m5_t_mc_reg[23:22]=data_temp[11]?2'b10:2'b01;
			m5_t_mc_reg[25:24]=data_temp[12]?2'b10:2'b01;
			m5_t_mc_reg[27:26]=data_temp[13]?2'b10:2'b01;
			m5_t_mc_reg[29:28]=data_temp[14]?2'b10:2'b01;
			m5_t_mc_reg[31:30]=data_temp[15]?2'b10:2'b01;
		  end		           
   end

always @(negedge clock_57,negedge reset_)
begin	
    if(reset_==1'b0)
		begin
			m5_t_mc_shiftreg <= 32'b10000000000000000000000000000000 ;
			m5_t_no_shiftreg <= 32'b10000000000000000000000000000000 ;
			bit_count <= 6'd0;
		end
	else
		begin
			
			if(load_head_shiftreg==1'b1)//???????
				begin
					m5_t_mc_shiftreg <= mc5_head ;
					m5_t_no_shiftreg <= mc5_headno ;
				end				
			if(load_data_shiftreg==1'b1)//??????
				begin
					m5_t_mc_shiftreg <= ~m5_t_mc_reg ;
					m5_t_no_shiftreg <= m5_t_mc_reg ;
				end
				
			if(bit_counter_clear==1'b1)//?????bit_count
				bit_count <= 6'd0;
				
			if(bit_counter_inc ==1'b1)
				bit_count <= bit_count+1'd1;//????(?????bit_count?????????)
			
			
			if(shift==1'b1)//????
				begin
					m5_t_mc_shiftreg <= {m5_t_mc_shiftreg[30:0],1'b0} ;//???
					m5_t_no_shiftreg <= {m5_t_no_shiftreg[30:0],1'b0} ;//???	
				end
				
			if(mcoutdisable == 1'b1)//?????m5_t_mc_shiftreg?m5_t_no_shiftreg??
				begin
					m5_t_mc_shiftreg <= 32'b10000000000000000000000000000000 ;
					m5_t_no_shiftreg <= 32'b10000000000000000000000000000000 ;
				end
				
		end
end

always @(negedge  clock_32x57,negedge reset_ )
   begin
     if(!reset_)
          begin
          low_flag <= 1'b0;
          high_flag <= 1'b0;
          end
     else if((address5==10'b0111111111)&&(rden5==1'b1))//address5=511,?:???RAM???512???????,?DSP????RAM??512???
          low_flag <= 1'b1;   
     else if((address5==10'b1111111110)&&(rden5==1'b1))//address5=1023,?:???RAM???512???????,?DSP????RAM??512???
          high_flag <= 1'b1;
     else 
          begin
          low_flag <= 1'b0; 
          high_flag <= 1'b0;
          end
   end

always @(posedge clock_32x57,negedge reset_)
   begin
     if (!reset_)
        rden55<=1'b0;
     else if (rden5==1'b1)//interface_m5????????0x034x,????0x034E,?rden??????
        rden55<=1'b1;
	 else 
        rden55<=1'b0;	
   end
 /* always @(negedge clock_32x57,negedge reset_)
   begin
     if (!reset_)
        rden555<=0;
    else 
        rden555<=rden55;	
   end*/
endmodule
