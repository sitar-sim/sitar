//sitar_token.h
//
//A token is a packet of information used for communication between modules.
//A token has basic information fields like sender, receiver, token ID etc
//and a payload. The payload is an array of Bytes. The payload size is 
//variable that has to be defined at compile time.


#ifndef SITAR_TOKEN_H
#define SITAR_TOKEN_H

#include<stdint.h>
#include<string>
#include<sstream>
#include<iomanip>


namespace sitar{

//base_token is an abstract base class for implementing tokens.
//The base_token class has all information fields but no payload.
//It defines virtual methods for accessing the payload which are
//implemented in the derived 'token' class where the payload is 
//actually present.
class base_token
{

	public :
		uint8_t	 type;
		uint64_t ID;
		
		//return a pointer to the data payload 
		virtual uint8_t* data()=0;
		
		//return size of the data payload in bytes
		virtual unsigned int size()=0;

		//constructor
		inline base_token() {type =0; ID=0;}
	
		//return information about the token as string 
		//for printing
		inline std::string info() 
		{
			std::ostringstream ss;
			ss<<"(type="<<(int)type;
			ss<<", ID="<<ID;
			if(this->size()>0 and data()!=NULL)
			{
				uint8_t* d=static_cast<uint8_t*>(data());
				ss<<", payload=0x";
				ss<<std::hex<<std::setfill('0');
				for(int i=0;i<(int)size();i++)
				{
					ss<<std::setw(2)<<(int)(d[i])<<" ";
				}
			}
			ss<<")";
			return ss.str();
		}
		
};



//token class has a payload which is an array of bytes.
//the size of the payload in bytes is a template argument.

//a token with default templates has no payload
template<unsigned int _size=0>
class token : public base_token
{
	public:
		inline uint8_t* data(){return _data;}
		inline unsigned int size(){return _size;}

		//constructor
		inline token()
		{
			for(int i=0;i<int(_size);i++)
				_data[i]=0;
		}
	private:
		uint8_t _data[_size];
			
};

//special case when size=0 
template<>
class token<0> : public base_token
{
	public:
		inline uint8_t* data(){return NULL;}
		inline unsigned int size(){return 0;}

		//constructor
		inline token(){};
				
};

}
#endif

