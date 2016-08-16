grammar sitar;

//syntax for a system description language for sitarV2.0
//with embedded actions for translating it to C++ code.


//The following attributes are used as an interface between 
//this parser and code generator for each design unit
	
	//design_unit_name
	//is_module
	//has_parameters
	//has_behavior
	
	//num_pointers
	//num_timers
	//num_if_flags
       
        ////information about input:  set through main.cpp once for each translation:
	//TIME
	//DATE
	//OUTPUT_DIR
	//INPUT_FILE

	////information about output file to be generated per design unit(procedure or module block)
	//filename_h
	//filename_cpp
	//header_guard
	//template_class
	//template_member
	//template_args


options 
{
	language=C;
}



tokens
{
	
	///Keywords used by structural description
	MODULE='module';
	PROCEDURE='procedure';
	END='end';
	PARAMETER='parameter';
	
	
	INPORT='inport';
	INPORT_ARRAY='inport_array';
	OUTPORT='outport';
	OUTPORT_ARRAY='outport_array';
	
	NET='net';
	NET_ARRAY='net_array';
	SUBMODULE='submodule';
	SUBMODULE_ARRAY='submodule_array';
	
	COLON=':';
	CAPACITY='capacity';
	WIDTH='width';
	
	FOR='for';
	IN='in';
	TO='to';

	CONNECT_RIGHT='=>';
	CONNECT_LEFT='<=';
	
	//connectors for C++ identifiers
	SCOPE='::';
	POINTER='->';
	DOT='.';
	
	
	
	//data-types
	KEYWORD_INT='int';
	KEYWORD_BOOL='bool';
	KEYWORD_CHAR='char';

	//Symbols
	EQUALS='=';
	MINUS= '-';
	PLUS='+';

	//delimiters for
	//regions containing raw c++
	CODE = 'code';
	INCLUDE='include';
	DECL='decl';
	INIT='init';
	EXPR='expr';
	
	
	

	//keywords used by Controlflow 
	//description
	BEHAVIOR='behavior';
	BEGIN='begin';


	WAIT='wait';
	UNTIL='until';
	IF='if';
	THEN ='then';
	ELSE='else';	
	DO='do';
	WHILE='while';
	NOTHING='nothing';
	RUN='run';
	
	
	//logical operators
	OR='or';
	AND='and';
	NOT='not';

	//keywords to refer to current time
	THIS_CYCLE='this_cycle';
	THIS_PHASE='this_phase';
	
	
	STOP='stop';
	SIMULATION='simulation';
	
	//logging related
	LOG='log';
	SEND='<<';
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
#include<algorithm>
#include "GlobalData.h" //Data structure written to by parser, and read by code generator
#include "CodeGen.h"    //code generator class.
 }


//ADD stuff to the parser's API
@parser::includes
{
#define GDATA  (CTX->_globalData)
#define CODEGEN (CTX->_codeGen)
//Files for dumping sections of code for each design unit
#define C_file (CTX->_globalData->C_file) //Constructor
#define D_file (CTX->_globalData->D_file) //Declarations
#define E_file (CTX->_globalData->E_file) //Function to execute controlFlow
#define I_file (CTX->_globalData->I_file) //Includes block
//#define OUTPUT_FILE_PREFIX sitar_
//#define OUTPUT_FILE_PREFIX_STR "sitar_"
#define OUTPUT_FILE_PREFIX  
#define OUTPUT_FILE_PREFIX_STR ""

}



@parser::context
{
// A pointer to the global data structure
//The parser fills in data into a global data structure, which is then read
//by the code generator. We need to point out this global data structure to this parser.
GlobalData* _globalData;
CodeGen* _codeGen;
void setGlobalDataPtr(GlobalData* global_data){_globalData=global_data;};
void setCodeGenPtr(CodeGen * code_gen){ _codeGen=code_gen;};
}

@parser::apifuncs
{
	ctx->_globalData= NULL;
	ctx->_codeGen= NULL;
}






top 
scope {std::set<std::string>* design_unit_names_list; }
@init{ $top::design_unit_names_list=new std::set<std::string>;}			
@after{ delete $top::design_unit_names_list;}

	:	{
			//check if all initializations have occured correctly
			assert(CODEGEN!=NULL); 
			assert(GDATA!=NULL);
			
			
		}
		
		//Parse  design units
		(
			{//Ready the data structure:
			//open files for writing and clear
			//the data from previous module description
			if(!(GDATA->openFilesForWriting())) 
			 {std::cout<<"\nERROR: sitar translator couldn't open temporary files for code generation"; exit(1);}
			 D_file<<" ";
			 C_file<<" ";
			 I_file<<" ";
			 E_file<<" ";
			}
		
			//parse a design unit
			design_unit
			
		 	{
		 	 // after parsing a design unit, close temp files. 
			 //They will be opened by CodeGen for reading
			 GDATA->closeFiles();
			 
			 //Ask codeGen to dump code for the module description just parsed.
			 CODEGEN->parse();
		 	}
		)+  
		EOF
		
		{
		GDATA->closeFiles();
		GDATA->deleteTemporaryFiles();
		}
	;




design_unit : du ; //just introducing a shorted name for the rule...

du
scope{
	//Every design unit has Attributes to be used for code generation:
	 
	//Information about input (set through main.cpp once) :

	//TIME
	//DATE
	//OUTPUT_DIR
	//INPUT_FILE
	
	//-------------------------------------------------------------
	//Attributes of each design unit
	//-------------------------------------------------------------
	std::string* design_unit_name;

	bool	is_module;
	bool	has_parameters;
	bool	has_behavior; // (applicable for modules)
	
	int num_pointers;
	int num_timers;
	int num_if_flags;

	 ///information about output file to be
	 //generated per design unit(procedure or module block)
	std::string* filename_h;
	std::string* filename_cpp;
	std::string* header_guard;
	
	std::string* template_class;  //looks like "template<int N=0, bool B=true>"
	std::string* template_member; //looks like "template<int N,   bool B     >"
	std::string* template_args;   //looks like "<N,B>"

	//list of  parameters, their types and default values
	std::list<std::string>*	param_name;
	std::list<std::string>*	param_type;
	std::list<std::string>*	param_value;
	//-----------------------------------------------------------
}







@init{
	//initialize aatributes
	$du::design_unit_name=new std::string("");
	
	$du::is_module=true;
	$du::has_parameters=false;
	$du::has_behavior=false;
	
	$du::num_pointers=0;
	$du::num_timers=0;
	$du::num_if_flags=0;
	
	$du::filename_h=new std::string("");
	$du::filename_cpp=new std::string("");;
	$du::header_guard=new std::string("");
	$du::template_class=new std::string("");;
	$du::template_member=new std::string("");
	$du::template_args=new std::string("");
	
	$du::param_name=new std::list<std::string>;
	$du::param_type=new std::list<std::string>;
	$du::param_value=new std::list<std::string>;

}
@after{
	
	
	
	
	
	//deallocate memory
	delete $du::design_unit_name;
	delete $du::filename_h;
	delete $du::filename_cpp;
	delete $du::header_guard;
	delete $du::template_class;
	delete $du::template_member;
	delete $du::template_args;

	delete $du::param_name;
	delete $du::param_type;
	delete $du::param_value;
}



