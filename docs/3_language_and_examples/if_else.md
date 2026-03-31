# If-else

The `if`-`else` statement is a compound statement that selects one of two sequences to execute based on a boolean condition. The `else` branch is optional.

---

## Syntax

With both branches:

```sitar
if (condition) then
    // true branch: any sequence of statements
else
    // false branch: any sequence of statements
end if;
```

Without an `else` branch:

```sitar
if (condition) then
    // executes only when condition is true
end if;
```

The condition is written inside standard parentheses. The `then` keyword follows the closing parenthesis.

---

## Condition expressions

The condition expression is parsed by Sitar's own grammar, which supports a structured subset of C++ expressions:

- **Comparison:** `==`, `!=`, `<`, `>`, `<=`, `>=`
- **Arithmetic:** `+`, `-`, `*`, `/`, `%`, unary `-`
- **Logical:** keywords `and`, `or`, `not` (translate to C++ `&&`, `||`, `!`)
- **Atomics:** integer literals, identifiers, `this_cycle`, `this_phase`, function calls, parenthesised sub-expressions
- **Verbatim C++:** a `$...$` block used as an atomic expression — any valid C++ boolean sub-expression can be embedded this way

```sitar
if (count == 0) then ... end if;
if (x > 0 and y < 10) then ... end if;
if (not flag) then ... end if;
if ($ptr != nullptr and ptr->ready$) then ... end if;   // $ wraps complex C++
```

Note that `&&`, `||`, and `!` are not recognised outside dollar signs — use `and`, `or`, `not` instead. To use C++ operators or any other construct not in the grammar, wrap the expression in `$...$`.

---

## Branch contents

Each branch is a full sequence. It may contain any combination of atomic and compound statements, including nested `if`-`else`, `do`-`while`, parallel blocks, and `run` invocations:

```sitar
if (mode == 0) then
    wait(1, 0);
    $process_mode_0();$;
else
    do
        $process_mode_1();$;
        wait(1, 0);
    while (not done) end do;
end if;
```

---

## `stop simulation` and `stop behavior` inside `if`

`stop simulation` and `stop behavior` may appear inside an `if` branch. Statements that follow in the same phase (before the next `wait`) still execute:

```sitar
if (count >= limit) then
    $log << endl << "limit reached";$;
    stop simulation;
end if;
```

---

## Example

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_if_else.sitar:model"
```

Expected output:

```
(0,0)TOP.m      :count=0: even
(1,0)TOP.m      :count=1: odd
(2,0)TOP.m      :count=2: even
(3,0)TOP.m      :count=3: odd
(4,0)TOP.m      :count=4: even
Simulation stopped at time (5,0)
```

The loop runs five iterations (count 0 through 4), logging "even" or "odd" at each step. After the fifth `wait(1,0)`, the loop condition `count < 5` is false (count is now 5) and the loop exits. `stop simulation` is called at cycle 5.

---

## What's next

Proceed to [Do-while](do_while.md) to learn the loop construct.
