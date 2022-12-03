`timescale 100 ns / 10 ps
/*比较 A与B的大小， B>A时减出来的余数是正的，MSB为0 ，sign为0
    进行B-A的运算   B<A时减出来的余数是负的，MSB为1 ，sign为1
  所以 A>B 时有 sign = 1，是组合逻辑输出
*/
module comparator (floatA,floatB,bigger_one);
	
input [15:0] floatA, floatB;
wire [15:0] floatA_minus;
wire [15:0] sub_sum;
wire sign;
output [15:0] bigger_one;

assign floatA_minus = {~floatA[15],floatA[14:0]};

floatAdd16 uut1
(.floatB(floatB),
 .floatA(floatA_minus),
 .sum(sub_sum)
);

assign sign = sub_sum[15];
assign bigger_one = sign ? floatA : floatB;

endmodule