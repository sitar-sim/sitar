//sitar_loggger.h

//Library for implementing systematic logging.
//See logger.sitar in the examples folder for usage instructions.
//
//The logger class is basically a wrapper around an ostream object.  
//By default, all logger instances send their output to an ostrem
//instance called "defaultLogstream" which is a reference to std::cout.
//However, the user can create any number of additional loggers, 
//and can change every logger's ostream to an ostream object such as a file.
//
//Each logger instance has a prefix variable (which is an empty string by default).  
//Whenever the std::endl is passed to the logger, a newline followed by this prefix 
//gets inserted into the generated log.
//
//For modules, by default the prefix is set to "<TIME> <HIERARCHICAL ID>"
//and is updated every cycle, since the current time changes every cycle.
//The prefix can be changed by calling the setPrefix() method.


#ifndef SITAR_LOGGER_H
#define SITAR_LOGGER_H

#include<iostream>
#include<fstream>
#include<sstream>
#include<ostream>
#include<string>
#include<cassert>


#ifdef SITAR_ENABLE_LOGGING
namespace sitar{
class logger 
	{
		public:
			
			inline void setOstream(std::ostream* os){_logstream =os;}
			inline void turnON(){_logON=true;}
			inline void turnOFF(){_logON=false;}
			inline bool isON(){return _logON;}
			inline void setPrefix(std::string prefix){_prefix=prefix;}
			

			//log standard types
			template <class T>
			inline logger& operator <<(const T& value) 
			{
				if(_logON)
				{
					assert(_logstream); //check that _logstream has been set
					//insert a prefix
					if(_lastTokenWasEndl) 
					{
						(*_logstream)<<_prefix;
						_lastTokenWasEndl=false;
					}
					//pass on stuff to ostream
					(*_logstream) << value;
				}
				return *this;
			}

			//log special types such as std::endl			
			inline logger& operator<<( std::ostream&(*f)(std::ostream&) )
			{
				if(_logON)
				{
					assert(_logstream);
					(*_logstream) << f;
					if(f == static_cast<std::ostream& (*)(std::ostream&)>(std::endl))
					_lastTokenWasEndl = true;
				}
				return *this;
			}
			
			//constructor
			inline logger()
			{
				_logstream=NULL;
				_logON = true;
				_lastTokenWasEndl=true;
				_prefix="";
				useDefaultPrefix = true;
				
			}

			//default ostream used by all modules for logging
			static std::ostream* default_logstream;	
			
			bool useDefaultPrefix;
			//This variable is used by modules owning the logger.
			//If set to true, modules generate a prefix "<time><name>" every cycle
			//for the logger. Else, modules don't change the prefix each cycle.
			//Set to true by default.



			
		private:
			std::ostream* 	_logstream; 	//pointer to ostream to which stuff to be logged is passed
			bool 		_logON;		//variable to control logging at runtime
			bool		_lastTokenWasEndl; //a flag to detect newlines and 
							 //attach a prefix to the output for every new line
			std::string	_prefix;         //prefix to be attached to every new line
	};
}

#else //logger functions do nothing
namespace sitar{
class logger 
	{
		public:
			
			inline void setOstream(std::ostream* ){}
			inline void turnON(){}
			inline void turnOFF(){}
			inline bool isON(){return 0;}
			inline void setPrefix(std::string ){}

			//log standard types
			template <class T>
			inline logger& operator <<(const T& ) {return *this;}
		
			//log special types such as std::endl			
			inline logger& operator<<( std::ostream&(*)(std::ostream&) ){return *this;}
			//constructor
			inline logger(){}
			//default ostream used by all modules for logging
			static std::ostream* default_logstream;	

	};
}
#endif
#endif

