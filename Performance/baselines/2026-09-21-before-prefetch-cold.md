# Before prefetching, cold start

- **Date:** 2026-09-21
- **Branch:** `analyze/performance-tracing`, uncommitted at the time of recording
- **Trace:** `baseline-cold-trace.trace` (not in repo)
- **Device:** iPhone 12, iOS 26.4 · System Trace · 10.6 s
- **Scenario:** cold install, first screen, 4 fast swipes down and 4 up, open one product. See [../README.md](../README.md).
- **Data:** [2026-09-21-before-prefetch-cold.json](2026-09-21-before-prefetch-cold.json)


| Metric | n | mean | p50 | p90 | max | unit | notes |
|---|---|---|---|---|---|---|---|
| `products.fetch` | 1 | 429.6 | 429.6 | 429.6 | 429.6 | ms |  |
| `list.timeToContent` | 1 | 506.3 | 506.3 | 506.3 | 506.3 | ms |  |
| `image.load` | 40 | 170.6 | 0.0 | 509.7 | 1637.9 | ms | memory 28/40 (70% hit) |
| `image.network` | 12 | 553.3 | 360.2 | 981.6 | 1608.2 | ms |  |
| `image.decode` | 12 | 15.2 | 8.7 | 29.5 | 48.9 | ms |  |
| `image.decodeCPU` | 12 | 12.6 | 7.1 | 24.8 | 37.1 | ms |  |
| `image.visibleWait` | 40 | 174.1 | 1.5 | 517.0 | 1648.1 | ms |  |
| `scroll.hitchRatio` | 7 | 0.0 | 0.0 | 0.0 | 0.0 | ms/s |  |

Hangs: 0

## Reading

- **Placeholder time is the cost.** `image.visibleWait` p50 1.5 ms (memory
  hits) but p90 517 ms, max 1.6 s: cells whose image was not yet loaded when
  they scrolled in. That tail is what prefetching should remove.
- **All of it is network.** 12 cold loads, `image.network` p50 360 ms, p90
  982 ms. Each `visibleWait` is roughly its `image.load` plus ~5 ms, so
  delivery to the main thread costs nothing.
- **Decode is not a problem.** `image.decode` p50 8.7 ms, p90 29.5 ms; CPU is
  ~80% of wall, so there is little waiting on the hardware decoder in this run.
  No case for a decode concurrency limit (ARCHITECTURE §9a).
- **70% memory hit rate** comes from scrolling back over the 12 products, not
  from anything ahead of the user. The list has only 12 items, so prefetching
  can only help the first pass down.
- **Scrolling is smooth:** 7 sessions, 0 ms/s hitch ratio. No hangs.

## What prefetching should change

| Metric | Now | Expect |
|---|---|---|
| `image.visibleWait` p90 | 517 ms | close to memory-hit level, for cells below the first screen |
| `image.load` memory hit rate | 70% | higher |
| cancelled loads | 0 | stay low, or prefetch is over-fetching |
| `scroll.hitchRatio` | 0 ms/s | still 0, so prefetch adds no main-thread work |
