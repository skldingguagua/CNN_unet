//fifo2是用于全部读取的fifo，每个mem只存放一个DATA_WIDTH的内容
//在读入所有内容后 发出full信号，并且将内容全部输出到下一个模块
//取消了循环读写的功能
module fifo2(clk, reset, write, data_in, full, all);

parameter DATA_WIDTH = 16;
parameter size = 256*256;

function integer log2;
        input integer number;
        begin
            log2=0;
            while(2**log2<number) begin
                log2=log2+1;
            end
        end
endfunction // log2
localparam num = log2(size); 


input clk;
input reset;
input write;
input [DATA_WIDTH-1:0]data_in;


output wire [size*DATA_WIDTH-1:0]all;
output reg full;

reg [num:0]waddr;     
reg [DATA_WIDTH-1:0] mem [0:size];

genvar i;
    generate
        for (i = 0; i < size; i = i + 1)
            begin: all_memory
                assign all[i*DATA_WIDTH +: DATA_WIDTH] = mem[i];
            end
    endgenerate
    
always@(posedge clk or posedge reset)
    if (reset == 1'b1)
        begin
            waddr <= 0;
            full  <= 0;
        end
    else if (write == 1'b1)
        begin
            if (waddr == size ) //fifo满了
                full <= 1'b1;
            else
                begin
                    mem[waddr] <= data_in;
                    waddr      <= waddr + 1'b1;
                end 
        end
    else
        full     <= 1'b0;

endmodule