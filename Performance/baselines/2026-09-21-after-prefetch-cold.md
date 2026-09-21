# After prefetching, cold start

- **Date:** 2026-09-21
- **Change:** prefetching merged (`1756df0`: `ImagePrefetcher`, `InFlightRegistry`, pixel-matched `ImageRequest`)
- **Trace:** `baseline-cold-trace.trace` (not in repo). The same document as the
  baseline, holding several runs. Document run numbers differ from Instruments'
  labels, because a cancelled run (5) isn't stored:

  | Document run | Instruments run | What it was |
  |---|---|---|
  | 1 | 2 | the [before-prefetch baseline](2026-09-21-before-prefetch-cold.md) |
  | 2 | 3 | cold, fresh install, 1 hang |
  | 3 | 4 | re-run of 3 without reinstalling: `URLCache` warm, **not comparable** |
  | 4 | 6 | cold, fresh install, no hangs |

- **Data:** [run2.json](2026-09-21-after-prefetch-cold-run2.json), [run4.json](2026-09-21-after-prefetch-cold-run4.json)
  (`Scripts/perf_summary.py <trace> --run N`)

## Numbers

| Metric | Before (run 1) | After, run 2 | After, run 4 |
|---|---|---|---|
| `image.visibleWait` p50 | 1.5 ms | 1.5 ms | 1.6 ms |
| `image.visibleWait` p90 | 517 ms | 932 ms | 770 ms |
| `image.network` p50 / p90 | 360 / 982 ms | 411 / 1052 ms | 301 / 1207 ms |
| downloads (`image.network` n) | 12 | 12 | 12 |
| `image.load` memory hit | 70% | 75% | 76% |
| joined an in-flight prefetch | – | 4 | 4 |
| `image.prefetch` | – | 28, all completed | 30, all completed |
| `image.decode` p50 / `decodeCPU` p50 | 8.7 / 7.1 ms | 9.6 / 7.6 ms | 9.1 / 7.9 ms |
| `list.timeToContent` | 506 ms | 819 ms | 452 ms |
| `scroll.hitchRatio` | 0 | 0 | 0 |
| hangs | 0 | 1 (513 ms) | 0 |

## Reading

**No measurable change either way, and this dataset can't show one.**

- **The 12 images split 8 + 4.** The first 8 are requested together the moment
  the list appears (visible cells plus UIKit's own cell pre-preparation).
  Nothing can prefetch those, and they make up every sample in the
  `visibleWait` p90. The p90 moved with network luck on those 8, not with
  prefetching: network max was 1.6 s, 1.3 s and 2.1 s across the three runs.
- **The last 4 are where prefetching could help, and it starts too late.**
  The prefetch for them begins about 20 ms before the cells ask (run 2: 2.31 s
  vs 2.32 s; run 4: 1.12 s vs 1.14 s), so the cells just join the in-flight
  download (`inflight` = 4). Their waits: 136–245 ms before, 78–241 and
  106–726 ms after (the 726 was a 751 ms download). With 12 items, the rows
  after the first screen are already next in line when scrolling starts;
  there is no further-ahead row for `UICollectionViewDataSourcePrefetching`
  to reach earlier.
- **No regressions.** Still exactly 12 downloads: prefetch and cell requests
  land on the same cache key, so no duplicate fetches. No cancelled
  prefetches, no hitches, decode unchanged. Joined loads show `InFlightRegistry`
  works.
- **The run 2 hang is not prefetching.** It is 3.13–3.65 s, between tapping
  Open and the fetch starting: the main thread building and presenting the list
  for the first time in a cold process (layout, Core Animation commit, Swift
  type metadata). It pushed `products.fetch` 300 ms after `viewDidLoad` and
  `list.timeToContent` to 819 ms. The prefetch code runs later. It didn't
  recur in run 4. It's a cold-launch cost that varies between runs.

## To actually measure prefetching

Needs more content than one screen plus one row: a longer list (a stub
repository repeating the 12 products with distinct image URLs, ~100 items),
the same cold scenario, and several runs per side, comparing the median of
their p90s. Network variance per run is larger than the effect being measured.
