# Kernel and execution

This page describes the simulation kernel and how it implements the execution model. For how `.sitar` source is translated to C++, see [Translation](translation.md).

---

## The simulation kernel

The kernel is a small set of C++ header files in `core/` — approximately 1000 lines total, with no compiled library. Generated model code includes the headers directly, allowing the compiler to inline across kernel and model boundaries.

The central classes are:

| Class | Role |
|---|---|
| `sitar::module` | Base class for all modules. Provides `run()`, `log`, `current_time`, `this_cycle`, `this_phase`. |
| `sitar::net<W,C>` | Fixed-capacity FIFO for `token<W>`. `push()` returns false when full; `pull()` returns false when empty. |
| `sitar::inport<W>` / `sitar::outport<W>` | Typed port wrappers that delegate to the connected `net`. |
| `sitar::token<N>` | Fixed-size byte payload container with metadata (ID, type, sender, receiver). |
| `sitar::time` | (cycle, phase) stored as a 64-bit integer; supports arithmetic and comparison. |
| `sitar::logger` | Thin `ostream` wrapper that prepends a (time, module-id) prefix on `endl`. |

For a full description of the kernel classes, see [Development Notes - Code Organization](../development.md#code-organization).

---

## Execution semantics

The execution model — two phases per cycle, phase 0 for reads, phase 1 for writes, the convergence rule, and how `wait` and `wait until` interact with the phase counter — is covered in detail in [Execution Model](../2_basic_concepts/execution_model.md). The kernel implements exactly what that page describes: the simulation loop calls `run(t)` for each module at each phase, modules advance their behavior or return immediately, and the loop iterates until `stop_simulation()` is called.
