# Performance baselines

Recorded runs to compare changes against, prefetching first. Each baseline is
a markdown write-up plus the JSON from `Scripts/perf_summary.py --json`, so a
later run can be diffed number by number. The `.trace` files stay out of the
repo (60+ MB each); the file name is recorded for whoever has them.

## Recording a comparable run

Same scenario every time, or the numbers don't compare:

1. Device, not simulator. Release build via Profile (⌘I), no debugger.
   `-perfTracing YES` in the scheme's Run arguments (Profile inherits them);
   tracing is off by default in Release.
2. Cold: delete and reinstall the app, so the decoded-image cache and
   `URLCache` both start empty.
3. System Trace template. Flow picker ▸ Open MVVM-C · UIKit, wait for the
   first screen, 4 fast swipes down, 4 back up, open one product.
4. Save the trace, then:

       Scripts/perf_summary.py path/to/run.trace          # table
       Scripts/perf_summary.py path/to/run.trace --json   # for this folder
       Scripts/perf_summary.py path/to/run.trace --run 3  # one run of several

## Baselines

| Date | Name | Change |
|---|---|---|
| 2026-09-21 | [before-prefetch-cold](baselines/2026-09-21-before-prefetch-cold.md) | none, pre-prefetching |
| 2026-09-21 | [after-prefetch-cold](baselines/2026-09-21-after-prefetch-cold.md) | prefetching (`1756df0`), 2 cold runs |
