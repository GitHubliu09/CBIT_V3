`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////

module peak_data_ram(
wclk,
waddr,
din_sync,
din,
rclk,
re,
ra,
dout
    );

input wclk;
input [13:0]waddr;
input din_sync;
input [15:0]din;
input rclk;
input re;
input [13:0]ra;
output [15:0]dout;

wire sbiterr,dbiterr;
wire [13:0]rdaddrecc;

blk_mem_gen_2 ram0(
.clka(wclk),
.ena(din_sync),
.wea(din_sync),
.addra(waddr),
.dina(din),
.clkb(rclk),
.enb(re),
.addrb(ra),
.doutb(dout),
.sbiterr(sbiterr),
.dbiterr(dbiterr),
.rdaddrecc(rdaddrecc)
);

endmodule