:	(  (   module_definition   {$du::is_module=true;} )
	|  (   procedure_definition{$du::is_module=false;})
	)
	
	
	{
	//ready attributes for storing in Global Data structure
	std::string is_module="";
	std::string has_parameters="";
	std::string has_behavior="";

	if($du::is_module) {is_module="y";};
	if($du::has_parameters) {has_parameters="y";};
	if($du::has_behavior) {has_behavior="y";};
	
	//determine output file names
	*$du::filename_h  =std::string(OUTPUT_FILE_PREFIX_STR+ *$du::design_unit_name + ".h");
	*$du::filename_cpp=std::string(OUTPUT_FILE_PREFIX_STR+ *$du::design_unit_name + ".cpp");


	//Generate a string for header guard
	std::string h=OUTPUT_FILE_PREFIX_STR + *$du::design_unit_name;
	std::transform(h.begin(), h.end(),h.begin(), ::toupper);
	*$du::header_guard=h+"_H";



	//Generate strings for declaration of template
	//parameters at various places in the generated code
	 *$du::template_class="";
	 *$du::template_member="";
	 *$du::template_args="";

		
	if($du::has_parameters==true)
	{
		bool flag_first =true;
	
		*$du::template_class= "template<";
		*$du::template_member="template<";
		*$du::template_args=  "<";

		while(!$du::param_name->empty())
		{
			if(!flag_first)
			{
				//put a comma
				$du::template_class->append(","); 
				$du::template_member->append(",");
				$du::template_args->append(",");
			}
			$du::template_class->append($du::param_type->front()+" ");
			$du::template_member->append($du::param_type->front()+" ");

			$du::template_class->append( $du::param_name->front());
			$du::template_member->append($du::param_name->front());
			$du::template_args->append(  $du::param_name->front());

			$du::template_class->append("=");
			$du::template_class->append($du::param_value->front());

			$du::param_name->pop_front();
			$du::param_type->pop_front();
			$du::param_value->pop_front();

			//the 3 lists should be in sync
			assert($du::param_name->size()==$du::param_value->size());
			assert($du::param_name->size()==$du::param_type->size());

			flag_first=false;
		}
		$du::template_class->append(">"); 
		$du::template_member->append(">");
		$du::template_args->append(">");
	};


	//Now store all the attributes in GDATA

	GDATA->storeAttrib("design_unit_name",*$du::design_unit_name);
	GDATA->storeAttrib("is_module",is_module);
	GDATA->storeAttrib("has_parameters",has_parameters);
	GDATA->storeAttrib("has_behavior",has_behavior);

	GDATA->storeAttrib("num_pointers",CODEGEN->intToString($du::num_pointers)); 
	GDATA->storeAttrib("num_timers",CODEGEN->intToString($du::num_timers)); 
	GDATA->storeAttrib("num_if_flags",CODEGEN->intToString($du::num_if_flags)); 
	
	GDATA->storeAttrib("filename_h",*$du::filename_h);
	GDATA->storeAttrib("filename_cpp",*$du::filename_cpp);
	GDATA->storeAttrib("header_guard",*$du::header_guard);
	
	
	GDATA->storeAttrib("template_class",*$du::template_class);
	GDATA->storeAttrib("template_member",*$du::template_member);
	GDATA->storeAttrib("template_args",*$du::template_args); 
	}
	;









module_definition 
	:	MODULE{$du::is_module=true;} id=IDENTIFIER
		{
		    //check for duplicate design unit names
		    *$du::design_unit_name=(const char*)($id.text->chars);
		    std::string mname=*$du::design_unit_name;
		    		    
		    if($top::design_unit_names_list->count(mname)>0)
		    {
			    std::cout<<"\nDuplicate definition of module ";
			    std::cout<<mname<<" on line ";
			    std::cout<<$id.line;
		    }
		    else{$top::design_unit_names_list->insert(mname);}
		
		}
		
		module_body
		END MODULE
		
		{
			
			//Write msg to screen
			std::cout<<"\nParsed module "<<*$du::design_unit_name; 
		}       	  
	;



procedure_definition 
	:	PROCEDURE{$du::is_module=false;} id=IDENTIFIER 
		{
		    //check for duplicate design unit names
		    *$du::design_unit_name=(const char*)($id.text->chars);
		    std::string mname=*$du::design_unit_name;
		    		    
		    if($top::design_unit_names_list->count(mname)>0)
		    {
			    std::cout<<"\nDuplicate definition of procedure ";
			    std::cout<<mname<<"on line ";
			    std::cout<<$id.line;
		    }
		    else{$top::design_unit_names_list->insert(mname);}
		
		}
		
		procedure_body
		END PROCEDURE
		
		{
			
			//Write msg to screen
			std::cout<<"\nParsed procedure "<<*$du::design_unit_name; 
		}       	  
	;












//=====================================================
//MODULE and PROCEDURE
//=====================================================

module_body 
	:	
		
		( parameter_declaration_region {$du::has_parameters=true;}                        )?
		( (code_block_regions | structural_component_declaration| procedure_declaration ) )*
		( behavior_block{$du::has_behavior=true;} (code_block_regions )*                  )?
	;


procedure_body 
	:	
		
		( parameter_declaration_region {$du::has_parameters=true;}        )?
		( (code_block_regions | procedure_declaration )                   )*		
		( behavior_block{$du::has_behavior=true;} (code_block_regions)*   )?
	;


//================================================
// MODULE STRUCTURE
//===============================================
code_block_regions
	:	include_block
	|	declaration_block
	|	initialization_block
	;
include_block
	:	INCLUDE c=code_block_with_info
	{	I_file<<$c.text;
	}
	;
declaration_block
	:	DECL c=code_block_with_info
	{	D_file<<$c.text;
	}
	;
initialization_block
	:	INIT c=code_block_with_info
	{	C_file<<$c.text;
	}
	;
	



structural_component_declaration
	:
	//Components become public
	//data-members of the module
	//class
		( port_declaration
		| net_declaration
		| submodule_declaration
		| connection
		)
		
	;		





//parameters
parameter_declaration_region 
	:	 (parameter_declaration ';'? )+
	; 



parameter_declaration 
	: 	PARAMETER pt=param_type id=IDENTIFIER  EQUALS val=default_value
		{
			//store this information into lists maintained 
			//per module_description
			$du::has_parameters=true;
			assert($du::param_name!=NULL);
			assert($du::param_type!=NULL);
			assert($du::param_value!=NULL);

			$du::param_type->push_back(std::string((const char*)($pt.text->chars)));
			$du::param_name->push_back(std::string((const char*)($id.text->chars)));
			$du::param_value->push_back(std::string((const char*)($val.text->chars)));
			
			//the 3 lists should be in sync
			assert($du::param_name->size()==$du::param_value->size());
			assert($du::param_name->size()==$du::param_type->size());

		}

	;
	//default values are compulsory
param_type 
	:	KEYWORD_INT
	|	KEYWORD_BOOL
	|	KEYWORD_CHAR
	;


default_value  
	:  	integer | BOOL | CHAR 
	;
integer
	:
	'-'? INTEGER
	;





//Structural components of the module:


//ports
port_declaration
scope
{
bool has_width;
}
@init
{
$port_declaration::has_width=false;
}
	:	inport_declaration
	|	inport_array_declaration
	|	outport_declaration
	|	outport_array_declaration
	;



inport_declaration //:	INPORT	identifier_list COLON WIDTH  expression  
@init
{
	//Declare a list of identifiers
	std::list<std::string> list1;
	std::string s;
		
}
@after
{
	//empty the list
	list1.clear();
}

	:	INPORT	id1=IDENTIFIER 
		{
			s=std::string((const char*)($id1.text->chars));  
			list1.push_back(s);
		}
	
		(',' id2=IDENTIFIER
		{
			s=std::string((const char*)($id2.text->chars)); 
			list1.push_back(s);
		} 
		)*  (COLON WIDTH e1=expression{$port_declaration::has_width=true;})?
	
		{
		std::string w;
		if($port_declaration::has_width==true) w = std::string((const char*)($e1.text->chars));
		else w = "0";
					
	        	while(!list1.empty())
	 	 	{
	 		s = list1.front();
	 		list1.pop_front();
	 		
			
			//Add port as data member of module class
			D_file<<"\ninport<"<<w<<"> "<<s<<";";
	 		
			//Initialize port attributes in the contructor
			C_file<<"\n//---Initializing inport "<<s<<"---";
			C_file<<"\n"<<s<<".setInstanceId(\""<<s<<"\");";
			C_file<<"\naddInport(&"<<s<<",\""<<s<<"\");\n";
	 	 	};
		}
		;
	
