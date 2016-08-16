///MainParser.h 
//Encapsulates the Lexer and Parser for parsing system descriptions in SiTAR
//--------------------------------------------------------------------------



#ifndef MAINPARSER_H
#define MAINPARSER_H

#include"sitarLexer.h"
#include"sitarParser.h"
#include"GlobalData.h"  


#include	<iostream> 
#include	<map>
#include	<string>

class CodeGen;

class MainParser
{

	public:


		//Constructor
		MainParser();
		//Destructor
		~MainParser();
		

		void setCodeGenPtr(CodeGen * code_gen);
		void setGlobalDataPtr(GlobalData * global_data);



		void parse();
		//Create token stream, lexer and parser,
		//parse the input, generate output code
		//and destroy everything.

	private:
		CodeGen * 	_codeGenPtr;
		GlobalData*	_globalDataPtr;


	private:
		pANTLR3_UINT8      		finput; //The template for generating code
		pANTLR3_INPUT_STREAM   		input;
		psitarLexer    			lxr;
		pANTLR3_COMMON_TOKEN_STREAM	tstream;
		psitarParser	 		psr;

};
#endif


