

/*
    一个完整的卷积过程， 
    先把256*256*3*16的数据进行padding ，分成256*256个3*3*3*16的块用fifo储存，
    fifo存储满了，发出的full信号高电平，
    给到convUnit的reset端，idle = 1, 导致read1 = 1，
    从fifo读出一个数据到convUnit，out_verify



    功能是：
    将大小，深度确定好的input feature map 输入，进行padding
    按照指定好filter_num (filter_num 也就是所输出的新的 feature map 的深度)
    之后送入convUnit 进行卷积计算 (filter系数初始化 在convUnit中完成)

*/
module padding_fifo_convUnit_fifo(clk, reset, result, result_0, idle);
//需要改变的参数： input_size  输入的大小
//                D 输入的深度
//                filter_num kernel的个数
    parameter p = 1;
    parameter input_size = 256;
    parameter num =  256;                     // (256+2 - 3)/1 + 1  = 256  , 输出的行数与列数，对应num还会生成receive_fifo所需要的
    parameter D = 3;
    parameter F = 3;
    parameter DATA_WIDTH = 16;
    localparam filter_num = 16;

input clk,reset;
output wire [DATA_WIDTH-1:0] result_0; //展现conv计算后的结果
//wire [input_size*input_size*DATA_WIDTH - 1: 0] all_result_0;
output wire [filter_num*DATA_WIDTH-1:0] result ;
wire [15:0] max_one [filter_num-1:0];
//output [DATA_WIDTH-1:0]max_one_0;    //展现pooling 的结果



output wire idle;
reg idle_1;
reg RST;
reg read1;
wire out_verify;

wire [F*F*D*DATA_WIDTH -1 : 0] out,out1;  //一次是从padding读到fifo，一次是从fifo读到convUnit
wire full;
reg reset1;
reg full_sign;
reg write1, write1_d1;


always@(posedge clk)
    write1_d1 <= write1;


//把write1往后打一拍，然后取中间的部分，形成长度为一个clk的脉冲信号RST  注意哪一个是0，哪一个是1
always@(*)
    if(write1 == 1'b0 && write1_d1 == 1'b1)
        RST = 1'b1;
    else 
        RST = 1'b0;

//关于reset1(convUnit 的 reset)
//reset需要同时检测到idle为1时out_verify 1->0的下跳变
//                和out_verify为0时idle 0->1的上跳变
/*always@(posedge RST or posedge idle or negedge out_verify)

    if (RST == 1'b1)
        reset1 <= 1'b1; 
    //检测下跳变
    else 
        if (out_verify == 1'b0 )
            reset1 <= 1'b0;
    //检测上跳变
    else if (idle == 1'b1 )
        reset1 <= 1'b1;
    else
        reset1 <= reset1;
*/

// 但是这两者在触发之后的判断结果都是 out_verify = 0, idle = 1
// 而且电路并不能判断是哪一种跳变导致这种结果，所以要换思路实现
//   区分开两种触发, 单独检测上升沿与下降沿
reg idle_d1,idle_d2;
reg idle_pulse;
reg out_verify_d1;
reg out_verify_pulse;

