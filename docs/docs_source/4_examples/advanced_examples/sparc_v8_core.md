# SPARC V8 Core

Every example on this page so far has been a small, self-contained model meant to teach one Sitar concept at a time. This page is different. It points to a **full-scale, real-world component** built entirely with Sitar: an instruction-accurate model of a real processor, provided as a separate repository and ready to be dropped into a larger system-on-chip model.

- **Repository:** [github.com/sitar-sim/SparcV8_core](https://github.com/sitar-sim/SparcV8_core)
- **Documentation:** [sitar-sim.github.io/SparcV8_core](https://sitar-sim.github.io/SparcV8_core/)

!!! note "A separate repository, not part of Sitar itself"
    `SparcV8_core` is a *model built using Sitar*, distributed independently of the Sitar framework. It has its own repository, its own documentation site, and its own release cycle. This page only summarizes what it offers and how it relates to the concepts covered elsewhere in these docs. For anything beyond that, follow the links above.

---

## What is SPARC V8?

SPARC (**S**calable **P**rocessor **AR**Chitecture) is a RISC instruction-set architecture originally developed at Sun Microsystems, derived from the Berkeley RISC I/II research designs. SPARC V8 is its 32-bit revision, standardized as ANSI/IEEE Std 1754-1994 and specified in *The SPARC Architecture Manual, Version 8*. Its most distinctive architectural feature is a **register window** file: a procedure call gets a fresh set of registers without spilling to memory, simply by advancing a circular window into a larger physical register file. See the [Wikipedia SPARC article](https://en.wikipedia.org/wiki/SPARC) for general background.

You don't need to know SPARC to use this component. It is best thought of as a stand-in for "a real, non-trivial CPU core": something with an actual instruction set, real traps and exceptions, and real memory-access timing. You can wire it into a Sitar model exactly as you would any other module or procedure.

---

## What the repository offers

The repository models a SPARC V8 **core**: an integer unit, a floating-point unit (including quad-precision), register windows, traps, and the full memory-access instruction set. It deliberately stops at the core boundary. There is no MMU, cache, or peripheral/device model here, and no full SoC. Building those around this core is exactly the kind of use case the repository is meant to enable.

The core is modeled at two levels, both driving the same underlying C++ implementation of SPARC V8 semantics:

1. **A plain C++ functional model**: a fetch-decode-execute loop with zero modeled latency and no Sitar dependency at all. Fast and simple, and useful for pure ISA-correctness testing.
2. **A Sitar-timed model**: the same core, driven instead through Sitar, with a simple, non-pipelined cycle-level timing model. It applies a fixed, configurable per-opcode delay, plus separate, independently configurable latencies for the memory interconnect and the memory itself.

See the [SparcV8_core documentation](https://sitar-sim.github.io/SparcV8_core/) for installation, usage, and everything else the repository offers.