inport_array_declaration 
//:INPORT_ARRAY IDENTIFIER '[' expression  ']'  ('[' expression  ']')? COLON WIDTH expression 
@init
{ 
	int flag_2D=0;
	std::string port;
	std::string portij;
	std::string pname;
}
@after
{ 
	flag_2D=0;
}


	:	INPORT_ARRAY id1=IDENTIFIER '[' e1=expression  ']'  
	       ('[' e2=expression {flag_2D=1;} ']')?  (COLON WIDTH w1=expression {$port_declaration::has_width=true;} )?
	{
		std::string w;
		if($port_declaration::has_width) 
		  w = std::string((const char*)($w1.text->chars));
		else w = "0";
		
		port=(std::string((const char*)($id1.text->chars)));
		
		if(flag_2D==0)
		{
			pname="\""+port+"[\"+sitar::toString(i)+\"]\"";
			portij= port + "[i]";
			
			//Add port as data member to module class
			D_file<<"\ninport<"<<w<<"> "<<port<<"["<<$e1.text->chars<<"];";


			//Initialize port attributes in the contructor
			C_file<<"\n//----Initializing inport-array "<<port<<"------";
			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			C_file<<"\nstd::string pname="<<pname<<";";
			C_file<<"\n"<<portij<<".setInstanceId(pname);";
			C_file<<"\naddInport(&"<<portij<<","<<pname<<");\n";
			C_file<<"\n}\n";

		}
		else if(flag_2D==1)
		{
			pname="\""+port+"[\"+sitar::toString(i)+\"]\"+\"[\"+sitar::toString(j)+\"]\"";
			portij= port + "[i][j]";
				
			//Add port as data member to module class
			D_file<<"\ninport<"<<w<<"> "<<port<<"["<<$e1.text->chars<<"]["<<$e2.text->chars<<"];";

			//Initialize port attributes in the contructor
			C_file<<"\n//----Initializing inport-array "<<port<<"------";
			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			C_file<<"\nfor(int j=0;j<("<<$e2.text->chars<<");j++)\n{\n";
			C_file<<"\nstd::string pname="<<pname<<";";
			C_file<<"\n"<<portij<<".setInstanceId(pname);";
			C_file<<"\naddInport(&"<<portij<<","<<pname<<");\n";
			C_file<<"\n}\n}\n";
		}

	}
	;	

outport_declaration //	:OUTPORT IDENTIFIER(',' IDENTIFIER)* COLON WIDTH expression 
@init
{
	//Declare a list of identifiers
	std::list<std::string> list1;
	std::string s;
}
@after
{
	//Empty the list
	list1.clear();
}

	:	OUTPORT	id1=IDENTIFIER 
		{
			s=std::string((const char*)($id1.text->chars));  
			list1.push_back(s);
		}
	
		(',' id2=IDENTIFIER
		{
			s=std::string((const char*)($id2.text->chars)); 
			list1.push_back(s);
		} 
		)*  (COLON WIDTH e1=expression{$port_declaration::has_width=true;})?
	
		{
		std::string w;
		if($port_declaration::has_width==true) w = std::string((const char*)($e1.text->chars));
		else w = "0";
			
	        	while(!list1.empty())
	 	 	{
	 		s = list1.front();
	 		list1.pop_front();
	 		
			
			//Add port as data member to module class
			D_file<<"\noutport<"<<w<<"> "<<s<<";";
	 		
			//Initialize port attributes in the contructor
			C_file<<"\n//---Initializing outport "<<s<<"---";
			C_file<<"\n"<<s<<".setInstanceId(\""<<s<<"\");";
			C_file<<"\naddOutport(&"<<s<<",\""<<s<<"\");\n";
	 	 	};
		}
		;

outport_array_declaration
//	:	OUTPORT_ARRAY IDENTIFIER '[' expression  ']' ( '[' expression  ']')? COLON WIDTH expression 
@init
{ 
	int flag_2D=0;
	std::string port;
	std::string portij;
	std::string pname;
}
@after
{ 
	flag_2D=0;
}


	:	OUTPORT_ARRAY id1=IDENTIFIER '[' e1=expression  ']'  
	       ('[' e2=expression {flag_2D=1;} ']')?   (COLON WIDTH w1=expression{$port_declaration::has_width=true;})?
	{
		std::string w;
		if($port_declaration::has_width==true) 
		 w = std::string((const char*)($w1.text->chars));
		else w = "0";
		port=(std::string((const char*)($id1.text->chars)));
		
		if(flag_2D==0)
		{
			pname="\""+port+"[\"+sitar::toString(i)+\"]\"";
			portij= port + "[i]";
			
			//Add port as data member to module class
			D_file<<"\noutport<"<<w<<"> "<<port<<"["<<$e1.text->chars<<"];";

			//Initialize port attributes in the contructor
			C_file<<"\n//----Initializing outport-array "<<port<<"------";
			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			C_file<<"\nstd::string pname="<<pname<<";";
			C_file<<"\n"<<portij<<".setInstanceId(pname);";
			C_file<<"\naddOutport(&"<<portij<<","<<pname<<");\n";
			C_file<<"\n}\n";

		}
		else if(flag_2D==1)
		{
			pname="\""+port+"[\"+sitar::toString(i)+\"]\"+\"[\"+sitar::toString(j)+\"]\"";
			portij= port + "[i][j]";
				
			//Add port as data member to module class
			D_file<<"\noutport<"<<w<<"> "<<port<<"["<<$e1.text->chars<<"]["<<$e2.text->chars<<"];";

			//Initialize port attributes in the contructor
			C_file<<"\n//----Initializing outport-array "<<port<<"------";
			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			C_file<<"\nfor(int j=0;j<("<<$e2.text->chars<<");j++)\n{\n";
			C_file<<"\nstd::string pname="<<pname<<";";
			C_file<<"\n"<<portij<<".setInstanceId(pname);";
			C_file<<"\naddOutport(&"<<portij<<","<<pname<<");\n";
			C_file<<"\n}\n}\n";
		}

	}
	;	











//nets

net_declaration
scope
{
bool has_width;
}
@init
{
$net_declaration::has_width=false;
}
	:	simple_net_declaration
	|	net_array_declaration
	;


simple_net_declaration //:	NET IDENTIFIER (',' IDENTIFIER)* COLON CAPACITY expression

@init
{
	//Declare a list of identifiers
	std::list<std::string> list1;
	std::string s;
}
@after
{
	//cmpty the list
	list1.clear();
}

	:	NET 	id1=IDENTIFIER 
		{
			s=std::string((const char*)($id1.text->chars));  
			list1.push_back(s);
		}
	
		(',' id2=IDENTIFIER
		{
			s=std::string((const char*)($id2.text->chars)); 
			list1.push_back(s);
		} 
		)*  
	
		COLON CAPACITY  c=expression  
		(WIDTH e1=expression{$net_declaration::has_width=true;})?
		{
		std::string w;
		if($net_declaration::has_width==true) w = std::string((const char*)($e1.text->chars));
		else w = "0";
	        	while(!list1.empty())
	 	 	{
	 		s = list1.front();
	 		list1.pop_front();
	 		
			
			//Add net as data member to module class
			D_file<<"\nnet<"<<w<<"> "<<s<<";"; 					//net
			D_file<<"\ntoken<"<<w<<"> "<<s<<"_buffer["<<$c.text->chars<<"];";	//token buffer for net
	 		
			//Initialize port attributes in the contructor
			C_file<<"\n//---Initializing net "<<s<<"---";
			C_file<<"\n"<<s<<".setInstanceId(\""<<s<<"\");";
			C_file<<"\n"<<s<<".setBuffer("<<s<<"_buffer,"<<$c.text->chars<<");";
			C_file<<"\naddNet(&"<<s<<",\""<<s<<"\");\n";
	 	 	};
		}
		;


