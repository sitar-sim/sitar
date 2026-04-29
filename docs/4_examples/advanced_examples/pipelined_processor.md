# Pipelined Processor

This example models a **4-stage pipelined processor** that executes **2 hardware threads** scheduled in round-robin.

### Objectives

The purpose of this example is to demonstrate how to build a *synchronous pipeline* in Sitar, where data transfer between stages happens on the same clock edge with zero latency between adjacent stages. This cannot be achieved by modeling each stage as a separate module connected by nets, because every net incurs Sitar's minimum one-cycle communication latency, which would stretch the pipeline out in time.

Instead, a tightly coupled synchronous system such as this is modeled using a **single module containing a parallel block with one procedure per stage**. Stages communicate via shared C++ variables (not nets) owned by the parent module. Branches of a parallel block execute until convergence within a phase, and synchronization on simple shared variables is safe and deterministic as long as they reside within a single module.

**What this example demonstrates:**

- Modeling a multi-stage pipeline in Sitar as a parallel block with procedures
- Inter-stage communication via shared C++ variables guarded by `valid` bits
- Zero-overhead thread interleaving (barrel-processor pattern)
- Procedures accessing parent-module state via pointers, configured in the parent's `init`
- A simple per-stage stop criterion based on an instruction-retired counter
- Per-cycle tabular logging driven by a dedicated branch of the parallel block

This is a multi-file example. Full source:

- <a href="../../sitar_examples/pipelined_processor/PipelinedProcessor.sitar" download="PipelinedProcessor.sitar"><code>PipelinedProcessor.sitar</code></a>
- <a href="../../sitar_examples/pipelined_processor/PipelineTypes.h" download="PipelineTypes.h"><code>PipelineTypes.h</code></a>
- <a href="../../sitar_examples/pipelined_processor/compile.sh" download="compile.sh"><code>compile.sh</code></a>

---

## Architecture

```mermaid
flowchart LR
    F["FETCH"] -->|"stage_inputs[1]"| D["DECODE"] -->|"stage_inputs[2]"| E["EXECUTE"] -->|"stage_inputs[3]"| W["WRITEBACK"]
```

- **2 threads** (thread 0 and thread 1) alternate each cycle in round-robin
- **4 pipeline stages**, each an instance of a single `Stage` procedure running in a parallel block
- **Information transfer between stages** is via shared `PipelineReg` structs (fields: `valid`, `thread_id`, `pc`). Adjacent stages share a register: stage *i*'s `stage_output` and stage *i+1*'s `stage_input` point to the same shared variable
- The upstream stage **writes** the register and sets `valid=true`; the downstream stage **reads** it and later sets `valid=false` (when it forwards the instruction along). This `valid` bit is the inter-stage handshake
- All shared state is bundled into a `ThreadData` struct that each stage holds by reference
- Each stage *acquires* an instruction into its `stage_input`, *waits `DELAY` cycles* to model processing, and then *commits* to the next stage's input register. The last stage (Writeback) has no downstream and simply retires the instruction
- This models an *elastic pipeline*: each stage's `DELAY` is an independent parameter. With all `DELAY=1` we get the full-throughput behavior. A new instruction enters the pipeline every cycle and one retires every cycle after the fill-up phase. With different delay values per stage, it behaves as an elastic pipeline.


!!! note "Dummy Stages"
    This example illustrates how to model the structure and timing of the pipeline. The actual functionality of each stage is not modeled. As a placeholder, each stage simply carries the `thread_id` and `pc` of the instruction, and the parent module logs one line per cycle showing each stage's current occupancy.

---

## Shared data structures

The `PipelineTypes.h` header defines the two structs shared between the parent module and every `Stage` procedure instance:

``` cpp linenums="1"
--8<-- "docs/sitar_examples/pipelined_processor/PipelineTypes.h"
```

`PipelineReg` is one pipeline register (the data that flows between two adjacent stages). `ThreadData` is the full set of pointers each stage needs: the shared thread state (`num_threads`, `pc[]`, `active_thread`) and this stage's own input/output registers. Each `Stage` procedure instance owns one `ThreadData` value; the parent wires up its fields in the parent's `init`.

---

## Top

The `Top` module simply instantiates one processor, supplying the single template parameter `NUM_THREADS`:

