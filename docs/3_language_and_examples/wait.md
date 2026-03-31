# Wait

The `wait` statement is the mechanism by which a module suspends its execution and lets simulation time advance. There are three forms. All are atomic statements.

---

## `wait(c, p)` — timed suspend

Suspends the module for `c` cycles and `p` phases:

```sitar
wait(1, 0);    // suspend for one full cycle
wait(0, 1);    // suspend for one phase
wait(3, 1);    // suspend for 3 cycles and 1 phase
```

**Time arithmetic.** Sitar time is stored as a single integer where each cycle contributes 2 units and each phase contributes 1 unit. `wait(c, p)` adds `time(c, p)` to `current_time`:

```
wait(c, p) at time (r, s) resumes at (r + c, s + p)
```

Phase addition may carry into the cycle counter: `wait(3, 1)` from `(2, 1)` resumes at `(6, 0)` because `(2*2+1) + (3*2+1) = 5 + 7 = 12`, and `12 >> 1 = 6`, `12 & 1 = 0`.

Both `c` and `p` must be non-negative. `p` is typically 0 or 1. Using `p > 1` is valid but unusual.

---

## `wait` — advance one phase

The bare `wait` statement is shorthand for `wait(0, 1)`. It advances the module exactly one phase:

```sitar
wait;    // same as wait(0, 1)
```

This is the most common form used in module behaviors to enforce the phase discipline (push in phase 1, pull in phase 0). A module that ends phase 0 work calls `wait;` to advance to phase 1:

```sitar
// phase 0: pull from net
wait until (this_phase == 0);
$if (inp.pull(t)) { ... }$;

// advance to phase 1
wait;

// phase 1: push to net
$outp.push(t);$;
wait;
```

---

## `wait until (expr)` — conditional suspend

Suspends the module and tests `expr` at the start of each phase the module is nudged. When `expr` evaluates to true, execution continues. If `expr` is already true when the statement is reached, the module does not suspend at all:

```sitar
wait until (this_phase == 0);     // ensure we are in phase 0
wait until (this_phase == 1);     // ensure we are in phase 1
wait until (this_cycle >= 10);    // wait for a specific cycle
wait until (x > 0);               // wait for a shared variable condition
```

The expression `expr` uses the same structured condition grammar as `if`-`else` and `do`-`while` — see [Condition expressions](if_else.md#condition-expressions) for the full syntax. In brief: comparison and arithmetic operators work as in C++; use `and`, `or`, `not` for logical operators; wrap complex C++ in `$...$` for anything outside the grammar.

### Phase-discipline idiom

`wait until (this_phase == N)` is the standard way to enforce push/pull discipline when a module needs to do work in a specific phase regardless of when it last woke up:

```sitar
do
    wait until (this_phase == 0);
    $if (inp.pull(t)) { ... }$;    // pull only in phase 0
    wait until (this_phase == 1);
    $outp.push(t);$;               // push only in phase 1
while (1) end do;
```

!!! warning "Tight loops with `wait until`"
    A `wait until` inside a `do`-`while` body that has no other `wait` statement can cause the module to never converge if the condition is never true. The kernel will raise an iteration-limit error. Always ensure at least one path through a loop body hits a `wait` that advances time (or terminates the loop).

---

## Example

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_wait.sitar:model"
```

Expected output:

```
(0,0)TOP.m      :start:                   time=(0,0)
(2,0)TOP.m      :after wait(2,0):         time=(2,0)
(2,1)TOP.m      :after wait:              time=(2,1)
(6,0)TOP.m      :after wait(3,1):         time=(6,0)
(6,0)TOP.m      :after wait until ph==0:  time=(6,0)
(10,0)TOP.m     :after wait until cy>=10: time=(10,0)
Simulation stopped at time (10,0)
```

The `wait until (this_phase == 0)` at time `(6,0)` does not suspend because phase 0 is already active. Execution continues immediately at `(6,0)`.

---

## What's next

Proceed to [Logging](logging.md) to learn how to observe module state and simulation progress.
