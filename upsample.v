//这里实现的是最后一层128*128*32 -> 256*256*16的conv_transpose
//每个clk输入 1*1*32 ，32代表层数 ， 一共

//这里说明一下：conv层的参数是按照 列，行，层，个的顺序扫描的
//        conv_tran层的参数是按照 层，列，行，个的顺序扫描的


//所设想的工作流程：
//  1.  先读入16个 2*2*32的kernel系数
//  2.  一口气读入 128*128个数，准备upsample
//    3.  128*128的fifo，每个clk读出1个，并行共32个（层）输入到upsample模块中
//    4.  1*1*32的输入 经过2*2*32 的kernel卷积，经过32个clk后，得到2*2*1的输出
//  上述3，4步经过128*128次后，就得到一个 256*256*1大小的块（128*128 个2*2的块拼接出来的）
//  一共16个filter， 输出 256*256*16

//控制逻辑：前面一个fifo存满后(128*128)，发出full信号，用~full信号作reset启动
//
module upsample(clk, RST, up_in, idle);

parameter input_size = 128;
parameter output_size = input_size*2;
parameter D = 32;
parameter filter_num = 16;


input clk,RST;
input [D*DATA_WIDTH - 1:0] up_in;       //输入是  1*1*32,一共输入128*128次
reg idle;
output [4*DATA_WIDTH - 1 : 0] result

reg [2*2*D*DATA_WIDTH - 1:0]kernel[0:filter_num - 1];
reg [2*2*D*DATA_WIDTH - 1:0]mem2[  0:filter_num - 1];

//读取16个kernel 每个kernel为 2*2*32
initial
    begin
         $readmemh("C:/Users/sunkaili/Desktop/txt/kernel_trans_IEEE16/IEEE16_conv2d_transpose_3.txt",mem2,0,2*2*D*filter_num - 1);
    end
//给16个kernel赋值
generate
genvar j;
for (j = 0; j <= filter_num - 1; j = j + 1)
    begin: label0


		reg [D*DATA_WIDTH - 1: 0] k0,k1,k2,k3;
		reg [DATA_WIDTH - 1  : 0] selectedInput, selectedInput_k0,selectedInput_k1,selectedInput_k2,selectedInput_k3;
		reg [4*DATA_WIDTH - 1: 0] result;
        always@(*)
		//准备好2*2*32的kernel系数， 下一步例化4个PE来计算结果
		begin
			k0 = kernel[j][ 0              +: D*DATA_WIDTH];
        	k1 = kernel[j][ 1*D*DATA_WIDTH +: D*DATA_WIDTH];
			k2 = kernel[j][ 2*D*DATA_WIDTH +: D*DATA_WIDTH];
			k3 = kernel[j][ 3*D*DATA_WIDTH +: D*DATA_WIDTH];
		end
		//  1/4  计算upsample后的2*2结果的左上角
		processingElement16 PE
			(
				.reset(reset),
				.floatA(selectedInput),
				.floatB(selectedInput_k0),
				.result(result[0*DATA_WIDTH +: DATA_WIDTH])
			);
		//  2/4  计算upsample后的2*2结果的右上角
		processingElement16 PE
			(
				.reset(reset),
				.floatA(selectedInput),
				.floatB(selectedInput_k1),
				.result(result[1*DATA_WIDTH +: DATA_WIDTH])
			);
		//  3/4  计算upsample后的2*2结果的左下角
		processingElement16 PE
			(
				.reset(reset),
				.floatA(selectedInput),
				.floatB(selectedInput_k2),
				.result(result[2*DATA_WIDTH +: DATA_WIDTH])
			);
		//  4/4  计算upsample后的2*2结果的右下角
		processingElement16 PE
			(
				.reset(reset),
				.floatA(selectedInput),
				.floatB(selectedInput_k3),
				.result(result[3*DATA_WIDTH +: DATA_WIDTH])
			);
		//异步复位，同步清零
		integer i;

		always @ (posedge clk, posedge reset, posedge RST) 
				if (RST == 1'b1)
					idle <= 1'b1;
				else 
				begin
					if (reset == 1'b1) 
						begin // reset
							i <= 0;
							selectedInput <= 0;
							selectedInput_k0 <= 0;
							selectedInput_k1 <= 0;
							selectedInput_k2 <= 0;
							selectedInput_k3 <= 0;
									  idle <= 0;
						end 
					else if (i == D) 
						begin // if the convolution is finished but we still wait for other blocks to finsih, send zeros to the conv unit (in case of pipelining)
							selectedInput <= 0;
							selectedInput_k0 <= 0;
							selectedInput_k1 <= 0;
							selectedInput_k2 <= 0;
							selectedInput_k3 <= 0;
									  idle <= 0;
									  	 i <= i + 1;
						end 
					else if (i > D) 
						begin // if the convolution is finished but we still wait for other blocks to finsih, send zeros to the conv unit (in case of pipelining), send idle to suggest that work is done
							selectedInput <= 0;
							selectedInput_k0 <= 0;
							selectedInput_k1 <= 0;
							selectedInput_k2 <= 0;
							selectedInput_k3 <= 0;
									  idle <= 1;
						end 
					else 
						begin // send one element of the image part and one element of the filter to be multiplied and accumulated
							selectedInput     <= up_in[i*DATA_WIDTH+:DATA_WIDTH];
							selectedInput_k0  <= k0   [i*DATA_WIDTH+:DATA_WIDTH];
							selectedInput_k1  <= k1   [i*DATA_WIDTH+:DATA_WIDTH];
							selectedInput_k2  <= k2   [i*DATA_WIDTH+:DATA_WIDTH];
							selectedInput_k3  <= k3   [i*DATA_WIDTH+:DATA_WIDTH];
										 i <= i + 1;
									  idle <= 0;
						end
				end



				//拼接模块，将2*2的result拼接成256*256
				//每次idle 0->1时，取2*2*1 的 result ，拼接
				//下面的函数用于自动生成output_size的位宽。设置给row与col ，保证不溢出
				function integer log2;
				        input integer number;
				        begin
				            log2=0;
				            while(2**log2<number) begin
				                log2=log2+1;
				            end
				        end
				    endfunction // log2
				localparam                      width_output_size = log2(output_size*output_size);


				reg [width_output_size - 1: 0]col;
				reg [width_output_size - 1: 0]row;

				//每经过32个clk输出一个元素,idle 0->1
				always@(posedge idle or posedge RST)
					if(RST = 1'b1)
						col <= 1'b0;
						row <= 1'b0;
				else 
					begin
				        	    if(col == output_size - 2)
				        	        if(row == output_size - 2)
				        	            begin
				        	                row <= row;
				        	                col <= col;
				        	            end
				        	        else begin
				        	                row <= row + 2'd2;
				        	                col <= 0;
				        	            end
				        	    else
				        	        col <= col + 2'd2;
				        	    end
				    end

		//用来一次性全部输出的fifo
		reg [DATA_WIDTH-1:0] mem [output_size*output_size - 1 : 0];

	always@(*)
		begin
			mem[row*output_size + col]         = result[0*DATA_WIDTH +: DATA_WIDTH];
			mem[row*output_size + col + 1]     = result[1*DATA_WIDTH +: DATA_WIDTH];
			mem[(row+1)*output_size + col]     = result[2*DATA_WIDTH +: DATA_WIDTH];
			mem[(row+1)*output_size + col + 1] = result[3*DATA_WIDTH +: DATA_WIDTH];
		end

/*
end
endgenerate
*/

endmodule


