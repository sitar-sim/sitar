# Development notes

This page is intended for users who want to modify Sitar - extend the language, understand the translation pipeline, tune the kernel, or build on the framework for research.

---

## Background and design rationale

Sitar targets a specific subset of discrete-event systems called **synchronous discrete-event systems (SDES)**: systems where all communication has at least one clock cycle of latency and all modules update in a globally synchronized, two-phase cycle. This restriction - which rules out zero-latency communication between modules - is what makes deterministic parallel simulation straightforward without requiring static dependency analysis or time-window speculation.

The core insight from the design, described in [[1]](references.md), is that the two-phase execution model maps cleanly to a fork-join parallel schedule: in phase 0, all modules read their input nets independently (no write-write conflicts); in phase 1, all modules write their output nets independently (writes are to disjoint net buffers). Each phase is therefore embarrassingly parallel. OpenMP is used to exploit this at the thread level.

The 2024 Winter Simulation Conference paper [[2]](references.md) formalizes this as a correctness condition and evaluates scalability. Reported results show near-linear speedup up to 50x on a 40-core system, with single-threaded throughput comparable to SystemC for the same models.

The language and kernel are intentionally minimal: the kernel is approximately 1000 lines of C++ header code; the translator grammar is a single ANTLR V3 file. The goal is a framework that a graduate student can read, modify, and extend in a few days.

---

## Code organization

The repository is organized into four main directories. Each has a focused, bounded scope.

```
sitar/
- core/          Simulation kernel (C++ headers only, no compiled library)
- translator/    Language translator: ANTLR grammar and generated C++ parser
- compiler/      SCons build script and default main file
- examples/      Runnable example models
```

### `core/` - simulation kernel

The kernel is a set of C++ header files. There is no compiled library: user models `#include` these headers directly and compile everything together. This keeps the build simple and allows the compiler to inline and optimize across the kernel and the generated model code.

| File | Contents |
|---|---|
| `sitar_object.h` | Base class for all named objects. Provides `instanceId()`, `hierarchicalId()`, `parent()`, and `getInfo()`. |
| `sitar_module.h` | The `module` base class. Every translated module inherits from this. Provides `log`, `current_time`, `this_cycle`, `this_phase`, and the `run()` virtual method. |
| `sitar_net.h` | The `net<W,C>` class: a fixed-capacity FIFO for tokens of width W bytes. `push()` returns false when full; `pull()` returns false when empty. |
| `sitar_inport.h` | The `inport<W>` class: a read-side port connected to a net. Provides `pull()`, `peek()`, and `push()`. |
| `sitar_outport.h` | The `outport<W>` class: a write-side port. Provides `push()`. |
| `sitar_token.h` | The `token<N>` class: a fixed-size byte payload container with metadata fields (ID, type, sender, receiver). `token<>` is a zero-width token used for signaling. |
| `sitar_token_utils.h` | `sitar::pack(tok, args...)` and `sitar::unpack(tok, args...)`. Pack/unpack serialize and deserialize a variadic argument list into a token's byte payload using `memcpy`. The total `sizeof` of all arguments must equal the token width; this is checked by a `static_assert` at compile time. |
| `sitar_time.h` | The `time` class: (cycle, phase) stored as a 64-bit integer with cycle in bits 63..1 and phase in bit 0. Supports arithmetic and formatted output. |
| `sitar_logger.h` | The `logger` class: a thin wrapper around an `ostream` that inserts a (time, hierarchical-id) prefix on `endl`. Each module has a `log` member. `logger::default_logstream` is the shared global stream (stdout by default). |
| `sitar_simulation.h` | Global simulation control: `stop_simulation()` and `stop_behavior()` flags, guarded by OpenMP critical sections for thread-safe access from parallel module behavior. |
| `sitar_ancilliary.h` | Miscellaneous string conversion utilities. |

To add a new kernel primitive - for example, a new port type or a token inspection function - add a header here and include it in `sitar_module.h` so translated modules see it automatically.

### `translator/` - language translator

The translator converts `.sitar` source files to C++ code. It is built on ANTLR V3 with a C runtime.

