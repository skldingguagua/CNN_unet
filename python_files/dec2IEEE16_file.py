import numpy as np
#  转换指定文件夹，指定名字的 txt文件 ， 保存到 新的路径， 新的名字
def convert_file(path, filename):
    
    path_bias = path+"_IEEE16"
    filename_bias = "IEEE16_" + filename 
    filereadpath=path+"\\" +filename
    
    filewritepath=path_bias+"\\"+filename_bias
    
    file=open(filereadpath,"r")
    
    filewrite=open(filewritepath,"w")
    

    
    if (file.mode=="r"):
    
        content=file.readlines()
    
        for idx,num in enumerate(content):
    
            #num.replace('\n','')
    
            num = float(num)
    
            IEEE = hex(np.float16(num).view('H'))[2:].zfill(4)
    
            filewrite.write(IEEE)
    
            filewrite.write('\n')
    
    file.close()
    
    filewrite.close()    

#convert_file('C:/Users/Administrator.DESKTOP-VMUPUQF/Desktop/txt','x1.txt') 
convert_file('C:/Users/sunkaili/Desktop/1/1_1','1.txt')