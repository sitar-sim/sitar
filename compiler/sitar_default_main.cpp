//sitar_default_main.cpp
//Instantiate the Top module and run simulation for specified number of cycles

#include"Top.h"
#include"sitar_simulation.h"
#include"sitar_logger.h"
#include<cstdlib>
#include<iostream>
#include<cassert>
#include<stdint.h>

using namespace std;
using namespace sitar;


//function to assign an ostream object to
//a module and all its descendants for logging
//if it is desired to use separate streams for
//different modules (for instance when using 
//multithreaded execution).
//
//example: 
//setOstream(&TOP, &some_logstream);
//setOstream(&TOP, &std::cout);
void setOstream(module* m, std::ostream* log);


int main(int argc, char* argv[])
{
	std::cout<<"\n\n";

	
	//do elaboration
	Top TOP;
	TOP.setInstanceId("TOP");
	TOP.setHierarchicalId("");


#ifdef SITAR_ENABLE_LOGGING
	//Logging related
	logger::default_logstream=&std::cout; //send all logs to std::cout by default
	
	//to send all ogs to a file instead, 
	//comment the line above and 
	//uncomment the following:
	//ofstream logfile;
	//logfile.open ("LOG.txt", std::ofstream::out);
	//logger::default_logstream=&logfile; //to send all logs to the file

	setOstream(&TOP, logger::default_logstream);
#endif

	uint64_t simulation_cycles;
	uint64_t default_simulation_cycles = 100;

	//get simulation time from the command line
	std::cout<<"\nRunning simulation...";
	if(argc<2)
	{
		std::cout<<"\nSimulation time not specified";
		std::cout<<"\n( usage: <simulation_executable> <simulation time in cycles> )";
		std::cout<<"\nDefault maximum simulation time = "<<default_simulation_cycles<<" cycles";
		simulation_cycles=default_simulation_cycles;
	}
	else
	{
		simulation_cycles=atoi(argv[1]);
		std::cout<<"\nMaximum simulation time = "<<simulation_cycles<<" cycles";
	};

	std::cout<<"\n\n";
	uint64_t i;
	for(i=0; i<simulation_cycles*2 ;i++)
	{
		TOP.run(i);
		if(sitar::simulation_stopped()) break;
	};
	std::cout<<"\nsimulation stopped at time "<<sitar::time(i)<<"\n";
	return 0;
}

//function to assign an ostream object to
//a module and all its descendants for logging
void setOstream(module* m, std::ostream* stream)
{
	m->log.setOstream(stream);
	std::map<std::string,sitar::module*>::const_iterator it;
	for(it=m->_submodules.begin();it!=m->_submodules.end();it++)
	{
		module* child=it->second;
		setOstream(child, stream);
	}
}

