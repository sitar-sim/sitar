# Code blocks

Sitar embeds C++ code using dollar-sign delimiters: `$...$`. This is the primary escape hatch from the Sitar language into C++. There are four distinct embedding positions, each inserting the code into a different part of the generated C++ class.

---

## The four positions

| Keyword | Position | Where the C++ goes |
|---|---|---|
| `$...$` (behavioral) | Inside `behavior` block | Into the module's `run` function — executes as a behavioral statement |
| `include $...$` | Module scope | Into the file header, before the class definition |
| `decl $...$` | Module scope or inside `behavior` | Into the module class body (member declarations) |
| `init $...$` | Module scope or inside `behavior` | Into the module class constructor |

The behavioral `$...$` is the most common form. The structural forms (`include`, `decl`, `init`) are used to extend the generated class with custom state and initialization.

---

## Behavioral code block: `$...$`

A behavioral code block is an atomic statement that executes instantaneously. It runs inside the module's `run` function and has direct access to all member variables, ports, and the built-in simulation variables:

```sitar
behavior
    $
    x = x + 1;
    log << endl << "x is now " << x;
    $;
end behavior
```

Multiple lines of C++ are allowed between the dollar signs. The block is terminated by a semicolon after the closing `$`, which is the Sitar statement terminator.

Built-in variables accessible inside any code block:

| Name | Type | Description |
|---|---|---|
| `current_time` | `sitar::time` | Current simulation time; streams as `(cycle,phase)` |
| `this_cycle` | `uint64_t` | Current cycle number |
| `this_phase` | `bool` | Current phase (0 or 1) |
| `log` | `sitar::logger` | The module's default logger |

---

## `include $...$` — header injection

Inserts C++ into the file header section, before the generated class definition. Use this to include standard or project headers that the module's embedded code depends on:

```sitar
module MyModule
    include $#include <cmath>$
    include $#include "my_types.h"$
    ...
end module
```

`include` is written at module scope (before the `behavior` block), without a trailing semicolon.

!!! note
    Headers already included by the Sitar runtime (`<string>`, `<iostream>`, `<vector>`, and others pulled in by `sitar_module.h`) do not need to be re-included. Use `include` only for headers not already present.

---

## `decl $...$` — member declaration

Inserts C++ into the module class body. Use this to declare member variables, type aliases, or inline helper methods:

```sitar
module MyModule
    decl $int _count;$
    decl $std::string _name;$
    decl $inline void reset() { _count = 0; }$
    ...
end module
```

At module scope, `decl` is written without a trailing semicolon. Inside the `behavior` block, it is written as an atomic statement with a trailing semicolon:

```sitar
behavior
    decl $double _result;$;    // also goes into the class body, not the run function
    ...
end behavior
```

---

## `init $...$` — constructor initialization

Inserts C++ into the module class constructor. Use this to initialize member variables to their starting values before simulation begins:

```sitar
module MyModule
    decl $int _count; bool _active;$
    init
    $
        _count  = 0;
        _active = true;
    $
    ...
end module
```

Like `decl`, `init` can also appear inside the `behavior` block as an atomic statement (with a trailing semicolon). The generated C++ still goes into the constructor:

```sitar
behavior
    init $_count = 0;$;    // constructor code, not a behavioral statement
    $log << endl << _count;$;
    ...
end behavior
```

!!! warning "init is not a behavioral statement"
    Despite appearing inside `behavior`, `init $...$;` does not execute at the point where it appears in the behavior sequence. It is placed in the constructor and runs before simulation starts. Do not rely on `init` for mid-simulation resets; use a plain code block `$...$` instead.

---

## Example

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_code_blocks.sitar:model"
```

Expected output:

```
(0,0)TOP.m      :_pi=3.14159  sin(0)=0
(0,0)TOP.m      :pi=3.14159  count=100
Simulation stopped at time (0,0)
```

---

## What's next

Proceed to [Wait](wait.md) for the full reference on all three forms of the wait statement.
