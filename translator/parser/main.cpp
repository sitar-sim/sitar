
#include"CodeGen.h"
#include"MainParser.h"
#include"GlobalData.h"

#include<fstream>
#include<sstream>
#include<ctime>
#include <sys/stat.h>

int ANTLR3_CDECL
main(int argc, char *argv[])
{

	MainParser P;
	CodeGen C;
	GlobalData D;

	
	std::string input_file;
	std::string output_directory;
	std::string code_gen_template;


	//Usage : sitar_translator <input_file> <output_directory> <CodeGenerationTemplate> 






	//Get arguments from the command line
	//And check if they're all right
	
	if (argc < 4 || argv[3] == NULL)
	{
		std::cerr<<"\nSiTAR translator error: arguments not specified.\n";
		std::cerr<<"\nUsage : sitar_translator <input_file> <output_directory> <CodeGenerationTemplate>\n\n";
		exit(1);
	}
	else
	{
		input_file=(std::string(argv[1]));
		output_directory= (std::string(argv[2]));
		code_gen_template=(std::string(argv[3]));

			
		//Check if the input file exists:
		std::ifstream ip_file(input_file.c_str());
		if(!ip_file.is_open())
		{
			std::cerr<<"\nSiTAR translator error: Cannot open input file "<<input_file<<" \n\n";
			exit(1);
		}
		else
			ip_file.close();
		
		//check if output directory exists:
		struct stat st;
		if(stat(output_directory.c_str(),&st) == -1)
		{
			std::cerr<<"\nSiTAR translator error: Output directory ";
			std::cerr<<output_directory<<" does not exist \n\n";
			exit(1);
		}
		//Check if the code_gen_template file exists:
		std::ifstream template_file(code_gen_template.c_str());
		if(!template_file.is_open())
		{
			std::cerr<<"\nSiTAR translator error: Cannot open Code Generation template file "<<code_gen_template<<" \n\n";
			exit(1);
		};


	}

	//Now set up the agents comprising the translator:
	//* Main Parser
	//* Global Data
	//* Code Generator




	




	//Setup our translator

	//Store some information in the Global Data
	//structure to be used by both parser, and code generator
	D.storeAttrib("INPUT_FILE",input_file);
	D.storeAttrib("TEMPLATE_FILE",code_gen_template);
	D.storeAttrib("OUTPUT_DIR",(output_directory+"/"));

	
	
	//dump date and time of translation
	time_t t =time(0);
	struct tm * now = localtime( & t );
	std::stringstream ss;
	ss<<(now->tm_year + 1900)<<"-"<<(now->tm_mon + 1) <<"-"<< now->tm_mday;
	D.storeAttrib("DATE",ss.str());


	std::stringstream ss2;
	ss2<<(now->tm_hour)<<":"<<(now->tm_min)<<":"<<(now->tm_sec);
	D.storeAttrib("TIME",ss2.str());
	
	
	P.setCodeGenPtr(&C);
	P.setGlobalDataPtr(&D);
	C.setGlobalDataPtr(&D);

	
	
	//start translation
	P.parse();



	std::cout<<"\n\n\n";

}

