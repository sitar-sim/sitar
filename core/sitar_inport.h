//sitar_inport.h

//Input interface between a module and a net

#ifndef SITAR_INPORT_H
#define SITAR_INPORT_H

#include"sitar_object.h"
#include"sitar_token.h"
#include"sitar_net.h"
#include<cassert>


namespace sitar{

//base class 
class base_inport : public object
{
	public:
	virtual unsigned int width()=0;
	virtual base_net* getNet()=0;
};


template<unsigned int _width=0> //width of the net that this port connects to
class inport:public base_inport
{
		public :
			void setNet(net<_width>* n) 
			//connect the port to a net
			{assert(n); _net=n;}

			net<_width>* getNet() 
			//get a pointer to the net this port is connected to
			{return _net;}

			bool pull(token<_width>& tok)
			//pull a token into tok 
			//and return 1 if pull is 
			//successful, return 0 otherwise
			{
			assert(_net);
			return getNet()->pull(tok);
			}
	
			//return true if there are no tokens
			//to be pulled
			bool empty()
			{
				assert(_net);
				return (_net->empty());
			}

			//return the number of tokens 
			//present in the net connected to this port
			unsigned int numTokens()
			{
				assert(_net);
				return (_net->numTokens());
			}
			 
			//constructor
			inport()
			{_net=NULL;}

			//implement virtual function
			inline unsigned int width(){return _width;}

		private:
			net<_width>* _net;

};
}
#endif
