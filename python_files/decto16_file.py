import numpy as np
def convert_file(path, filename,filename2):
    
     
    filereadpath=path+"\\" +filename
    
    filewritepath=path+"\\"+filename2
    
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

convert_file("C:/Users/Administrator.DESKTOP-VMUPUQF/Desktop/txt", "k1.txt","k1_IEEE16.txt")