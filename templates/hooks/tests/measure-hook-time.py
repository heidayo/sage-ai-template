#!/usr/bin/env python3
# =============================================================================
# TASK-0123: measure-hook-time.py (SPEC-0015 FR-05 / NFR-08)
# Purpose:  Measure hook execution time over N runs, return median.
#           Compare against threshold (default 200ms, env override).
#           macOS / Linux portable (avoids GNU time -f incompat).
# Usage:    python3 measure-hook-time.py <hook-script> [--runs 5] [--threshold-ms 200]
# Exit:     0 if median < threshold, 1 if exceeds.
# =============================================================================
import argparse
import os
import statistics
import subprocess
import sys
import time


def measure_one(hook_path: str) -> float:
    """Run hook with empty stdin, return wall-clock ms."""
    start = time.perf_counter()
    try:
        subprocess.run(
            ["bash", hook_path],
            input="",
            capture_output=True,
            text=True,
            timeout=10,
        )
    except subprocess.TimeoutExpired:
        return float("inf")
    elapsed = (time.perf_counter() - start) * 1000
    return elapsed


def main() -> int:
    parser = argparse.ArgumentParser(description="Measure hook execution time (median of N runs).")
    parser.add_argument("hook", help="Path to hook script")
    parser.add_argument("--runs", type=int, default=5, help="Number of runs (default 5)")
    parser.add_argument(
        "--threshold-ms",
        type=int,
        default=int(os.environ.get("SAGE_HOOK_TIME_THRESHOLD_MS", "200")),
        help="Threshold in ms (default 200, env SAGE_HOOK_TIME_THRESHOLD_MS overrides)",
    )
    args = parser.parse_args()

    if not os.path.isfile(args.hook):
        print(f"ERROR: hook not found: {args.hook}", file=sys.stderr)
        return 1

    times = [measure_one(args.hook) for _ in range(args.runs)]
    median = statistics.median(times)
    minimum = min(times)
    maximum = max(times)

    print(f"hook:      {args.hook}")
    print(f"runs:      {args.runs}")
    print(f"runs(ms):  {[f'{t:.1f}' for t in times]}")
    print(f"min:       {minimum:.1f}ms")
    print(f"median:    {median:.1f}ms")
    print(f"max:       {maximum:.1f}ms")
    print(f"threshold: {args.threshold_ms}ms")

    if median < args.threshold_ms:
        print(f"PASS: median ({median:.1f}ms) < threshold ({args.threshold_ms}ms)")
        return 0
    else:
        print(f"FAIL: median ({median:.1f}ms) >= threshold ({args.threshold_ms}ms)", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
