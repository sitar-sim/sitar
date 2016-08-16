//sitar_logger.cpp
#include "sitar_logger.h"
#include<ostream>


#ifdef SITAR_ENABLE_LOGGING
namespace sitar{

			//definition of a static member variable 
			//in logger class:
			//
			//default ostream used by all modules for logging
			std::ofstream logger::default_logstream;	
}

#endif

