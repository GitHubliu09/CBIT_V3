// cmd_decoder.v
//receive from upper computer
//command data = 1.5bits high + 1.5bits low + 16bits data + 1bit check bit = 20 bits
//data = 1.5bits low + 1.5bits high + 16bits data + 1bit check bit = 20 bits
//free time -> m2udi = 0 
//在接收到命令后要判断命令后面是否有数据，有数据之后的状态都带有1


module cmd_decoder
(
    input md2udi,//input cmd
    input reset_,
    input clock_m2rx24,//clock 1m
    input clock_system,//24mHz
    output [15:0] rcvd_datareg,//receive data,
    output wr_fifo_en,         //接收到数据之后置一，类似于标志位的作用 （时钟是1m）
    output m2rxirqb,          //useless，前面调用这个模块时没有使用这个输出
    //output [3:0] send_cmd;//?interface_m5,interface_m7???send_cmd[3:0]??
                              //receive low 4bits command , 0x34x
    output [3:0] test
);

parameter word_size = 34;
parameter num_state_bits = 10;

parameter idle = 10'b0000000001;
parameter heading = 10'b0000000010;
parameter starting = 10'b0000000100;
parameter receiving = 10'b0000001000;
parameter waiting = 10'b0000010000;
parameter waiting1 = 10'b0000100000;
parameter idle1 = 10'b0001000000;
parameter heading1 = 10'b0010000000;
parameter starting1 = 10'b0100000000;
parameter receiving1 = 10'b1000000000;

parameter state_1=2'b01;
parameter state_2=2'b10;


	
reg [word_size-1:0] rcv_shftreg;//存储到接收到的命令是曼码的形式
reg [4:0] sample_counter;
reg [5:0] bit_counter;
reg inc_bit_counter;
reg clr_bit_counter;
reg inc_sample_counter;
reg clr_sample_counter;
reg shift,load;
reg [15:0] rcvd_datareg;
reg [num_state_bits-1:0] state,next_state;
reg [7:0] headreg ;
reg headshift ;
reg headshift_clr ;
reg loaddata ;
reg m2rxirq_out;
reg md2udireg;
reg [3:0] send_cmd;
reg [3:0] delay_cnt;
reg clr_delay_cnt;
reg inc_delay_cnt;
// reg send_flag;
reg m2cmdtest;
reg wr_fifo_ent,wr_fifo_en1;
reg [1:0] state_ii,next_state_ii;
reg int_counter_inc,int_counter_clr;
reg m2rxirqb;
reg [3:0]int_counter;

reg rst_out_en;
reg [2:0] disturb_cnt;

assign wr_fifo_en = wr_fifo_en1;

//------------test------------
// reg md2udi_;
// always @(posedge clock_system)
// begin
	// if(reset_ == 0)
		// md2udi_ <= 1'b0;
	// else
		// md2udi_ <= md2udi;

// end
//    assign test = {m2cmdtest, m2cmdtest, m2cmdtest, m2cmdtest};
//assign test = {m2cmdtest, m2cmdtest,0,0};


always @(posedge clock_system)
begin
	if(reset_ == 0)
		md2udireg = 1'b0;
	else if(state == idle || state == idle1 || state == waiting || state == waiting1)
		md2udireg = md2udi;

end

always @(posedge clock_m2rx24, negedge reset_)   //状态转移
begin
     if(reset_==0)
     begin
        state<=idle;
     end       
     else
        begin
            state<=next_state;
        end
end

always @(state,md2udireg,headreg,sample_counter,bit_counter,rcv_shftreg,disturb_cnt)
begin
    m2rxirq_out=0;
	clr_sample_counter=0;
	clr_bit_counter=0;
	inc_sample_counter=0;
	inc_bit_counter=0;
	shift=0;
	load=0;
	headshift = 0 ;
	headshift_clr = 0 ;
	loaddata = 0 ;
	next_state=state;
    rst_out_en = 0;
    send_cmd = 4'b0000;
	clr_delay_cnt = 0;
	inc_delay_cnt = 0;
    // send_flag = 0;

	case(state)
	idle:
        begin
        m2cmdtest = 4'd0;
		    if(md2udireg == 1)//when input is high -> next state ==> heading
			begin
				next_state = heading ;
				headshift_clr = 1 ;//clear headreg
