`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
module m2_send(
    input empty, //fifo empty flag
    input rstn,
    input clock_41p766k,
    input [15:0] data,
    output reg rd_en,
    output m2_bzo,
    output m2_boo
    );
parameter cmd_head = 6'b000111;
parameter data_head = 6'b000111;

parameter IDLE = 11'b000_0000_0001;
parameter START = 11'b000_0000_0010;//产生fifo读使能
parameter START1 = 11'b000_0000_0100;
parameter LOAD_CMD = 11'b000_0000_1000;//加载命令
parameter SET_CMD_PARITY = 11'b000_0001_0000;//设置校验位
parameter ENCODE_M2_CMD = 11'b000_0010_0000;//编码命令
parameter SEND_CMD = 11'b000_0100_0000;//发送命令
parameter LOAD_DATA = 11'b000_1000_0000;//加载数据
parameter SET_DATA_PARITY = 11'b001_0000_0000;//设置校验位
parameter ENCODE_M2_DATA = 11'b010_0000_0000;//编码数据
parameter SEND_DATA = 11'b100_0000_0000;//发送数据

reg parity;
reg empty_r1;
reg empty_r2;
reg [15:0] data_reg;
reg [5:0] bit_count;
reg [39:0] code_reg;

reg [10:0] current_state, next_state;

assign m2_bzo = code_reg[39];
assign m2_boo = ~code_reg[39];
always @(posedge clock_41p766k or negedge rstn)
begin
	if(!rstn)
		begin
			empty_r1 <= 1'b1;
			empty_r2 <= 1'b1;
		end
	else
		begin
			empty_r1 <= empty;
			empty_r2 <= empty_r1;
		end
end

always @(posedge clock_41p766k or negedge rstn)
begin
	if(!rstn)
		current_state <= IDLE;
	else	
		current_state <= next_state;
end

always @(current_state, empty_r2, bit_count)
begin
	next_state = current_state;
	case(current_state)
	IDLE:
		if(empty_r2 == 1'b0)  //empty_r2 == 1'b0  则fifo中有数据
			next_state = START;
	START:
		next_state = START1;
	START1:
		next_state = LOAD_CMD;
	LOAD_CMD:
		next_state = SET_CMD_PARITY;
	SET_CMD_PARITY:
		next_state = ENCODE_M2_CMD;
	ENCODE_M2_CMD:
		next_state = SEND_CMD;
	SEND_CMD:
		if((empty_r2 == 1'b0) && (bit_count == 6'd40))
			next_state = LOAD_DATA;
		else if((empty_r2 == 1'b1) && (bit_count == 6'd40))
			next_state = IDLE;
	LOAD_DATA:
		next_state = SET_DATA_PARITY;
	SET_DATA_PARITY:
		next_state = ENCODE_M2_DATA;
	ENCODE_M2_DATA:
		next_state = SEND_DATA;
	SEND_DATA:
		if(empty_r2 == 1'b0 && (bit_count == 6'd40))
			next_state = LOAD_DATA;
		else if((empty_r2 == 1'b1) && (bit_count == 6'd40))
			next_state = IDLE;
	default:
		next_state = IDLE;
	endcase
end

always @(posedge clock_41p766k or negedge rstn)
begin
	if(!rstn)
		begin
			data_reg <= 16'd0;
			bit_count <= 6'd0;
			parity <= 1'b0;
			code_reg <= 40'd0;
			rd_en <= 1'b0;
		end
	else
		begin
			case(next_state)
			IDLE:
				bit_count <= 6'd0;
			START:
				begin
					rd_en <= 1'b1;
				end
			START1:
				rd_en <= 1'b0;
			LOAD_CMD, LOAD_DATA:
				begin
				    data_reg <= data;
					//data_reg[15:8] <= data[7:0];
					//data_reg[7:0] <= data[15:8];
					bit_count <= 6'd0;
				end
			SET_CMD_PARITY, SET_DATA_PARITY:
				parity <= ^data_reg;  //对数据取异或，获取奇偶校验位，M2采用的是奇校验位
			ENCODE_M2_CMD:
				begin
				/********************************************************************
				    将不归零码转换成曼码，不归零码的1就是曼码的10
					不归零码data_reg =1的话输出的曼码code_reg就是10					
				*********************************************************************/
					code_reg[1:0] <= parity ? 2'b01:2'b10;  //注意 2'b01:2'b10;此处和下面的不同
					code_reg[3:2] <= data_reg[0]? 2'b10:2'b01;
					code_reg[5:4] <= data_reg[1]? 2'b10:2'b01;
					code_reg[7:6] <= data_reg[2]? 2'b10:2'b01;
					code_reg[9:8] <= data_reg[3]? 2'b10:2'b01;
					code_reg[11:10] <= data_reg[4]? 2'b10:2'b01;
					code_reg[13:12] <= data_reg[5]? 2'b10:2'b01;
					code_reg[15:14] <= data_reg[6]? 2'b10:2'b01;
					code_reg[17:16] <= data_reg[7]? 2'b10:2'b01;
					code_reg[19:18] <= data_reg[8]? 2'b10:2'b01;
					code_reg[21:20] <= data_reg[9]? 2'b10:2'b01;
					code_reg[23:22] <= data_reg[10]? 2'b10:2'b01;
					code_reg[25:24] <= data_reg[11]? 2'b10:2'b01;
					code_reg[27:26] <= data_reg[12]? 2'b10:2'b01;
					code_reg[29:28] <= data_reg[13]? 2'b10:2'b01;
					code_reg[31:30] <= data_reg[14]? 2'b10:2'b01;
					code_reg[33:32] <= data_reg[15]? 2'b10:2'b01;
					code_reg[39:34] <= cmd_head;
				end
			SEND_CMD, SEND_DATA:
				begin
					code_reg <= {code_reg[38:0],1'b0};
					bit_count <= bit_count + 6'd1;
					if(bit_count == 6'd38)
						rd_en <= 1'b1;
					else if(bit_count == 6'd39)
						rd_en <= 1'b0;
				end
			ENCODE_M2_DATA:
				begin
					code_reg[1:0] <= parity ? 2'b01:2'b10;
					code_reg[3:2] <= data_reg[0]? 2'b10:2'b01;
					code_reg[5:4] <= data_reg[1]? 2'b10:2'b01;
					code_reg[7:6] <= data_reg[2]? 2'b10:2'b01;
					code_reg[9:8] <= data_reg[3]? 2'b10:2'b01;
					code_reg[11:10] <= data_reg[4]? 2'b10:2'b01;
					code_reg[13:12] <= data_reg[5]? 2'b10:2'b01;
					code_reg[15:14] <= data_reg[6]? 2'b10:2'b01;
					code_reg[17:16] <= data_reg[7]? 2'b10:2'b01;
					code_reg[19:18] <= data_reg[8]? 2'b10:2'b01;
					code_reg[21:20] <= data_reg[9]? 2'b10:2'b01;
					code_reg[23:22] <= data_reg[10]? 2'b10:2'b01;
					code_reg[25:24] <= data_reg[11]? 2'b10:2'b01;
					code_reg[27:26] <= data_reg[12]? 2'b10:2'b01;
					code_reg[29:28] <= data_reg[13]? 2'b10:2'b01;
					code_reg[31:30] <= data_reg[14]? 2'b10:2'b01;
					code_reg[33:32] <= data_reg[15]? 2'b10:2'b01;
					code_reg[39:34] <= data_head;
				end	
			endcase
			end
end

endmodule
