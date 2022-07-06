//sitar_default_main.cpp
//Instantiate the Top module and run simulation for specified number of cycles

#include"Top.h"
#include"sitar_simulation.h"
#include"sitar_logger.h"
#include<cstdlib>
#include<iostream>
#include<cassert>
#include<stdint.h>
#include <csignal>
#include <vector>

#ifdef _OPENMP
#include<omp.h>
#endif

//flags for checking termination
bool INTERRUPTED  = false;


//Interrupt Handler (for interrupting long simulations):
extern "C" void InterruptHandler( int signum )
{
	INTERRUPTED=true;
	#ifdef _OPENMP
	#pragma omp flush(INTERRUPTED)
	#endif
	printf("\n INTERRUPT SIGNAL %d RECEIVED \n stopping simulation and saving results to file",signum);
	sitar::stop_simulation();
	return;
}



//function to assign an ostream object to a module 
//for logging.
void setOstream(sitar::module* m, std::ostream* log);

//A hierarchical(recursive version of setOstream
//that sets an ostream for a module and all its descendants
void setHierarchicalOstream(sitar::module* m, std::ostream* log);

//A function to flatten hierarchy for parallel execution
void flattenHierarchy(std::vector<sitar::module*>* module_list, sitar::module* parent_module);


int main(int argc, char* argv[])
{
	using namespace std;
	using namespace sitar;

	//Register an interrupt handler
	signal(SIGINT, InterruptHandler); 

	//Instantiate the sitar module hierarchy
	Top TOP;
	TOP.setInstanceId("TOP");
	TOP.setHierarchicalId("");
	
	//Get simulation time from the command line
	uint64_t simulation_cycles;
	uint64_t default_simulation_cycles = 100;
	cout<<"\n\n";
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

	int num_threads =1; //number of threads used for simulation 
	uint64_t simulation_time;//iteration/time variable
	uint64_t final_time;
	
	//Logging-related
	#ifdef SITAR_ENABLE_LOGGING
	//send all logs to std::cout by default.
	logger::default_logstream=&std::cout; 
	//To send all logs to a file instead, 
	//comment the line above and 
	//uncomment the following:
	//ofstream logfile;
	//logfile.open ("LOG.txt", std::ofstream::out);
	//logger::default_logstream=&logfile; 
	setHierarchicalOstream(&TOP, logger::default_logstream);
	#endif


	#ifdef _OPENMP
		//If we want parallel execution,
		//we first flatten the hierarchy and create 
		//a list of modules to run in parallel.
		std::vector<module*> modules_to_run_in_parallel;
		flattenHierarchy(&modules_to_run_in_parallel, &TOP);
		int num_modules = modules_to_run_in_parallel.size();
	
		//also, we need each of these modules
		//to use a separate log stream (file)
		#ifdef SITAR_ENABLE_LOGGING
			std::vector<std::ofstream *> logstreams;
			for(int i=0;i<num_modules;i++)
			{
				std::ofstream* ofs = new std::ofstream;
				logstreams.push_back(ofs);
				std::string log_name = modules_to_run_in_parallel[i]-> hierarchicalId()+"_log.txt";
				logstreams[i]->open(log_name.c_str());
				setHierarchicalOstream(modules_to_run_in_parallel[i],logstreams[i]);
			}
		#endif
		
		//Now, run simulation in parallel using OpenMP
		omp_set_dynamic(0);  //disable dynamic teams
		#pragma omp parallel private(simulation_time) 
		{
			//get this thread's ID
			//int thread_id = omp_get_thread_num();
			//find out how many threads ran:
			#pragma omp single nowait
			{
				num_threads = omp_get_num_threads();
			}
			
			//run the simulation.
			//all threads synchronize at the end of each phase:
			for(simulation_time=0; (simulation_time<simulation_cycles*2 and INTERRUPTED==false);simulation_time++)
			{
				#pragma omp for nowait schedule(static)   
				for(int j =0;j<num_modules;j++)
				{
					modules_to_run_in_parallel[j]->run(simulation_time);
				}
				#pragma omp barrier
				if(sitar::simulation_stopped()) break;
			};
			#pragma omp single
			{final_time = simulation_time;}
		}
	
		//close all opened log files
		#ifdef SITAR_ENABLE_LOGGING
		for(int i=0;i<num_modules;i++)
			logstreams[i]->close();
		#endif
	#else
	//If we only want serial execution...
		for(simulation_time=0; (simulation_time<simulation_cycles*2 and INTERRUPTED==false);simulation_time++)
		{
			TOP.runHierarchical(simulation_time);
			if(sitar::simulation_stopped()) break;
		}
		final_time = simulation_time;
	#endif

	cout<<"\nsimulation stopped at time "<<sitar::time(final_time)<<"\n";
	cout<<"\nnum threads = "<<num_threads<<"\n";
	return 0;
}




//function to assign an ostream object to
//a module for logging
void setOstream(sitar::module* m, std::ostream* stream)
{
	m->log.setOstream(stream);
}

//hierarchical version of setOstream
void setHierarchicalOstream(sitar::module* m, std::ostream* stream)
{
	m->log.setOstream(stream);
	std::map<std::string,sitar::module*>::const_iterator it;
	for(it=m->_submodules.begin();it!=m->_submodules.end();it++)
	{
		sitar::module* child=it->second;
		setHierarchicalOstream(child, stream);
	}
}

void flattenHierarchy(std::vector<sitar::module*>* module_list, sitar::module* this_module)
{
	module_list->push_back(this_module);
	std::map<std::string,sitar::module*>::iterator it;
	for(it=(this_module->_submodules).begin();it!=(this_module->_submodules).end();it++)
	{
		sitar::module* child=it->second;
		flattenHierarchy(module_list,child);
	}
}

