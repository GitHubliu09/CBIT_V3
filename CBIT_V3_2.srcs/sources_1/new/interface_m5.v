// interface_m5.v
module interface_m5
(
    db, ma, XZ6_CS, wr_, clock_32x57,clock_system, reset_,   rden, 
	 rd_address
 );

parameter all_zero_18=18'b000000000000000000;
parameter idle   =3'b001;
parameter waiting=3'b010;
parameter running=3'b100;

	input [15:0] db;//data bus , connect to PIC
	input [11:0] ma;//address
	input XZ6_CS;
	input wr_;//
	input clock_system;//24M
    input clock_32x57;//5.86KHz
	input reset_;
	output rden;//connect to ram , read enable
    output [9:0] rd_address;//connect to ram , read address

 
reg rden;
reg [17:0] counter_temp;
reg [2:0] state = 3'b001;
reg [2:0] next_state;
reg [17:0] counter;
reg counter_dec;
reg [9:0] rd_address;
reg flag;
reg aload;


//use clock 24MHz detect , receive "upload" command 0xC84x, send_cmd[3:0] means the last 4bits of "upload" command 
//when receive "upload" command , -> flag = 1;
//use clock 5.86KHz detect , when flag = 1 -> aload = 1 , after 1 clock , aload = 0
//when aload = 1, start send data , (5.86KHz) counter = (data number) , rd_en = 1
//counter_dec = 1 , -> (5.86KHz)counter-- , rd_address++
//when counter = 0 , stop send
always @(aload,state,counter)
begin
   rden = 1'b0;
   counter_dec = 1'b0;
   next_state = state;
   case(state)
      idle: 
          begin 
          if(aload)
             next_state = waiting;
          end
      waiting:
          begin
          if(counter!=all_zero_18)//send data number
             next_state=running;
             rden=1'b1;
          end
      running:
          begin
          
          if(counter!=all_zero_18)//counter-- untill counter = 0
          begin
             counter_dec = 1'b1;
             rden=1'b1;
          end
          else 
             next_state = idle;
          end
    default:
       next_state = idle;
    endcase
end
             
always @(posedge clock_system,negedge reset_)
begin
     if(!reset_)
        state<=idle;
     else 
        state<=next_state; 
end

always @(posedge clock_32x57,negedge reset_)
begin
     if(!reset_)
       counter <= all_zero_18;
     else if(aload)   
       counter <= counter_temp;//the number of data needed send 
     else if(counter_dec)
       counter <= counter - 1'b1;      
end

//when read , read address++ 
always @(posedge clock_32x57,negedge reset_)
begin
   if(!reset_)
      rd_address <= 10'b0000000000;
   else if(!rden)
      rd_address <= 10'b0000000000;
   else
      rd_address <= rd_address + 1'b1;
end
 
always @(posedge clock_system or negedge reset_)
   begin
    if(reset_==1'b0)   
       begin
          counter_temp<=all_zero_18;
          flag<=1'b0;
       end
	//when DSP receive 0x034E (test command , test M2M5M7), 
	//write 17 (number) into 0x2050 (M5Port_start address) and 0x2070 , means upload 17 parameters
    else if(!XZ6_CS && (wr_==1'b0) && (ma[11:0]==12'b0000_0101_0000))//0x2050
        begin
        counter_temp<={2'b00,db};
        flag<=1'b1;//when receive 0x034x or 0x034E -> flag = 1
        end
	else if(aload)
	            flag<=1'b0;	
    else begin
        if(aload)
			flag<=1'b0;
	end
  end

always @(posedge clock_32x57,negedge reset_)
begin
   if(!reset_)
   aload<=5'b0;
   else if(flag)
   aload<=1'b1;//?aload?flag??????????clock_32x57??????
   else if(aload)
   aload<=1'b0;
end



endmodule

// interface_m5.v
module interface_m5
(
    db, ma, XZ6_CS, wr_, clock_32x57,clock_system, reset_,   rden, 
	 rd_address
 );

parameter all_zero_18=18'b000000000000000000;
parameter idle   =3'b001;
parameter waiting=3'b010;
parameter running=3'b100;

	input [15:0] db;//data bus , connect to PIC
	input [11:0] ma;//address
	input XZ6_CS;
	input wr_;//
	input clock_system;//24M
    input clock_32x57;//5.86KHz
	input reset_;
	output rden;//connect to ram , read enable
    output [9:0] rd_address;//connect to ram , read address

 
reg rden;
reg [17:0] counter_temp;
reg [2:0] state = 3'b001;
reg [2:0] next_state;
reg [17:0] counter;
reg counter_dec;
reg [9:0] rd_address;
reg flag;
reg aload;


//use clock 24MHz detect , receive "upload" command 0xC84x, send_cmd[3:0] means the last 4bits of "upload" command 
//when receive "upload" command , -> flag = 1;
//use clock 5.86KHz detect , when flag = 1 -> aload = 1 , after 1 clock , aload = 0
//when aload = 1, start send data , (5.86KHz) counter = (data number) , rd_en = 1
//counter_dec = 1 , -> (5.86KHz)counter-- , rd_address++
//when counter = 0 , stop send
always @(aload,state,counter)
begin
   rden = 1'b0;
   counter_dec = 1'b0;
   next_state = state;
   case(state)
      idle: 
          begin 
          if(aload)
             next_state = waiting;
          end
      waiting:
          begin
          if(counter!=all_zero_18)//send data number
             next_state=running;
             rden=1'b1;
          end
      running:
          begin
          
          if(counter!=all_zero_18)//counter-- untill counter = 0
          begin
             counter_dec = 1'b1;
             rden=1'b1;
          end
          else 
             next_state = idle;
          end
    default:
       next_state = idle;
    endcase
end
             
always @(posedge clock_system,negedge reset_)
begin
     if(!reset_)
        state<=idle;
     else 
        state<=next_state; 
end

always @(posedge clock_32x57,negedge reset_)
begin
     if(!reset_)
       counter <= all_zero_18;
     else if(aload)   
       counter <= counter_temp;//the number of data needed send 
     else if(counter_dec)
       counter <= counter - 1'b1;      
end

//when read , read address++ 
always @(posedge clock_32x57,negedge reset_)
begin
   if(!reset_)
      rd_address <= 10'b0000000000;
   else if(!rden)
      rd_address <= 10'b0000000000;
   else
      rd_address <= rd_address + 1'b1;
end
 
always @(posedge clock_system or negedge reset_)
   begin
    if(reset_==1'b0)   
       begin
          counter_temp<=all_zero_18;
          flag<=1'b0;
       end
	//when DSP receive 0x034E (test command , test M2M5M7), 
	//write 17 (number) into 0x2050 (M5Port_start address) and 0x2070 , means upload 17 parameters
    else if(!XZ6_CS && (wr_==1'b0) && (ma[11:0]==12'b0000_0101_0000))//0x2050
        begin
        counter_temp<={2'b00,db};
        flag<=1'b1;//when receive 0x034x or 0x034E -> flag = 1
        end
	else if(aload)
	            flag<=1'b0;	
    else begin
        if(aload)
			flag<=1'b0;
	end
  end

always @(posedge clock_32x57,negedge reset_)
begin
   if(!reset_)
   aload<=5'b0;
   else if(flag)
   aload<=1'b1;//?aload?flag??????????clock_32x57??????
   else if(aload)
   aload<=1'b0;
end



endmodule