net_array_declaration //: 	NET_ARRAY IDENTIFIER '[' expression  ']'  ('[' expression  ']')? COLON CAPACITY expression
@init
{ 
	int flag_2D=0; //0 implies net array is 1 dimensional, else 2-dimensional
	std::string net;
	std::string netij;
	std::string nname;
}
@after
{ 
	flag_2D=0;
}


	:	NET_ARRAY id1=IDENTIFIER '[' e1=expression  ']'  
	       ('[' e2=expression {flag_2D=1;} ']')? COLON CAPACITY c=expression 
	       (WIDTH e11=expression{$net_declaration::has_width=true;})?
	{
		std::string w;
		if($net_declaration::has_width==true) w = std::string((const char*)($e11.text->chars));
		else w = "0";
		net=(std::string((const char*)($id1.text->chars)));
		
		if(flag_2D==0)
		{
			nname="\""+net+"[\"+sitar::toString(i)+\"]\"";
			netij= net + "[i]";
			
			//Add net as data member to module class
			D_file<<"\nnet<"<<w<<"> "<<net<<"["<<$e1.text->chars<<"];";
			D_file<<"\ntoken<"<<w<<"> "<<net<<"_buffer["<<$e1.text->chars<<"]["<<$c.text->chars<<"];";	//token buffer for net

			//Initialize net attributes in the contructor
			C_file<<"\n//----Initializing net-array "<<net<<"------";
			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			C_file<<"\nstd::string nname="<<nname<<";";
			C_file<<"\n"<<netij<<".setInstanceId(nname);";
			C_file<<"\n"<<netij<<".setBuffer("<<net<<"_buffer[i],"<<$c.text->chars<<");";
			C_file<<"\naddNet(&"<<netij<<","<<nname<<");\n";
			C_file<<"\n}\n";

		}
		else if(flag_2D==1)
		{
			nname="\""+net+"[\"+sitar::toString(i)+\"]\"+\"[\"+sitar::toString(j)+\"]\"";
			netij= net + "[i][j]";
				
			//Add net as data member to module class
			D_file<<"\nnet<"<<w<<"> "<<net<<"["<<$e1.text->chars<<"]["<<$e2.text->chars<<"];";
			D_file<<"\ntoken<"<<w<<"> "<<net<<"_buffer["<<$e1.text->chars<<"]["<<$e2.text->chars<<"]["<<$c.text->chars<<"];";	//token buffer for net

			//Initialize net attributes in the contructor
			C_file<<"\n//----Initializing net-array "<<net<<"------";
			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			C_file<<"\nfor(int j=0;j<("<<$e2.text->chars<<");j++)\n{\n";
			C_file<<"\nstd::string nname="<<nname<<";";
			C_file<<"\n"<<netij<<".setInstanceId(nname);";
			C_file<<"\n"<<netij<<".setBuffer("<<net<<"_buffer[i][j],"<<$c.text->chars<<");";
			C_file<<"\naddNet(&"<<netij<<","<<nname<<");\n";
			C_file<<"\n}\n}\n";
		}

	}
	;	



//submodules

submodule_declaration
	:	simple_submodule_declaration
	|	submodule_array_declaration
	;



simple_submodule_declaration //	:	SUBMODULE IDENTIFIER (',' IDENTIFIER)*  COLON IDENTIFIER ('<' template_arguments '>' )?
@init
{
	//Declare a list of identifiers
	std::list<std::string> list1;
	std::string s;
	std::string mname; //name/type of the submodule
	std::string fname; //name of file that contains submodule description
	bool flag1=0;	   //flag1==1 indicates the submodule has template arguments.
	bool flag2=0;
}
@after
{
	//cmpty the list
	list1.clear();
	flag1=0;
	flag2=0;
}
	:	SUBMODULE	id1=IDENTIFIER 
		{
			s=std::string((const char*)($id1.text->chars));  
			list1.push_back(s);
		}
	
		(',' id2=IDENTIFIER
		{
			s=std::string((const char*)($id2.text->chars)); 
			list1.push_back(s);
		} 
		)*  
	
		COLON mod_type=IDENTIFIER ('<' (template_arguments{flag2=1;})? '>'{flag1=1;} )?
		{
			//Generate type-name of the module
			fname= (const char*)($mod_type.text->chars);
			mname=fname;
			if(flag1==1)
			{
			  mname=mname+"<" ;
			  if(flag2==1)
			  	mname=mname +(const char*)($template_arguments.text->chars);
			  mname=mname+">";
			  }
			
                                                                         //Include the header that contains description of
			//Submodule
			I_file<<"\n#include\""<<OUTPUT_FILE_PREFIX_STR<<fname<<".h\"";
			
	        	while(!list1.empty())
	 	 	{
				s = list1.front();
				list1.pop_front();

								
				//Add Submodule as data member of module class
				D_file<<"\n"<<mname<<" "<<s<<";";
				
				
				
				//Initialize Submodule instance in the contructor
				C_file<<"\n//---Initializing submodule "<<s<<"---";
				C_file<<"\n"<<s<<".setInstanceId(\""<<s<<"\");";
				C_file<<"\naddSubmodule(&"<<s<<",\""<<s<<"\");\n";
	 	 	}
		}
		;

template_arguments 
	:	argument (',' argument)*
	;
argument 
	:	 BOOL | CHAR | STRING | expression
	;




submodule_array_declaration
//	:	SUBMODULE_ARRAY IDENTIFIER '[' expression ']'( '[' expression ']')? COLON IDENTIFIER  ('<' template_arguments '>' )?
//	;	
@init
{ 
	bool flag_2D=0; //1 implies array is 2-dimensional, else 1D
	bool flag1=0; //1 implies submodule takes template arguments
	bool flag2=0;


	
	//generate some handy strings for translation
	//Eg. for input
	//sr[2][3] :ShiftRegister<4>


	//iname=sr[2][3]        instance name -goes into declaration
	//inameij=sr[i][j]      for initilalizing the array inside a for loop
	//inamestring="sr[" + "sitar::toString(i)" +"]".... ->for creating
	//			an instance name at elaboration time
	//tname=ShiftRegister<4> type name
	//fname=ShiftRegister   Goes into the includes region as
	//			#include"sitar_ShiftRegister.h"


	std::string iname0;
	std::string iname;
	std::string inameij;
	std::string inamestring;
	std::string tname;
	std::string fname;
}
@after
{ 
	flag_2D=0;
	flag1=0;
	flag2=0;
}


	:	SUBMODULE_ARRAY id1=IDENTIFIER '[' e1=expression  ']'  
	       ('[' e2=expression {flag_2D=1;} ']')? 
	       
	       COLON mod_type=IDENTIFIER  ('<' (t=template_arguments{flag2=1;} )? '>'{flag1=1;} )?
 
	{
		fname=(const char*)($mod_type.text->chars);
		tname=fname;
		if(flag1==1)
		{
			tname=tname+"<";
			if(flag2==1)
			 tname+=(const char*)($t.text->chars);
			tname+=">";
		}
		
		//Include the header that contains description of
		//Submodule
		I_file<<"\n#include\""<<OUTPUT_FILE_PREFIX_STR<<fname<<".h\"";


		
		
		if(flag_2D==1)
		{
			iname0=std::string((const char*)($id1.text->chars) );
			iname=iname0+ "[" + (const char*)($e1.text->chars) + "][" + (const char *) ($e2.text->chars) + "]";
			inameij=iname0+"[i][j]";
			inamestring="\""+iname0+"[\"+sitar::toString(i)+\"]\"+\"[\"+sitar::toString(j)+\"]\"";
				
			//Add module as data member to module class
			D_file<<"\n"<<tname<<" "<<iname<<";"; 

			//Initialize module attributes in the contructor
			C_file<<"\n//----Initializing module-array "<<fname<<"------";

			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			C_file<<"\nfor(int j=0;j<("<<$e2.text->chars<<");j++)\n{\n";
			
			C_file<<"\n"<<inameij<<".setInstanceId("<<inamestring<<");";
			C_file<<"\naddSubmodule(&"<<inameij<<","<<inamestring<<");\n";
			C_file<<"\n}\n}\n";
		}
		else if(flag_2D==0)
		{
			iname0=std::string((const char*)($id1.text->chars) );
			iname=iname0+"[" + (const char*)($e1.text->chars) + "]";
			inameij=iname0+"[i]";
			inamestring="\""+iname0+"[\"+sitar::toString(i)+\"]\"";
				
			
				
			//Add module as data member to module class
			D_file<<"\n"<<tname<<" "<<iname<<";"; 

			//Initialize module attributes in the contructor
			C_file<<"\n//----Initializing module-array "<<fname<<"------";

			C_file<<"\nfor(int i=0;i<("<<$e1.text->chars<<");i++)\n{\n";
			
			C_file<<"\n"<<inameij<<".setInstanceId("<<inamestring<<");";
			C_file<<"\naddSubmodule(&"<<inameij<<","<<inamestring<<");\n";
			C_file<<"\n}\n";
		}
	}
	;	


