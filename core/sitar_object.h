//sitar_object.h

//Base class to all objects that are created during elaboration, 
//and exist throughout the simulation,
//such as module, net, inport and outport.
//
//
//Each object has an instance name, and belongs to 
//a parent module


#ifndef SITAR_OBJECT_H
#define SITAR_OBJECT_H
#include<iostream>
#include<string>
#include<cassert>

namespace sitar{

class module;
class object
{
	public:
		//get, set methods
		
		inline const std::string&	instanceId()const{return _instanceId;}//Instance Id within this object's parent
		inline const std::string&	hierarchicalId()const{return _hierarchicalId;}//Hierarchical ID Eg, "Top.foo.bar.port1"
		inline module*			parent()const{return _parent;}//get pointer to parent module
		
		inline void			setInstanceId(const std::string& instance_id){_instanceId=instance_id;}
		inline void			setHierarchicalId(const std::string& parents_hierarchical_id)
					{	if(parents_hierarchical_id=="")
							_hierarchicalId=_instanceId;
						else
							_hierarchicalId=parents_hierarchical_id+"."+_instanceId;
					}

		inline void			setParent(module* parent){assert(parent!=NULL);_parent=parent;}
		

		//constructor,destructor
		inline object(){_parent=NULL; _instanceId="NONE"; _hierarchicalId="NONE";}
		inline object(const std::string& instance_id):_instanceId(instance_id){_parent=NULL;_hierarchicalId="NOT_SET";}
		inline ~object(){}

	protected:	
		std::string 		_instanceId;
		std::string 		_hierarchicalId;
		module* 		_parent;
};
}
#endif

