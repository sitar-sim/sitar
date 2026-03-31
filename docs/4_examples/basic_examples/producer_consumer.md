# Producer-consumer

A producer module generates a stream of integer-valued tokens and a consumer receives them through a bounded channel. This example uses the producer-consumer pair to illustrate three different ways to terminate a simulation: by production count, by consumption count, or by elapsed time.

**What this example demonstrates:**

- Integer payloads with `sitar::pack` and `sitar::unpack`
- Bounded channel with back-pressure (`net channel : capacity 4`)
- Three distinct stop conditions selectable at the top level
- A `Timer` module for cycle-count-based termination

---

## Selecting a stop condition

Change `STOP_MODE` in the `Top` module to select how the simulation ends:

| `STOP_MODE` | Meaning |
|---|---|
| `1` | Producer calls `stop simulation` after sending `MAX_TOKENS` tokens |
| `2` | Consumer calls `stop simulation` after receiving `MAX_TOKENS` tokens |
| `3` | A Timer module calls `stop simulation` after `MAX_CYCLES` cycles |

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_producer_consumer.sitar:top"
```

All three modules (Producer, Consumer, Timer) are always instantiated. Each checks its own MODE parameter and acts only when it matches. When `MODE` is a compile-time constant, the C++ compiler eliminates the dead branches entirely.

---

## Producer

The Producer packs each successive integer into a `token<4>` payload and pushes it to the channel. It greedily fills the channel each cycle (the `while (outp.push(t))` loop pushes until the net is full). In mode 1, the Producer calls `stop simulation` once it has sent `MAX_TOKENS` tokens.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_producer_consumer.sitar:producer"
```

---

## Consumer

The Consumer drains all available tokens in phase 0 each cycle, unpacking and logging each value. In mode 2, it calls `stop simulation` once it has received `MAX_TOKENS` tokens.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_producer_consumer.sitar:consumer"
```

---

## Timer

The Timer module is a one-shot: if `MODE == 3`, it waits `MAX_CYCLES` cycles and then stops the simulation. If `MODE != 3`, its behavior ends immediately and the module is dormant for the rest of the simulation.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_producer_consumer.sitar:timer"
```

---

## Expected output

**Mode 1** (`STOP_MODE=1, MAX_TOKENS=10`):

```
(0,1) TOP.sys.prod : produced 0
(0,1) TOP.sys.prod : produced 1
(0,1) TOP.sys.prod : produced 2
(0,1) TOP.sys.prod : produced 3
(1,0) TOP.sys.cons : consumed 0
(1,0) TOP.sys.cons : consumed 1
...
(2,1) TOP.sys.prod : produced 9
(2,1) TOP.sys.prod : producer: 10 tokens sent -- stopping
Simulation stopped at time (2,1)
```

**Mode 2** (`STOP_MODE=2, MAX_TOKENS=10`): The Producer runs indefinitely; the Consumer stops simulation after receiving 10 tokens. The final `stop simulation` call comes from the Consumer rather than the Producer.

**Mode 3** (`STOP_MODE=3, MAX_CYCLES=25`): Both Producer and Consumer run indefinitely until the Timer fires at cycle 25. The number of tokens in flight at that point is determined by the channel capacity and the relative rates of production and consumption.

!!! note "Modes 1 and 2 are not equivalent"
    In mode 1, tokens may still be in transit inside the channel when `stop simulation` is called; the Consumer may not have seen all of them. In mode 2, the Consumer counts only tokens it has actually pulled, so the stop condition captures end-to-end delivery. Choose the mode that matches what your model needs to measure.
