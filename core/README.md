# Core

This folder contains the core classes in Sitar's C++ simulation kernel.

## Main classes

- **`object`** -- Base class to all other classes (such as `net`, `module`, ports). Has an instance id, a hierarchical id, and a pointer to the parent module.
- **`net`** -- A channel of communication between modules. A net provides fixed-size FIFO buffering for tokens (packets of information). Modules can push/pull tokens from a net.
- **`inport`, `outport`** -- Interface between a module and a net.
- **`module`** -- Behavioral entity in the system.
- **`time`** -- Time is cycle-based; each cycle consists of two phases, phase 0 and phase 1.
- **`token`** -- A packet of information transferred from one module to another. Tokens have information fields such as sender, receiver, and ID, in addition to a payload. Tokens have a parameter `width`, the size of the payload in bytes.

## Keywords

The following cannot be used as names for identifiers:

- `object`
- `module`
- `net`
- `inport`
- `outport`
- `time`
- `token`
- `simulation`
