#!/usr/bin/env python3
"""
speedup_plot.py — measures Sitar parallel simulation speedup across thread counts
and generates execution-time and speedup plots.

Usage:
    python3 speedup_plot.py [options]

Options:
    --exec    PATH     path to the sitar_sim executable (default: ./sitar_sim)
    --cycles  N        number of simulation cycles to run (default: 50)
    --threads T1,T2    comma-separated list of thread counts (default: 1,2,4,8)
    --repeats N        number of timed runs per configuration; mean is reported (default: 3)
    --output  DIR      directory in which to save the output PNG plots (default: .)

Examples:
    # Quick check (4 configurations, 3 repeats each):
    python3 speedup_plot.py --exec ./sitar_sim --cycles 50 --threads 1,2,4,8

    # Longer sweep for publication-quality results:
    python3 speedup_plot.py --exec ./sitar_sim --cycles 200 --threads 1,2,4,6,8,12,16 --repeats 5
"""

import argparse
import os
import statistics
import subprocess
import sys
import time

# ---------------------------------------------------------------------------
# Matplotlib import (optional: if not available, only the table is printed)
# ---------------------------------------------------------------------------
try:
    import matplotlib
    matplotlib.use('Agg')          # non-interactive backend; no display needed
    import matplotlib.pyplot as plt
    HAVE_MPL = True
except ImportError:
    HAVE_MPL = False
    print("Warning: matplotlib not found — plots will not be generated.")
    print("         Install with:  pip install matplotlib\n")


# ---------------------------------------------------------------------------
# Core measurement function
# ---------------------------------------------------------------------------

def run_once(executable: str, cycles: int, num_threads: int) -> float:
    """Run ./sitar_sim cycles with OMP_NUM_THREADS=num_threads, return wall time (s)."""
    env = os.environ.copy()
    env['OMP_NUM_THREADS'] = str(num_threads)

    t0 = time.perf_counter()
    result = subprocess.run(
        [executable, str(cycles)],
        env=env,
        capture_output=True,
        text=True,
    )
    elapsed = time.perf_counter() - t0

    if result.returncode != 0:
        print(f"\nERROR: simulation exited with code {result.returncode}")
        print("  stdout:", result.stdout[:400])
        print("  stderr:", result.stderr[:400])
        sys.exit(1)

    return elapsed


def measure(executable: str, cycles: int, num_threads: int, repeats: int) -> float:
    """Return the mean wall time over `repeats` independent runs."""
    samples = [run_once(executable, cycles, num_threads) for _ in range(repeats)]
    return statistics.mean(samples)


# ---------------------------------------------------------------------------
# Plot helpers
# ---------------------------------------------------------------------------

def plot_time(thread_counts, times, cycles, output_dir):
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.plot(thread_counts, times, 'o-', color='steelblue', label='measured')
    ax.set_xlabel('Number of threads')
    ax.set_ylabel('Wall-clock time (s)')
    ax.set_title(f'Execution time vs threads  ({cycles} cycles)')
    ax.grid(True, linestyle='--', alpha=0.5)
    ax.legend()
    path = os.path.join(output_dir, 'execution_time.png')
    fig.savefig(path, dpi=150, bbox_inches='tight')
    plt.close(fig)
    return path


def plot_speedup(thread_counts, speedups, cycles, output_dir):
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.plot(thread_counts, speedups, 'o-', color='steelblue', label='measured speedup')
    ax.plot(thread_counts, thread_counts, '--', color='gray', alpha=0.6, label='ideal (linear)')
    ax.set_xlabel('Number of threads')
    ax.set_ylabel('Speedup  (T₁ / Tₙ)')
    ax.set_title(f'Speedup vs threads  ({cycles} cycles)')
    ax.grid(True, linestyle='--', alpha=0.5)
    ax.legend()
    path = os.path.join(output_dir, 'speedup.png')
    fig.savefig(path, dpi=150, bbox_inches='tight')
    plt.close(fig)
    return path


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Measure Sitar parallel simulation speedup.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split('\n\nUsage:')[0],
    )
    parser.add_argument('--exec',    default='./sitar_sim', metavar='PATH',
                        help='path to the sitar_sim executable')
    parser.add_argument('--cycles',  type=int, default=50, metavar='N',
                        help='number of simulation cycles per run')
    parser.add_argument('--threads', default='1,2,4,8', metavar='T1,T2,...',
                        help='comma-separated list of thread counts')
    parser.add_argument('--repeats', type=int, default=3, metavar='N',
                        help='timed runs per configuration (mean is used)')
    parser.add_argument('--output',  default='.', metavar='DIR',
                        help='output directory for PNG plots')
    args = parser.parse_args()

    thread_counts = [int(t.strip()) for t in args.threads.split(',')]

    if not os.path.isfile(args.exec):
        print(f"Error: executable not found: {args.exec}")
        sys.exit(1)

    os.makedirs(args.output, exist_ok=True)

    print(f"Executable : {args.exec}")
    print(f"Cycles     : {args.cycles}")
    print(f"Threads    : {thread_counts}")
    print(f"Repeats    : {args.repeats}")
    print()
    print(f"{'Threads':>8}  {'Mean time (s)':>14}  {'Speedup':>8}")
    print('-' * 36)

    times    = []
    speedups = []

    for t in thread_counts:
        mean_t = measure(args.exec, args.cycles, t, args.repeats)
        times.append(mean_t)
        sp = times[0] / mean_t if mean_t > 0 else float('inf')
        speedups.append(sp)
        print(f"{t:>8}  {mean_t:>14.3f}  {sp:>8.2f}x")

    print()

    if HAVE_MPL:
        p1 = plot_time(thread_counts, times, args.cycles, args.output)
        p2 = plot_speedup(thread_counts, speedups, args.cycles, args.output)
        print(f"Saved plots:")
        print(f"  {p1}")
        print(f"  {p2}")
    else:
        print("Skipped plots (matplotlib not available).")


if __name__ == '__main__':
    main()
