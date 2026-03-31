# Do-while

The `do`-`while` statement is a compound statement that repeats a sequence of statements as long as a condition remains true. The loop body always executes at least once before the condition is checked.

---

## Syntax

```sitar
do
    // loop body: any sequence of statements
while (condition) end do;
```

The condition uses the same structured expression grammar as `if`-`else` — see [Condition expressions](if_else.md#condition-expressions) for the full syntax. In brief: comparison and arithmetic operators work as in C++; use `and`, `or`, `not` for logical operators; wrap complex C++ in `$...$` for anything outside the grammar. The condition is evaluated at the end of each iteration; if true the body executes again, if false execution continues after `end do`.

---

## Loop body and wait statements

The loop body may contain `wait` statements, nested loops, `if`-`else` blocks, and any other statements. In practice, most useful loops contain at least one `wait` to advance simulation time between iterations:

```sitar
do
    $process();$;
    wait(1, 0);
while (not done) end do;
```

---

## Infinite loop idiom

The most common pattern in Sitar module behaviors is an infinite loop that drives a module's operation for the duration of simulation. Use `while (1)` to create an infinite loop and `stop simulation` or `stop behavior` to exit:

```sitar
do
    wait until (this_phase == 0);
    $if (inp.pull(t)) { handle(t); }$;
    wait until (this_phase == 1);
    $outp.push(result);$;
while (1) end do;
```

`stop simulation` inside the loop body halts the entire simulation at the end of the current phase. `stop behavior` halts only this module.

---

## Iteration limit

Every `do`-`while` loop body must converge (reach a `wait` statement or terminate) within a bounded number of instantaneous iterations per phase. The Sitar kernel enforces a maximum iteration count to detect non-terminating zero-delay loops.

A loop body that executes only instantaneous statements and loops indefinitely will exceed this limit and cause a runtime error:

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_do_while.sitar:iteration_limit"
```

!!! warning "Iteration limit"
    The kernel counts how many times the loop body executes within a single call to `runBehavior`. If this count exceeds `SITAR_ITERATION_LIMIT`, the simulation stops with an error. A finite loop with only instantaneous statements is fine as long as it terminates. The limit is hit only when the loop cannot terminate or suspend within one phase. For example, an infinite `while (1)` loop with no `wait` inside will always exceed the limit.

The same applies to a `wait until` whose condition never becomes true within a phase. The module will keep polling without advancing time and will exceed the limit.

---

## Example

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_do_while.sitar:basic"
```

Expected output:

```
(0,0)TOP.m      :n=5
(1,0)TOP.m      :n=4
(2,0)TOP.m      :n=3
(3,0)TOP.m      :n=2
(4,0)TOP.m      :n=1
(5,0)TOP.m      :done.
Simulation stopped at time (5,0)
```

The loop body executes first (at cycle 0), decrements `n`, then waits. The condition is checked after each wait. After five iterations, `n` reaches 0 and the condition `n > 0` is false, so the loop exits.

---

## What's next

Proceed to [Parallel blocks](parallel.md) to learn how to run multiple sequences concurrently within a single module.
