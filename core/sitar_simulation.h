//sitar_simulation.h

//routines for simulation control


#ifndef SITAR_SIMULATION_H
#define SITAR_SIMULATION_H

#define SITAR_ITERATION_LIMIT 1000

#ifdef _OPENMP
   #include<omp.h>
#endif

#include"sitar_time.h"
#include"sitar_module.h"
namespace sitar{


	extern bool _stop_simulation;
	
	inline void stop_simulation()
	{
		#ifdef _OPENMP
		#pragma omp critical
		#endif
		{
			_stop_simulation=1;
		}
		#ifdef _OPENMP
		#pragma omp flush(_stop_simulation)
		#endif
	}
	
	inline void restart_simulation()
	{
		#ifdef _OPENMP
		#pragma omp critical
		#endif
		{
			_stop_simulation=0;
		}
		#ifdef _OPENMP
		#pragma omp flush(_stop_simulation)
		#endif
	}

	inline bool simulation_stopped()
	{
		return _stop_simulation;
	}


	
}
#endif