procedure_declaration 
@init
{
	//Declare a list of identifiers
	std::list<std::string> list1;
	std::string s;
	std::string mname; //name/type of the  procedure
	std::string fname; //name of file that contains procedure description
	bool flag1=0;	   //flag1==1 indicates the procedure has template arguments.
	bool flag2=0;
}
@after
{
	//cmpty the list
	list1.clear();
	flag1=0;
	flag2=0;
}
	:	PROCEDURE    id1=IDENTIFIER 
		{
			s=std::string((const char*)($id1.text->chars));  
			list1.push_back(s);
		}
	
		(',' id2=IDENTIFIER
		{
			s=std::string((const char*)($id2.text->chars)); 
			list1.push_back(s);
		} 
		)*  
	
		COLON mod_type=IDENTIFIER ('<' (template_arguments{flag2=1;})? '>'{flag1=1;} )?
		{
			//Generate type-name of the module
			fname= (const char*)($mod_type.text->chars);
			mname=fname;
			if(flag1==1)
			{
			  mname=mname+"<" ;
			  if(flag2==1)
			  	mname=mname +(const char*)($template_arguments.text->chars);
			  mname=mname+">";
			  }
			

			
	        	while(!list1.empty())
	 	 	{
				s = list1.front();
				list1.pop_front();

				//Include the header that contains description of
				//procedure
				I_file<<"\n#include\""<<OUTPUT_FILE_PREFIX_STR<<fname<<".h\"";
				
				
				//Add Submodule as data member of module class
				D_file<<"\n"<<mname<<" "<<s<<";";
				
				
				
				//Initialize Submodule instance in the contructor
				C_file<<"\n//---Initializing procedure instance "<<s<<"---";
				C_file<<"\n"<<s<<".setInstanceId(\""<<s<<"\");";
				C_file<<"\naddProcedure(&"<<s<<",\""<<s<<"\");\n";
	 	 	}
		}
		;








connection 
	:	simple_connect_statement //for connecting ports to nets
	|	for_loop_for_connections	//for connecting/linking regular structures
	;





simple_connect_statement //:	port_name (',' port_name )* ('=>'|'<=') net_name
@init
{
	//Declare a list of identifiers
	std::list<std::string> list1;
	std::string s;
}
@after
{
	//cmpty the list
	list1.clear();
}

	:	id1=port_instance_name 	 
		{
			s=std::string((const char*)($id1.text->chars));  
			list1.push_back(s);
		}
	
		(',' id2=port_instance_name
		{
			s=std::string((const char*)($id2.text->chars)); 
			list1.push_back(s);
		} 
		)*  

		(CONNECT_LEFT | CONNECT_RIGHT) n1=net_instance_name
	
		{
	        	while(!list1.empty())
	 	 	{
	 		s = list1.front();
	 		list1.pop_front();
			
			//Connect port to net, inside the constructor.
			C_file<<"\n"<<s<<".setNet(&";
			C_file<<($n1.text->chars)<<");";
	 	 	};
		}
		;


port_instance_name  
	:		hierarchical_instance_name 	
	;
net_instance_name  
	:		hierarchical_instance_name 
	;

hierarchical_instance_name 
	:	object_name((DOT|SCOPE|POINTER) object_name)*
	;
object_name 	
	:	IDENTIFIER ('['expression ']' ('['expression ']')?)?
	;
		//supports names such as 
		//A.B.C[1][2].D[1].port[0]
		//A.B[1][2]->C[0]
	

	



for_loop_for_connections 
	:	FOR id=IDENTIFIER IN e1=expression TO e2=expression
	{
	C_file<<"\n//---connecting ports to nets----";
	C_file<<"\nfor(int "<<($id.text->chars)<<"=("<<($e1.text->chars)<<");";
	C_file<<($id.text->chars)<<"<=("<<$e2.text->chars<<");";
	C_file<<($id.text->chars)<<"++)\n{\n\n";
	}
		connection+		
		END FOR
	{
	C_file<<"\n\n};\n";
	}
	;








//-------------------------------------------------
//EXPRESSIONS FOR STRCUTURAL DESCRIPTION:
//-------------------------------------------------
//parameters such as port width and net capacities,
//sizes of arrays and array indices in 
//port. net and submodule declarations and 
//connect statements can be expressions.

//Expressions can be simple arithmetic expressions.
//All expressions should return 0 or a positive integer.



//operator preceedence:  
//	  unary minus, 
//	  (*,/,%), 
//	  (+,-), 
//	



expression 	:  term ((PLUS|MINUS) term)*;

term		: signed_expression (('*'|'/'|'%') signed_expression)*;

signed_expression 
	:	MINUS? atomic_expression
	;
	




atomic_expression
	:
	'('expression')'
	| INTEGER
	| IDENTIFIER
	//check if IDENTIFIER is either a loop index (inside for loop) 
	//or a PARAMETER of type int or uint
	;






//------------------------------------------------------------------
//	Syntax for Control Flow block
//------------------------------------------------------------------

behavior_block
	:
		cf
	;


cf	
scope{

	
	
	//variables to keep count of pointers and
	//timers and flags ued by the controlflow.
	int pointer_count;	
	int timer_count;
	int if_flag_count;
}
@init{

	

	//initialize counts
	$cf::pointer_count=0;
	$cf::timer_count=0;
	$cf::if_flag_count=0;
}
@after{

	//add declarations for pointers, timers and flags
	//used by the  behavior block 
	$du::num_pointers=$cf::pointer_count;
	$du::num_timers=$cf::timer_count;
	$du::num_if_flags=$cf::if_flag_count;

}



	:	
	BEHAVIOR 
	
	{++$cf::pointer_count;} 
	sequence[0]
	END BEHAVIOR
	;   















//-------------------------------------------
//	STATEMENTS
//-------------------------------------------




sequence [int p] returns [int last_case] 
//	:	 (statement (  ';'  statement)* ';'?)
//	|	( '(' statement (';' statement)*  ';'? ')' )
//	;
// A sequence uses pointer p to point to the currently active statement
// p=last_case means the sequence has finished executing

@init
{ int k=0;
}
@after
{
	//add the last case that indicates the sequence has terminated
	E_file<<"\ncase "<<k<<": break;\n}\n";
	$last_case=k;
	C_file<<"\n_pointer_last_value["<<$p<<"]="<<k<<";";
}
:
{	
	//Add some text at the start of the sequence
	E_file<<"\nswitch(_pointer["<<$p<<"])\n{\n";
}


( 
	//statements add cases to the switch block
             s1=statement[p,k] {k=$s1.last_case_+1;}
	(';' s2=statement[p,k] {k=($s2.last_case_+1);})* ';'?
|	'('  s3=statement[p,k] {k=($s3.last_case_+1);}
        (';' s4=statement[p,k] {k=($s4.last_case_+1);} )* ';'? ')'
)
;






statement[int p_, int k_] returns [int last_case_]
  
//	:	atomic_statement	
//	|	compound_statement
//	;
scope
{
	//variables that can be accessed by rules down the hierarchy.
	int p; //input argument -pointer used by the sequence containing this statement
	int k; //input argument -case label to be used by this statement
	int last_case; //return value -last case label used.
}
@init{
	//Initialize variables
	$statement::p=$p_;
	$statement::k=$k_;
	$statement::last_case=$k_;
	
	
}
@after{
	//return the last case label used by this statement
	$last_case_=$statement::last_case;
	
	
}
	:
{
	//Initialize variables
	$statement::p=$p_;
	$statement::k=$k_;
	$statement::last_case=$k_;
	
	
}
	
		atomic_statement	
	|	compound_statement
	;



atomic_statement  
	:	nothing_statement
	|	wait_statement
	|	stop_statement
	|	run_procedure_statement
	|	code_block_statement	
		//|	log_statement
		//|	function_call_statement	
		//|	variable_assignment_statement
		//|	logging_statement
	;


code_block_statement 
	:	behavior_code_block_statement
	|	declaration_block_statement
	|	initialization_block_statement
	|	includes_block_statement
	;
	




behavior_code_block_statement
	:  c=code_block_with_info
	//CODE c=code_block_with_info
	{
               	
        E_file<<"\ncase "<<$statement::k<<":";
	E_file<<"\n{ \n ";
	E_file<<"\n//code_block_statement ";
	E_file<<$c.text;
	E_file<<"\n _incrementPointer("<<$statement::p<<");";
	E_file<<"\n}\n";
	$statement::last_case=$statement::k;
        	}
	;
	
