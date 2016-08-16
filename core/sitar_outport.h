//sitar_outport.h

//Output interface between a module and a net

#ifndef SITAR_OUTPORT_H
#define SITAR_OUTPORT_H

#include"sitar_object.h"
#include"sitar_token.h"
#include"sitar_net.h"
#include<cassert>


namespace sitar{

//base class 
class base_outport : public object
{
	public:
	virtual unsigned int width()=0;
	virtual base_net* getNet()=0;
};

template<unsigned int _width=0> //width of the net that this port connects to
class outport:public base_outport
{
		public :
			void setNet(net<_width>* n) 
			//connect the port to a net
			{assert(n); _net=n;}

			net<_width>* getNet() 
			//get a pointer to the net this port is connected to
			{return _net;}

			bool push(token<_width>& tok)
			//push a token into net 
			//and return 1 if push is 
			//successful, return 0 otherwise
			{
			assert(_net);
			return getNet()->push(tok);
			}

			bool full()
			//return true if the
			//net is full, and tokens
			//cannot be pushed through 
			//this port
			{
				assert(_net);
				return(_net->full());
			}
				
			
			//constructor
			outport()
			{_net=NULL;}

			//implement virtual function
			inline unsigned int width(){return _width;}

		private:
			net<_width>* _net;

};

}
#endif
