#include"GlobalData.h"


#include<iostream>
#include<fstream>
#include<string>
#include<map>
#include<cstdio>


GlobalData::GlobalData()
{
	directory_name="";
	file_name="";
};



void GlobalData::storeAttrib(const std::string& s1, const std::string & s2)
{
	attributes[s1]=s2;
};

std::string GlobalData::getAttribute(const std::string & key)
{
	//If attribute not found, 
	//print a warning and return empty string
	if(attributes.count(key)==0)
	{
		std::cout<<"\n Attribute "<<key<<"not found";
		return "";
	}
	else//else return value of the attribute
	{
		return attributes[key];
	}
};

void GlobalData::clearAttributes()
{
	attributes.clear();
};


#define C_FILE_NAME "sitar_temp_C_file.txt" //constructor block
#define D_FILE_NAME "sitar_temp_D_file.txt" //declarations block
#define E_FILE_NAME "sitar_temp_E_file.txt" //execution block
#define I_FILE_NAME "sitar_temp_I_file.txt" //includes block




bool GlobalData::openFilesForWriting()
{
	bool allOkay=true;
	if(getAttribute("OUTPUT_DIR")=="")
	{
		std::cerr<<"\n Global Data Error: output directory not specified\n";
		return false;
	}
	else
		directory_name=getAttribute("OUTPUT_DIR");


	//Open C_file
	file_name=directory_name+C_FILE_NAME;
	C_file.open(file_name.c_str(), std::ios_base::out);
	if(!C_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	//Open D_file
	file_name=directory_name+D_FILE_NAME;
	D_file.open(file_name.c_str(), std::ios_base::out);
	if(!D_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	//Open E_file
	file_name=directory_name+E_FILE_NAME;
	E_file.open(file_name.c_str(), std::ios_base::out);
	if(!E_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	//Open I_file
	file_name=directory_name+I_FILE_NAME;
	I_file.open(file_name.c_str(), std::ios_base::out);
	if(!I_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	return allOkay;
};

void GlobalData::closeFiles()
{

	C_file.close();
	D_file.close();
	E_file.close();
	I_file.close();
};


bool GlobalData::openFilesForReading()
{
	bool allOkay=true;

	if(getAttribute("OUTPUT_DIR")=="")
	{
		std::cerr<<"\n Global Data Error: output directory not specified\n";
		return false;
	}
	else
		directory_name=getAttribute("OUTPUT_DIR");


	//Open C_file
	file_name=directory_name+C_FILE_NAME;
	C_file.open(file_name.c_str(), std::ios_base::in);
	if(!C_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	//Open D_file
	file_name=directory_name+D_FILE_NAME;
	D_file.open(file_name.c_str(), std::ios_base::in);
	if(!D_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	//Open E_file
	file_name=directory_name+E_FILE_NAME;
	E_file.open(file_name.c_str(), std::ios_base::in);
	if(!E_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	//Open I_file
	file_name=directory_name+I_FILE_NAME;
	I_file.open(file_name.c_str(), std::ios_base::in);
	if(!I_file.is_open()) {std::cout<<"ERROR: sitar translator could not create/open temporary file "<<file_name; allOkay=false;}

	return allOkay;
};


void GlobalData::deleteTemporaryFiles()
{
	if(getAttribute("OUTPUT_DIR")=="")
	{
		std::cerr<<"\n Global Data Error: output directory not specified\n";
		return ;
	}
	else
		directory_name=getAttribute("OUTPUT_DIR");


	//delete temporary files
	remove((directory_name+"/"+C_FILE_NAME).c_str());
	remove((directory_name+"/"+D_FILE_NAME).c_str());
	remove((directory_name+"/"+E_FILE_NAME).c_str());
	remove((directory_name+"/"+I_FILE_NAME).c_str());

};

	
