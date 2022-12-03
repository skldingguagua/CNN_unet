//所采用的buffer结构是循环结构 ：circle buffer
//假设buffer size为 256 ，data——width为16
//初始状态 ，w_ptr与r_ptr在同一个位置，代表fifo为空，
//每次往fifo写入数据，w_ptr + 1,指向下一个等待写入的空单元
//每次从fifo写出数据，r_ptr + 1,指向下一个准备读取的满单元
//所以一般情况下，都是r_ptr 追逐着 w_ptr 而上升, 
//与一般的fifo不同的是，ptr在达到边界 (size - 1)时，会指向0，
//fifo如果存满，那么w_ptr与r_ptr重合，与空fifo无法区分
//所以fifo实际存储的只有 size - 1个元素 

//num是waddr , raddr 的位宽
//考虑到卷积计算都是 256*256 128*128 64*64 ，刚好是2的整数次幂，
// eg: 输入最大size为 256*256， 位宽就是8+8 = 16bit
//按理来说 只要是 [15：0]就可以  但是我们必须读入256个数据 fifo其实需要257个的大小，
//所以位宽必须是 [16:0]


module fifo(clk, reset, write, read, data_in, data_out, out_verify, empty, full);


parameter DATA_WIDTH = 16;

parameter size = 256*256;
parameter D = 3;
parameter F = 3;

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
input read;
input [D*F*F*DATA_WIDTH-1:0]data_in;

output reg [D*F*F*DATA_WIDTH-1:0]data_out;
output reg out_verify,empty,full;

reg [num:0]waddr, raddr;     //waddr，raddr分别记录读写的位置， cnt记录总计写入到fifo的元素个数（最终应该是与num相同）
reg [D*F*F*DATA_WIDTH-1:0] mem [0:size];

always@(posedge clk or posedge reset)
    if (reset == 1'b1)
        begin
            waddr <= 0;
            raddr <= 0;
            full  <= 0;
            out_verify <= 0;
            empty <= 0;
        end
    else if (write == 1'b1)
        begin
            if (waddr < size && raddr == waddr + 1'b1 ) //fifo满了的一般情况
                full <= 1'b1;
            else if (waddr == size && raddr == 1'b0)  //fifo满了的特殊情况
                full <= 1'b1;
            else
                begin
                    mem[waddr] <= data_in;
                    if (waddr == size )
                        waddr      <=         1'b0;
                    else
                        waddr      <= waddr + 1'b1;
                end 
        end
    else if (read == 1'b1)
        begin
            if (waddr != raddr)      //还未空，可以将数据读出
                begin
                    data_out <= mem[raddr];
                    out_verify <= 1'b1;

                    if (raddr == size)
                        raddr <= 1'b0;
                    else
                        raddr <= raddr + 1'b1;
                end
            else
                empty <= 1'b1;
        end
    else
        begin
                out_verify <= 1'b0;
                full       <= 1'b0;
                empty      <= 1'b0;
        end
endmodule