``` sitar linenums="1"
--8<-- "docs/sitar_examples/pipelined_processor/PipelinedProcessor.sitar:top"
```

---

## Pipelined_Processor module

The processor owns the shared state (per-thread PCs, active thread, all four pipeline registers) and instantiates four `Stage` procedure instances named `fetch`, `decode`, `execute`, `writeback`. Its `init` block sets the `id`, `name`, and `ThreadData` pointers on each stage, chains the registers to form the pipeline, and installs the stop criterion on `writeback`.

!!! note "Init block and construction order"
    When `sitar translate` converts a module description to a C++ class, the content inside the `init` block gets placed inside its constructor. If a parent module instantiates a child submodule, the child's init gets executed before the parent's init, in accordance with the order in which C++ constructors get executed. Thus in a child module's init, default or initial values can be assigned to its variables, which can later be finalized/updated by the parent module's init, as illustrated by the following example.


``` sitar linenums="1"
--8<-- "docs/sitar_examples/pipelined_processor/PipelinedProcessor.sitar:pipelined_processor"
```

**Wiring pattern.** `stage_inputs[i]` is stage *i*'s working register. The currently processed instruction always sits there. Adjacent stages share a register:

| Stage | id | `stage_input` | `stage_output` |
|---|---|---|---|
| Fetch | 0 | `&stage_inputs[0]` (self-filled) | `&stage_inputs[1]` |
| Decode | 1 | `&stage_inputs[1]` | `&stage_inputs[2]` |
| Execute | 2 | `&stage_inputs[2]` | `&stage_inputs[3]` |
| Writeback | 3 | `&stage_inputs[3]` | `nullptr` (retires) |

**Behavior.** The `behavior` block is a single parallel block with five branches: one `run <stage>;` per stage, plus a logging branch. The logging branch runs in **phase 1**, after all phase-0 stage activity has converged, so every `stage_input.valid` reflects the stable end-of-cycle pipeline state rather than an intermediate convergence state.

---

## Stage procedure

A single `Stage` procedure is used by all four pipeline stages. Its body is a do-while loop with three steps: acquire, process and commit, plus bookkeeping.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/pipelined_processor/PipelinedProcessor.sitar:stage"
```

**Acquire (step 1).** Non-fetch stages wait in phase 0 for their upstream to deliver a valid input. The Fetch stage (`id==0`) has no upstream, so instead it waits for its input slot to be *free*, then self-fills it from `pc[active_thread]` and advances the round-robin thread selector.

**Process (step 2).** `wait(DELAY, 0)` models the stage's processing time. Because `stage_input.valid` stays `true` throughout, the logging branch in the parent sees this stage's currently working instruction during every cycle of its processing window.

**Commit (step 3).** Normal stages wait for the downstream input slot to be free, then copy `stage_input` into `stage_output` and flip both valid bits atomically (within a single code block): `stage_output.valid = true`, `stage_input.valid = false`. Writeback has no downstream, so it simply clears its own `stage_input.valid` to retire the instruction.

**Stop criterion (step 4).** Each stage keeps a `total_instr_executed` counter. If `stop_when_total_executed` has been set to a non-negative value (the parent does this on `writeback` only), the stage logs a stop message and calls `stop simulation` once the threshold is reached. Other stages leave the default `-1` and never trigger the stop.

!!! tip "Intra-cycle flow through all stages"
    A parallel block's branches are re-run round-robin until all have converged within a phase. Consider a steady-state cycle: `writeback` retires its instruction (invalidating `stage_inputs[3]`), which unblocks `execute`'s commit in a later iteration of the same phase; that invalidates `stage_inputs[2]`, unblocking `decode`; and finally `fetch` commits. Net effect: one instruction moves through every stage boundary per cycle, with no extra latency.

---

## Building and running

From the `pipelined_processor/` directory:

```bash
bash compile.sh
./sitar_sim 40
```

`compile.sh` runs `sitar translate PipelinedProcessor.sitar` and then `sitar compile -d Output/ -d ./`. The extra `-d ./` adds the current directory to the include path so that `PipelineTypes.h` is found by the generated code.

---

## Expected output

```
Model size (size of TOP in Bytes):3488
Running simulation...
Maximum simulation time = 40 cycles