declaration_block_statement 
	: 
	DECL c=code_block_with_info
	{
               	
               	
        E_file<<"\ncase "<<$statement::k<<":";
	E_file<<"\n{ \n ";
	E_file<<"\n//declaration_block_statement ";
	
	D_file<<$c.text;
	

	E_file<<"\n _incrementPointer("<<$statement::p<<");";
	E_file<<"\n}\n";
	$statement::last_case=$statement::k;
        	}
	;
	
	
initialization_block_statement 
	: 
	INIT c=code_block_with_info
	{
               	
       	E_file<<"\ncase "<<$statement::k<<":";
	E_file<<"\n{ \n ";
	E_file<<"\n//initialization_block_statement";
	C_file<<$c.text;
	E_file<<"\n _incrementPointer("<<$statement::p<<");";
	E_file<<"\n}\n";
	$statement::last_case=$statement::k;
        	}
	;	

includes_block_statement 
	: 
	INCLUDE c=code_block_with_info
	{
               	
       	E_file<<"\ncase "<<$statement::k<<":";
	E_file<<"\n{ \n ";
	E_file<<"\n//includes_block_statement";

	I_file<<$c.text;
	
	E_file<<"\n _incrementPointer("<<$statement::p<<");";
	E_file<<"\n}\n";
	$statement::last_case=$statement::k;
        }
	;	

nothing_statement 
		:	n1=NOTHING
		{
		E_file<<"\ncase "<<$statement::k<<":";
		E_file<<"\n{ \n ";
		E_file<<"\n//nothing statement , line:"<<$n1.line;
		E_file<<"\n _incrementPointer("<<$statement::p<<");";
		E_file<<"\n}\n";
		$statement::last_case=$statement::k;
		}
		;
/*
log_statement 
		:	l=LOG 
		{
		E_file<<"\ncase "<<$statement::k<<":";
		E_file<<"\n{ \n ";
		E_file<<"\n//log statement , line:"<<$l.line;
		E_file<<"\nlog";
		}
		(SEND e=expression_cf
		{
		E_file<<"<<"<<$e.text;
		}	
		)+
		{
		E_file<<";";
		E_file<<"\n _incrementPointer("<<$statement::p<<");";
		E_file<<"\n}\n";
		$statement::last_case=$statement::k;
		}
		;		
*/

	
/*
function_call_statement
        : f=function_call
        {
                	 E_file<<"\ncase "<<$statement::k<<":";
                	 E_file<<"\n{\n";
                	 E_file<<"\n//function call statement, line:"<<$f.line;
	 E_file<<"\n"<<$f.text<<";";
                	 E_file<<"\n _incrementPointer("<<$statement::p<<");";
	E_file<<"\n}\n";
                 	$statement::last_case=$statement::k;

        };
        
variable_assignment_statement 
	:
      id1=IDENTIFIER '=' ex1=expression_cf
        {
                        E_file<<"\ncase "<<$statement::k<<":";
                        E_file<<"\n{\n";
                         E_file<<"\n//variable assignment statement, line:"<<$id1.line;
                        E_file<<"\n"<<$id1.text->chars<<"="<<$ex1.text<<";";
                         E_file<<"\n _incrementPointer("<<$statement::p<<");";
	E_file<<"\n}\n";
                        $statement::last_case=$statement::k;
        }
        ;
logging_statement 
	:	s=LOG '(' arg=arguments_to_log ')'
	 {
                        E_file<<"\ncase "<<$statement::k<<":";
                        E_file<<"\n{\n";
                        E_file<<"\n//log statement, line:"<<$s.line;
                        E_file<<"\nLogger::debug(current_time, getHierarchicalId(), ("<<($arg.text->chars)<<"));";                                    
                        
                         E_file<<"\n _incrementPointer("<<$statement::p<<");";
                         
	E_file<<"\n}\n";
                        $statement::last_case=$statement::k;
                       
        	}
        	;
arguments_to_log 
	:	  log_string (PLUS log_string)*
	;
log_string 
	:	 STRING | function_call | identifier
	;
*/
	
	
wait_statement 
	: wait_until				//wait until expression evaluates to non-zero
	|wait_for_time				//wait for a specified time interval
	|single_wait				//wait until the next phase
	;


wait_until
        : s=WAIT UNTIL e=expression_cf
        {
		E_file<<"\ncase "<<$statement::k<<":";
		E_file<<"\n{\n";
		E_file<<"\n//wait-until statement , line:"<<$s.line;
		E_file<<"\nif("<<$e.text<<")";
		E_file<<"\n _incrementPointer("<<$statement::p<<");";
		E_file<<"\nelse\n break;\n }";
		$statement::last_case=$statement::k;
        }
        ;

wait_for_time
        : s=WAIT  '(' e1=expression_cf ',' e2=expression_cf ')'
        {
                 E_file<<"\ncase "<<$statement::k<<":";
                 E_file<<"\n{\n";


		 E_file<<"\n//wait-for -time statement , line:"<<$s.line;
                 E_file<<"\n_timer["<<$cf::timer_count<<"] = sitar::time(current_time)+sitar::time(";
                 E_file<<$e1.text<<","<<$e2.text<<");";
		 E_file<<"\n _incrementPointer("<<$statement::p<<");";
                 E_file<<"\n}\n";


                 E_file<<"\ncase "<<($statement::k+1)<<":";
                 E_file<<"\n{\n";
                 E_file<<"if(current_time>=_timer["<<$cf::timer_count<<"])";
                 E_file<<"\n _incrementPointer("<<$statement::p<<");";
                 E_file<<"\nelse\n break; \n}";

                //a unique timer has been used to implement this delay.
                //increment the timer count
                 ++$cf::timer_count;

                 $statement::last_case=($statement::k+1);

        }
        ;


single_wait
	: s=WAIT 
        {
                 E_file<<"\ncase "<<$statement::k<<":";
                 E_file<<"\n{\n";


                 E_file<<"\n//wait statement , line:"<<$s.line;
                 E_file<<"\n_timer["<<$cf::timer_count<<"] = sitar::time(current_time)+sitar::time(0,1);";
		 E_file<<"\n _incrementPointer("<<$statement::p<<");";
                 E_file<<"\n}\n";


                 E_file<<"\ncase "<<($statement::k+1)<<":";
                 E_file<<"\n{\n";
                 E_file<<"if(current_time>=_timer["<<$cf::timer_count<<"])";
		 E_file<<"\n _incrementPointer("<<$statement::p<<");";
                 E_file<<"\nelse\n break; \n}";

                //a unique timer has been used to implement this delay.
                //increment the timer count
                 ++$cf::timer_count;

                 $statement::last_case=($statement::k+1);
        }
	;
		

stop_statement 
	:	stop_behavior
	| 	stop_simulation
	;
stop_behavior
		:	s=STOP BEHAVIOR
		{
			
			
			E_file<<"\ncase "<<$statement::k<<":";
			E_file<<"\n{ \n ";
			E_file<<"\n//stop module statement , line:"<<$s.line;
			E_file<<"\n _incrementPointer("<<$statement::p<<");";
			E_file<<"\n _terminated=1;";
			E_file<<"\n}\n";
			$statement::last_case=$statement::k;
		}
		;

stop_simulation 
		:	s=STOP SIMULATION
		{
			
			
			E_file<<"\ncase "<<$statement::k<<":";
			E_file<<"\n{ \n ";
			E_file<<"\n//stop simulation statement , line:"<<$s.line;
			E_file<<"\n _incrementPointer("<<$statement::p<<");";
			E_file<<"\n stop_simulation();";
			E_file<<"\n}\n";
			$statement::last_case=$statement::k;
		}
		;

run_procedure_statement 
		:	s=RUN id=IDENTIFIER
		{
		std::string name =(const char *)($id.text->chars);
		E_file<<"\ncase "<<$statement::k<<":";
		E_file<<"\n{ \n ";
		
		E_file<<"\n//run procedure statement , line:"<<$s.line;
		E_file<<"\n"<<name<<".runBehavior(current_time);";
		E_file<<"\nif("<<name<<"._terminated==1)";
		E_file<<"\n{";
		E_file<<"\n"<<name<<"._resetBehavior();";
		E_file<<"\n_incrementPointer("<<$statement::p<<");";
		E_file<<"\n}";
		E_file<<"\nelse";
		E_file<<"\n{";
		E_file<<"\n//procedure has converged, and might";
		E_file<<"\n//need to be re-executed";
		E_file<<"\nif("<<name<<"._reexecute==true)";
		E_file<<"\n_reexecute=true;";
		E_file<<"\nbreak;";
		E_file<<"\n}";
		
		E_file<<"\n}\n";
		$statement::last_case=$statement::k;
		}
		;





