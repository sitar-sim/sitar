# Sequences and statements

This page is the behavioral language reference. It covers all statement types, their syntax, and their semantics. For a conceptual introduction to behavior-as-sequence and execution state, see [Module Behavior](../2_basic_concepts/module_behavior.md). For the simulation execution loop, see [Execution Model](../2_basic_concepts/execution_model.md).

---

## Sequences

A module's `behavior` block is a **sequence** of statements separated by semicolons, executed one by one from top to bottom:

```sitar
behavior
    statement1;
    statement2;
    statement3;
    ...
end behavior
```

The same structure applies inside every compound statement: the body of a `do`-`while`, the branches of an `if`-`else`, every branch of a parallel block, and the body of a procedure are all sequences. Sequences may be nested to any depth.

A statement is either **atomic** or **compound**.

---

## Atomic statements

An atomic statement is a single, indivisible action. It either executes instantaneously (no time advances) or suspends the module until a future time. The table below lists all atomic statements; detailed pages follow for the most important ones.

| Statement | Executes | Description |
|---|---|---|
| `$...$` | instantly | Embedded C++ code block |
| `wait(c, p)` | suspends | Suspend for `c` cycles and `p` phases |
| `wait` | suspends | Shorthand for `wait(0,1)` — advance one phase |
| `wait until (expr)` | suspends | Suspend until `expr` is true at the start of a phase |
| `nothing` | instantly | No-op placeholder |
| `stop simulation` | instantly | Halt the entire simulation at end of current phase |
| `stop behavior` | instantly | Halt this module's behavior (and all submodules') at end of current phase |
| `decl $...$` | instantly | Declare a C++ class member (goes into class body) |
| `init $...$` | instantly | C++ constructor code (goes into module constructor) |
| `include $...$` | instantly | C++ inserted into file header |
| `run p` | suspends | Invoke procedure `p`; suspends until `p` terminates (compound — see below) |

---

### `$...$` — code block

A C++ code block executes instantaneously. It may span multiple lines:

```sitar
$
x = x + 1;
log << endl << "x is now " << x;
$;
```

The code is copied verbatim into the generated `run` function. It has access to all member variables, ports, nets, and the built-in variables `current_time`, `this_cycle`, `this_phase`, and `log`.

See [Code blocks](code_blocks.md) for the structural positions (`include`, `decl`, `init`) that inject C++ into the class body rather than the run function.

---

### `wait(c, p)` — timed suspend

Suspends the module for `c` cycles and `p` phases. Time advances by adding `time(c, p)` to the current time:

```sitar
wait(1, 0);    // suspend for one full cycle
wait(0, 1);    // suspend for one phase
wait(3, 1);    // suspend for 3 cycles and 1 phase
```

See [Wait](wait.md) for full details including arithmetic semantics and the idiomatic phase-discipline patterns.

---

### `wait` — advance one phase

The bare `wait` statement is shorthand for `wait(0, 1)`. It advances the module to the next phase:

```sitar
wait;    // equivalent to wait(0,1)
```

---

### `wait until (expr)` — conditional suspend

Suspends the module and re-evaluates `expr` at the start of each subsequent phase. When `expr` is true, execution continues. If `expr` is already true when the statement is reached, the module does not suspend:

```sitar
wait until (this_phase == 0);
wait until (this_cycle >= 10);
wait until (x > 0);
```

The expression `expr` is any C++ boolean expression. See [Wait](wait.md) for caveats on tight loops.

---

### `nothing` — no-op

Executes instantaneously and has no effect. Useful as a placeholder in a branch that must exist syntactically but requires no action:

```sitar
if (flag) then
    $do_something();$;
else
    nothing;
end if;
```

---

### `stop simulation`

Halts the entire simulation at the end of the current phase. All modules complete their current phase before the simulation terminates. Statements that follow `stop simulation` in the same sequence and before the next `wait` still execute (since no time advances within a phase).

```sitar
if (done) then
    stop simulation;
end if;
```

---

### `stop behavior`

Halts this module's behavior and the behaviors of all its submodules at the end of the current phase. Other modules in the simulation continue running. Statements after `stop behavior` in the same phase (before the next `wait`) still execute.

```sitar
wait(10, 0);
stop behavior;
```

---

## Compound statements

A compound statement contains one or more nested sequences inside it. It acts as a single statement within its enclosing sequence. The nested sequences follow the same rules as any other sequence.

| Statement | Nested sequences | Description |
|---|---|---|
| `if (cond) then ... end if` | 1 (true branch) | Conditional — executes branch if `cond` is true |
| `if (cond) then ... else ... end if` | 2 (true and false branches) | Conditional with both branches |
| `do ... while (cond) end do` | 1 (loop body) | Loop — body executes at least once; repeats while `cond` is true |
| `[ ... \|\| ... ]` | 2 or more branches | Parallel fork-join — all branches run concurrently |
| `run p` | 1 (procedure body) | Invoke procedure `p`; suspends until `p`'s sequence terminates |

Each of these is covered in detail on its own page: [If-else](if_else.md), [Do-while](do_while.md), [Parallel blocks](parallel.md), [Procedures](procedures.md).

---

## Example

The following module exercises all atomic statement forms in a single behavior:

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_sequence_statements.sitar:atomic"
```

Expected output:

```
(0,0)TOP.m      :start: x=42  time=(0,0)
(2,0)TOP.m      :after wait(2,0):          time=(2,0)
(2,1)TOP.m      :after wait:               time=(2,1)
(5,0)TOP.m      :after wait until cycle>=5: time=(5,0)
(5,0)TOP.m      :stopping at               time=(5,0)
Simulation stopped at time (5,0)
```

---

## What's next

Proceed to [Code blocks](code_blocks.md) for the full reference on C++ embedding positions, or skip ahead to [Wait](wait.md), [If-else](if_else.md), or any other statement page.
