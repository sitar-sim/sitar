# Parallel blocks

A parallel block is a compound statement that runs two or more sequences concurrently within a single module. All branches start simultaneously. The block completes only when every branch has either terminated or converged (reached a `wait`).

---

## Syntax

```sitar
[
    // branch A
    statement1;
    statement2;
    ...
||
    // branch B
    statement1;
    statement2;
    ...
||
    // optional branch C, D, ...
];
```

The `[` opens the block; `||` separates branches; `]` closes it. The trailing `;` is the Sitar statement terminator.

Each branch is a full sequence. Branches may contain any combination of atomic and compound statements, including nested loops, `if`-`else`, and further parallel blocks.

---

## Execution semantics

Within a phase, the kernel executes the branches of a parallel block in the order they are written, round-robin, until all branches have converged (reached a `wait`) or terminated. This is sequential interleaving, not simultaneous multi-threading.

When one branch hits a `wait` or terminates, the kernel moves to the next branch and continues from where it left off. When all branches have converged or terminated in the current phase, the module is considered converged and the kernel moves on. In the next phase, each branch resumes from its current execution pointer.

The parallel block as a whole terminates (and execution continues with the next statement after `]`) only after the last active branch terminates. Branches that terminate early remain idle while other branches continue.

For a deeper discussion of convergence and execution state, see [Module Behavior](../2_basic_concepts/module_behavior.md).

---

## Key use case: zero-latency interaction

The primary purpose of parallel blocks is to model components that must interact within a single cycle with zero latency. Two sub-components in separate modules communicate over a net and incur a minimum one-cycle latency. To eliminate that latency, place both components inside a single module as parallel branches. They execute in the same phase, sharing access to member variables:

```sitar
[
    // component A: writes to shared variable x, then reads y
    $x = compute_a();$;
    wait until (y != 0);
    $use(y);$;
||
    // component B: waits for x, then writes y
    wait until (x != 0);
    $y = compute_b(x);$;
];
```

Because both branches execute within the same phase and the kernel re-runs branches until convergence, `A` and `B` can exchange values in a single cycle.

!!! note "Execution order"
    Branches are not truly simultaneous. They execute in written order within each phase iteration. If branch A sets `x` and branch B reads it, and A is written before B, B will see A's updated value in the same phase iteration. Rely only on `wait until` for explicit synchronization; do not depend on branch ordering for correctness.

---

## Parallel branches with different durations

Branches may have different lifetimes. The parallel block waits for the slowest branch:

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_parallel.sitar:model"
```

Expected output:

```
(0,0)TOP.m      :start: (0,0)
(0,0)TOP.m      :branch C done: (0,0)
(1,0)TOP.m      :branch B done: (1,0)
(3,0)TOP.m      :branch A done: (3,0)
(3,0)TOP.m      :parallel block complete: (3,0)
Simulation stopped at time (3,0)
```

Branch C completes immediately (no wait). Branch B completes at cycle 1. Branch A is the last to complete, at cycle 3. The statement after `]` executes only at cycle 3, when all branches have terminated.

---

## What's next

Proceed to [Procedures](procedures.md) to learn how to define and invoke named, reusable behavior sequences.
