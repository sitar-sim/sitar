grammar output_template;


//Something like STringTemplates.

//Has the following:

//plain text : dumped as it is into generated code
//attributes : whose values are to be looked up from a data structure and written eg. <name>
//Enclosed within angular braces.

//conditional: <(attribute-name)   ....        >	    //Take action if attribute is non-empty
//conditional: <!(attribute-name)...>	 //Tale action if attribute is empty
//Template comment <//comment>               //Does not appear in the generated code
//actions:<@filetype()> <@name(args)>
//the escaped angular brackets: \< \>



//----To be implemented later: 
//----attributes of type lists : <[template_types] separator=";">    , <[name] separator=";">





options {
	language=C;
}




tokens{
ESC_LBR='\\<';
ESC_RBR='\\>';
LBR='<';
RBR='>';
SLASH='\\';
LPAREN='(';
RPAREN=')';
NOT1='!';
AT='@';

}

@parser::preincludes
{
#include<iostream>
#include<map>
#include<list>
#include<set>
#include<string>
#include<sstream>
#include<fstream>
#include<cassert>
#include "GlobalData.h" //Data structure written to by parser, and read by code generator
 }




//ADD stuff to the parser's API

@parser::includes
{

#define GDATA  (CTX->_globalData)
#define OUTFILE (*$top::outfile)


//Files into which the main parser has dumped sections of code
#define C_file (CTX->_globalData->C_file) //Constructor
#define D_file (CTX->_globalData->D_file) //Declarations
#define E_file (CTX->_globalData->E_file) //Function to execute controlFlow
#define I_file  (CTX->_globalData->I_file)//Includes section
}


@parser::context
{
// A pointer to the global data structure
//The parser fills in data into a global data structure, which is then read
//by the code generator. We need to point out this global data structure to this parser.
GlobalData* _globalData;
void setGlobalDataPtr(GlobalData* global_data){_globalData=global_data;};
}

@parser::apifuncs
{
	ctx->_globalData= NULL;
	
}
//====================================




//---------------------------------------------
//      PARSER RULES
//--------------------------------------------

top 
scope{
	std::ofstream * outfile;
	std::ofstream* h_file;
	std::ofstream* cpp_file;
	
}
@init
{
	
	
	
	//open files for reading
	assert(GDATA!=NULL);
	if(! GDATA->openFilesForReading())
  	{std::cout<<"\n Could not open files for reading";exit(1);}
  	
  	 
 	//open files for writing
 	($top::h_file)=new std::ofstream;
	($top::cpp_file)=new std::ofstream;
	
	std::string fname;
 	fname=GDATA->getAttribute("OUTPUT_DIR")+"/"+GDATA->getAttribute("filename_h");
	$top::h_file->open(fname.c_str());
	fname=GDATA->getAttribute("OUTPUT_DIR")+"/"+GDATA->getAttribute("filename_cpp");
	$top::cpp_file->open(fname.c_str());
	
	
	//check if the files opened correctly
	if(!$top::h_file->is_open()) {std::cout<<"\nError opening file "<<fname;}
	if(!$top::cpp_file->is_open()) {std::cout<<"\nError opening file "<<fname;}
	
	
	//start writing to the .h file by default
	$top::outfile=$top::h_file;
	//std::cout<<"\nWriting code into directory: "<<GDATA->getAttribute("output_dir");

}


@after{
//close files
GDATA->closeFiles();
$top::h_file->close();
$top::cpp_file->close();
}	





//---------------------------------------------
//      PARSER RULES
//---------------------------------------------


	: statement[true] +
	EOF
	;	

statement[bool X]
	:	conditional[X]
	|	action[X]
	|	attribute[X]
	|	plaintext[X]
	;






 
conditional[bool X]  //example, <!(has_parameters) write to a cpp file.... >
@init{
bool Xnext=true;
bool not_flag=false;
}	//LBR NOT1 LPAREN IDENT RPAREN  statement+  RBR;
	:	(LBR (NOT1{not_flag=true;})? LPAREN id=IDENT RPAREN 
		
		{
			if(X==false) Xnext=false;
				
			else
			{
			std::string s=(const char*)($id.text->chars);
			std::string cond=GDATA->getAttribute(s);
			if(cond=="") //attribute does not exist
				Xnext =false;
			 else Xnext=true;
			 
			if(not_flag==true) Xnext=!Xnext;
			}
		}
		 (statement[Xnext])+  RBR)
	;








action[bool X]		//LBR AT IDENT (LPAREN IDENT RPAREN )? RBR;
@init{
std::string s_id="";
std::string s_arg="";
}	
	:	(LBR AT id=IDENT 
			{
			s_id=(const char*)($id.text->chars);
			}
		( 
		LPAREN arg=IDENT RPAREN
			{
			s_arg=(const char*)($arg.text->chars);
			}
		)?
		
		 RBR)
		 {
		 if(X)
		 {
		 assert(OUTFILE.is_open());
		
		//take action
		if(s_id=="add")
		//dump contents of the specified file in outfile
			{
			if(s_arg=="includes") {OUTFILE<<I_file.rdbuf();}
			else if(s_arg=="declarations") {OUTFILE<<D_file.rdbuf();}
			else if(s_arg=="constructor") {OUTFILE<<C_file.rdbuf();}
			else if(s_arg=="behavior") {OUTFILE<<E_file.rdbuf();}
			else{std::cout<<"\nError in template for code generation:";
			        std::cout<<" On line "<<$arg.line<<" unknown argument "<<s_arg;
			        }
			}
		else if(s_id=="file")  //change destination file

			{
			if(s_arg=="h"||s_arg=="H") {$top::outfile=$top::h_file;}
			else if(s_arg=="cpp"||s_arg=="CPP") {$top::outfile=$top::cpp_file;}
			else{std::cout<<"\nError in template for code generation:";
			        std::cout<<" On line "<<$arg.line<<" unknown argument "<<s_arg;
			        }
			}		
		else
			{
			std::cout<<"\nError in template for code generation:";
			std::cout<<" On line "<<$id.line<<" unknown action "<<s_id;
			        }
		 }
		 }
	;



attribute[bool X] 	//<name>
	:	LBR id=IDENT RBR
		{if(X)
		{
		 assert(OUTFILE.is_open());
		 std::string s =(const char*)($id.text->chars);
		 OUTFILE<<GDATA->getAttribute(s);
		 }
		 }
		 
	;


plaintext[bool X]
	: (esc_brackets[X] | simple_text[X]);




esc_brackets[bool X]
	:	(ESC_LBR
			{if(X)
			{
			assert(OUTFILE.is_open());
			OUTFILE<<"<";
			}
			}
		)
		|
		(ESC_RBR
			{if(X)
			{
			assert(OUTFILE.is_open());
			OUTFILE<<">";
			}
			}
		)
	;

simple_text[bool X]
	:	(IDENT|PLAINTEXT|SLASH|LPAREN|RPAREN|NOT1|AT)
		//dump to target as it is
		{if(X)	
		{
		assert(OUTFILE.is_open());
		OUTFILE<<$simple_text.text->chars;
		}
		}
	;






//---------------------------------------------
//      LEXER RULES
//---------------------------------------------

IDENT
	:	('a'..'z'|'A'..'Z')('a'..'z'|'A'..'Z'|'_')*;
PLAINTEXT
	:	(~('<'|'>'|'\\'|'('|')'|'!'|'@'))+;

SLASH	:	'\\';
LPAREN	:	'(';
RPAREN	:	')';
NOT1 	:	'!';
AT	:	'@';



	