```
translator/
- grammar/
    - sitar.g                  ANTLR V3 grammar: parses .sitar source, walks the AST,
    |                          and emits C++ output directly in grammar actions.
    - output_template.g        Helper grammar for C++ code generation templating.
    - sitar_ebnf_syntax.txt    Human-readable EBNF transcription of the grammar.
    - sitar_syntax_diagram.xhtml  Railroad diagram (see Language syntax below).
    - attributes.txt           Attribute definitions used in grammar actions.
- parser/                      Generated C parser, lexer, and C++ wrapper.
    - sitar_translator.cpp     Entry point: wraps the ANTLR-generated C parser in a
                               C++ driver that can be called from the build system.
- antlr3Cruntime/              ANTLR V3 C runtime (version 3.4), bundled with the repo.
- antlrworks-1.4.3.jar         ANTLRWorks GUI editor (for grammar editing and debugging).
```

The translation strategy is a single-pass tree walk: `sitar.g` both parses the source and directly emits C++ output in grammar actions. There is no separate IR or AST transformation pass. The key translation is the **behavior block**: a Sitar behavior (a sequence of statements) becomes a C++ coroutine-style function using an explicit program-counter variable and a `switch` statement. Each `wait` statement in the Sitar source becomes a case label; execution returns to the caller at each wait and resumes at the correct label on the next call. This is how cycle-accurate suspension and resumption is implemented without OS threads.

To modify the language - add a new statement type, change a keyword, or extend expression syntax - edit `sitar.g`. Regenerate the parser using ANTLR V3 (`java -jar antlr-3.x.jar sitar.g`) and rebuild.

### `compiler/` - build system and default main

```
compiler/
- SConstruct               SCons build script. Reads sitar_scons_config.txt, runs
|                          the translator, compiles generated C++, and links the
|                          executable. Supports GCC optimization levels 0-3, OpenMP,
|                          and optional debug/logging flags.
- sitar_default_main.cpp   Default top-level driver. Instantiates the Top module,
                           flattens the module hierarchy, runs the simulation loop
                           (interleaving phase 0 and phase 1 for all modules), and
                           manages the logging streams. OpenMP parallel sections are
                           inserted here around the phase loops.
```

The `SConstruct` script reads a configuration file `sitar_scons_config.txt` placed alongside the user's model. Relevant settings:

| Setting | Effect |
|---|---|
| `SITAR_INSTALLATION_DIR` | Path to the Sitar repository root |
| `TARGET_NAME` | Name of the compiled executable |
| `MAIN_FILE_NAME` | Main C++ file to compile (defaults to `sitar_default_main.cpp`) |
| `ENABLE_OPENMP` | Enable multi-threaded parallel execution |
| `ENABLE_LOGGING` | Compile-time enable/disable of all logging |
| `OPTIMIZATION_LEVEL` | GCC `-O` level (0-3) |

To use a custom main file - for example, to control simulation parameters programmatically or integrate with an external co-simulation framework - set `MAIN_FILE_NAME` to your own file and follow the pattern in `sitar_default_main.cpp`.

---

## Language syntax

The complete Sitar grammar is visualized as an interactive railroad diagram. Open the diagram in any modern browser:

[Sitar language syntax diagram (EBNF railroad diagram)](sitar_syntax_diagram.xhtml)

The diagram was generated from `translator/grammar/sitar_ebnf_syntax.txt` (an EBNF transcription of the ANTLR grammar) using the railroad diagram tool at [https://bottlecaps.de/rr/ui](https://bottlecaps.de/rr/ui). Each production rule is clickable; clicking a rule name navigates to its definition.

The plain-text EBNF source (`translator/grammar/sitar_ebnf_syntax.txt`) is useful for quick reference or for pasting into other grammar tools. It uses standard EBNF notation: `?` for optional, `*` for zero-or-more, `+` for one-or-more, `|` for alternatives, and `'keyword'` for terminals.

!!! tip "Finding a production rule quickly"
    Use your browser's in-page search (`Ctrl+F`) in the railroad diagram to jump to a specific production rule by name, for example `wait_statement` or `behavior_block`.
