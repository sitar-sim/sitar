---
name: sitar
description: Write, translate, compile and run Sitar models (.sitar) — a DSL + C++ kernel for cycle-based parallel simulation of synchronous discrete-event systems (SoC, NoC, queueing nets). Use whenever the user asks to create, edit, debug, or execute a `.sitar` file or a Sitar model.
---

# Sitar Modeling Skill

Sitar models a synchronous system as **modules** (active, hierarchical) connected by **nets** (passive 1-reader/1-writer FIFO channels carrying `token<W>` packets). Time is `(cycle, phase)`, with phase 0 = read, phase 1 = write. A `.sitar` file is translated to C++ classes, compiled with the kernel, and run as a standalone executable.

## Toolchain

Run all three steps from the directory holding `model.sitar` (works *outside* the Sitar repo too):

```bash
sitar translate model.sitar           # -> ./Output/*.h (and .cpp for non-templated)
sitar compile                         # -> ./sitar_sim
./sitar_sim 100                       # run for at most 100 cycles
```

Useful flags:

| Command | Flag | Effect |
|---|---|---|
| `sitar translate` | `-o DIR` | put generated C++ in `DIR` instead of `./Output` |
| `sitar compile` | `-o NAME` | name of executable (default `sitar_sim`) |
| `sitar compile` | `-d DIR` | extra source directory (repeatable) |
| `sitar compile` | `-m FILE` | custom main.cpp (otherwise `compiler/sitar_default_main.cpp`) |
| `sitar compile` | `--openmp` | parallel build (links `-fopenmp`, `-lgomp`) |
| `sitar compile` | `--no-logging` | omit `-DSITAR_ENABLE_LOGGING`; `log<<...` becomes a no-op |
| `sitar compile` | `--cflags "..."` | extra g++ flags |

`./sitar_sim N` caps simulation at `N` cycles (default 100). `stop simulation` inside the model is the other stop condition; whichever fires first wins.

