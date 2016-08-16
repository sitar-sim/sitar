//sitar_module.cpp

#include"sitar_time.h"
#include"sitar_token.h"
#include"sitar_simulation.h"

#include"sitar_object.h"
#include"sitar_net.h"
#include"sitar_inport.h"
#include"sitar_outport.h"
#include"sitar_module.h"


#include<string>
#include<sstream>
#include<map>
#include<cassert>

namespace sitar{
		
		void module::run(const time& current_time)
		//first execute behavior of this module (runBehavior())
		//then call run() for each child module
		{
			//set logger prefix for current cycle
			#ifdef SITAR_ENABLE_LOGGING
			if(log.isON() and log.useDefaultPrefix)
				setLogPrefix(current_time);
			#endif
			
			runBehavior(current_time);
			std::map<std::string,module*>::iterator it;
			for(it=_submodules.begin();it!=_submodules.end();it++)
			{
				module* child=it->second;
				if(child and not(child->_terminated))
					child->run(current_time);
			}
			
		}

		void module::setLogPrefix(const time& current_time)
		{
			//set prefix for logger with a reasonable width =16.
			//pad the remaining characters with spaces
			int padding=16;
			std::string s = toString(current_time)+hierarchicalId();
			if(s.size()<16)
				s.insert(s.end(), padding - s.size(), ' ');
			log.setPrefix(s+":");
		}
			


		//virtual void module::runBehavior(const time& current_time)=0;
		//execute behavior of this module
		//for one phase

		std::string module::getInfo()const
		//return information about this module
		//and all its subcomponents as a string.
		{
			std::ostringstream os;
			os<<"\n----------------------------------";
			os<<"\n module ID  : "<<hierarchicalId();
			os<<"\n type       : "<<_type;
			{
				//net
				os<<"\n nets       : ";
				if(_nets.empty()) os<<"NONE";

				for(std::map<std::string,base_net*>::const_iterator ip=_nets.begin();\
						ip!=_nets.end();ip++)
				{
					base_net* child=ip->second;
					os<<"\n\t    - "<<child->instanceId();
					os<<" of capacity "<<child->capacity();
					os<<", width "<<child->width();
				}
			}

			
			{
				//inport
				os<<"\n inports    : ";
				if(_inports.empty()) os<<"NONE";

				for(std::map<std::string,base_inport*>::const_iterator ip=_inports.begin();\
						ip!=_inports.end();ip++)
				{
					base_inport* child=ip->second;
					os<<"\n\t    - "<<child->instanceId();
					os<<" of width "<<child->width();
					os<<", connected to net ";
					if(child->getNet()!=NULL)
						os<<child->getNet()->hierarchicalId();
					else
						os<<"NONE";
				}
			}



			{
				//outport
				os<<"\n outports   : ";
				if(_outports.empty()) os<<"NONE";
				std::map<std::string,base_outport*>::const_iterator op;
				for(op=_outports.begin();op!=_outports.end();op++)
				{
					base_outport* child=op->second;
					os<<"\n\t    - "<<child->instanceId();
					os<<" of width "<<child->width();
					os<<", connected to net ";
					if(child->getNet()!=NULL)
						os<<child->getNet()->hierarchicalId();
					else
						os<<"NONE";
				}
			}

			{
				//module
				os<<"\n submodules : ";
				if(_submodules.empty()) os<<"NONE";
				std::map<std::string,module*>::const_iterator it;
				for(it=_submodules.begin();it!=_submodules.end();it++)
				{
					module* child=it->second;
					os<<"\n\t    - "<<child->instanceId();
					os<<" of type "<<child->_type;
				}
			}
			{
				//Procedure
				os<<"\n procedures : ";
				if(_procedures.empty()) os<<"NONE";
				std::map<std::string,module*>::const_iterator it;
				for(it=_procedures.begin();it!=_procedures.end();it++)
				{
					module* child=it->second;
					os<<"\n\t    - "<<child->instanceId();
					os<<" of type "<<child->_type;
				}
			}
			os<<"\n----------------------------------";

			//Call getInfo recursively on all submodules and procedures:
			{
				//module
				std::map<std::string,module*>::const_iterator it;
				for(it=_submodules.begin();it!=_submodules.end();it++)
				{
					module* child=it->second;
					os<<child->getInfo();
				}
				for(it=_procedures.begin();it!=_procedures.end();it++)
				{
					module* child=it->second;
					os<<child->getInfo();
				}
			}
			return os.str();
		}

