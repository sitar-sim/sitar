# Translation

Sitar has three components: a **translator** that converts `.sitar` source to C++, a **kernel** that provides the simulation runtime, and a **build system** that ties them together. This page explains how the translator works. For the kernel classes and execution semantics, see [Kernel and execution](kernel.md).

---

## The translation pipeline

```
my_model.sitar
      |
      | sitar translate [-o output_dir]
      v
output_dir/          <- one .h (and optionally .cpp) per module/procedure
      |
      | sitar compile [--openmp] [--no-logging]
      | (runs SConstruct, invokes GCC)
      v
sitar_sim            <- standalone executable
      |
      | ./sitar_sim <cycles>
      v
simulation output
```

`sitar translate` invokes the ANTLR V3-based translator. `sitar compile` runs SCons with `compiler/SConstruct`, which compiles the generated C++ together with the kernel headers and `compiler/sitar_default_main.cpp` into the final executable.

---

## Module and procedure classes

Each `module` and `procedure` in the source becomes a C++ class inheriting from `sitar::module`. There is one class per module/procedure, regardless of how many times it is instantiated.

**Non-parameterized modules and procedures** produce two files: a `.h` with the class declaration and a `.cpp` with the constructor and method bodies.

**Parameterized modules and procedures** produce a `.h` file only. Because parameters become C++ template parameters, the entire class — including the constructor and all method bodies — must be in the header so the compiler can instantiate it for each distinct set of parameter values.

```sitar
module Counter               -- non-parameterized -> Counter.h + Counter.cpp
module Buffer                -- non-parameterized -> Buffer.h  + Buffer.cpp
    parameter int N = 4      -- parameterized     -> Buffer.h only (template class)
```

### Structural declarations

Structural declarations become member variables of the class:

- `net n : capacity C width W` → `sitar::net<W> n;` plus a token buffer array `sitar::token<W> n_buffer[C];`
- `net_array n[R][S] : capacity C width W` → `sitar::net<W> n[R][S];` plus `sitar::token<W> n_buffer[R][S][C];`
- `inport p : width W` / `outport p : width W` → `sitar::inport<W> p;` / `sitar::outport<W> p;`
- `submodule a : Foo` → `Foo a;`
- `submodule_array node[N][M] : Node<S>` → `Node<S> node[N][M];`

### Constructor body

The constructor sets up the module's identity, initializes the behavior state variables, and makes all structural connections. Structural `for` loops in the source translate to C++ `for` loops in the constructor that call `setNet()` on each port:

```cpp
// from: for row in 0 to (N-2)  for col in 0 to (M-1)  node[row][col].out_d => n_d[row][col]
for (int row = 0; row <= (N-2); row++) {
    for (int col = 0; col <= (M-1); col++) {
        node[row][col].out_d.setNet(&n_d[row][col]);
        node[row+1][col].in_u.setNet(&n_d[row][col]);
    }
}
```

The `init $...$` block is appended verbatim at the end of the constructor. The `decl $...$` block is inserted as additional public member declarations in the class.

---

## The behavior block

The behavior block is the most non-obvious part of the translation. A Sitar behavior is a sequence of statements that can suspend at any `wait` and resume from the same point when called again. This is implemented as a **switch-based coroutine** with explicit state variables.

### State variables

The translator counts all statements in the behavior and allocates:

| Variable | Type | Role |
|---|---|---|
| `_pointer[k]` | `unsigned int` array | Program counter for sequence `k`; `_pointer[0]` is the outermost |
| `_pointer_last_value[k]` | `unsigned int` | Terminal case value — behavior has ended when `_pointer[k]` reaches this |
| `_timer[k]` | `sitar::time` | Stores the wake-up time for each `wait` statement |
| `_if_flag[k]` | `bool` | Stores the evaluated condition for each `if` statement |
| `_terminated` | `bool` | Set when the outermost pointer reaches its last value; future calls return immediately |
| `_reexecute` | `bool` | Set to `true` whenever a pointer is incremented; drives the convergence loop |

### `runBehavior()` and the convergence loop

The base class `run()` calls `runBehavior(current_time)`. The translated `runBehavior` wraps the switch in a convergence loop:

```cpp
void Wait::runBehavior(const time& current_time) {
    if (_terminated) return;

    _reexecute = true;
    for (int _sitar_iteration = 1;
         _sitar_iteration <= SITAR_ITERATION_LIMIT && _reexecute;
         _sitar_iteration++)
    {
        _reexecute = false;
        switch (_pointer[0]) {
            // ... cases ...
        }
    }
    if (_reexecute)  // iteration limit exceeded
        stop_simulation();
    if (_pointer[0] == _pointer_last_value[0])
        _terminated = true;
}
```

Every time a statement completes, `_incrementPointer(k)` is called, which increments `_pointer[k]` and sets `_reexecute = true`. The loop then re-enters the switch at the new case. Execution advances as far as possible in one call — stopping only when a `wait` condition is not met (the case hits `break` without incrementing the pointer) or when the behavior terminates.

### One case per statement

**Every** semicolon-separated statement in the behavior generates one or more case labels. Examples from an actual translation:

```cpp
// $code_block$;  ->  one case: execute and increment
case 0: {
    cout << "\n time = " << current_time;  // verbatim C++ from $...$
    _incrementPointer(0);
}

// wait(c, p);  ->  TWO cases: set timer, then poll it
case 1: {
    _timer[0] = sitar::time(current_time) + sitar::time(0, 1);
    _incrementPointer(0);
}
case 2: {
    if (current_time >= _timer[0])
        _incrementPointer(0);
    else
        break;  // suspend: return without incrementing; re-enter here next call
}

// wait until (expr);  ->  one case: poll condition
case 3: {
    if (expr)
        _incrementPointer(0);
    else
        break;  // suspend
}

// terminal case — never executes, marks the end
case 4: break;
```

The `break` on a wait case exits the switch, leaves `_reexecute` false, and the convergence loop terminates. The module returns from `runBehavior()` and the pointer stays at the wait case, so the next call re-enters at the same point.

### Compound statements

`if-else`, `do-while`, and `parallel` blocks each get their own nested switch with a dedicated `_pointer[k]`:

- **`if (cond) then ... else ... end if`**: one case evaluates the condition into `_if_flag[k]`; the next case dispatches into the taken branch's sub-switch. When the branch's sub-switch terminates, the outer pointer is incremented.

- **`do ... while (cond) end do`**: the do-while body is a nested switch inside a C++ `for` loop bounded by `SITAR_ITERATION_LIMIT`. When the body's sub-switch terminates, the condition is checked: if true the inner pointer resets and the body re-executes; if false the outer pointer increments (loop exits).

- **`[ A || B ]`**: each branch gets its own pointer. The parallel case runs both branch sub-switches on every call. When all branch pointers reach their terminal values, the branch pointers are reset and the outer pointer is incremented.

### Procedures

A procedure translates identically to a module — it has its own class, its own `runBehavior()`, its own `_pointer[]`/`_timer[]` state, and a `_terminated` flag. The parent module's `run p;` statement translates to a case that calls `p.runBehavior(current_time)` and checks `p._terminated`; it breaks (suspends) until the procedure has finished, then calls `p._resetBehavior()` to prepare it for the next invocation.

---

## Modifying Sitar

To extend the language, edit `translator/grammar/sitar.g` and regenerate the parser with ANTLR V3. To add a kernel primitive (a new port type, a token inspection function, etc.), add a header to `core/` and `#include` it from `sitar_module.h`. The [Development Notes](../development.md) page has a full listing of source files and their roles.
