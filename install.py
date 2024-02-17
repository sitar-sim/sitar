#! /usr/bin/env python3
import sys, os, subprocess



def run():
    #cd to directory in which this script resides
    working_dir  = os.path.dirname(os.path.realpath(__file__))
    os.chdir(working_dir)


    #install antlr C runtime
    print("Installing antlr3C runtime............")
    os.chdir("./translator/antlr3Cruntime/")
    command = "tar -xzvf libantlr3c-3.4.tar.gz"
    subprocess.call(command.split())
    os.chdir("./libantlr3c-3.4")
    build_dir = working_dir+"/translator/antlr3Cruntime/build"
    command= "./configure --prefix="+build_dir+" --exec-prefix="+build_dir+" "

    #check if this system is 64 bit
    is_64bits = sys.maxsize > 2**32
    if (is_64bits) :
        command= command+" --enable-64bit "

    subprocess.call(command.split())
    subprocess.call("make")
    command="make install"
    subprocess.call(command.split())
    os.chdir("../../parser")
    status = subprocess.call("scons")



    #done
    if(status==0):
        print("======================")
        print("finished installation")
        print("======================")
        print("")
        print("add the following lines to your ~/.bashrc file")
        print("#-------------------------")
        print("#sitarV2 paths:")
        lib_path = working_dir+"/translator/antlr3Cruntime/build/lib"
        path     = working_dir+"/scripts"
        alias_path = working_dir+"/translator/antlrworks-1.4.3.jar"
        s= "export LD_LIBRARY_PATH="+lib_path+":${LD_LIBRARY_PATH}"
        print(s)
        s ="export PATH="+path+":${PATH}"
        print(s)
        s = "alias antlrwors='java -jar "+alias_path+"'"
        print(s)
        print("#-------------------------")
    else :
        
        print("======================")
        print("installation FAILED")
        print("======================")
        
    print("\n\n")
    return

if __name__ == "__main__":
    run()
    
