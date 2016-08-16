#ifndef GLOBAL_DATA_H
#define GLOBAL_DATA_H
//A Data structure that is filled up 
//by the Main Parser, and read by the code generator
//
//It contains one look-up table storing field-value pairs,
//and several file handles. When MainParser is running,
//it instructs this global data object to open all files for writing.
//When Main Parser is done, and code generation begins, all files
//are closed and reopened for reading.


#include<iostream>
#include<fstream>
#include<string>
#include<map>

class GlobalData
{

	public:
		

		//There are 4 temporary files used by the parser to dump code: 
		//C - contains stuff to be dumped into the constructor 
		//D - contains declarations
		//E - stuff that goes into execute/control flow function definition
		//I - header/includes region
				
		std::fstream C_file;
		std::fstream D_file;
		std::fstream E_file;
		std::fstream I_file;

		//Attributes
		std::map<std::string,std::string> attributes;
		
		std::string directory_name;
		std::string file_name;

		GlobalData();
		
		void storeAttrib(const std::string& s1, const std::string & s2);
		std::string getAttribute(const std::string & key);
		void clearAttributes();
		
		bool openFilesForWriting();
		void closeFiles();
		bool openFilesForReading();
		void deleteTemporaryFiles();	
				
};


#endif
