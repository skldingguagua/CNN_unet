`timescale 100 ns / 100 ns
module padding_fifo_convUnit_fifo_TB();
    parameter p = 1;
    parameter input_size = 256;
    parameter num =  256;                     // (256+2 - 3)/1 + 1  = 256  , 输出的行数与列数
    parameter D = 3;
    parameter F = 3;
    parameter DATA_WIDTH = 16;
    localparam PERIOD = 100;



    reg clk;
    reg reset;
    wire [DATA_WIDTH-1:0] result_0;
    wire [DATA_WIDTH-1:0] max_one_0;
    //integer handle,handle1;
    wire idle;

always
	#(PERIOD/2) clk = ~clk; 


    initial
    begin
        #0
            clk = 1'b0;
            reset = 1'b1;
        #18                  //reset 不可以与时钟周期重合�? 会导致padding之后的第�?个数据读不进去fifo
            reset <= 1'b0;

        //#(256*256*PERIOD + 256*256*31*PERIOD + 256*3*PERIOD)




    end
    /*
    always@(posedge idle)
    begin
            $fwrite(handle,"%h\n",result_0);
    end
    
    always@(result_0)
    begin
            $fwrite(handle1,"%h\n",max_one_0);
    end
    */

padding_fifo_convUnit_fifo uut1(
    .clk(clk),
    .reset(reset),
    .result_0(result_0),
    //.max_one_0(max_one_0),
    .idle(idle)
    
);

endmodule