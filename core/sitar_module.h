//sitar_module.h


#ifndef SITAR_MODULE_H
#define SITAR_MODULE_H

#include"sitar_time.h"
#include"sitar_token.h"
#include"sitar_logger.h"
#include"sitar_simulation.h"
#include"sitar_ancilliary.h"

#include"sitar_object.h"
#include"sitar_net.h"
#include"sitar_inport.h"
#include"sitar_outport.h"


#include<string>
#include<map>

namespace sitar{
class module:public object
{
	public :
		
		void run(const time& current_time);
		//first execute behavior of this module (runBehavior())
		//then call run() for each child module

		inline virtual void runBehavior(const time& ){};
		//execute behavior of this module
		//for one phase. 


		std::string getInfo()const;
		//return information about this module
		//and all its subcomponents as a string.

		void setHierarchicalId(const std::string& parents_hierarchical_id);
		
		//methods to register components of a module
		void addSubmodule(module * module   , const std::string& ID);
		void addProcedure(module * procedure, const std::string& ID);
		void addInport   (base_inport*  inp   , const std::string& ID);
		void addOutport  (base_outport* outp  , const std::string& ID);
		void addNet      (base_net*     n     , const std::string& ID);

		
		//constructor
		module();

		//-----------------------------------------------
		//public data members:
		std::string _type;
		
		//list of sub-somponents
		std::map<std::string,module*> _submodules;
		std::map<std::string,module*> _procedures;
		std::map<std::string,base_inport*> _inports;
		std::map<std::string,base_outport*>_outports;
		std::map<std::string,base_net*>    _nets;

		//variables for storing state of the behavioral block
		bool _terminated;
		bool _reexecute;

		//logger
		logger log;
		void setLogPrefix(const time& current_time);
		bool useDefaultPrefix; 
		//Set to true by default.
		//if set to true, the default logginf prefix is
		//"<time><module name>:".
		//Set this to false to use a custom prefix for
		//logging.


};

}
#endif
