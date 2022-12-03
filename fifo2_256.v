//fifo256是特殊的fifo2，
//为了处理输入为256*256而特别设计：以规避输出[256*256*DATA_WIDTH -  1 : 0]all 
//其位宽 1048576大于1000000 的问题 ，转而用all_1,all_2,两个[128*256*DATA_WIDTH -  1 : 0]来输出
module fifo2_256(clk, reset, write, data_in, full, all_1, all_2);

parameter DATA_WIDTH = 16;
parameter size = 256*256;
parameter half_size = 256*128;

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


output wire [half_size*DATA_WIDTH-1:0]all_1;
output wire [half_size*DATA_WIDTH-1:0]all_2;

output reg full;

reg [num:0]waddr;     
reg [DATA_WIDTH-1:0] mem [half_size-1:0];
reg [DATA_WIDTH-1:0] mem2 [half_size-1:0];

genvar i;
    generate
        for (i = 0; i < half_size; i = i + 1)
            begin: all_memory
                assign all_1[i*DATA_WIDTH +: DATA_WIDTH] = mem[i];
                assign all_2[i*DATA_WIDTH +: DATA_WIDTH] = mem2[i];
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
            if (waddr == size ) //fifo满了  (0,size-1)装有元素， size处是waddr停放的位置，并不存放元素
                full <= 1'b1;
            else
                begin
                    if(waddr < half_size ) //waddr为（0，half - 1)  
                        mem[waddr] <= data_in;
                    else      //waddr为（half，2*half - 1)
                        //要注意mem2是0，half-1   代表half，2*half-1
                        mem2[waddr - half_size] <= data_in;
                    waddr      <= waddr + 1'b1;
                end 
        end
    else
        full     <= 1'b0;

endmodule