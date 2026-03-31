# Measuring speedup

Speedup is the ratio of serial execution time to parallel execution time on N threads:

**Speedup(N) = T(1) / T(N)**

Ideal (linear) speedup gives Speedup(N) = N. In practice, communication overhead, load imbalance, and barriers reduce this. This page explains how to measure speedup for a Sitar model and what factors to consider when interpreting the results.

---

## Prerequisites

1. Build the model with OpenMP enabled:
   ```bash
   sitar translate my_model.sitar
   sitar compile --openmp --no-logging
   ```
   Compile with `--no-logging` for timing measurements. Logging adds I/O overhead that does not reflect the simulation workload.

2. Verify the serial baseline runs correctly:
   ```bash
   OMP_NUM_THREADS=1 ./sitar_sim 50
   ```

---

## Manual measurement

The simplest measurement uses the shell `time` command:

```bash
# Serial baseline
OMP_NUM_THREADS=1 time ./sitar_sim 50

# 2 threads
OMP_NUM_THREADS=2 time ./sitar_sim 50

# 4 threads
OMP_NUM_THREADS=4 time ./sitar_sim 50
```

Record the **real** (wall-clock) time from each run and compute speedup manually.

---

## Automated measurement with `speedup_plot.py`

The script [`speedup_plot.py`](speedup_plot.py) automates this sweep. It runs the simulation for each specified thread count, repeats each configuration a configurable number of times, prints a summary table, and generates two PNG plots.

**Requirements:** Python 3 (standard library only for the table; `matplotlib` for the plots — install with `pip install matplotlib`).

### Basic usage

```bash
# From the directory containing sitar_sim:
python3 path/to/speedup_plot.py --exec ./sitar_sim --cycles 50 --threads 1,2,4,8
```

### Options

| Option | Default | Description |
|---|---|---|
| `--exec PATH` | `./sitar_sim` | Path to the compiled executable |
| `--cycles N` | `50` | Simulation cycles per run |
| `--threads T1,T2,...` | `1,2,4,8` | Thread counts to sweep |
| `--repeats N` | `3` | Runs per configuration; mean wall time is reported |
| `--output DIR` | `.` | Directory for PNG output |

### Example output

```
Executable : ./sitar_sim
Cycles     : 50
Threads    : [1, 2, 4, 8]
Repeats    : 3

 Threads    Mean time (s)   Speedup
------------------------------------
       1          2.041      1.00x
       2          1.024      1.99x
       4          0.517      3.95x
       8          0.274      7.45x

Saved plots:
  ./execution_time.png
  ./speedup.png
```

The script produces two plots:

- **`execution_time.png`** — wall-clock time vs thread count
- **`speedup.png`** — measured speedup vs thread count, with ideal linear speedup overlaid

---

## Interpreting results

### Factors that reduce speedup below ideal

**Compute-to-communication ratio.** Speedup is close to linear when each module performs significant compute work relative to the time spent pushing and pulling tokens. If the behavior is mostly waiting (blocked on empty nets or full nets), adding threads gives diminishing returns. The `5_parallel_simple.sitar` model is designed to show near-linear speedup because each module burns ~1 ms of CPU per phase.

**Load imbalance.** With the default static round-robin schedule, speedup is best when all modules have roughly equal per-cycle work. If one module is much heavier than the others, it becomes the bottleneck regardless of thread count. See [Enabling Parallel Execution](parallel_execution.md#customizing-module-to-thread-mapping) for custom thread-to-module assignment.

**OpenMP barrier overhead.** A global barrier runs between every phase. For very short phases (sub-microsecond module work), the barrier cost is proportionally large. Use `--cycles N` with a large N to amortize barrier overhead over more simulation time.

**Number of modules vs threads.** Speedup saturates when `OMP_NUM_THREADS` exceeds the number of modules. If your model has 4 modules, using 8 threads provides no benefit. Set `OMP_NUM_THREADS` to at most the number of modules in the flattened hierarchy.

### How many cycles to use for benchmarking

Use enough cycles that the total runtime is at least a few seconds at 1 thread, so that measurement noise from process startup and operating system scheduling is small. For the `5_parallel_simple.sitar` model, 20-50 cycles suffice. For lighter models, use 200-1000 cycles.

!!! tip "Disabling logging for timing"
    Always use `--no-logging` when compiling for speedup measurements. Even though logging is typically buffered, the overhead of formatting and writing log lines is significant and artificially reduces parallel efficiency. Measure with logging off; verify correctness with logging on.
