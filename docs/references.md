# References

## Publications

The following papers describe Sitar's design, execution model, and parallel simulation approach. They are the primary references for understanding the framework's theoretical foundations.

---

**[1]** N. Karanjkar and M. P. Desai. "Sitar: A Cycle-based Discrete-Event Simulation Framework for Architecture Exploration." In *Proceedings of the 12th International Conference on Simulation and Modeling Methodologies, Technologies and Applications (SIMULTECH 2022)*, pages 142-150, SCITEPRESS, 2022.
DOI: [10.5220/0011320000003274](https://doi.org/10.5220/0011320000003274)

> Introduces the two-phase cycle-based execution model, the Sitar modeling language, and the simulation kernel. Demonstrates use for multi-core system design exploration with a SPARC V8 processor model. Received the Best Paper Award at SIMULTECH 2022.

---

**[2]** N. Karanjkar, M. P. Desai, A. Kushe, and A. Natekar. "Efficient Parallel Simulation of Networked Synchronous Discrete-Event Systems." In *Proceedings of the 2024 Winter Simulation Conference (WSC 2024)*, 2024.

> Analyzes the class of synchronous discrete-event systems (SDES) and characterizes when parallel simulation is correct and efficient. Presents scalability results showing near-linear speedup - up to 50x on a 40-core system - and compares Sitar's single-threaded performance with SystemC and SimPy.

---

## Talks and tutorials

Presentation slides from conference talks and tutorials are included in the `documentation/slides/` folder of the repository:

- `1_Overview.pdf` - High-level overview of Sitar's design goals and execution model
- `2_sitar_tutorial.pdf` - Step-by-step tutorial covering language features and example models
