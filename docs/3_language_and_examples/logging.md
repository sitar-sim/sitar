# Logging

Sitar provides a built-in logger object `log` in every module. It is an instance of `sitar::logger`, a thin wrapper around a C++ `std::ostream` that automatically prepends a time-and-name prefix to each output line.

---

## Basic usage

`log` behaves like a C++ output stream. Use `<<` to pass values, and `std::endl` to start a new prefixed line:

```sitar
$
log << endl << "Hello from " << hierarchicalId();
log << endl << "current time: " << current_time;
$;
```

**`endl` inserts a newline followed by the default prefix.** The default prefix format is:

```
(cycle,phase)full_hierarchical_name    :
```

For example: `(3,1)TOP.sys.producer   :`.

Without `endl`, output continues on the same line with no new prefix:

```sitar
$
log << endl << "cycle=" << this_cycle;
log << "  phase=" << this_phase;    // appended to the same line, no prefix
$;
```

---

## Module info in log output

The following built-in functions are useful for identifying the logging module:

```sitar
$
log << endl << "instance : " << instanceId();        // e.g. "producer"
log << endl << "full name: " << hierarchicalId();    // e.g. "TOP.sys.producer"
log << endl << "parent   : " << parent()->instanceId();
log << endl << "hierarchy: " << "\n" << getInfo();  // full subtree
$;
```

---

## Token info

The `t.info()` method returns a formatted string showing a token's type, ID, and payload bytes. It is useful for tracing token flow:

```sitar
$
token<4> t;
int val = 42;
sitar::pack(t, val);
log << endl << "token: " << t.info();
// prints: token: (type=0, ID=0, payload=0x2a 00 00 00 )
$;
```

---

## Multiple loggers and file output

A module can create additional `logger` instances and direct each to any `std::ostream`, including files. Additional loggers are declared with `decl` (so they persist as class members):

```sitar
decl $logger log2; std::ofstream logfile;$;

$
logfile.open("log_" + hierarchicalId() + ".txt", std::ofstream::out);
log2.setOstream(&logfile);
$;

$log  << endl << "This line goes to stdout";$;
$log2 << endl << "This line goes to the log file";$;
```

The default logger `log` can also be redirected:

```sitar
$log.setOstream(&logfile);$;    // redirect default log to file
$log.setOstream(logger::default_logstream);$;    // reset to stdout
```

`logger::default_logstream` is the shared output stream used by all modules by default (points to `std::cout`). It can be changed globally in the main file to redirect all module output.

---

## Custom prefix

By default, the prefix is updated every phase to reflect the current time and module name. This can be replaced with a custom string:

```sitar
$
log.useDefaultPrefix = false;    // disable automatic prefix update
log.setPrefix("MY_PREFIX: ");
log << endl << "Custom prefix, no time";
$;
```

To include time in a custom prefix, set it explicitly each cycle:

```sitar
do
    $
    log.setPrefix(current_time.toString() + " CUSTOM: ");
    log << endl << "with time in custom prefix";
    $;
    wait(1, 0);
while (this_cycle < 5) end do;
```

To restore the default prefix, set `useDefaultPrefix` back to `true`. The change takes effect after the next `wait`:

```sitar
$log.useDefaultPrefix = true;$;
wait;
$log << endl << "default prefix restored";$;
```

---

## Enable and disable at runtime

Logging can be turned off and on for individual modules at runtime:

```sitar
$
log.turnOFF();
log << endl << "This will NOT appear";
log.turnON();
log << endl << "This WILL appear";
$;
```

---

## Compile-time control

All logging is gated on the `SITAR_ENABLE_LOGGING` preprocessor macro. When this macro is not defined at compile time, the `logger` class becomes a no-op and all `log <<` calls are optimized away. This allows logging code to remain in the model source without imposing runtime overhead in performance-critical builds.

---

## Example

The file `docs/sitar_examples/3_logging.sitar` contains named sections demonstrating each logging feature covered above. The sections `:basic`, `:multiple_loggers`, `:prefix`, and `:control` can be read independently.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/3_logging.sitar:basic"
```

---

## What's next

Proceed to [If-else](if_else.md) to learn conditional branching.