		//called at elaboration time
		void module::setHierarchicalId(const std::string& parents_hierarchical_id)
		{
			//set self id
			object::setHierarchicalId(parents_hierarchical_id);

					
			//set ids on all components:
			{
				//inport
				std::map<std::string,base_inport*>::iterator it;
				for(it=_inports.begin();it!=_inports.end();it++)
				{
					base_inport* child=it->second;
					child->setHierarchicalId(hierarchicalId());
				}
			}
			{
				//outport
				std::map<std::string,base_outport*>::iterator it;
				for(it=_outports.begin();it!=_outports.end();it++)
				{
					base_outport* child=it->second;
					child->setHierarchicalId(hierarchicalId());
				}
			}
			{
				//net
				std::map<std::string,base_net*>::iterator it;
				for(it=_nets.begin();it!=_nets.end();it++)
				{
					base_net* child=it->second;
					child->setHierarchicalId(hierarchicalId());
				}
			}
			{
				//module
				std::map<std::string,module*>::iterator it;
				for(it=_submodules.begin();it!=_submodules.end();it++)
				{
					module* child=it->second;
					child->setHierarchicalId(hierarchicalId());
				}
			}
			{
				//Procedure
				std::map<std::string,module*>::iterator it;
				for(it=_procedures.begin();it!=_procedures.end();it++)
				{
					module* child=it->second;
					child->setHierarchicalId(hierarchicalId());
				}
			}
		}


		
		//constructor
		module::module()
		{
			_type = "NONE";
			_terminated = false;
			_reexecute  = false;

			//set logger to use the default logstream
			log.setOstream(&logger::defaultLogstream());

		}

		//methods to register components of a module
		void module::addSubmodule(module * m   , const std::string& ID){ assert(m);	 _submodules[ID] = m; 	m->setParent(this);}
		void module::addProcedure(module * procedure, const std::string& ID){ assert(procedure); _procedures[ID] = procedure; 	procedure->setParent(this);}
		void module::addInport   (base_inport*  inp   , const std::string& ID){ assert(inp);	 _inports[ID] = inp; 	inp->setParent(this);}
		void module::addOutport  (base_outport* outp  , const std::string& ID){ assert(outp);	 _outports[ID] = outp; 	outp->setParent(this);}
		void module::addNet      (base_net*     n      , const std::string& ID){ assert(n);	 _nets[ID] = n;  		n->setParent(this);}


	

}



//testbench
/*
int main()
{
	using namespace std;
	using namespace sitar;

	static const unsigned int W =10;

	module m1	; m1.setInstanceId("m1"); m1._type="type_m";
	module m2	; m2.setInstanceId("m2"); m2._type="type_m";
	
	token<W> n1_buffer[10]; 
	net<W> n1; 
	n1.setInstanceId("n1"); 
	n1.setBuffer(n1_buffer,10);

	inport<W> p1	; 
	p1.setInstanceId("p1"); 
	p1.setNet(&n1);


	
	m1.addSubmodule(&m2,"m2");
	m1.addInport(&p1,"p1");
	m1.addNet(&n1,"n1");
	m1.setHierarchicalId("");

	cout<<"\n\n";
	cout<<m1.getInfo();
	cout<<m2.getInfo();
	cout<<"\n\n";
	return 0;
}
*/
