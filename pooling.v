//形成 4*4 的pooling
module pooling (floatA0, floatA1, floatB0, floatB1, max_one);

input [15:0] floatA0, floatB0, floatA1, floatB1;
wire [15:0] bigger_oneA, bigger_oneB;
output [15:0] max_one;


comparator u1 
(
    .floatA(floatA0),
    .floatB(floatA1),
    .bigger_one(bigger_oneA)
);

comparator u2 
(
    .floatA(floatB0),
    .floatB(floatB1),
    .bigger_one(bigger_oneB)
);

comparator u3
(
    .floatA(bigger_oneA),
    .floatB(bigger_oneB),
    .bigger_one(max_one)
);

endmodule