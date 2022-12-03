import numpy as np

x = -3.7856
num = float(x)
IEEE = hex(np.float16(num).view('H'))[2:].zfill(4)
print(IEEE)

#正数与负数的区别在转化之后只在于 符号位， 减去一个数， 也就是加上该数符号位取反后的数 ， 就可以实现减法的设计