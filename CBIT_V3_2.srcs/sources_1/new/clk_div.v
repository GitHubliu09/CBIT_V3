// clk_div.v
// clk_div.v
module clk_div(clock_24m,rst,clk_1m,clk_2m,clk_5p86k,clk_187p5k,clock_100k,clk_83p3k,clk_750k,clk_23p43k,clk_41p667k,clk_12m);

input clock_24m;
output rst;
output clk_1m;
output clk_2m;
output clock_100k;
output clk_5p86k;	//187.5kHz?1/32
output clk_187p5k;  //187.5kHz
output clk_750k;	//750kHz
output clk_23p43k;	//750kHz?1/32
output clk_83p3k;
output clk_41p667k;
output clk_12m;

wire reset_;

reg clk_83p3k;
reg clk_1m;
reg clk_2m;
reg clock_100k;
reg clk_5p86k;
reg clk_187p5k;
reg clk_23p43k;
reg clk_750k;
reg clk_41p667k;
reg clk_12m;
reg [4:0]cnt1;
reg [5:0]cnt2;
reg [4:0]cnt3;
reg [7:0]cnt5;
reg [4:0]cnt6;
reg	[1:0]cnt7;		//??4??		750k->187p5k
reg [5:0]cnt8;		//??32??	187p5k->5p86k

reg [15:0]counter = 16'd0;
reg rst_t = 1'b0;

assign reset_ = ~rst_t;
assign rst = rst_t;

always@(posedge clock_24m)
begin
    if(counter == 16'd1000)
    begin
        counter <= 16'd1000;
        rst_t <= 1'b0;
    end
    else
    begin
        counter <= counter + 1'b1;
        rst_t <= 1'b1;
    end
end


always@(negedge reset_ or posedge clock_24m)
begin
    if(!reset_)
        clk_12m <= 1'b0;
    else
        clk_12m <= ~clk_12m;
    
end


always @(negedge reset_ or posedge clock_24m)

begin
     if(!reset_)
        cnt1 <= 16'b0;
     else if(cnt1 == 23) 
         cnt1 <= 16'b0;
     else
         cnt1 <= cnt1+1;
end

always @(negedge reset_ or posedge clock_24m)

begin
     if(!reset_)
		clk_1m <= 1'b0;
     else if(cnt1 > 11) 
         clk_1m <= 1'b1;
     else
         clk_1m <= 1'b0;
end

always @(negedge reset_ or posedge clock_24m)
begin
    if(!reset_)
        clk_2m <= 1'b0;
    else if(cnt1 < 6)
        clk_2m <= 1'b0;
    else if(cnt1 > 5 && cnt1 < 12)
        clk_2m <= 1'b1;
    else if(cnt1 > 11 && cnt1 < 18)
        clk_2m <= 1'b0;
    else if (cnt1 > 17 && cnt1 < 24)
        clk_2m <= 1'b1;
end



always @(negedge reset_ or posedge clock_24m)

begin
     if(!reset_)
         cnt2 <= 6'b0;
     else if(cnt2 == 31) 
         cnt2 <= 6'b0;
     else
         cnt2<= cnt2 + 1;
end

always @(negedge reset_ or posedge clock_24m)

begin
     if(!reset_)
		clk_750k <= 1'b0;
     else if(cnt2 > 15) 
         clk_750k<= 1'b1;
     else
         clk_750k <= 1'b0;
end

always @(negedge reset_ or posedge clk_750k)

begin
     if(!reset_)
         cnt3 <= 5'b0;
     else if(cnt3 == 31) 
         cnt3 <= 5'b0;
     else
         cnt3<= cnt3+1;
end

always @(negedge reset_ or posedge clk_750k)

begin
     if(!reset_)
		clk_23p43k <= 1'b0;
     else if(cnt3 > 15) 
         clk_23p43k<= 1'b1;
     else
         clk_23p43k <= 1'b0;
end

always @(negedge reset_ or posedge clk_750k)

begin
     if(!reset_)
         cnt7 <= 2'b0;
     else if(cnt3 == 3) 
         cnt7 <= 2'b0;
     else
         cnt7<= cnt7+1;
end

always @(negedge reset_ or posedge clk_750k)

begin
     if(!reset_)
		clk_187p5k <= 1'b0;
     else if(cnt7 > 1) 
         clk_187p5k<= 1'b1;
     else
         clk_187p5k <= 1'b0;
end

always @(negedge reset_ or posedge clk_187p5k)

begin
     if(!reset_)
         cnt8 <= 5'b0;
     else if(cnt8 == 31) 
         cnt8 <= 5'b0;
     else
         cnt8<= cnt8+1;
end

always @(negedge reset_ or posedge clk_187p5k)

begin
     if(!reset_)
		clk_5p86k <= 1'b0;
     else if(cnt8 > 15) 
         clk_5p86k<= 1'b1;
     else
         clk_5p86k <= 1'b0;
end


always @(negedge reset_ or posedge clock_24m)

begin
     if(!reset_)
        cnt5 <= 8'b0;
     else if(cnt5 == 239) 
         cnt5 <= 8'b0;
     else
         cnt5<= cnt5+1;
end

always @(negedge reset_ or posedge clock_24m)

begin
     if(!reset_)
      clock_100k<= 1'b0;
     else if(cnt5> 119) 
         clock_100k<= 1'b1;
     else
         clock_100k<= 1'b0;
end


always @(negedge reset_ or posedge clk_1m)
begin
     if(!reset_)
         cnt6 <= 4'b0;
     else if(cnt6 == 11) 
         cnt6 <= 4'b0;
     else
         cnt6 <= cnt6+1;
end

always @(negedge reset_ or posedge clk_1m)

begin
     if(!reset_)
      clk_83p3k <= 1'b0;
     else if(cnt6 > 5) 
         clk_83p3k <= 1'b1;
     else
         clk_83p3k <= 1'b0;
end


always @(negedge reset_ or posedge clk_83p3k)

begin
     if(!reset_)
      clk_41p667k <= 1'b0;
     else 
      clk_41p667k <= ~clk_41p667k;
end

endmodule