# Parameters and templates

Sitar modules and procedures can be parameterized with compile-time constant values. Parameterized modules are sometimes called *templates* — the concept and syntax are the same. Parameters translate directly to C++ template parameters, so they must be known at compile time and are resolved before the simulation runs.

Parameters are the right tool for structural configurability: things like the number of stages in a pipeline, cache block size, address bus width, or net capacity. A single parameterized module definition covers an entire family of configurations, each compiled to its own C++ class.

For differences that only need to be set once at simulation start, module-level variables are often more appropriate. Variables can be declared in `decl` and initialized by a parent module's `init` block, allowing instances of the same type to be distinguished at run time without requiring separate template instantiations. See [Modules and hierarchy](modules_and_hierarchy.md) for the parent `init` pattern.

---

## Declaring parameters

Parameters are declared at the top of a module or procedure body, before any other declarations:

```sitar
module Foo
    parameter int  N     = 1      // integer parameter with default value 1
    parameter char label = 'a'    // character parameter
    parameter bool flag  = 0      // boolean (0 = false, 1 = true)
    ...
end module
```

- Supported types: `int`, `char`, `bool`.
- The default value is required and must be a compile-time literal.
- Parameters are read-only within the module body.

!!! tip "Float and other types are not supported as parameters"
    Only `int`, `char`, and `bool` are valid parameter types. For quantities that require other types — such as a `float` miss probability or a `double` threshold — declare a module-level variable of the required type in `decl` and have the parent set it in its `init` block. Module-level variables can be any valid C++ type; only parameters are restricted.

---

## Instantiation with angle brackets

Parameter values are supplied in angle brackets when instantiating the module:

```sitar
submodule a : Foo<10, 'x', 1>   // N=10, label='x', flag=1
submodule b : Foo<>              // all defaults: N=1, label='a', flag=0
submodule c : Foo<5>            // N=5; label and flag use defaults
```

Parameters are matched positionally from left to right. Trailing parameters that take their default values may be omitted.

---

## Using parameters in structure and behavior

Parameters may be used anywhere in the module body: in structure (e.g., as net capacity or array size) and in behavior (in any embedded C++ expression or wait condition):

```sitar
module Buffer
    parameter int DEPTH = 4
    parameter int WIDTH = 1

    inport  inp  : width WIDTH
    outport outp : width WIDTH

    net fifo : capacity DEPTH width WIDTH
    ...
end module
```

```sitar
module Counter
    parameter int LIMIT = 10
    decl $int count;$
    init $count = 0;$
    behavior
        do
            $count = count + 1;$;
            wait(1, 0);
        while (count < LIMIT) end do;
        $log << endl << "count reached " << LIMIT;$;
        stop simulation;
    end behavior
end module
```

---

## Parameterized procedures

A procedure is a named, reusable behavior block (a sequence of statements) that a module can invoke with `run`. It can be used to encapsulate a set of actions that need to be performed multiple times, defining them just once. It can contain code blocks (`decl`, `init`, `include`). However, unlike a module, a procedure cannot contain any structural parts such as submodules, ports, or nets. See [Procedures](procedures.md) for the complete syntax.

Procedures accept parameters using the same syntax as modules:

```sitar
procedure Delay
    parameter int N = 1
    behavior
        wait(N, 0);
    end behavior
end procedure
```

Instantiated inside a module:

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

See [Procedures](procedures.md) for the full procedure syntax.

---

## Example

The following example instantiates the same module type three times with different parameter values. Each instance waits a different number of cycles before logging:

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_parameters_templates.sitar:model"
```

Expected output:

```
(1,0)TOP.c      :counter c done  waited 1 cycles
(3,0)TOP.b      :counter b done  waited 3 cycles
(5,0)TOP.a      :counter a done  waited 5 cycles
Simulation stopped at time (6,0)
```

Each instance runs independently on the same clock. The instance with `N=1` finishes first; the instance with `N=5` finishes last. `Top`'s behavior stops the simulation after 6 cycles, after all counter instances have completed.

---

## What's next

Proceed to [Regular structures](regular_structures.md) to learn how to declare arrays of submodules and nets and connect them with `for` loops.
