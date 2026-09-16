//sitar_logger.cpp
#include "sitar_logger.h"
#include<ostream>

//Definition of logger::default_logstream, a static member declared in
//both the SITAR_ENABLE_LOGGING and non-logging variants of class
//logger (sitar_logger.h) and referenced unconditionally by callers
//(e.g. module::module(), sitar_default_main.cpp) -- so its storage
//must exist unconditionally too, not just when logging is enabled.
namespace sitar{

			//default ostream used by all modules for logging
			std::ostream* logger::default_logstream;

}

