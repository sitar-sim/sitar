// 5_parallel_custom_main.cpp
//
// Custom main for the 5_parallel_simple example.
// Demonstrates:
//   1. Static mapping: modules a, b, c run on one thread group;
//      module d runs on a separate thread group.
//   2. Per-module RNG seeding before parallel execution begins.
//   3. Per-module log files in parallel mode.
//
// Compile:
//   sitar translate 5_parallel_simple.sitar
//   sitar compile -m 5_parallel_custom_main.cpp --openmp --logging
//
// Run:
//   export OMP_NUM_THREADS=2
//   time ./sitar_sim 20

#include "Top.h"
#include "sitar_simulation.h"
#include "sitar_logger.h"
#include <cstdlib>
#include <iostream>
#include <vector>
#include <cassert>
#include <stdint.h>

#ifdef _OPENMP
#include <omp.h>
#endif

void setHierarchicalOstream(sitar::module* m, std::ostream* stream);
void flattenHierarchy(std::vector<sitar::module*>* list, sitar::module* m);


int main(int argc, char* argv[])
{
    using namespace std;
    using namespace sitar;

    // Instantiate hierarchy
    Top* TOP = new Top;
    TOP->setInstanceId("TOP");
    TOP->setHierarchicalId("");

    // Simulation time
    uint64_t simulation_cycles = (argc < 2) ? 100 : atoi(argv[1]);
    cout << "\nMaximum simulation time = " << simulation_cycles << " cycles\n";

    // Set unique RNG seeds for each node before simulation starts.
    // Each node's seed member is set here so that parallel threads
    // each draw from an independent sequence.
    TOP->sys.a.seed = 101;
    TOP->sys.b.seed = 202;
    TOP->sys.c.seed = 303;
    TOP->sys.d.seed = 404;

    uint64_t simulation_time;
    uint64_t final_time;

#ifdef _OPENMP

    // --- Static module-to-thread mapping ---
    // Group 0: a, b, c  (heavier load, or co-located by design)
    // Group 1: d        (lighter or isolated)
    // With OMP_NUM_THREADS=2, group 0 runs on thread 0 and group 1 on thread 1.
    // With more threads, OpenMP distributes within each group via schedule(static).

    vector<module*> group0 = { &TOP->sys.a, &TOP->sys.b, &TOP->sys.c };
    vector<module*> group1 = { &TOP->sys.d };

    // Combine into a single list for the parallel for loop.
    // The first 3 entries go to thread 0, the last to thread 1
    // when OMP_NUM_THREADS=2 and schedule(static) is used.
    vector<module*> modules_to_run;
    for (auto m : group0) modules_to_run.push_back(m);
    for (auto m : group1) modules_to_run.push_back(m);
    int num_modules = modules_to_run.size();

#ifdef SITAR_ENABLE_LOGGING
    // Each module gets its own log file.
    // This is essential in parallel mode: a shared stream would interleave output.
    vector<ofstream*> logstreams;
    for (int i = 0; i < num_modules; i++)
    {
        ofstream* ofs = new ofstream;
        logstreams.push_back(ofs);
        string log_name = modules_to_run[i]->hierarchicalId() + "_log.txt";
        logstreams[i]->open(log_name.c_str());
        modules_to_run[i]->log.setOstream(logstreams[i]);
    }
#endif

    int num_threads = 1;
    omp_set_dynamic(0);

    #pragma omp parallel private(simulation_time)
    {
        #pragma omp single nowait
        { num_threads = omp_get_num_threads(); }

        for (simulation_time = 0;
             simulation_time < simulation_cycles * 2;
             simulation_time++)
        {
            #pragma omp for nowait schedule(static)
            for (int j = 0; j < num_modules; j++)
                modules_to_run[j]->run(simulation_time);

            #pragma omp barrier
            if (sitar::simulation_stopped()) break;
        }

        #pragma omp single
        { final_time = simulation_time; }
    }

    cout << "\nSimulation stopped at time " << sitar::time(final_time);
    cout << "\nRan with " << num_threads << " OpenMP thread(s).";

#ifdef SITAR_ENABLE_LOGGING
    cout << "\nPer-module log files generated.";
    for (int i = 0; i < num_modules; i++)
        logstreams[i]->close();
#endif

#else
    // Serial fallback
#ifdef SITAR_ENABLE_LOGGING
    sitar::logger::default_logstream = &cout;
    setHierarchicalOstream(TOP, sitar::logger::default_logstream);
#endif

    for (simulation_time = 0;
         simulation_time < simulation_cycles * 2;
         simulation_time++)
    {
        TOP->runHierarchical(simulation_time);
        if (sitar::simulation_stopped()) break;
    }
    final_time = simulation_time;
    cout << "\nSimulation stopped at time " << sitar::time(final_time);
#endif

    cout << "\n";
    return 0;
}


void setHierarchicalOstream(sitar::module* m, std::ostream* stream)
{
    m->log.setOstream(stream);
    for (auto it = m->_submodules.begin(); it != m->_submodules.end(); ++it)
        setHierarchicalOstream(it->second, stream);
}

void flattenHierarchy(std::vector<sitar::module*>* list, sitar::module* m)
{
    list->push_back(m);
    for (auto it = m->_submodules.begin(); it != m->_submodules.end(); ++it)
        flattenHierarchy(list, it->second);
}
