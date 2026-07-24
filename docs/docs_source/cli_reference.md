# CLI Reference

This page documents `sitar translate` and `sitar compile` in full, with illustrative examples for every option. For a quick first pass through the toolchain, see [Getting Started](getting_started.md); use this page as the reference to come back to.

Both commands operate relative to your **current working directory**, where your `.sitar` model (and, after translation, the `Output/` directory) lives.

```bash
sitar -h                # top-level help
sitar translate -h      # options for the translate step
sitar compile -h        # options for the compile step
```

---

## `sitar translate`

Converts a `.sitar` model into C++ code.

```
usage: sitar translate [-h] [-o OUTPUT_DIR] INPUT_FILE
```

| Option | Description |
|---|---|
| `INPUT_FILE` | (positional, required) the `.sitar` file to translate |
| `-o DIR`, `--output DIR` | directory to place the generated C++ in (default: `./Output`) |

**Examples**

Translate `model.sitar`, writing generated code to the default `./Output`:

```bash
sitar translate model.sitar
```

Translate into a custom directory:

```bash
sitar translate model.sitar -o MyGeneratedCode
```

---

## `sitar compile`

Compiles the generated C++ (plus the Sitar kernel) into a standalone simulation executable. Run it from the same directory as the preceding `sitar translate` step.

```
usage: sitar compile [-h] [-o OUTPUT_FILE] [-d CODE_DIR] [-m MAIN_FILE]
                     [--cflags C_FLAGS] [-l LIBS] [--openmp]
                     [--logging | --no-logging]
```

| Option | Description |
|---|---|
| `-o NAME`, `--output NAME` | name of the executable to create (default: `sitar_sim`) |
| `-d DIR`, `--directory DIR` | a directory to search for source/header files. Repeatable |
| `-m FILE`, `--main_file FILE` | a custom `main.cpp` to instantiate `Top` and drive the simulation, replacing `compiler/sitar_default_main.cpp` |
| `--cflags "..."` | extra flags for the **compile step only** (`CCFLAGS`, i.e. `g++ -c`). Does **not** affect linking |
| `-l LIB`, `--libs LIB` | an extra library to **link** against, without the `-l` prefix (e.g. `-l quadmath`). Repeatable and/or comma-separated |
| `--openmp` | compile with OpenMP support for parallel simulation |
| `--logging` / `--no-logging` | enable (default) or disable the `log` object and `-DSITAR_ENABLE_LOGGING` |

**Examples**

Compile with defaults, producing `./sitar_sim`:

```bash
sitar compile
```

Name the executable explicitly:

```bash
sitar compile -o my_sim
```

Include an extra directory of hand-written code (e.g. a shared header referenced from a `$#include ...$` block) in addition to the default `Output/`:

```bash
sitar compile -d Output/ -d ./
```

Use a custom `main.cpp`, e.g. to control simulation parameters programmatically or to pick which modules run on which thread (see [Parallel Execution](5_parallel_execution/parallel_execution.md)):

```bash
sitar compile -m custom_main.cpp
```

Pass an extra compile-time flag, e.g. to disable optimization for easier debugging. Since the value itself starts with `-`, use the `--cflags=VALUE` form so it isn't mistaken for another option:

```bash
sitar compile --cflags="-O0"
```

Link against an external library, e.g. `libquadmath` for `__float128` support:

```bash
sitar compile -l quadmath
```

Link against several libraries at once (repeat `-l`, or comma-separate):

```bash
sitar compile -l quadmath -l gomp
sitar compile --libs quadmath,gomp
```

Build for parallel simulation with OpenMP, and disable logging for a faster run:

```bash
sitar compile --openmp --no-logging
```

Combine several options together (note `-d Output/` must be listed explicitly alongside any other `-d`, since specifying `-d` at all replaces the implicit default of `./Output`):

```bash
sitar compile -o my_sim -d Output/ -d ./ --cflags="-O0" -l quadmath --openmp
```

---

## Beyond the CLI flags

The options above cover the common cases. `sitar compile` works by writing the resolved options to a file, `sitar_scons_config.txt`, in the current directory, and then invoking [SCons](https://scons.org/) with the build script `compiler/SConstruct`.

For anything not covered by a CLI flag — a different compiler, extra linker flags, additional preprocessor defines, custom SCons logic, etc. — copy `compiler/SConstruct` into your own project and modify it directly, then invoke `scons -f your_SConstruct.py` in place of `sitar compile`. See [Development Notes](development.md) for the meaning of each setting `SConstruct` reads from `sitar_scons_config.txt`.
