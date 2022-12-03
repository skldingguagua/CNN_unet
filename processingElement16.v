`timescale 100 ns / 10 ps

module processingElement16(reset,floatA,floatB,result);

parameter DATA_WIDTH = 16;

input reset;
input [DATA_WIDTH-1:0] floatA, floatB;
output reg [DATA_WIDTH-1:0] result;

reg [DATA_WIDTH-1:0] floatA_reg, floatB_reg;
wire [DATA_WIDTH-1:0] multResult;
wire [DATA_WIDTH-1:0] addResult;

floatMult16 FM (floatA_reg,floatB_reg,multResult);
floatAdd16 FADD (multResult,result,addResult);

always @ (floatA or floatB or reset) begin
	if (reset == 1'b1) begin
		result = 0;
		floatA_reg = 0;
		floatB_reg = 0;
	end else begin
		floatA_reg = floatA;
		floatB_reg = floatB;
		result = addResult;
	end
end


endmodule

