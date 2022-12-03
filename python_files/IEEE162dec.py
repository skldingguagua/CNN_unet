import struct
import numpy as np
bin = "0010100011110101"
hex = "bc00"
dec_float = -0.676+3*-0.5295

y = struct.pack("H",int(hex,16))
float = np.frombuffer(y, dtype =np.float16)[0]
#print(dec_float)
print(float)

