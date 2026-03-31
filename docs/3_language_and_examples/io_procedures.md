# Procedures for I/O

Waiting for a token on a port — checking with `peek`, retrying `pull` in phase 0, or retrying `push` in phase 1 — is a recurring pattern. When a module has many ports or must monitor several ports simultaneously, rewriting this loop for every port makes the behavior hard to read and easy to get wrong.

Encapsulating the I/O pattern in a **procedure** separates the "what to do with the token" from the "how to receive or send it". The procedure is defined once and instantiated for each port that needs it.

---

## The port-pointer pattern

A procedure cannot declare ports in the structural sense — ports belong to modules. Instead, the procedure holds a **C++ pointer** to the port it manages. The parent module assigns this pointer in its `init` block.

```sitar
procedure GetToken
    parameter int W = 4
    decl $
    inport<W>* src;   // pointer to the managed port, set by parent
    token<W>   tok;   // result token, readable by parent after run
    bool       pulled;
    $
    init $src = nullptr;$
    behavior
        ...
    end behavior
end procedure
```

In the parent:
```sitar
module Merger
    inport in_a : width 4
    procedure get_a : GetToken<4>
    init $
    get_a.src = &in_a;   // wire procedure to port
    $
    ...
end module
```

The procedure's `decl` variables are C++ member variables of the procedure object. Because `get_a` is a member of `Merger`, `get_a.tok`, `get_a.src`, and `get_a.pulled` are all accessible from `Merger`'s code blocks and `init`.

---

## `GetToken` — one-shot receive

`GetToken` waits until a token is available on `src`, pulls it into `tok`, and returns. Its behavior is finite: it ends naturally after one successful pull, which returns control to the `run get_a;` statement in the caller.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_io_procedures.sitar:get_token"
```

---

## `SendToken` — one-shot send with retry

`SendToken` pushes `tok` (set by the parent before calling `run send`) to `dst`, retrying each phase until `push` succeeds.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_io_procedures.sitar:send_token"
```

---

## Parallel I/O with procedures

A parallel block makes it natural to wait for tokens on multiple ports simultaneously. The block completes only when **all** branches have finished:

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_io_procedures.sitar:merger"
```

The key lines:

```sitar
[
    run get_a;
||
    run get_b;
];
```

This suspends `Merger` until `get_a` and `get_b` have both completed — that is, until a token has arrived on both `in_a` and `in_b`. The two procedures run concurrently: if `in_b` has a token but `in_a` does not, the branch running `get_b` finishes first and waits for the `get_a` branch before the parallel block exits.

After the parallel block, the parent reads the results directly from the procedure variables:

```sitar
$
sitar::unpack(get_a.tok, val_a);
sitar::unpack(get_b.tok, val_b);
$;
```

---

## Complete example

The full example connects two counter sources and a sink to the `Merger`:

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_io_procedures.sitar:harness"
```

---

## Expected output

```
(1,0) TOP.sys.merger : merged 0 + 0 = 0
(2,0) TOP.sys.merger : merged 1 + 2 = 3
(3,0) TOP.sys.merger : merged 2 + 4 = 6
(4,0) TOP.sys.merger : merged 3 + 6 = 9
...
Simulation stopped at time (11,0)
```

---

## Design notes

!!! tip "Procedures vs submodules for I/O"
    Use a procedure for I/O when the I/O logic is tightly coupled to the parent's behavior — particularly when the parent needs to read the result immediately after the operation, or when it needs to wait for multiple ports in parallel.

    Use a **submodule** when the I/O work should run continuously and independently of the parent's main loop. A submodule has its own behavior that runs concurrently with all other modules; it is not blocked by the parent's state.

!!! note "Procedure variables and re-entrancy"
    Each procedure instance (`get_a`, `get_b`, `send`) has its own copy of the `decl` variables. Two instances of `GetToken` manage separate ports and separate `tok` fields without interference. However, Sitar does not allow recursive procedure calls.