//打一拍来形成脉冲，利用脉冲来检测沿
always@(posedge clk or posedge reset)
    begin
        if(reset == 1'b1)
            begin
            out_verify_d1 <= 1'b0;
            idle_d1       <= 1'b0;
            idle_d2       <= 1'b0;
            end
        else
            begin
            out_verify_d1 <= out_verify;
            idle_d1       <= idle;
            idle_d2       <= idle_d1;
            end
    end

always@(*)
    begin
        if(idle_d2 == 1'b0 && idle_d1 == 1'b1)
            idle_pulse = 1'b1;
        else
            idle_pulse = 1'b0;

        if(out_verify_d1 == 1'b0 && out_verify == 1'b1)
            out_verify_pulse = 1'b1;
        else
            out_verify_pulse = 1'b0;
    end

always@(posedge RST or posedge idle_pulse or negedge out_verify_pulse)
    begin
        if (RST == 1'b1)
            reset1 <= 1'b1; 
        else if (idle_pulse == 1'b1 )
            reset1 <= 1'b1;
        else if (out_verify_pulse == 1'b0 )
                reset1 <= 1'b0;
        else
            reset1 <= reset1;
    end


//为了让read精确的只持续一个时钟周期，
//因为使idle来使read上升
//利用idle打一拍的idle_d1来使read下降
always@(posedge clk or posedge reset)
    if (reset)
        idle_1 <= 1'b0;
    else
        idle_1 <= idle;

always@(posedge idle or posedge idle_1) //记得延后一拍的先进行判定
    if (idle_1)
        read1 <= 1'b0;
    else if(idle)
        read1 <= 1'b1;
    else
        read1 <= read1;




always@(posedge reset or posedge clk)
    if (reset == 1'b1)
        write1 <= 1'b0;
    else
        begin
        if (full_sign == 1'b1)
            write1 <= 1'b0;
        else
            write1 <= 1'b1;
        end

always@(posedge full)
    if(full)
        full_sign <= 1'b1;
    else
        full_sign <= 1'b0;


reg write2; // write2 与 read1 是同一个逻辑 在idle拉高的时候读入convUnit计算完成后的结果
            //但是有一个重要差别： fifo在第一个由于RST导致idle拉高时不读入（此时读入的是0，无效数据），就需要借助第一个fifo的write1 来帮助判断 ，
            //有需要注意， write1的下降沿与 idle的上升沿是统一时刻，判定之后，write2仍为1，无法做到不读入第一个0 ， 所以使用打一拍之后的write_d1来判断
            //而如果使用write_d1，又会引入一个问题，
always@( posedge idle or posedge idle_1 or posedge write1_d1) //记得延后一拍的先进行判定 (对于idle 与 idle_d1来说)
    if (write1_d1)
        write2 <= 1'b0;
    else if (idle_1)
        write2 <= 1'b0;
    else if(idle)
        write2 <= 1'b1;
    else
        write2 <= write2;




//uut0 输出256*256个 3*3*3 的块，存入uut1中  
//uut1 （fifo类型）发给uut2 进行16个kernel的并行卷积计算。得到所有结果256*256*16后，存入uut3（fifo2类型）中
//uut3存满后，直接全部输入到maxpooling
padding_row padding(
    .clk(clk),
    .reset(reset),
    .saved_d1(out)
);

fifo_256
#(
  .DATA_WIDTH(16),
  .size(256*256),
  .D(3),
  .F(3)
)
fifo_256_256
(
    .clk(clk),
    .reset(reset), 
    .write(write1), 
    .read(read1),
    .data_in(out),
    .data_out(out1),
    .full(full),
    .out_verify(out_verify)
);


convUnit 
#(
  .filter_num(filter_num)
)
convpart
(
    .clk(clk),
    .reset(reset1),
    .RST(RST), 
    .image(out1),
    .result(result),
    .idle(idle)
);






//16个maxpooling模块，对于result（256*256*16）进行maxpooling
genvar j;
generate


    for (j = 0; j <= filter_num - 1; j = j + 1)
    begin: receive_fifo
        //由于256*256*16 = 1048576 稍大于 vivado sythesis 的最大值 1000000  所以分两批，  
        wire [input_size*input_size/2*DATA_WIDTH-1:0] all_1;
        wire [input_size*input_size/2*DATA_WIDTH-1:0] all_2;

        wire full_fifo,full_fifo1,done;
        reg full_fifo_sign;
        wire [DATA_WIDTH-1:0] out_fifo;
        fifo2_256
        #(
          .DATA_WIDTH(16),
          .size(num*num)
        )
        fifo_256_256_1
        (
            .clk(clk),
            .reset(reset), 
            .write(write2), 
            .data_in(result[j*DATA_WIDTH +: DATA_WIDTH]),
            .full(full_fifo),
            .all_1(all_1),
            .all_2(all_2)
        );
        //256*256的结果得到后，全部输出到这里面做padding，最终得到128*128*16


        // full_fifo 是0000000-->1-->0000000
        // full_fifo_sign 是000000-->11111111
        //~full_fifo_sign 是111111-->00000000
        always@(posedge full_fifo or posedge reset)
            if(reset == 1'b1)
                full_fifo_sign = 1'b0;
            else
                full_fifo_sign = 1'b1;

        //conv之后一个个存进fifo，存满后 ，full_fifo脉冲  使得full_fifo_sign阶跃
        //从而启动pooling,每个clk生成一个out_fifo, 读入fifo(uut5),直至读满128*128个，done信号停止读
        maxpooling_256
        #(
            .input_size(256)
        )
        maxpooling_128_128
        (
            .clk(clk), 
            .reset(~full_fifo_sign), 
            .in_fifo_1(all_1), 
            .in_fifo_2(all_2), 
            .max_one(out_fifo),
            .done(done)
        );




        fifo2
        #(
          .DATA_WIDTH(16),
          .size( (num/2) * (num/2)  ),
        )
        fifo_128_128
        (
            .clk(clk),
            .reset(~full_fifo_sign), 
            .write(~done), 
            .data_in(out_fifo),
            .full(full_fifo1)
        );


        
    end

endgenerate


//assign all_result_0 = all[0];
assign result_0 = result[DATA_WIDTH - 1:0];



endmodule