(0,1)TOP.proc   :| Fetch     (t=0,pc=0)  | Decode    (---)       | Execute   (---)       | Writeback (---)       |
(1,1)TOP.proc   :| Fetch     (t=1,pc=0)  | Decode    (t=0,pc=0)  | Execute   (---)       | Writeback (---)       |
(2,1)TOP.proc   :| Fetch     (t=0,pc=1)  | Decode    (t=1,pc=0)  | Execute   (t=0,pc=0)  | Writeback (---)       |
(3,1)TOP.proc   :| Fetch     (t=1,pc=1)  | Decode    (t=0,pc=1)  | Execute   (t=1,pc=0)  | Writeback (t=0,pc=0)  |
(4,1)TOP.proc   :| Fetch     (t=0,pc=2)  | Decode    (t=1,pc=1)  | Execute   (t=0,pc=1)  | Writeback (t=1,pc=0)  |
(5,1)TOP.proc   :| Fetch     (t=1,pc=2)  | Decode    (t=0,pc=2)  | Execute   (t=1,pc=1)  | Writeback (t=0,pc=1)  |
(6,1)TOP.proc   :| Fetch     (t=0,pc=3)  | Decode    (t=1,pc=2)  | Execute   (t=0,pc=2)  | Writeback (t=1,pc=1)  |
(7,1)TOP.proc   :| Fetch     (t=1,pc=3)  | Decode    (t=0,pc=3)  | Execute   (t=1,pc=2)  | Writeback (t=0,pc=2)  |
(8,1)TOP.proc   :| Fetch     (t=0,pc=4)  | Decode    (t=1,pc=3)  | Execute   (t=0,pc=3)  | Writeback (t=1,pc=2)  |
(9,1)TOP.proc   :| Fetch     (t=1,pc=4)  | Decode    (t=0,pc=4)  | Execute   (t=1,pc=3)  | Writeback (t=0,pc=3)  |
(10,1)TOP.proc  :| Fetch     (t=0,pc=5)  | Decode    (t=1,pc=4)  | Execute   (t=0,pc=4)  | Writeback (t=1,pc=3)  |
(11,1)TOP.proc  :| Fetch     (t=1,pc=5)  | Decode    (t=0,pc=5)  | Execute   (t=1,pc=4)  | Writeback (t=0,pc=4)  |
(12,1)TOP.proc  :| Fetch     (t=0,pc=6)  | Decode    (t=1,pc=5)  | Execute   (t=0,pc=5)  | Writeback (t=1,pc=4)  |
(13,0)TOP.proc.writeback:Writeback: simulation stopped upon reaching stopping criteria, num executed=10
Simulation stopped at time (13,0)
```

- **Cycles 0–2: fill-up.** Each cycle a new instruction enters Fetch and everything downstream shifts right by one.
- **Cycle 3 onward: steady state.** All four stages are active; one instruction retires every cycle. The two threads alternate (round-robin `active_thread`), and each thread's PC advances independently.
- **Cycle 13: stop.** Writeback retires its 10th instruction at cycle 12 (visible in the `(12,1)` log line), its stop check fires immediately, and `stop simulation` halts the run at `(13,0)`.

The `(N,1)` prefix on the log lines comes from the logging branch running in phase 1 that's the stable end-of-cycle snapshot. The final stop message has prefix `(13,0)TOP.proc.writeback:` because it's emitted from the Writeback stage's own logger at phase 0.

---

## Adapting this pattern

!!! tip "Varying pipeline depth or stage delays"
    To add a longer execute phase, change the instantiation: `procedure execute : Stage<3>`. The handshake absorbs the change automatically.  Fetch and Decode will stall cleanly whenever Execute is busy, and the throughput will drop accordingly. To add more stages or more threads, extend `NUM_STAGES` (and the `stage_names[]` array) or change the `NUM_THREADS` template argument in `Top`.

!!! tip "Real stage functionality"
    The stages here carry only `thread_id` and `pc`. To model real behavior, extend `PipelineReg` with additional fields (opcode, operands, result), have Fetch populate them (e.g. from an instruction memory submodule), and have Execute/Writeback act on them. The pipeline skeleton stays the same.
