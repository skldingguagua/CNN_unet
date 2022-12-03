import os
import numpy as np
from dec2IEEE16_file import convert_file
path = "C:\\Users\\sunkaili\\Desktop\\txt\\kernel_trans"
for filename in os.listdir(path):
    print(filename)
    convert_file(path, filename)