compound_statement 
	:	if_statement
	|	do_while_statement
	|	parallel_statement
	;





if_statement
@init
{
        //pointers used by the two sequences
        //within this statement
        int true_branch=0;
        int false_branch=0;
        int flag;
}
@after
{
 $statement::last_case=($statement::k+1);
}
	: s=IF   e1=expression_cf   THEN 	
	{
                true_branch=$cf::pointer_count;
                ++$cf::pointer_count;
                flag=$cf::if_flag_count;
                ++$cf::if_flag_count;

		E_file<<"\ncase "<<$statement::k<<":";
		E_file<<"\n{\n";
		E_file<<"\n//if statement , line:"<<$s.line;

		E_file<<"\nif("<<$e1.text<<")";
		E_file<<"\n_if_flag["<<flag<<"]=true;";
		E_file<<"\nelse";
		E_file<<"\n_if_flag["<<flag<<"]=false;";
		E_file<<"\n _incrementPointer("<<$statement::p<<");";
		E_file<<"\n}\n";

		E_file<<"\ncase "<<($statement::k+1)<<":";
		E_file<<"\n{\n";

		E_file<<"\nif(_if_flag["<<flag<<"]==true)";
		E_file<<"\n{\n";

        }
	s1=sequence[true_branch]
        {

                 E_file<<"\n}\n";
                 E_file<<"\nelse\n{\n";
        }
	(	else_clause=ELSE 
			{
				false_branch=$cf::pointer_count; 
				++$cf::pointer_count;
			}
             	s2=sequence[false_branch]
        )?
        {

                 E_file<<"\n}\n";
        }
        END IF
        {
                E_file<<"\nif(";
                E_file<<"(_if_flag["<<flag<<"]==true && _pointer["<<true_branch<<"]>=_pointer_last_value["<<true_branch<<"])";
                E_file<<" || (_if_flag["<<flag<<"]==false";
                if(else_clause!=NULL) 
		{	E_file<<"&& _pointer["<<false_branch<<"]>= _pointer_last_value["<<false_branch<<"]"; }
		E_file<<"))\n";
                E_file<<"\n{";
                E_file<<"\n //if-statement has terminated";
                E_file<<"\n _incrementPointer("<<$statement::p<<");";
                E_file<<"\n _pointer["<<true_branch<<"]=0;\n";
                if(else_clause!=NULL)   E_file<<"\n _pointer["<<false_branch<<"]=0;\n";
                E_file<<"\n}\n";

                E_file<<"\n else ";
                E_file<<"\n //if-statement has converged";
                E_file<<"\n break;";
                E_file<<"\n}\n";
        };












do_while_statement
//	:DO
//	sequence
//	WHILE expression_cf END DO          
//	;                                      
@init{
	int Q=0; //pointer used by child sequence
	int m=0; //last case in child sequence
}
	: s=DO
	{
	Q=$cf::pointer_count;
	$cf::pointer_count++;
	}


	{

	E_file<<"\ncase "<<$statement::k<<" :";
	E_file<<"\n{";
	E_file<<"\n//do-while statement , line:"<<$s.line;
	E_file<<"\n int _dowhile_iteration;";
	E_file<<"\nfor(_dowhile_iteration=1; _dowhile_iteration<=SITAR_ITERATION_LIMIT; _dowhile_iteration++)";
	E_file<<"\n{";
	E_file<<"\n//execute the sequence  ";
	} 		                                                                          
	s1=sequence[Q]                                                            
	WHILE e1=expression_cf END DO    
	{
	m=$s1.last_case;
	E_file<<"\nif(_pointer["<<Q<<"]< _pointer_last_value["<<Q<<"])  ";
	E_file<<"\nbreak; //sequence has converged  ";
	E_file<<"\n else ";
	E_file<<"\n if(_pointer["<<Q<<"]==_pointer_last_value["<<Q<<"] && ("<<$e1.text<<"==true))";
	E_file<<"\n {";
	E_file<<"\n//re-activate the sequence	"; 
	E_file<<"\n_pointer["<<Q<<"]=0;	";
	E_file<<"\n_reexecute=1;       	";
	E_file<<"\n}				";
	E_file<<"\nelse break; //sequence has terminated			";
	E_file<<"\n };";

		

	E_file<<"\n	//For loop will finish if									";	
	E_file<<"\n	//the sequence inside do-while loop converges                                                   ";
	E_file<<"\n	//OR the expression becomes false at the end of some execution of while loop                    ";
	E_file<<"\n	//OR  if the iteration limit is exceeded.                                                       ";
	
	E_file<<"\n	if (_dowhile_iteration>SITAR_ITERATION_LIMIT)   ";
	E_file<<"\n	{                                                                                               ";
	E_file<<"\n		//iteration limit exceeded. Throw error and                                             ";
	E_file<<"\n		//terminate the do-while statement                                                      ";
	E_file<<"\n 		std::cerr<<\"\\nERROR:Iteration limit exceeded for do-while loop on line:"<<$s.line<<" in file "<<GDATA->getAttribute("INPUT_FILE")<<"\";";
	E_file<<"\n		_pointer["<<Q<<"]=0;                                                               ";
	E_file<<"\n		_incrementPointer("<<$statement::p<<");                                                                    ";
	E_file<<"\n	}                                                                                              ";
	
	E_file<<"\n	else if(_pointer["<<Q<<"]<_pointer_last_value["<<Q<<"])                                    ";
	E_file<<"\n	{                                                                                               ";
	E_file<<"\n		//sequence just converged;                                                              ";
	E_file<<"\n		break;                                                                                  ";
	E_file<<"\n	}                                                                                               ";
	E_file<<"\n	else if (_pointer["<<Q<<"]==_pointer_last_value["<<Q<<"] && ("<<$e1.text<<"==false))  ";
	E_file<<"\n	{                                                                                               ";
	E_file<<"\n		//terminate the do-while statement                                                      ";
	E_file<<"\n		_pointer["<<Q<<"]=0;                                                               ";
	E_file<<"\n		_incrementPointer("<<$statement::p<<");                                                                    ";
	E_file<<"\n	} ;                                                                                              ";
	
	E_file<<"\n};                                                                                                   ";
	}
	;




parallel_statement 
//	:	'[' sequence ('||'  sequence  )+ ']'
//	;
@init
{
        //list that stores pointers and last
        //states of each of the sequences contained in the
        //parallel region.
        std::list<std::pair<int,int> > ptr_list;
        std::list<std::pair<int,int> >::iterator it;
        std::pair<int,int> pair;

        int branches=0; //number of branches
        int ptr=0;      //pointer for each branch
	ptr_list.clear();
}

@after
{
 	$statement::last_case=$statement::k;
}
        :	s='['
                
	{	//write some text
			E_file<<"\ncase "<<$statement::k<<":";
			E_file<<" {\n";
			E_file<<"\n//parallel statement begins, line "<<$s.line;
			
			//generate a pointer for the child sequence
			ptr=$cf::pointer_count;
			++$cf::pointer_count;

                	}
                	{E_file<<"\n//one branch of parallel statement, using pointer "<<ptr;}
                	s1=sequence[ptr]
                	 //push information about this sequence into a list
        {
	pair=std::make_pair(ptr, $s1.last_case);
        	ptr_list.push_back(pair);
        }


        ('||'
                {
                        //generate a pointer for the child sequence
                        ptr=$cf::pointer_count;
                        ++$cf::pointer_count;
                }
                {E_file<<"\n//another branch of parallel statement, using pointer "<<ptr;}
                s2= sequence[ptr]
        //push information about this sequence into a list
        { 
	pair=std::make_pair(ptr, $s2.last_case);
        	ptr_list.push_back(pair);
        }

        )+ ']'


        {
                //write some code at the end of the parallel block:
                //to check if all parallel branches have terminated
                E_file<<"\n//if all parallel branches have terminated,";
                E_file<<"\n//exit the parallel statement.";
                E_file<<"\nif(";

                for(it=ptr_list.begin(); it!=ptr_list.end();it++)
                {
                        if(!(it==ptr_list.begin()))
                              E_file<<" &&";
                        pair=*it;
                        int P=pair.first;
                        int Q=pair.second;
                        E_file<<" _pointer["<<P<<"]=="<<Q;
                }
                E_file<<") \n{\n";
                E_file<<"\n //reset pointers of parallel branches";
                for(it=ptr_list.begin(); it!=ptr_list.end();it++)
                         {
                              pair=*it;
                               int P=pair.first;
                                E_file<<"\n_pointer["<<P<<"]=0;";
	}
	E_file<<"\n_reexecute=1;";
	E_file<<"\n//terminate the parallel statement";
	E_file<<"\n _incrementPointer("<<$statement::p<<");\n}";
	
                E_file<<"\nelse \n break;";
                E_file<<"\n//parallel statement ends";
                E_file<<"\n}\n";
        }
        ;













