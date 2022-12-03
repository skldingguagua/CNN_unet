module padding_row
#(
    parameter p = 1,
    parameter input_size = 256,
    parameter num =  256,                       // (256+2 - 3)/1 + 1  = 256  , 输出的行数与列数
    parameter D = 3,
    parameter F = 3,
    parameter DATA_WIDTH = 16
)
(clk,reset,saved_d1);
    input clk;
    input reset;
    
    reg[DATA_WIDTH-1:0]mem[0:input_size*input_size*D - 1];  //读取256*256*3
    reg[16:0] cnt;                                       //分256*256个时钟周期， 输出256*256 个 3*3*3的结果，计数这256*256 ， 需要16bit
    reg[7:0] col;                                           //0~255
    reg[7:0] row;                                           //0~255

    output reg[0:F*F*D*DATA_WIDTH -1] saved_d1;
    reg[0:F*F*D*DATA_WIDTH -1] saved;
    /*
      使用 [0:x]  与 [j*datawidth + : datawidth]  来赋值
    */


    //只有第一层使用initial语句读取， 之后的输入来源于上一次层的data frame 
    //模块的端口需要从(clk,reset,saved) 改为(clk,input,reset,saved)
    initial
        begin
            $readmemh("C:/Users/sunkaili/Desktop/txt/image_IEEE16/IEEE16_img0.txt",mem,0,input_size*input_size*D - 1);
        end            

    //异步复位，同步清零
    always@(posedge clk or posedge reset)
    begin
        if(reset == 1'b1)
            begin
                col <= 0;
                row <= 0;
            end
        
        else begin
            if(col == num-1)
                if(row == num-1)
                    begin
                        row <= row;
                        col <= col;
                    end
                else begin
                        row <= row + 1'b1;
                        col <= 0;
                    end
            else
                col <= col + 1'b1;
            end
    end

    integer i,j,k,i0,j0,k0,i1,j1,k1,i2,j2,k2,i3,j3,k3,i4,j4,k4,i5,j5,k5,i6,j6,k6,i7,j7,k7;

    always@(*)
    begin
        
        if (  (row >= 8'd1 && row <= num-2)  &&   (col >= 8'd1 && col <= num -2)  )
            begin
                for (k = 0 ; k <= D - 1; k =  k + 1)   // F*F*D每一层扫描
                    for (j = 0; j <= F - 1; j = j + 1) // F*F*D每一行扫描
                        for(i = 0; i <= F -1 ; i = i + 1)//F*F*D每一列扫描
                            saved[k*F*F*DATA_WIDTH + j*F*DATA_WIDTH + i*DATA_WIDTH+:DATA_WIDTH] = mem[k*input_size*input_size + (j+row-1)*input_size + i+col-1];
            end
        else if (row == 8'd0 && col != 8'd0 && col != num - 1)//最上面一行不包括两个顶角   有问题
            begin
                for (k0 = 0; k0 <= D - 1; k0 = k0 + 1)
                begin
                    //第一行F个为0
                    saved[k0*F*F*DATA_WIDTH + 0*F*DATA_WIDTH+: F*DATA_WIDTH] = 0;
                    for (j0 = 1; j0 <= F - 1; j0 = j0 + 1) //只用填第2......F行
                        for (i0 = 0; i0 <= F - 1; i0 = i0 + 1)
                            saved[k0*F*F*DATA_WIDTH + j0*F*DATA_WIDTH + i0*DATA_WIDTH+:DATA_WIDTH] = mem[k0*input_size*input_size + (j0+row-1)*input_size + i0 +col-1];
                end
            end
        else if (row == num - 1 && col != 8'd0 && col != num - 1)//最下面一行不包括两个顶角
            begin
                for (k1 = 0; k1 <= D - 1; k1 = k1 + 1)
                begin
                    //最后一行F个为0
                    saved[k1*F*F*DATA_WIDTH + (F-1)*F*DATA_WIDTH+: F*DATA_WIDTH] = 0;
                    for (j1 = 0; j1 <= F - 2; j1 = j1 + 1) //只用填第1.....F-1行
                        for (i1 = 0; i1 <= F - 1; i1 = i1 + 1)
                            saved[k1*F*F*DATA_WIDTH + j1*F*DATA_WIDTH + i1*DATA_WIDTH+:DATA_WIDTH] = mem[k1*input_size*input_size + (j1+row-1)*input_size + i1 +col-1];
                end
            end
        else if (col == 8'd0 && row != 8'd0 && row != num - 1)//最左面一行不包括两个顶角
            begin
                for (k2 = 0; k2 <= D - 1; k2 = k2 + 1)
                begin
                    for (j2 = 0; j2 <= F - 1; j2 = j2 + 1)   
                    begin//左侧一列F个为0
                        saved[k2*F*F*DATA_WIDTH + j2*F*DATA_WIDTH + 0*DATA_WIDTH+:DATA_WIDTH] = 0;
                        for (i2 = 1; i2 <= F - 1; i2 = i2 + 1) //每行只用填 第2......F个
                            saved[k2*F*F*DATA_WIDTH + j2*F*DATA_WIDTH + i2*DATA_WIDTH+:DATA_WIDTH] = mem[k2*input_size*input_size + (j2+row-1)*input_size + i2 +col-1];
                    end
                end
            end
        else if (col == num - 1 && row != 8'd0 && row != num - 1)//最右面一行不包括两个顶角    有问题
            begin
                for (k3 = 0; k3 <= D - 1; k3 = k3 + 1)
                begin
                    for (j3 = 0; j3 <= F - 1; j3 = j3 + 1)       
                    begin//右侧一列F个为0
                        saved[k3*F*F*DATA_WIDTH + j3*F*DATA_WIDTH + (F-1)*DATA_WIDTH+:DATA_WIDTH] = 0;
                        for (i3 = 0; i3 <= F - 2; i3 = i3 + 1) //每行只用填 第1......F-1个
                            saved[k3*F*F*DATA_WIDTH + j3*F*DATA_WIDTH + i3*DATA_WIDTH+:DATA_WIDTH] = mem[k3*input_size*input_size + (j3+row-1)*input_size + i3 +col-1];
                    end
                end
            end
        else if (row == 8'd0 && col == 8'd0)                  //左上顶角
            begin
                for (k4 = 0; k4 <= D - 1; k4 = k4 + 1)
                begin
                    //第一行F个为0
                    saved[k4*F*F*DATA_WIDTH + 0*F*DATA_WIDTH+: F*DATA_WIDTH] = 0;
                    
                    for (j4 = 1; j4 <= F - 1; j4 = j4 + 1)   //只用填第2......F行
                    begin//并且左侧一列F个为0
                        saved[k4*F*F*DATA_WIDTH + j4*F*DATA_WIDTH + 0*DATA_WIDTH+:DATA_WIDTH] = 0;
                        for (i4 = 1; i4 <= F - 1; i4 = i4 + 1)   //每行只用填 第2......F个
                            saved[k4*F*F*DATA_WIDTH + j4*F*DATA_WIDTH + i4*DATA_WIDTH+:DATA_WIDTH] = mem[k4*input_size*input_size + (j4+row-1)*input_size + i4 +col-1];
                    end
                end
            end
        else if (row == 8'd0 && col == num - 1)             //右上顶角
            begin
                for (k5 = 0; k5 <= D - 1; k5 = k5 + 1)
                begin
                    //第一行F个为0
                    saved[k5*F*F*DATA_WIDTH + 0*F*DATA_WIDTH+: F*DATA_WIDTH] = 0;

                    for (j5 = 1; j5 <= F - 1; j5 = j5 + 1)  //只用填第2......F行
                    begin//并且右侧一列F个为0
                        saved[k5*F*F*DATA_WIDTH + j5*F*DATA_WIDTH + (F-1)*DATA_WIDTH+:DATA_WIDTH] = 0;
                        for (i5 = 0; i5 <= F - 2; i5 = i5 + 1)  //每行只用填 第1......F-1个
                            saved[k5*F*F*DATA_WIDTH + j5*F*DATA_WIDTH + i5*DATA_WIDTH+:DATA_WIDTH] = mem[k5*input_size*input_size + (j5+row-1)*input_size + i5 +col-1];
                    end
                end
            end
        else if (row == num - 1 && col == 8'd0)             //左下顶角
            begin
                for (k6 = 0; k6 <= D - 1; k6 = k6 + 1)
                begin
                    //最后一行F个为0
                    saved[k6*F*F*DATA_WIDTH + (F-1)*F*DATA_WIDTH+: F*DATA_WIDTH] = 0;
                    
                    for (j6 = 0; j6 <= F - 2; j6 = j6 + 1) //只用填第1......F-1行
                    begin//并且左侧一列F个为0
                        saved[k6*F*F*DATA_WIDTH + j6*F*DATA_WIDTH + 0*DATA_WIDTH+:DATA_WIDTH] = 0;
                        for (i6 = 1; i6 <= F - 1; i6 = i6 + 1)   //每行只用填 第2......F个
                            saved[k6*F*F*DATA_WIDTH + j6*F*DATA_WIDTH + i6*DATA_WIDTH+:DATA_WIDTH] = mem[k6*input_size*input_size + (j6+row-1)*input_size + i6 +col-1];
                    end
                end
            end
        else //if (row == num - 1 && col == num - 1)       //右上顶角      最后一个case了， 不写else if ，写else
            begin
                for (k7 = 0; k7 <= D - 1; k7 = k7 + 1)
                begin
                    //最后一行F个为0
                    saved[k7*F*F*DATA_WIDTH + (F-1)*F*DATA_WIDTH+: F*DATA_WIDTH] = 0;
                    for (j7 = 0; j7 <= F - 2; j7 = j7 + 1) //只用填第1......F-1行
                    begin//并且右侧一列F个为0
                        saved[k7*F*F*DATA_WIDTH + j7*F*DATA_WIDTH + (F-1)*DATA_WIDTH+:DATA_WIDTH] = 0;
                        for (i7 = 0; i7 <= F - 2; i7 = i7 + 1)  //每行只用填 第1......F-1个
                            saved[k7*F*F*DATA_WIDTH + j7*F*DATA_WIDTH + i7*DATA_WIDTH+:DATA_WIDTH] = mem[k7*input_size*input_size + (j7+row-1)*input_size + i7 +col-1];
                    end
                end
            end
    end

    always@(posedge clk)
        saved_d1 <= saved;

endmodule