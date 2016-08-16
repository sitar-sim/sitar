" Vim syntax file 
" Language: sitarV2.0 System Description Language
" Maintainer: Neha Karanjkar (neha.karanjkar@gmail.com)
" Latest Revision: Feb 2015


if exists("b:current_syntax")
finish
endif

syn clear
syn sync fromstart " change this if it gets slow.
syn sync linebreaks=1

" Keywords
syn keyword sitarMainKeywords 		module procedure parameter behavior  
syn keyword sitarBehavioralKeywords 	wait until if then else do while nothing stop simulation run  end
syn keyword sitarStructuralKeywords  	inport inport_array outport outport_array buffer net net_array submodule submodule_array width capacity for in to 
syn keyword sitarOtherKeywords 		or and not this_phase this_cycle
syn keyword sitarCodeSnipetteKeywords 	include decl init 

" Code regions
syn region sitarCodeBlock start="\$"  end="\$"  contains=sitarComment2     

" Strings
syn region sitarString start='"' end='"'

" Comments
syn match sitarComment "\/\/.*$"
syn match sitarComment2 "\/\/.*$" contained

" Symbols
syn match sitarSymbol "<=\|=>\|:"  
syn match sitarStatementConnectors ";\|||\|\[\|\]"

let b:current_syntax = "sitar"

hi def link sitarMainKeywords   	Keyword
hi def link sitarBehavioralKeywords	Keyword
hi def link sitarStructuralKeywords 	Keyword
hi def link sitarOtherKeywords  	Keyword
hi def link sitarCodeSnipetteKeywords 	Keyword
hi def link sitarSymbol			Keyword

hi def link sitarComment   		Comment
hi def link sitarComment2   		Identifier
hi def link sitarStatementConnectors 	Type
hi def link sitarString              	Constant
hi def link sitarCodeBlock 		PreProc


"