//-------------------------------------------
//EXPRESSIONS FOR  CONTROL FLOW REGION
//-------------------------------------------


//An expression can be anything that returns an INT
//including constants, variables, function calls,
//and keywords 'this_cycle' and 'this_phase'
//
//expressions do not include variable assignment
//
//operator preceedence:  
//	  unary minus, 
//	  (*,/,%), 
//	  (+,-), 
//	   comparison operators(==,<, etc), 
//	  logical NOT, 
//	  logical AND, 
//	  logical OR

//Expressions return their translated values as
//a string to the calling rule.


//
//expression_cf 	:exp1( OR exp1)* ;
//exp1 		:exp2(AND exp2)* ;
//exp2		: NOT? exp3;
//exp3		: exp4 (comparison_operator exp4)*;
//exp4 		: exp5 (add_operator exp5)*;
//exp5		: exp6 (mul_operator exp6)*;
//exp6		: '-'?	atomic_expression_cf;
//
//comparison_operator 
//	: '==' | '!='|'>='|'<='|'<'|'>'
//	;
//add_operator 
//	:'+'|'-'
//	;
//mul_operator 
//	:'*'|'/'|'%'
//	;		
//
//atomic_expression_cf 
//	:
//	'('expression_cf')' 
//	|function_call 
//	|this_cycle    
//	|this_phase    
//	|INTEGER     
//	|IDENTIFIER 
//	//add translation-time check 
//	//to ensure that this ID is either
//	//a parameter or a constant or variable
//	;
//
//
//function_call 
//	: IDENTIFIER '('  argument_list? ')';
//
//argument_list
//	: expression_cf (',' expression_cf)*;
//
//
//
//this_cycle : THIS_CYCLE;
//this_phase : THIS_PHASE;
//	

//--------------------------------------------


expression_cf returns[std::string text]
        :
       
                
        e1=exp1{$text=$e1.text;}
        ( OR{$text.append("||");} e2=exp1{$text.append($e2.text); })*  
        ;


exp1 returns[std::string text]
        :
        e1=exp2{$text=$e1.text;}
        (AND{$text.append("&&");}    e2=exp2{$text.append($e2.text);  }
        )*
        ;

exp2 returns[std::string text]
        :{$text="";}
        (NOT {$text.append("!");})?
         exp3{$text.append("(");$text.append($exp3.text); $text.append(")");}
        ;

exp3 returns[std::string text]
        :e1=exp4{$text=$e1.text;}
         (c1=comparison_operator{$text.append( (const char*)($c1.text->chars));}
           e2=exp4{$text.append($e2.text); }
         )*
        ;



exp4 returns[std::string text]
        : e1=exp5{$text=$e1.text;}
         (c1=add_operator{$text.append((const char*)($c1.text->chars));}
           e2=exp5{$text.append($e2.text); }
         )*
        ;


exp5 returns[std::string text]
        : e1=exp6{$text=$e1.text; }
        ( c1=mul_operator{$text.append((const char*)($c1.text->chars));}
           e2=exp6{$text.append($e2.text);  }
        )*

        ;
exp6 returns[std::string text]
        :{$text="(";}
        ('-' {$text.append("-");})?
          a1=atomic_expression_cf{$text.append($a1.text); $text.append(")");}
        ;





comparison_operator
        : '==' | '!='|'>='|'<='|'<'|'>'
        ;
add_operator
        :'+'|'-'
        ;
mul_operator
        :'*'|'/'|'%'
        ;



atomic_expression_cf  returns[std::string text]
        :
        '('e=expression_cf')'
          {$text="("+$e.text+")";}
        |f=function_call   {$text=$f.text;}
        |tc=this_cycle     {$text=$tc.text;}
        |tp=this_phase     {$text=$tp.text;}
        |int1=INTEGER      {$text=((const char*)$int1.text->chars);}
        |str1=STRING         {$text=((const char*)$str1.text->chars);}
        |id1=identifier    {$text=((const char*)$id1.text->chars);}
        | exp=expression_code_block{$text=$exp.text;}
        ;
        
     
               
expression_code_block  returns [std::string text, int line]
        : c=code_block
        //EXPR c=code_block
            {$line=$c.line; 
             $text=$c.text;
            }
       ; 
       
       
       
function_call returns [std::string text, int line]
        :
        id1=identifier '('
            {$line=$id1.line; 
             $text=((const char*)$id1.text->chars);
             $text.append("(");
            }
         ( a1=argument_list{ $text.append($a1.text); }
         )?
         ')'{$text.append(")");}
        ;



argument_list returns [std::string text]
        :  e1=expression_cf        {$text=$e1.text;}
        ( ','                   {$text.append(",");}
           e2=expression_cf     {$text.append($e2.text);}
        )*
        ;




this_cycle returns[std::string text]
        :       THIS_CYCLE
                {$text="(current_time.cycle())";}
        ;

this_phase returns [std::string text]
        :       THIS_PHASE
                {$text="(current_time.phase())";}
        ;


	
code_block_with_info returns [std::string text, int line]
        :         code_block
        {

                //Delete the delimeters of the code block,
                //and return the entire code as a string
                //to the parent rule
                $line=$code_block.line;
                $text = $code_block.text;
                 std::stringstream ss;
                ss.str(std::string());  //clear the string stream
                ss<<"\n//----code block from file "<<(GDATA->getAttribute("INPUT_FILE"))<<", line:"<<$code_block.line<<" ----\n";
                ss<<$text;
                ss<<"\n//----end code block-------\n";
                $text=ss.str();
        }
        ;






    
        
code_block returns [std::string text, int line]
        :          CODE_BLOCK
        {

                //Delete the delimeters of the code block,
                //and return the entire code as a string
                //to the parent rule
                $line=$CODE_BLOCK.line;
                $text = std::string((const char*)($CODE_BLOCK.text->chars));
                std::string &s = $text;
                //erase the first '$'
                s.erase(0,1);
                //erase the last '$'
                if(s.size() > 0)
                   s.resize(s.size() - 1);
                //s.erase(s.find("\$"),1);
                }
        ;           
        

//common cpp identifiers such as a->b, a.b or a::b
identifier returns [int line]
	:	 id=IDENTIFIER((DOT|SCOPE|POINTER)IDENTIFIER)*
		{$line=$id.line;}
	;
	



//---------------------------------------------
//      LEXER RULES
//---------------------------------------------

//code block : contains a block of code to be
// pasted verbatim into the generated code.


CODE_BLOCK options{greedy=false;}  : '$' .* '$' ;


BOOL	 	: 'true' | 'false';
INTEGER	 	:  '0'..'9'+ ;
STRING	 	:  '"' ( ESC_SEQ | ~('\\'|'"') )* '"' ;
CHAR     		:  '\'' ( ESC_SEQ | ~('\''|'\\') ) '\''   ;

IDENTIFIER 	 	:       ('a'..'z'|'A'..'Z') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')* ;


WS             	 	:     ( ' '  | '\t'  | '\r'  | '\n' ) {$channel=HIDDEN;}  ;

//comments can be single line or multi line
COMMENT
    :   '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    |   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

//COMMENT	 	:   '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}   ;
    
fragment
HEX_DIGIT : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
ESC_SEQ
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   UNICODE_ESC
    |   OCTAL_ESC
    ;

fragment
OCTAL_ESC
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UNICODE_ESC
    :   '\\' 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
    ;



