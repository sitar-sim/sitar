//sitar_ancilliary.h
//a token is a packet of information used for communication between modules.


#ifndef SITAR_ANCILLIARY_H
#define SITAR_ANCILLIARY_H

#include<stdint.h>
#include<string>
#include<sstream>
namespace sitar{

	template<typename T>
		std::string toString(const T& val)
		{
			std::ostringstream out;
			out << val;
			return out.str();
		}
}
#endif

