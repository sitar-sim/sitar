//sitar_loggger.h

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
				assert(_logstream);
				//no stream attached to this logger!
				if(_logON)
				{
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
				assert(_logstream);
				if(_logON)
				{
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
			static std::ofstream default_logstream;	
			static inline std::ofstream& defaultLogstream(){return default_logstream;}
			
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
			static std::ofstream default_logstream;	
			static inline std::ofstream& defaultLogstream(){return default_logstream;}

	};
}
#endif
#endif

