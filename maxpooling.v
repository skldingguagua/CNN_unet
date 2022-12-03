//功能：将 存储有  1层 已经完成好计算的数据  的fifo  （256*256）
// 进行maxpooling，    将maxpooling之后的数据存入新的fifo (128*128)
module maxpooling(clk, reset, in_fifo, max_one, done);
//需要改变的参数： input_size 输入的大小   (fifo1的大小)
    parameter DATA_WIDTH = 16;
    parameter input_size = 256;
    
    //得到inPut_size的位宽
    function integer log2;
        input integer number;
        begin
            log2=0;
            while(2**log2<number) begin
                log2=log2+1;
            end
        end
    endfunction // log2
    localparam                      width_input_size = log2(input_size*input_size);

    input clk;
    input reset;
    input [input_size*input_size*DATA_WIDTH - 1 : 0] in_fifo;  //读取256*256(1层)
    output [15:0] max_one;                                     //经过128*128个clk输出128*128个结果
    output reg done;
    reg[width_input_size - 1:0] col;                                           //0~255  7
    reg[width_input_size - 1:0] row;                                           //0~255




always@(posedge clk or posedge reset)
    begin
        if(reset == 1'b1)
            begin
                col <= 0;
                row <= 0;
            end
        
        else begin
            if(col == input_size - 2)
                if(row == input_size - 2)
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

    reg [15:0] selectedInput1,selectedInput2,selectedInput3,selectedInput4;
    
    pooling uut0
    (
        .floatA0(selectedInput1), 
        .floatA1(selectedInput2), 
        .floatB0(selectedInput3), 
        .floatB1(selectedInput4),
        .max_one(max_one)
    );

    reg i;
    always@(i)
        if (i == (input_size/2)*(input_size/2))
            done = 1'b1;
        else
            done = 1'b0;

	always @ (posedge clk, posedge reset) 
		begin
			if (reset == 1'b1) 
				begin // reset
                    selectedInput1 <= 0;
					selectedInput2 <= 0;
                    selectedInput3 <= 0;
                    selectedInput4 <= 0;
					             i <= 0;
				end 
			else if (i == (input_size/2)*(input_size/2) ) 
				begin // if the convolution is finished but we still wait for other blocks to finsih, send zeros to the conv unit (in case of pipelining)
					selectedInput1 <= 0;
					selectedInput2 <= 0;
                    selectedInput3 <= 0;
                    selectedInput4 <= 0;
							  	 i <= i + 1;
				end 
			else if (i > (input_size/2)*(input_size/2) ) 
				begin // if the convolution is finished but we still wait for other blocks to finsih, send zeros to the conv unit (in case of pipelining), send idle to suggest that work is done
					selectedInput1 <= 0;
					selectedInput2 <= 0;
                    selectedInput3 <= 0;
                    selectedInput4 <= 0;
				end 
			else 
				begin // send one element of the image part and one element of the filter to be multiplied and accumulated
					selectedInput1 <= in_fifo[(row*input_size + col)*DATA_WIDTH +: DATA_WIDTH];
					selectedInput2 <= in_fifo[(row*input_size + col + 1)*DATA_WIDTH +: DATA_WIDTH];
                    selectedInput3 <= in_fifo[((row+1)*input_size + col)*DATA_WIDTH +: DATA_WIDTH];
                    selectedInput4 <= in_fifo[((row+1)*input_size + col + 1)*DATA_WIDTH +: DATA_WIDTH];
								 i <= i + 1;
				end
		end
endmodule
