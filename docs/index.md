# Sitar Simulation Framework

Sitar is a framework for modeling and parallel simulation of **synchronous discrete-event systems**. It combines a **domain-specific modeling language** with a **lightweight C++ simulation kernel**, enabling scalable simulation of tightly synchronized systems.

Sitar is designed for:

- cycle-based and phase-based models
- explicit representation of concurrency and synchronization
- efficient parallel execution on shared-memory systems
- co-simulation with external models

---

## Quick Links

- **Source code**: [https://github.com/sitar-sim/sitar](https://github.com/sitar-sim/sitar)
- [**Getting started**](getting-started.md)
- [**Modeling language**](language/overview.md)
- [**Examples**](examples/overview.md)
- [**Publications**](publications.md)
- [**Authors**](authors.md)

---

## About Sitar

Sitar models systems as collections of **modules** that communicate through **nets**, and evolve in discrete logical time. Every time-step is divided into two-phases, enabling deterministic and race-free parallel execution irrespective of the interconnection and dependency structure between the modules.

The Sitar toolchain consists of:

- a modeling language and translator
- a lightweight C++ simulation kernel that supports parallel execution via OpenMP
- a build pipeline that generates optimized simulation executables

This design allows users to focus on **system structure and behavior**, while the framework handles execution scheduling and parallelization.

![Sitar simulation framework](assets/images/sitar.png "Sitar"){ width=60% }
---

## Publications and Learning Material

To learn more about the design and applications of Sitar, see the following resources:

1. **SIMULTECH 2022 (Best Paper Award)**  
   Foundational paper introducing Sitar and its parallel simulation approach.  
   [`download pdf`](/publications/paper1_SIMULTECH2022.pdf)

2. **Winter Simulation Conference 2024**  
   Detailed description of the execution model and performance evaluation.  
   [`download pdf`](/publications/paper2_WinterSim2024.pdf)


3. **Tutorial Slides**  
   Overview of key ideas, modeling constructs, and execution semantics.  
   [`download pdf`](/publications/2_sitar_tutorial.pdf)

---


## License

Sitar is released under the MIT License.  
See the `LICENSE` file in the repository for details.

