// address_latch.v
module address_latch
(
	XZ6_CS, DSP_MA, MA,rst_ctrl
);

	input XZ6_CS;//???DSP????XZCS0AND1
    input [11:0]DSP_MA;//???DSP?????dsp_A[11:0]
    input rst_ctrl;
    output [11:0] MA;

    assign MA   = (!rst_ctrl)?12'b0:((XZ6_CS==0)? DSP_MA : MA);

endmodule 

// address_latch.v
module address_latch
(
	XZ6_CS, DSP_MA, MA,rst_ctrl
);

	input XZ6_CS;//???DSP????XZCS0AND1
    input [11:0]DSP_MA;//???DSP?????dsp_A[11:0]
    input rst_ctrl;
    output [11:0] MA;

    assign MA   = (!rst_ctrl)?12'b0:((XZ6_CS==0)? DSP_MA : MA);

endmodule 

