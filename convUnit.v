
module convUnit
#(
parameter DATA_WIDTH = 16,
parameter origin_side = 256,
parameter D = 3, //depth of the filter
parameter F = 3, //size of the filter
parameter filter_num = 16
)
(clk,reset,RST, image,result,idle);

//功能是image与filter做3*3*3与3*3*3的卷积
//其中image与filter的小端顺序是为了86，87行正确地给selectedInput0/1赋值，这样做的结果是：
//result[16*DATA_WIDTH-1:0] 最低16位是第一个filter核的conv输出结果，最高16位是第16个filter

input clk, reset,RST;
input [0:D*F*F*DATA_WIDTH-1] image; // image输入是3*3*3的块
wire [0:filter_num*D*F*F*DATA_WIDTH-1] filter;// filter输入是3*3*3的块  共16个filter
output wire [filter_num*DATA_WIDTH-1:0] result;
output reg idle;

//对应16个processingUnit的输入
reg [DATA_WIDTH-1:0] selectedInput1 [filter_num - 1:0];
reg [DATA_WIDTH-1:0] selectedInput2 [filter_num - 1:0];

reg [DATA_WIDTH-1:0]mem2[0:filter_num*D*F*F -1];//使用mem作为中介从txt将系数读到filter

integer i;

initial
//载入16个3*3*3的filter系数
begin			
    $readmemh("C:/Users/sunkaili/Desktop/txt/kernel_IEEE16/IEEE16_conv2d.txt",mem2,0,filter_num*D*F*F - 1);
end 

//初始化kernel的值
generate
genvar j;
for (j = 0; j <= filter_num*F*F*D - 1; j = j + 1)
    begin: label0
        //assign image_temp[j*DATA_WIDTH+:DATA_WIDTH] = mem[j];
        assign filter[j*DATA_WIDTH +: DATA_WIDTH] = mem2[j];
    end
endgenerate

genvar k;
generate
	for (k = 0; k <= filter_num - 1; k = k + 1)
		begin: label1

		processingElement16 PE
			(
				.reset(reset),
				.floatA(selectedInput1[k]),
				.floatB(selectedInput2[k]),
				.result(result[k*DATA_WIDTH +: DATA_WIDTH])
			);

		// The convolution is calculated in a sequential process to save hardware
		// The result of the element wise matrix multiplication is finished after (F*F+2) cycles (2 cycles to reset the processing element and F*F cycles to accumulate the result of the F*F multiplications) 
			always @ (posedge clk, posedge reset, posedge RST) 
				if (RST == 1'b1)
					idle <= 1'b1;
				else 
				begin
					if (reset == 1'b1) 
						begin // reset
							i <= 0;
							selectedInput1[k] <= 0;
							selectedInput2[k] <= 0;
									  idle <= 0;
						end 
					else if (i == D*F*F) 
						begin // if the convolution is finished but we still wait for other blocks to finsih, send zeros to the conv unit (in case of pipelining)
							selectedInput1[k] <= 0;
							selectedInput2[k] <= 0;
									  idle <= 0;
									  	 i <= i + 1;
						end 
					else if (i > D*F*F) 
						begin // if the convolution is finished but we still wait for other blocks to finsih, send zeros to the conv unit (in case of pipelining), send idle to suggest that work is done
							selectedInput1[k] <= 0;
							selectedInput2[k] <= 0;
									  idle <= 1;
						end 
					else 
						begin // send one element of the image part and one element of the filter to be multiplied and accumulated
							selectedInput1[k] <= image[i*DATA_WIDTH+:DATA_WIDTH];
							selectedInput2[k] <= filter[k*D*F*F*DATA_WIDTH + i*DATA_WIDTH+:DATA_WIDTH];
										 i <= i + 1;
									  idle <= 0;
						end
				end
		end
endgenerate
endmodule