//                m2cmdtest = 4'd0;
			end
        end
			
	heading: 
		if(sample_counter != 5'd9)//after input become high 9 periods , next state ==> starting ,,, move md2udi into headreg
            begin
			inc_sample_counter = 1;//means : reg sample_counter ++
            m2cmdtest = 1'd1;
            end
		else
			begin
				headshift = 1 ;//move md2udi into headreg
				next_state = starting ;
				clr_sample_counter = 1 ;//clear sample_counter
				clr_delay_cnt = 1;
                m2cmdtest = 1'd1;
			end
			
	starting:
		begin
			if(sample_counter < 5'd23)//  1M/24.0=41.667KHz ,,, every 24us (41.667KHz) move md2udi into headreg
                begin
				inc_sample_counter = 1 ;
                m2cmdtest = 1'd1;
                end
			else
				begin
				headshift = 1 ;
				clr_sample_counter = 1 ;
				inc_delay_cnt = 1 ; // delay_cnt ++
                m2cmdtest = 1'd1;
				end
				
			if(delay_cnt < 4'd10) // when move 9 bits into headreg , execute  
				begin
					if( (headreg == 8'b10001001) || (headreg == 8'b10001010) || (headreg == 8'b10000101) || (headreg == 8'b10000110) )//when receive cmd data , next_state ==> receiving
					begin
					loaddata = 1 ;//set "bit_counter" to 4 , means receive 4bits data
					next_state = receiving;
                    m2cmdtest = 4'd0;
					end
				end
            else//  after receive 9 bits headreg , but found not receive cmd data , next_state ==> waiting
                begin
				next_state = waiting;
                m2cmdtest = 4'd0;
                end
		end
		
	receiving:
		if(sample_counter != 5'd23)//every 24us (41.667KHz) move md2udi into rcv_shftreg
            begin
			inc_sample_counter=1;
            m2cmdtest = 4'd0;
            end
		else
			begin
				clr_sample_counter=1;
                m2cmdtest = 4'd0;
				
				if(bit_counter!=6'd34)
					begin
						shift=1;//import 32bits manchester + 2bits check bit manchester
						inc_bit_counter=1;//bit_counter++
					end
				else // when receive all data
					begin
						
						clr_bit_counter=1;
						load=1;
						headshift_clr = 1 ;//clear headreg
						//rcv_shftreg[33:0] , the first 12bits of the received command 
                        case({rcv_shftreg[33],rcv_shftreg[31],rcv_shftreg[29],rcv_shftreg[27],rcv_shftreg[25],rcv_shftreg[23],rcv_shftreg[21],rcv_shftreg[19],rcv_shftreg[17],rcv_shftreg[15],rcv_shftreg[13],rcv_shftreg[11],rcv_shftreg[9],rcv_shftreg[7],rcv_shftreg[5],rcv_shftreg[3]})
                            16'b1100_1000_0000_0001://0xc801  rcv_shftreg曼彻斯特码对应的内容
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting;
                            end
                            16'b1100_1000_0000_0000://0xc800
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting;
                            end
                            16'b1100_1000_0000_0011://0xc803，这个命令后面跟有参数
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;//waiting1都表示后面跟有参数，需要进行参数的接收
                            end
                            16'b1100_1000_0000_1010://0xc80a
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;
                            end                 
                            16'b1100_1000_0011_0011://0xc833
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;
                            end
                            16'b1100_1000_0011_0100://0xc834
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;
                            end
                            
							default:
								next_state=waiting;
						endcase		                                                  
                   end
			end
	waiting:
        begin
        m2cmdtest = 4'd0;
		    if(md2udireg == 1)
            begin
		    next_state = idle;
            end
        end
	waiting1:
		if(md2udireg == 0)     //后面还跟有数据
        	next_state = idle1;
	idle1:
		if(md2udireg == 1)
			begin
				next_state = heading1 ;
				headshift_clr = 1 ;
			end
	heading1:
		if(sample_counter != 5'd9)
			inc_sample_counter = 1 ;
		else
			begin
				headshift = 1 ;
				next_state = starting1 ;
				clr_sample_counter = 1 ;

			end
	starting1:
		begin
			if(sample_counter != 5'd23)//接收的时钟间隔
                begin
					inc_sample_counter = 1 ;
                end
				else
					begin
					headshift = 1 ;
					clr_sample_counter = 1 ;
                    
					end
            if (disturb_cnt != 3'b100)
		        if(headreg[2:0] == 3'b000 || headreg[2:0] == 3'b010  ||headreg[2:0] == 3'b110)
                 next_state = idle1; //前三个数据头不对则重新接收
                 else 
                 next_state = state;
   
            else begin//数据头接收完成

    			if(headreg == 8'b01111001 || headreg == 8'b01111010 || headreg == 8'b01110101 || headreg == 8'b01110110)//data
    				begin
    					loaddata = 1 ;
    					next_state = receiving1 ;
    				end
				
    			if((headreg == 8'b10001001) || (headreg == 8'b10001010) || (headreg == 8'b10000101) || (headreg == 8'b10000110))//cmd
    				begin
    					loaddata = 1 ;//bit_counter=0x10000
    					next_state = receiving ;
    				end
                if(headreg == 8'b00000000)
			    	next_state = idle1;
            end

		end
	receiving1:
		if(sample_counter != 5'd23)
			inc_sample_counter=1;
		else
			begin
				clr_sample_counter=1;
				
				if(bit_counter!=6'd34)
					begin
						shift=1;//import 32bits manchester + 2bits check bit manchester
						inc_bit_counter=1;
					end
				else
					begin
						next_state = waiting1;//接收完成跳转到等待状态
						clr_bit_counter=1;
						load=1;               //接收到的数据载入完成，
						headshift_clr = 1 ;
						m2rxirq_out = 1'b1;		 
					end
			end		
    default:       
           next_state = idle;
   endcase 
end



always @(posedge clock_m2rx24, negedge reset_)
begin
	if(reset_==0)
		begin
			sample_counter<=5'd0;
			bit_counter<=6'd0;
			rcvd_datareg<=0;
			rcv_shftreg<=0;
			headreg <= 8'b00000000 ;
            disturb_cnt = 3'b000;
           wr_fifo_ent <= 1'b0;
		end
	else
		begin
			
			if(headshift_clr == 1)begin
                disturb_cnt = 3'b000;

				headreg <= 8'b00000000 ;
			end
			if(clr_sample_counter==1)
				sample_counter<=5'd0;
				
			if(inc_sample_counter==1)
				sample_counter<=sample_counter + 1'd1;//????
				
			if(inc_delay_cnt == 1)
				delay_cnt <= delay_cnt + 1'd1;
			
			if(clr_delay_cnt == 1)
				delay_cnt <= 4'd0;
			
			if(clr_bit_counter==1)
				bit_counter<=6'd0;
				
			if(inc_bit_counter==1)
				bit_counter<=bit_counter + 1'd1;//????
				
			if(loaddata == 1)
				begin
					bit_counter<=6'd4;
					rcv_shftreg<={rcv_shftreg[29:0],headreg[3:0]};//move headreg[3:0]data into rcv_shftreg
				end
				
			if(shift==1)
				rcv_shftreg<={rcv_shftreg[word_size-2:0],md2udi};//接收cmd
			
			if(headshift == 1)begin
            	headreg <= {headreg[6:0],md2udi};//move datahead into headreg
                if (disturb_cnt != 3'b100)
                      disturb_cnt = disturb_cnt + 3'b001;
                     else
                      disturb_cnt = disturb_cnt;
			
			end
			
			if(load==1)//manchester bits move into rcv_datareg output 
				begin
				    wr_fifo_ent <= 1'b1;
					rcvd_datareg[15]<=rcv_shftreg[33];
					rcvd_datareg[14]<=rcv_shftreg[31];
					rcvd_datareg[13]<=rcv_shftreg[29];
					rcvd_datareg[12]<=rcv_shftreg[27];
					rcvd_datareg[11]<=rcv_shftreg[25];
					rcvd_datareg[10]<=rcv_shftreg[23];
					rcvd_datareg[9]<=rcv_shftreg[21];
					rcvd_datareg[8]<=rcv_shftreg[19];
					rcvd_datareg[7]<=rcv_shftreg[17];
					rcvd_datareg[6]<=rcv_shftreg[15];
					rcvd_datareg[5]<=rcv_shftreg[13];
					rcvd_datareg[4]<=rcv_shftreg[11];
					rcvd_datareg[3]<=rcv_shftreg[9];
					rcvd_datareg[2]<=rcv_shftreg[7];
					rcvd_datareg[1]<=rcv_shftreg[5];
					rcvd_datareg[0]<=rcv_shftreg[3];
				end
		      else    wr_fifo_ent <= 1'b0;
		end
end


always@(negedge clock_m2rx24 or negedge reset_)
begin
    if(!reset_)
        wr_fifo_en1 <= 1'b0;
    else
        wr_fifo_en1 <= wr_fifo_ent;
end


//m2rxirqb输出8个clock_m2rx24周期的高电平
always @(state_ii,m2rxirq_out,int_counter)
begin
	m2rxirqb=0;
	int_counter_inc = 0 ;
	int_counter_clr = 0 ;
	next_state_ii=state_ii ;

	case(state_ii)
	state_1:
		if(m2rxirq_out==1 )
			next_state_ii=state_2;
	state_2:
			if(int_counter == 4'd8)//m2rxirqb保持8个clock_m2rx24周期的高电平
				begin
					int_counter_clr = 1 ;
					m2rxirqb = 1 ;
					next_state_ii=state_1;
				end
			else
				begin
					int_counter_inc = 1 ;
					m2rxirqb = 1 ;
				end
	default:
		next_state_ii=state_1;
		
	endcase
end

always @(posedge clock_m2rx24, negedge reset_)
begin
	if(reset_==0)
		begin
			state_ii <= state_1 ;
			int_counter <= 4'd0 ;
		end
	else
		begin
			state_ii <= next_state_ii ;
			
			if(int_counter_inc == 1)
				int_counter <= int_counter + 1'd1;
				
			if(int_counter_clr == 1)
				int_counter <= 4'd0;
		end
end



endmodule
// cmd_decoder.v
//receive from upper computer
//command data = 1.5bits high + 1.5bits low + 16bits data + 1bit check bit = 20 bits
//data = 1.5bits low + 1.5bits high + 16bits data + 1bit check bit = 20 bits
//free time -> m2udi = 0 
//在接收到命令后要判断命令后面是否有数据，有数据之后的状态都带有1


module cmd_decoder
(
    input md2udi,//input cmd
    input reset_,
    input clock_m2rx24,//clock 1m
    input clock_system,//24mHz
    output [15:0] rcvd_datareg,//receive data,
    output wr_fifo_en,         //接收到数据之后置一，类似于标志位的作用 （时钟是1m）
    output m2rxirqb,          //useless，前面调用这个模块时没有使用这个输出
    //output [3:0] send_cmd;//?interface_m5,interface_m7???send_cmd[3:0]??
                              //receive low 4bits command , 0x34x
    output [3:0] test
);

parameter word_size = 34;
parameter num_state_bits = 10;

parameter idle = 10'b0000000001;
parameter heading = 10'b0000000010;
parameter starting = 10'b0000000100;
parameter receiving = 10'b0000001000;
parameter waiting = 10'b0000010000;
parameter waiting1 = 10'b0000100000;
parameter idle1 = 10'b0001000000;
parameter heading1 = 10'b0010000000;
parameter starting1 = 10'b0100000000;
parameter receiving1 = 10'b1000000000;

parameter state_1=2'b01;
parameter state_2=2'b10;


	
reg [word_size-1:0] rcv_shftreg;//存储到接收到的命令是曼码的形式
reg [4:0] sample_counter;
reg [5:0] bit_counter;
reg inc_bit_counter;
reg clr_bit_counter;
reg inc_sample_counter;
reg clr_sample_counter;
reg shift,load;
reg [15:0] rcvd_datareg;
reg [num_state_bits-1:0] state,next_state;
reg [7:0] headreg ;
reg headshift ;
reg headshift_clr ;
reg loaddata ;
reg m2rxirq_out;
reg md2udireg;
reg [3:0] send_cmd;
reg [3:0] delay_cnt;
reg clr_delay_cnt;
reg inc_delay_cnt;
// reg send_flag;
reg m2cmdtest;
reg wr_fifo_ent,wr_fifo_en1;
reg [1:0] state_ii,next_state_ii;
reg int_counter_inc,int_counter_clr;
reg m2rxirqb;
reg [3:0]int_counter;

reg rst_out_en;
reg [2:0] disturb_cnt;

assign wr_fifo_en = wr_fifo_en1;

//------------test------------
// reg md2udi_;
// always @(posedge clock_system)
// begin
	// if(reset_ == 0)
		// md2udi_ <= 1'b0;
	// else
		// md2udi_ <= md2udi;

// end
//    assign test = {m2cmdtest, m2cmdtest, m2cmdtest, m2cmdtest};
//assign test = {m2cmdtest, m2cmdtest,0,0};


always @(posedge clock_system)
begin
	if(reset_ == 0)
		md2udireg = 1'b0;
	else if(state == idle || state == idle1 || state == waiting || state == waiting1)
		md2udireg = md2udi;

end

always @(posedge clock_m2rx24, negedge reset_)   //状态转移
begin
     if(reset_==0)
     begin
        state<=idle;
     end       
     else
        begin
            state<=next_state;
        end
end

always @(state,md2udireg,headreg,sample_counter,bit_counter,rcv_shftreg,disturb_cnt)
begin
    m2rxirq_out=0;
	clr_sample_counter=0;
	clr_bit_counter=0;
	inc_sample_counter=0;
	inc_bit_counter=0;
	shift=0;
	load=0;
	headshift = 0 ;
	headshift_clr = 0 ;
	loaddata = 0 ;
	next_state=state;
    rst_out_en = 0;
    send_cmd = 4'b0000;
	clr_delay_cnt = 0;
	inc_delay_cnt = 0;
    // send_flag = 0;

	case(state)
	idle:
        begin
        m2cmdtest = 4'd0;
		    if(md2udireg == 1)//when input is high -> next state ==> heading
			begin
				next_state = heading ;
				headshift_clr = 1 ;//clear headreg
//                m2cmdtest = 4'd0;
			end
        end
			
	heading: 
		if(sample_counter != 5'd9)//after input become high 9 periods , next state ==> starting ,,, move md2udi into headreg
            begin
			inc_sample_counter = 1;//means : reg sample_counter ++
            m2cmdtest = 1'd1;
            end
		else
			begin
				headshift = 1 ;//move md2udi into headreg
				next_state = starting ;
				clr_sample_counter = 1 ;//clear sample_counter
				clr_delay_cnt = 1;
                m2cmdtest = 1'd1;
			end
			
	starting:
		begin
			if(sample_counter < 5'd23)//  1M/24.0=41.667KHz ,,, every 24us (41.667KHz) move md2udi into headreg
                begin
				inc_sample_counter = 1 ;
                m2cmdtest = 1'd1;
                end
			else
				begin
				headshift = 1 ;
				clr_sample_counter = 1 ;
				inc_delay_cnt = 1 ; // delay_cnt ++
                m2cmdtest = 1'd1;
				end
				
			if(delay_cnt < 4'd10) // when move 9 bits into headreg , execute  
				begin
					if( (headreg == 8'b10001001) || (headreg == 8'b10001010) || (headreg == 8'b10000101) || (headreg == 8'b10000110) )//when receive cmd data , next_state ==> receiving
					begin
					loaddata = 1 ;//set "bit_counter" to 4 , means receive 4bits data
					next_state = receiving;
                    m2cmdtest = 4'd0;
					end
				end
            else//  after receive 9 bits headreg , but found not receive cmd data , next_state ==> waiting
                begin
				next_state = waiting;
                m2cmdtest = 4'd0;
                end
		end
		
	receiving:
		if(sample_counter != 5'd23)//every 24us (41.667KHz) move md2udi into rcv_shftreg
            begin
			inc_sample_counter=1;
            m2cmdtest = 4'd0;
            end
		else
			begin
				clr_sample_counter=1;
                m2cmdtest = 4'd0;
				
				if(bit_counter!=6'd34)
					begin
						shift=1;//import 32bits manchester + 2bits check bit manchester
						inc_bit_counter=1;//bit_counter++
					end
				else // when receive all data
					begin
						
						clr_bit_counter=1;
						load=1;
						headshift_clr = 1 ;//clear headreg
						//rcv_shftreg[33:0] , the first 12bits of the received command 
                        case({rcv_shftreg[33],rcv_shftreg[31],rcv_shftreg[29],rcv_shftreg[27],rcv_shftreg[25],rcv_shftreg[23],rcv_shftreg[21],rcv_shftreg[19],rcv_shftreg[17],rcv_shftreg[15],rcv_shftreg[13],rcv_shftreg[11],rcv_shftreg[9],rcv_shftreg[7],rcv_shftreg[5],rcv_shftreg[3]})
                            16'b1100_1000_0000_0001://0xc801  rcv_shftreg曼彻斯特码对应的内容
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting;
                            end
                            16'b1100_1000_0000_0000://0xc800
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting;
                            end
                            16'b1100_1000_0000_0011://0xc803，这个命令后面跟有参数
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;//waiting1都表示后面跟有参数，需要进行参数的接收
                            end
                            16'b1100_1000_0000_1010://0xc80a
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;
                            end                 
                            16'b1100_1000_0011_0011://0xc833
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;
                            end
                            16'b1100_1000_0011_0100://0xc834
                            begin
                                m2rxirq_out = 1'b1;
                                next_state = waiting1;
                            end
                            
							default:
								next_state=waiting;
						endcase		                                                  
                   end
			end
	waiting:
        begin
        m2cmdtest = 4'd0;
		    if(md2udireg == 1)
            begin
		    next_state = idle;
            end
        end
	waiting1:
		if(md2udireg == 0)     //后面还跟有数据
        	next_state = idle1;
	idle1:
		if(md2udireg == 1)
			begin
				next_state = heading1 ;
				headshift_clr = 1 ;
			end
	heading1:
		if(sample_counter != 5'd9)
			inc_sample_counter = 1 ;
		else
			begin
				headshift = 1 ;
				next_state = starting1 ;
				clr_sample_counter = 1 ;

			end
	starting1:
		begin
			if(sample_counter != 5'd23)//接收的时钟间隔
                begin
					inc_sample_counter = 1 ;
                end
				else
					begin
					headshift = 1 ;
					clr_sample_counter = 1 ;
                    
					end
            if (disturb_cnt != 3'b100)
		        if(headreg[2:0] == 3'b000 || headreg[2:0] == 3'b010  ||headreg[2:0] == 3'b110)
                 next_state = idle1; //前三个数据头不对则重新接收
                 else 
                 next_state = state;
   
            else begin//数据头接收完成

    			if(headreg == 8'b01111001 || headreg == 8'b01111010 || headreg == 8'b01110101 || headreg == 8'b01110110)//data
    				begin
    					loaddata = 1 ;
    					next_state = receiving1 ;
    				end
				
    			if((headreg == 8'b10001001) || (headreg == 8'b10001010) || (headreg == 8'b10000101) || (headreg == 8'b10000110))//cmd
    				begin
    					loaddata = 1 ;//bit_counter=0x10000
    					next_state = receiving ;
    				end
                if(headreg == 8'b00000000)
			    	next_state = idle1;
            end

		end
	receiving1:
		if(sample_counter != 5'd23)
			inc_sample_counter=1;
		else
			begin
				clr_sample_counter=1;
				
				if(bit_counter!=6'd34)
					begin
						shift=1;//import 32bits manchester + 2bits check bit manchester
						inc_bit_counter=1;
					end
				else
					begin
						next_state = waiting1;//接收完成跳转到等待状态
						clr_bit_counter=1;
						load=1;               //接收到的数据载入完成，
						headshift_clr = 1 ;
						m2rxirq_out = 1'b1;		 
					end
			end		
    default:       
           next_state = idle;
   endcase 
end



always @(posedge clock_m2rx24, negedge reset_)
begin
	if(reset_==0)
		begin
			sample_counter<=5'd0;
			bit_counter<=6'd0;
			rcvd_datareg<=0;
			rcv_shftreg<=0;
			headreg <= 8'b00000000 ;
            disturb_cnt = 3'b000;
           wr_fifo_ent <= 1'b0;
		end
	else
		begin
			
			if(headshift_clr == 1)begin
                disturb_cnt = 3'b000;

				headreg <= 8'b00000000 ;
			end
			if(clr_sample_counter==1)
				sample_counter<=5'd0;
				
			if(inc_sample_counter==1)
				sample_counter<=sample_counter + 1'd1;//????
				
			if(inc_delay_cnt == 1)
				delay_cnt <= delay_cnt + 1'd1;
			
			if(clr_delay_cnt == 1)
				delay_cnt <= 4'd0;
			
			if(clr_bit_counter==1)
				bit_counter<=6'd0;
				
			if(inc_bit_counter==1)
				bit_counter<=bit_counter + 1'd1;//????
				
			if(loaddata == 1)
				begin
					bit_counter<=6'd4;
					rcv_shftreg<={rcv_shftreg[29:0],headreg[3:0]};//move headreg[3:0]data into rcv_shftreg
				end
				
			if(shift==1)
				rcv_shftreg<={rcv_shftreg[word_size-2:0],md2udi};//接收cmd
			
			if(headshift == 1)begin
            	headreg <= {headreg[6:0],md2udi};//move datahead into headreg
                if (disturb_cnt != 3'b100)
                      disturb_cnt = disturb_cnt + 3'b001;
                     else
                      disturb_cnt = disturb_cnt;
			
			end
			
			if(load==1)//manchester bits move into rcv_datareg output 
				begin
				    wr_fifo_ent <= 1'b1;
					rcvd_datareg[15]<=rcv_shftreg[33];
					rcvd_datareg[14]<=rcv_shftreg[31];
					rcvd_datareg[13]<=rcv_shftreg[29];
					rcvd_datareg[12]<=rcv_shftreg[27];
					rcvd_datareg[11]<=rcv_shftreg[25];
					rcvd_datareg[10]<=rcv_shftreg[23];
					rcvd_datareg[9]<=rcv_shftreg[21];
					rcvd_datareg[8]<=rcv_shftreg[19];
					rcvd_datareg[7]<=rcv_shftreg[17];
					rcvd_datareg[6]<=rcv_shftreg[15];
					rcvd_datareg[5]<=rcv_shftreg[13];
					rcvd_datareg[4]<=rcv_shftreg[11];
					rcvd_datareg[3]<=rcv_shftreg[9];
					rcvd_datareg[2]<=rcv_shftreg[7];
					rcvd_datareg[1]<=rcv_shftreg[5];
					rcvd_datareg[0]<=rcv_shftreg[3];
				end
		      else    wr_fifo_ent <= 1'b0;
		end
end


always@(negedge clock_m2rx24 or negedge reset_)
begin
    if(!reset_)
        wr_fifo_en1 <= 1'b0;
    else
        wr_fifo_en1 <= wr_fifo_ent;
end


//m2rxirqb输出8个clock_m2rx24周期的高电平
always @(state_ii,m2rxirq_out,int_counter)
begin
	m2rxirqb=0;
	int_counter_inc = 0 ;
	int_counter_clr = 0 ;
	next_state_ii=state_ii ;

	case(state_ii)
	state_1:
		if(m2rxirq_out==1 )
			next_state_ii=state_2;
	state_2:
			if(int_counter == 4'd8)//m2rxirqb保持8个clock_m2rx24周期的高电平
				begin
					int_counter_clr = 1 ;
					m2rxirqb = 1 ;
					next_state_ii=state_1;
				end
			else
				begin
					int_counter_inc = 1 ;
					m2rxirqb = 1 ;
				end
	default:
		next_state_ii=state_1;
		
	endcase
end

always @(posedge clock_m2rx24, negedge reset_)
begin
	if(reset_==0)
		begin
			state_ii <= state_1 ;
			int_counter <= 4'd0 ;
		end
	else
		begin
			state_ii <= next_state_ii ;
			
			if(int_counter_inc == 1)
				int_counter <= int_counter + 1'd1;
				
			if(int_counter_clr == 1)
				int_counter <= 4'd0;
		end
end



endmodule
