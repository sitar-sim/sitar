#ifndef PIPELINE_TYPES_H
#define PIPELINE_TYPES_H

// A per-stage pipeline register. Holds the instruction metadata
// (thread_id, pc) that one stage hands off to the next, plus a
// valid bit that acts as the inter-stage handshake.
struct PipelineReg {
    bool valid;
    int  thread_id;
    int  pc;
};

// ThreadData bundles all per-stage pointers into parent-owned state.
// Each Stage procedure instance holds its own ThreadData, wired up
// by the parent module (Pipelined_Processor) in its init block.
struct ThreadData {
    int          num_threads;    // snapshot of parent's NUM_THREADS (for Fetch round-robin)
    int*         pc;             // -> parent's pc[num_threads] array
    int*         active_thread;  // -> parent's active_thread
    PipelineReg* stage_input;    // this stage's working register (currently processed instr)
    PipelineReg* stage_output;   // next stage's input register; nullptr on the last stage
};

#endif
