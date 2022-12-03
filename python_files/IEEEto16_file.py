import struct
import numpy as np
#  转换指定文件夹，指定名字的 txt文件 ， 保存到 新的路径， 新的名字
def convert_file(path, filename):
    
    filename_bias = "IEEE16_" + filename 
    filereadpath=path+"\\" +filename
    
    filewritepath=path+"\\"+filename_bias
    
    file=open(filereadpath,"r")
    
    filewrite=open(filewritepath,"w")
    

    
    if (file.mode=="r"):
    
        content=file.readlines()
    
        for idx,num in enumerate(content):
    
            #num.replace('\n','')
            
            IEEE = struct.pack("H",int(num,16))
            float = np.frombuffer(IEEE, dtype =np.float16)[0]
            float_str = str(float)
            
    
            filewrite.write(float_str)
    
            filewrite.write('\n')
    
    file.close()
    
    filewrite.close()    


convert_file('C:/Users/sunkaili/Desktop/txt/test','result_0.txt')