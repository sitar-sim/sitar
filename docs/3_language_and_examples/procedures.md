# Procedures

A procedure is a named, reusable sequence of statements that can be invoked from within a module's behavior using `run`. Procedures are declared independently of modules, instantiated inside a module, and called as compound statements.

## Sequence states and procedures

Every sequence in Sitar, including a procedure's behavior, is in one of four states at any point during simulation. See [Execution State](../2_basic_concepts/module_behavior.md#execution-state) for the full description. Briefly:

| State | Meaning |
|---|---|
| **Not yet active** | Control has not entered the sequence yet |
| **Active, not converged** | Executing within the current phase |
| **Active, converged** | Suspended at a `wait`. Will resume when nudged next phase |
| **Terminated** | Reached the last statement. Can be re-activated |

When a procedure terminates, the `run` statement in the calling sequence completes and the caller moves on to the next statement. The caller is not suspended at that point. When a procedure is suspended at a `wait` inside its body, the calling sequence is also suspended and cannot advance until the procedure resumes and eventually terminates.

In a parallel block, the block itself is suspended until every branch has converged (each branch either reached a `wait` or terminated). A branch containing `run p` converges only when `p` converges or terminates for that phase.

---

## Procedure declaration

A procedure is declared at the top level of the file, alongside module declarations:

```sitar
procedure ProcName
    // optional parameter declarations
    // optional code blocks (decl, init, include)
    // optional sub-procedure instantiations
    behavior
        // any sequence of statements
    end behavior
end procedure
```

A procedure body follows the same rules as a module behavior: it is a sequence of atomic and compound statements, may contain `wait` statements, and may call other procedures with `run`. Unlike a module, a procedure cannot contain structural declarations such as ports, nets, or submodules.

---

## Instantiation inside a module

Before a procedure can be invoked, it must be instantiated inside the module that will call it:

```sitar
module M
    procedure p1 : ProcName
    procedure p2 : ProcName      // two independent instances of the same type
    procedure p3 : OtherProc<5>  // parameterized instance
    ...
end module
```

Each instance has its own independent execution state.

---

## Invocation with `run`

`run p` is a compound statement. The calling sequence suspends until `p`'s behavior terminates. If `p` suspends at a `wait` internally, the caller also suspends. When `p` terminates, the caller moves immediately to the next statement without suspending again.

```sitar
behavior
    run p1;    // suspend until p1 terminates, then continue
    run p2;    // suspend until p2 terminates, then continue
    $log << endl << "both done";$;
end behavior
```

**Re-using the same instance.** When a procedure terminates it enters the terminated state, but it is automatically re-activated the next time `run` is called on it. The same instance can therefore be invoked multiple times across the lifetime of the behavior:

```sitar
behavior
    do
        run do_input;          // first invocation: wait for input, pull token
        $process(do_input.tok);$;
        run do_input;          // second invocation in the same loop body: reactivated automatically
        $merge(do_input.tok);$;
        run send_output;
    while (1) end do;
end behavior
```

Each call to `run do_input` starts the procedure from the beginning of its behavior sequence.

**Running different instances in parallel.** Two procedure instances can be run concurrently inside a parallel block. The parallel block terminates only when both branches have terminated:

```sitar
[
    run p1;
||
    run p2;
];
```

`p1` and `p2` execute concurrently. If `p1` finishes before `p2`, the first branch is in the terminated state and the parallel block waits for `p2` to finish before continuing.

---

## Parameterized procedures

Procedures accept parameters using the same syntax as modules. Parameters are declared at the top of the procedure body and supplied in angle brackets at the instantiation site:

```sitar
procedure Delay
    parameter int N = 1
    behavior
        wait(N, 0);
    end behavior
end procedure
```

```sitar
module M
    procedure short_d : Delay<2>
    procedure long_d  : Delay<10>
    behavior
        run short_d;
        run long_d;
        stop simulation;
    end behavior
end module
```

---

## Nested procedures

A procedure may declare and invoke sub-procedures. The nesting depth is not limited. A sub-procedure is declared inside the calling procedure's body using the same `procedure name : Type` syntax:

```sitar
procedure Level1
    procedure sub : Level2
    behavior
        wait(1, 0);
        run sub;
    end behavior
end procedure

procedure Level2
    behavior
        wait(1, 0);
        $log << endl << "Level2 at " << current_time;$;
    end behavior
end procedure
```

!!! warning "No recursive calls"
    A procedure may not invoke itself, directly or indirectly. Recursive procedure calls are not supported.

---

## Example

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_procedures.sitar:basic"
```

The module `ProcDemo` runs `fetch` and `execute` alternately in an infinite loop. Each procedure waits one cycle and logs its name. The loop stops at cycle 4:

```
(1,0)TOP.m      :fetch  at (1,0)
(2,0)TOP.m      :execute at (2,0)
(3,0)TOP.m      :fetch  at (3,0)
(4,0)TOP.m      :execute at (4,0)
Simulation stopped at time (4,0)
```

For the parameterized and nested procedure examples, see `docs/sitar_examples/3_procedures.sitar` sections `:parameterized` and `:nested`.

---

## What's next

With the full language reference in place, proceed to the Examples section for complete worked models.
