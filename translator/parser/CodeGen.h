//CodeGen.h 
//Encapsulates the Lexer and Parser for Code Generation
//-----------------------------------------------------



#ifndef CODEGEN_H
#define CODEGEN_H

#include"output_templateLexer.h"
#include"output_templateParser.h"
#include"GlobalData.h"  


#include	<iostream> 
#include	<map>
#include	<string>


class CodeGen
{

	public:


		//Constructor
		CodeGen();
		//Destructor
		~CodeGen();
		

		void setGlobalDataPtr(GlobalData * global_data);




		void parse();
		//Create token stream, lexer and parser,
		//parse the template, generate output code
		//and destroy everything.

		//Note: each time we use this function, we create and destroy
		//everything. Actually, all we need to do is to rewind the token 
		//stream, and reuse the parser,(and free up all the strings created
		//by the string factory when getText() methods were called.)
		//I cannot figure out a way to do this currently. Might need to 
		//use the latest C rntime of ANTLR which has reuse() method for 
		//token stream
		//

		//some common helper methods

		std::string intToString(const int & i);



	private:
		GlobalData*	_globalDataPtr;

	private:
		pANTLR3_UINT8      	finput; //The template for generating code
		pANTLR3_INPUT_STREAM   input;
		poutput_templateLexer    lxr;
		pANTLR3_COMMON_TOKEN_STREAM        tstream;
		poutput_templateParser	 	psr;

};


#endif

