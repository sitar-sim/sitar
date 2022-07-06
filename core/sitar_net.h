//sitar_net.h


//A net serves as a channel of communication between modules.
//A net provides a fixed sized FIFO buffering for tokens. 
//A net has two parameters:
//	capacity: maximum number of tokens that it can buffer at a time
//	width   : the net can only hold tokens of this width.
//
//A net object does not allocate memory for implementing the buffer.
//A buffer memory (an array of tokens) must be assigned to each net
//at elaboration time. This is done automatically in the translated code.



#ifndef SITAR_NET_H
#define SITAR_NET_H
#include"sitar_object.h"
#include"sitar_token.h"
#include<cassert>

namespace sitar{

//abstract base class for class net
class base_net:public object
{
	public :
		
		inline bool empty()const {return _num_tokens==0;}
		//return 1 if buffer is empty
		inline bool full()const  {return _num_tokens>=_capacity;}
		//return 1 if buffer is full
		inline unsigned int capacity()const {return _capacity;}
		//return maximum capacity
		inline unsigned int numTokens()const{return _num_tokens;}
		//return number of tokens currently in net
		inline unsigned int remainingCapacity()const{ return (_capacity-_num_tokens);}
		//get remaining capacity
		
		
		//constructor
		inline base_net(){_capacity=0;_num_tokens=0;}

		//virtual methods:
		//implemented in the derived token class
		
		virtual unsigned int width()=0;
		//returns width of the tokens this net can carry
		


	protected:
		unsigned int _capacity; //max number of tokens that can be stored
		unsigned int _num_tokens;//number of tokens present on the net
};





template<unsigned int _width=0> //width of the data token's payload in Bytes
class net:public base_net
{
	public :
		
		void setBuffer(token<_width>* buff, unsigned int cap) 
			//Assign a buffer to be used by net.
			//(called at elaboration time)
			//buffer is a pointer to an array of tokens of size <_width>
			//cap is the maximum number of tokens that the net can hold
			{
				assert(buff);
				assert(cap);
				_buffer=buff; 
				_capacity=cap;
			}
		
		bool push(const token<_width>& tok)
			//push a token and return 1 if net is not full.
			//return 0 otherwise
			{
				if (full()) return 0; //can't push
				//else
				assert(_buffer);
				_buffer[_back]=tok;
				_back = (_back+1)%_capacity;
				_num_tokens++;
				return 1;
			}
	
		bool pull(token<_width>& tok)
			//pull a token and return 1 if net is not empty
			//return 0 otherwise
			{
				if (empty()) return 0; //can't pull
				//else
				assert(_buffer);
				tok=_buffer[_front];
				_front=(_front+1)%_capacity;
				_num_tokens--;
				return 1;
			}
		
		bool peek(token<_width>& tok)
			//copy a token and return 1 if net is not empty
			//return 0 otherwise. Do not modify the state of the net.
			{
				if (empty()) return 0; //can't pull
				//else
				assert(_buffer);
				tok=_buffer[_front];
				return 1;
			}

		//constructor
		net()
		{
			_buffer=NULL;
			_front=0;
			_back=0;
		}

		inline unsigned int width(){return _width;}


	//private:
		token<_width>*	_buffer; //pointer to a fixed size array of tokens
		//variables for implementing a circular buffer
		unsigned int _front;
		unsigned int _back;


};
}
#endif