Errors typically surface in this order: ANTLR parse error from `sitar translate`; SCons/g++ compile error referencing generated `.h`/`.cpp` (line numbers map to embedded `$...$` C++); runtime errors (assertion failures from kernel, or `SITAR_ITERATION_LIMIT` exceeded — see [Pitfalls](#common-pitfalls)).

For OpenMP runs: `export OMP_NUM_THREADS=N`. Each module gets its own log file `<hierarchicalId>_log.txt` automatically. Never share a single ostream across modules in parallel mode; use module-local RNG state (e.g. a per-module `seed` member set from main).

## File anatomy

A `.sitar` file is a sequence of top-level **module** and **procedure** declarations. Exactly one module must be named `Top` — the kernel instantiates it as `TOP` and runs it.

```
module ModuleName
    parameter int N = 1                  // optional; before everything else. types: int, char, bool
    parameter char tag = 'a'

    include $#include <cmath>$           // optional; goes to file header
    decl    $int x; std::vector<int> v;$  // optional; class members
    init    $x = 0;$                     // optional; constructor body

    inport  inp1, inp2 : width 4         // optional ports (zero-width if width omitted)
    outport outp       : width 4
    inport_array  ia[N] : width 1        // 1D or 2D arrays of ports
    outport_array oa[N][M] : width 1

    net  n1, n2 : capacity 8 width 4     // optional nets (zero-width if width omitted)
    net_array na[N][M] : capacity 4 width 8

    submodule a, b : Worker              // optional submodule instances
    submodule c    : Worker<5,'x',1>     // with template params
    submodule_array node[N][M] : Cell<N,M>

    procedure proc1 : Helper             // optional procedure instances (callable via `run`)
    procedure proc2 : Helper<2>

    a.outp => n1   b.inp <= n1           // connections: => from outport, <= to inport
    for i in 0 to (N-1)
        node[0][i].out_e => na[0][i]
        node[0][i+1].in_w <= na[0][i]
    end for

    behavior                             // optional
        statement;
        statement;
        ...
    end behavior
end module

procedure Helper
    parameter int K = 1
    decl $token<4>* port_ptr;$           // procedures cannot have ports/nets/submodules,
    init $port_ptr = nullptr;$           // but can hold pointers set by their parent module
    behavior
        wait(K, 0);
        $log << endl << "ran";$;
    end behavior
end procedure
```

The `behavior` body is a sequence of `;`-separated statements. `init`/`decl`/`include` may also appear *inside* `behavior` as atomic statements with a trailing `;` — but they still inject into class body / constructor / header, **not** the run function. They do not execute mid-simulation.

## Statements (in `behavior` body)

Atomic (no nesting):

| Statement | Semantics |
|---|---|
| `$ ... C++ ... $;` | Embedded C++ executed instantaneously inside the generated `runBehavior()` |
| `wait;` | Advance one phase (= `wait(0,1)`) |
| `wait(c, p);` | Advance `c` cycles + `p` extra phases |
| `wait until (expr);` | Suspend until `expr` is true at start of a phase. If already true, no suspend |
| `nothing;` | No-op |
| `stop behavior;` | Halt this module + all its descendants at end of current phase |
| `stop simulation;` | Halt entire simulation at end of current phase |
| `decl $...$;` `init $...$;` `include $...$;` | Inject into class/ctor/header (not the run fn) |

Compound (each branch is a full sequence):

```sitar
if (cond) then ... else ... end if;          // else optional
do ... while (cond) end do;                  // body executes >=1 time
[ branchA ; ... || branchB ; ... || ... ];   // parallel fork-join
run procName;                                // invoke procedure; suspends until it terminates
```

`expression_cf` (used by `if`, `while`, `wait until`) is Sitar's own grammar: `==`, `!=`, `<`, `<=`, `>`, `>=`; arithmetic `+ - * / %`; logical keywords `and`, `or`, `not` (NOT C `&&` `||` `!`). Atoms: integer literals, identifiers, `this_cycle`, `this_phase`, function calls, `(...)`, and `$ ... arbitrary C++ ... $` to escape into raw C++. To use `&&` etc., wrap them: `if ($flag1 && flag2$) then ... end if;`.

## Built-ins available inside any `$...$`

- `current_time` — `sitar::time`; streams as `(cycle,phase)`. `current_time.cycle()` and `current_time.phase()` are accessors.
- `time(c, p)` — construct a `sitar::time`. Comparable with `==`, `<`, `>=`, etc.
- `this_cycle` — `uint64_t`, current cycle (also valid in Sitar grammar expressions).
- `this_phase` — `bool`, 0 or 1 (also valid in Sitar grammar expressions).
- `log` — module's `sitar::logger` (acts as `std::ostream`). `log << endl << "msg";` emits a newline + the auto prefix `(cycle,phase)hierarchicalId :`. Without `endl` no prefix is added.
- `instanceId()` → `std::string` ("a"). `hierarchicalId()` → "TOP.sys.a". `parent()` → `module*`. `getInfo()` → recursive structural dump (call from `Top.behavior` to see whole system).
- `endl` is `std::endl`. `cout` is `std::cout`. The kernel pulls in `<iostream>`, `<string>`, `<sstream>`, `<fstream>`, `<vector>`, `<map>`, `<cassert>`, `<stdint.h>` — only `include $...$` headers it doesn't already provide.
- `stop_simulation()` C++ function — same effect as the `stop simulation;` statement.

## Tokens, ports, nets

A token is `sitar::token<W>` where `W` is payload size in bytes. Width 0 = signal-only (`token<>` is `token<0>`).

| API | Purpose |
|---|---|
| `t.ID` (`uint64_t`), `t.type` (`uint8_t`) | Free-form metadata; default 0 |
| `t.data()` → `uint8_t*` | Raw payload pointer (NULL when `W==0`) |
| `t.size()` | `W` |
| `t.info()` | `(type=..., ID=..., payload=0xXX XX ...)` formatted string for logging |
| `sitar::pack(t, a, b, ...)` | Memcpy args into payload sequentially; `sizeof(a)+sizeof(b)+...` must equal `W` (compile-time `static_assert`) |
| `sitar::unpack(t, a, b, ...)` | Inverse |
| `outp.push(t)` → `bool` | True on success, false if net full. **Use only in phase 1** |
| `inp.pull(t)` → `bool` | True on success, false if net empty. **Use only in phase 0** |
| `inp.peek(t)` → `bool` | Non-destructive read |
| `inp.empty()`, `inp.numTokens()`, `outp.full()` | Net state queries |

Width matching is strict: net width == port width == `token<W>` width. Mismatch → compile-time error. The kernel does NOT enforce phase discipline at runtime, but violating it (push in phase 0, pull in phase 1) breaks determinism in parallel mode.

Communication latency between modules is **always ≥ 1 cycle** (a token pushed in phase 1 of cycle N is visible in phase 0 of cycle N+1 at earliest). To get zero-latency interaction, put both components inside the same module as branches of a `[ ... || ... ]` parallel block sharing member variables.

## The two-phase rule (most important constraint)

Phase 0: **read only** (`pull`, `peek`). Phase 1: **write only** (`push`). The canonical idiomatic loop is:

```sitar
behavior
    do
        wait until (this_phase == 0);
        $ while (inp.pull(t)) { ...consume t... } $;

        wait until (this_phase == 1);
        $ ...prepare t...; while (outp.push(t)) { ...next t... } $;

        wait;                          // advance to next cycle
    while (1) end do;
end behavior
```

For producer/consumer with retry on full/empty buffer:

```sitar
$ done = false; $;
do
    wait until (this_phase == 1);
    $ done = outp.push(t); $;
    if (not done) then wait end if;
while (not done) end do;
```

## Multi-port pattern (indexed access via C++ pointer arrays)

Sitar has no first-class indexed port access in code blocks. Standard idiom:

```sitar
inport  in0, in1, in2, in3 : width 4
outport out0, out1, out2, out3 : width 4
decl $ inport<4>* ins[4]; outport<4>* outs[4]; $
init $ ins[0]=&in0; ins[1]=&in1; ins[2]=&in2; ins[3]=&in3;
       outs[0]=&out0; outs[1]=&out1; outs[2]=&out2; outs[3]=&out3; $
behavior
    $ for (int i = 0; i < 4; i++) ins[i]->pull(t); $;
    ...
end behavior
```

For declared `*_array` ports, `inport_array p[N]` exposes `p[i]` directly inside `$...$`.

## Procedures

A procedure is a named, reusable behavior. It has its own state (`decl`/`init`/parameters), can call sub-procedures, but **cannot** declare ports, nets, or submodules. Recursion is forbidden. Each instantiation gets independent state. `run p;` suspends caller until `p` terminates; on next call, `p` re-activates from the start.

To give a procedure access to ports, the parent declares the port and sets a pointer member of the procedure in its `init`:

```sitar
procedure GetToken
    parameter int W = 4
    decl $ inport<W>* src; token<W> tok; bool pulled; $
    init $ src = nullptr; $
    behavior
        $ pulled = false; $;
        do
            wait until (this_phase == 0);
            $ pulled = src->pull(tok); $;
            if (not pulled) then wait end if;
        while (not pulled) end do;
    end behavior
end procedure

module M
    inport in_a : width 4
    procedure get_a : GetToken<4>
    init $ get_a.src = &in_a; $
    behavior
        run get_a;
        $ /* now use get_a.tok */ $;
    end behavior
end module
```

Procedures shine inside parallel blocks for waiting on multiple ports concurrently:

```sitar
[ run get_a; || run get_b; ];   // completes when both have pulled
```

## Zero-latency synchronous pipelines (parallel-block-of-procedures pattern)

Nets always add ≥1 cycle of latency, so a classical N-stage pipeline built as N submodules wired with nets *stretches* the pipeline in time. To model a truly synchronous pipeline where a single instruction can traverse multiple stage boundaries within one cycle (e.g. a processor pipeline in steady state), keep all stages inside **one module** and run them as **branches of a single parallel block**:

```sitar
module Pipelined_Processor
    procedure fetch, decode, execute, writeback : Stage<1>
    decl $ PipelineReg stage_inputs[4]; /* shared regs */ $
    init $ /* wire each stage's input/output pointers to stage_inputs[i] */ $
    behavior
        do
            [ run fetch; || run decode; || run execute; || run writeback; || run log_branch; ];
            wait;
        while (1) end do;
    end behavior
end module
```

Key properties that make this work:

- **Shared C++ variables, not nets.** Adjacent stages share a `PipelineReg`-style struct owned by the parent; stage *i*'s `stage_output` pointer and stage *i+1*'s `stage_input` pointer address the same memory. A `valid` bit in each register is the handshake (upstream sets it `true` on commit; downstream clears it when it picks up the instruction).
- **Convergence-driven cascade.** Branches of a parallel block re-run round-robin within a phase until none progress. In steady state: Writeback retires (clears `stage_inputs[3].valid`) → Execute's commit unblocks in a later iteration → Decode's commit unblocks → Fetch commits. Net effect: one instruction crosses every stage boundary per cycle, with no extra latency.
- **Procedures reach shared state via pointer members.** One reusable `Stage` procedure with a `ThreadData*` (or similar) pointer member serves all stages; the parent sets each instance's `id`, upstream/downstream register pointers, and any per-stage config in its `init`. Because the parent's `init` runs *after* child constructors in C++ member-init order, those pointers are safely installed before any behavior executes.
- **Dedicated logging branch.** Add a branch that waits for phase 1 and logs per-cycle state — this runs after all phase-0 stage activity has converged, so it sees the stable end-of-cycle snapshot, not an intermediate convergence state.
- **Elastic delays.** Each stage is `Stage<DELAY>`. Increasing one stage's `DELAY` makes upstream stages stall cleanly via the `valid`-bit handshake; throughput drops but correctness is preserved.
- **External headers.** When sharing a struct definition across the parent module and stage procedure via an `include $#include "PipelineTypes.h"$`, add the current directory to the compile include path: `sitar compile -d Output/ -d ./`.

See `docs/sitar_examples/pipelined_processor/` (documented in `docs/4_examples/advanced_examples/pipelined_processor.md`) for the full worked example — a 4-stage, 2-thread barrel processor.

## Parameters and templates

Only `int`, `bool`, `char` parameters. They become C++ template params (compile-time, positional, defaults trailing-droppable). For non-int config (floats, strings, runtime-set values), use a `decl` member variable and have the parent set it in `init`.

```sitar
module Counter
    parameter int LIMIT = 10
    parameter char TAG = 'a'
    parameter bool VERBOSE = 0
    ...
end module

submodule c1 : Counter<>           // all defaults
submodule c2 : Counter<5>          // LIMIT=5
submodule c3 : Counter<5,'b',1>    // all three
```

Parameterized modules/procedures generate a `.h` only (header-only template class). Non-parameterized → `.h` + `.cpp`.

## Regular structures

```sitar
submodule_array node[N]    : Cell
submodule_array node[N][M] : Cell<N,M>
net_array       n[N+1]     : capacity 1
net_array       n[N][M-1]  : capacity 2 width 8

for i in 0 to (N-1)            // bounds inclusive on both ends
    stage[i].ip <= n[i]
    stage[i].op => n[i+1]
end for
```

For per-instance config in arrays, set fields from parent's `init` using a raw C++ loop:

```sitar
init $
for (int i = 0; i < N; i++)
    for (int j = 0; j < M; j++) {
        node[i][j].row = i;
        node[i][j].col = j;
    }
$
```

## Cross-hierarchy connections

Connections are written at the level of the module that owns the net. Port paths reach into nested submodules via `.`:

```sitar
module Top
    submodule x  : X
    submodule a1 : A
    net n : capacity 4
    x.outp        => n
    a1.b1.c1.inp  <= n          // dot path into nested submodule
end module
```

## Logging

`log << endl << ...;` auto-prefixes with `(cycle,phase)<padded hierarchicalId>:`. Each module has its own logger object accessible as `log`. Common patterns:

```sitar
$ log << endl << "x = " << x << "  t = " << current_time; $;

decl $ logger log2; std::ofstream logfile; $;
$ logfile.open("log_" + hierarchicalId() + ".txt"); log2.setOstream(&logfile); $;

$ log.turnOFF(); $;            // runtime gate
$ log.turnON();  $;
$ log.useDefaultPrefix = false; log.setPrefix("MY:"); $;   // custom prefix; reset useDefaultPrefix=true and `wait;` once to restore
```

Compile with `--no-logging` to make all `log<<` calls vanish (no-op classes); use this for performance runs. `getInfo()` returns the recursive system structure as a string — call from `Top.behavior` to dump the model.

## Execution model in one sentence

Each phase, the kernel calls `run()` on every module (default: flat list, OpenMP parallel-friendly; or `runHierarchical()` from TOP serially). A module advances through its behavior until it hits `wait`, then yields. A `do-while` body or parallel block iterates internally until convergence (bounded by `SITAR_ITERATION_LIMIT = 1000` instantaneous iterations per phase). Branches of `[A || B]` execute in written order, round-robin within a phase, until all converge.

Because reads and writes are segregated by phase, no two modules can race on a net within a phase — execution order between modules is irrelevant, which is what enables OpenMP parallelism without locks.

## Common pitfalls

- **Iteration limit exceeded** → an infinite loop with no `wait` inside (`do ... while(1) end do` with all-instantaneous body), or a `wait until` whose condition can never become true within a phase. Add a `wait;` inside the loop.
- **Operator `&&`/`||`/`!` in `if`/`while`** → use `and`/`or`/`not`, or wrap in `$...$`.
- **Width mismatch** → token, port, and net widths must all be the literal same number. `static_assert` in `pack`/`unpack` catches sum-of-arg-sizes mismatches.
- **Pull in phase 1, push in phase 0** → silent data corruption in parallel mode. Always gate with `wait until (this_phase == 0)` / `wait until (this_phase == 1)`.
- **Forgot `;` after `$...$`** → parse error. Every behavioral code block needs the trailing semicolon: `$...$;`.
- **Port/net width is parameterizable but `token<W>` needs a literal** → use the same parameter on both: `parameter int W = 4`, then `inport p : width W` and `decl $token<W> t;$`.
- **`init $...$;` inside `behavior`** does NOT execute mid-flow — the C++ goes into the constructor, not the run function. Use a plain `$...$;` block for mid-simulation initialization.
- **No `Top` module** → SCons aborts with "WARNING: No Top.h found". Every model needs `module Top ... end module`.
- **Procedure recursion** → not supported; avoid (direct or indirect).
- **Cross-thread shared `std::cout` or shared `rand()`** → in OpenMP mode, output interleaves and RNG races. Use per-module log files (the default main does this) and per-module seed members.

## Minimal templates

**Hello world:**

```sitar
module Top
    behavior
        $ log << endl << "Hello, World!"; $;
        wait(2, 0);
        $ log << endl << "After 2 cycles."; $;
        stop simulation;
    end behavior
end module
```

**Producer-consumer with int payload:**

```sitar
module Top
    submodule p : Producer
    submodule c : Consumer
    net ch : capacity 4 width 4
    p.outp => ch    c.inp <= ch
end module

module Producer
    outport outp : width 4
    decl $ token<4> t; int v; $
    init $ v = 0; $
    behavior
        do
            wait until (this_phase == 1);
            $ sitar::pack(t, v); if (outp.push(t)) { log<<endl<<"sent "<<v; v++; } $;
            wait;
        while (v < 10) end do;
        stop simulation;
    end behavior
end module

module Consumer
    inport inp : width 4
    decl $ token<4> t; int v; $
    behavior
        do
            wait until (this_phase == 0);
            $ while (inp.pull(t)) { sitar::unpack(t, v); log<<endl<<"got "<<v; } $;
            wait;
        while (1) end do;
    end behavior
end module
```

**N-stage shift register (parameterized regular structure):**

```sitar
module Top
    submodule s : Pipeline<4, 1>
end module

module Pipeline
    parameter int N     = 1
    parameter int DELAY = 1
    submodule        prod  : Producer
    submodule        cons  : Consumer
    submodule_array  stage[N] : Stage<DELAY>
    net_array        n[N+1] : capacity 1 width 4

    prod.outp => n[0]
    cons.inp  <= n[N]
    for i in 0 to (N-1)
        stage[i].ip <= n[i]
        stage[i].op => n[i+1]
    end for
end module

module Stage
    parameter int DELAY = 1
    inport ip : width 4
    outport op : width 4
    decl $ token<4> t; bool ok; $
    behavior
        do
            $ ok = false; $;
            do  wait until (this_phase == 0);
                $ ok = ip.pull(t); $;
                if (not ok) then wait end if;
            while (not ok) end do;
            wait(DELAY, 0);
            $ ok = false; $;
            do  wait until (this_phase == 1);
                $ ok = op.push(t); $;
                if (not ok) then wait end if;
            while (not ok) end do;
        while (1) end do;
    end behavior
end module
```

## Testing a model

Sitar has no test framework — testing is empirical via simulation output:

1. Always include a deterministic stop condition (`stop simulation` after fixed event count, or pass a cycle limit on the command line).
2. Use `log << endl << ...` liberally during development; remove or gate with `--no-logging` at compile time for perf runs.
3. For golden-file testing: `./sitar_sim 100 > actual.log; diff actual.log expected.log`. Logs include `(cycle,phase)hierarchicalId` prefixes which makes diffs deterministic *as long as the model uses correct phase discipline* (so OpenMP execution order doesn't matter).
4. Useful sanity check: `$ log << endl << parent()->getInfo(); $;` from the start of `Top.behavior` to dump the elaborated hierarchy.
5. To debug runtime crashes, compile with default settings (`SConstruct` already passes `-g`) and run under `gdb ./sitar_sim`. The kernel uses `assert()` heavily — assertions fire on null nets, time underflow, etc.
6. To debug "iteration limit exceeded": find a `do-while` with no `wait` reachable on every path, or a `wait until` that never becomes true within a phase.

## Reference paths in the repo

- Grammar: `translator/grammar/sitar.g`, EBNF `translator/grammar/sitar_ebnf_syntax.txt`.
- Kernel headers: `core/sitar_module.h`, `sitar_net.h`, `sitar_inport.h`, `sitar_outport.h`, `sitar_token.h`, `sitar_token_utils.h`, `sitar_time.h`, `sitar_logger.h`, `sitar_simulation.h`. ~1000 LOC total, header-only except for `sitar_module.cpp` and `sitar_logger.cpp`.
- Default main: `compiler/sitar_default_main.cpp` — copy and edit when customizing thread mapping or RNG seeding.
- Build: `compiler/SConstruct`. Adds `-g`, `-O2`, `-Wall`, `-Wpedantic`, plus optional `-fopenmp -lgomp` and `-DSITAR_ENABLE_LOGGING`.
- CLI script: `scripts/sitar` (Python). Writes a `sitar_scons_config.txt` in the working dir then invokes SCons.
- Worked examples (read these to learn idioms): `examples/0_HelloWorld.sitar` … `14_StopStatement.sitar`, `Cars.sitar`, `Behavior.sitar`; `docs/sitar_examples/4_router.sitar` (multi-port + arbitration), `4_shift_register.sitar` (regular structure), `4_state_machine.sitar` (Moore FSMs + handshake), `4_processor_memory.sitar` (request-response protocol), `4_mesh.sitar` (2D submodule_array + parent init for per-instance positions), `5_parallel_simple.sitar` (OpenMP), `pipelined_processor/PipelinedProcessor.sitar` (zero-latency synchronous pipeline as parallel block of procedures sharing C++ state).
- Docs: `docs/getting_started.md`, `docs/2_basic_concepts/`, `docs/3_language_and_examples/`, `docs/4_examples/`, `docs/5_parallel_execution/parallel_execution.md`, `docs/how_sitar_works/{translation,kernel}.md`.
