// interface_m7.v
//?interface_m5?????????.
module interface_m7
(
    db, ma, XZ6_CS, wr_, clock_32x57,clock_system, reset_,  rden,
	rd_address
 );

parameter all_zero_16=16'b0000000000000000;
parameter all_zero_18=18'b000000000000000000;
parameter all_zero_10=10'b0000000000;
parameter idle   =3'b001;
parameter waiting=3'b010;
parameter running=3'b100;
	input [15:0] db;
	input [11:0] ma;
	input XZ6_CS;
	input wr_;
	input clock_system;
    input clock_32x57;
	input reset_;
	output rden;
    output [9:0] rd_address;

 
reg rden;
reg [17:0] counter_temp;
reg [2:0] state;
reg [2:0] next_state;
reg [17:0] counter;
reg counter_dec;
reg [9:0] rd_address;
reg flag;
reg aload;

// reg m7_switch;

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
            if(counter!=all_zero_18)
               next_state=running;
               rden=1'b1;
		  end	
	  running:
          begin          
          if(counter!=all_zero_18)
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
       counter <= counter_temp ;
     else if(counter_dec)
       counter <= counter - 1'b1;
      
end
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
    if(!reset_)   
       begin
          counter_temp<=all_zero_18;
          flag<=1'b0;
       end
    else if(!XZ6_CS && (wr_==0) && (ma[11:0]==12'b0000_0111_0000))//0x2070
       begin
           counter_temp<={2'b00,db};
           flag<=1'b1;
       end
	else if(aload)
	           flag<=1'b0;
    else
        begin
           if(aload)
	                flag<=1'b0;
        end
   end

always @(posedge clock_32x57,negedge reset_)
begin
   if(!reset_)
   aload<=5'b0;
   else if(flag)
   aload<=1'b1;
   else if(aload)
   aload<=1'b0;
end



endmodule


