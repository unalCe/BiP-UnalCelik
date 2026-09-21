#!/usr/bin/env python3
"""Summarise PerformanceKit signposts and hangs from an Instruments trace.

Instruments' "Summary: Intervals" gives count/avg/min/max per signpost, but no
percentiles and nothing for event values (image.decodeCPU, scroll.hitchRatio).
This computes the same statistics PerformanceReport does, from the trace.

    Scripts/perf_summary.py path/to/run.trace            # markdown table
    Scripts/perf_summary.py path/to/run.trace --json     # machine-readable

Needs Xcode's `xctrace`. Works on any template that records os_signpost
(System Trace, Time Profiler, os_signpost...). Hangs come from the Hangs
instrument when the template has it.
"""

import argparse
import json
import math
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict

SUBSYSTEM = "TurkcellCase.Performance"

# Report order; anything else found is appended.
ORDER = [
    "products.fetch", "list.timeToContent",
    "image.load", "image.network", "image.decode", "image.decodeCPU",
    "image.visibleWait", "scroll.hitch", "scroll.hitchRatio",
]


def export(trace, xpath=None, toc=False):
    cmd = ["xcrun", "xctrace", "export", "--input", trace]
    cmd += ["--toc"] if toc else ["--xpath", xpath]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return ET.fromstring(result.stdout)


def rows(root):
    """Yields each row as {column mnemonic: element}, resolving id/ref reuse."""
    if root is None or root.find(".//schema") is None:
        return
    by_id = {}
    for element in root.iter():
        if element.get("id"):
            by_id[element.get("id")] = element
    columns = [c.findtext("mnemonic") for c in root.find(".//schema").findall("col")]
    for row in root.iter("row"):
        cells = [by_id.get(c.get("ref"), c) if c.get("ref") else c for c in row]
        yield dict(zip(columns, cells))


def fmt(row, key):
    element = row.get(key)
    return None if element is None else (element.get("fmt") or element.text or "")


def parse_message(message):
    """'completed   source=network' / '4,2034   hitches=0' -> (head, {k: v})."""
    parts = (message or "").split()
    head = parts[0] if parts else ""
    attributes = dict(p.split("=", 1) for p in parts[1:] if "=" in p)
    return head, attributes


def number(text):
    # Instruments renders %f with the device locale: "4,2034" in Turkish.
    try:
        return float(text.replace(",", "."))
    except ValueError:
        return None


def percentile(sorted_values, fraction):
    """Nearest-rank, matching PerformanceAggregator."""
    if not sorted_values:
        return None
    rank = math.ceil(fraction * len(sorted_values))
    return sorted_values[min(max(rank, 1), len(sorted_values)) - 1]


def summarise(trace):
    signposts = export(
        trace,
        '/trace-toc/run[@number="1"]/data/table[@schema="os-signpost" and @category="PointsOfInterest"]',
    )
    samples = defaultdict(list)          # name -> [(value, outcome, attributes)]
    open_intervals = {}

    for row in rows(signposts):
        if fmt(row, "subsystem") != SUBSYSTEM:
            continue
        name, kind = fmt(row, "name"), fmt(row, "event-type")
        time = int(row["time"].text)
        head, attributes = parse_message(fmt(row, "message"))

        if kind == "Begin":
            open_intervals[(name, fmt(row, "identifier"))] = time
        elif kind == "End":
            start = open_intervals.pop((name, fmt(row, "identifier")), None)
            if start is not None:
                samples[name].append(((time - start) / 1e6, head or "completed", attributes))
        elif kind == "Event":
            value = number(head)
            if value is not None:
                samples[name].append((value, "completed", attributes))

    metrics = {}
    for name in ORDER + sorted(set(samples) - set(ORDER)):
        if name not in samples:
            continue
        entries = samples[name]
        completed = sorted(v for v, outcome, _ in entries if outcome == "completed")
        outcomes = Counter(outcome for _, outcome, _ in entries)
        sources = Counter(a["source"] for _, _, a in entries if "source" in a)
        metrics[name] = {
            "unit": "ms/s" if name == "scroll.hitchRatio" else "ms",
            "count": len(completed),
            "mean": sum(completed) / len(completed) if completed else None,
            "p50": percentile(completed, 0.5),
            "p90": percentile(completed, 0.9),
            "max": completed[-1] if completed else None,
            "outcomes": dict(outcomes),
            "sources": dict(sources),
        }

    hangs = [
        {"start": fmt(row, "start"), "duration": fmt(row, "duration"), "type": fmt(row, "hang-type")}
        for row in rows(export(trace, '/trace-toc/run[@number="1"]/data/table[@schema="potential-hangs"]'))
    ]

    toc = export(trace, toc=True)
    device = toc.find(".//device") if toc is not None else None
    return {
        "trace": trace,
        "device": None if device is None else f'{device.get("model")}, iOS {device.get("os-version")}',
        "template": None if toc is None else toc.findtext(".//template-name"),
        "duration_s": None if toc is None else float(toc.findtext(".//summary/duration") or 0),
        "metrics": metrics,
        "hangs": hangs,
    }


def markdown(summary):
    def f(value):
        return "–" if value is None else f"{value:.1f}"

    lines = [
        f"Trace: `{summary['trace']}`  ",
        f"Device: {summary['device']} · {summary['template']} · {summary['duration_s']:.1f} s",
        "",
        "| Metric | n | mean | p50 | p90 | max | unit | notes |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for name, m in summary["metrics"].items():
        notes = []
        other = {k: v for k, v in m["outcomes"].items() if k != "completed"}
        if other:
            notes.append(" ".join(f"{k}:{v}" for k, v in sorted(other.items())))
        if m["sources"]:
            total = sum(m["sources"].values())
            memory = m["sources"].get("memory", 0)
            notes.append(f"memory {memory}/{total} ({100 * memory // total}% hit)")
        lines.append(
            f"| `{name}` | {m['count']} | {f(m['mean'])} | {f(m['p50'])} | {f(m['p90'])} "
            f"| {f(m['max'])} | {m['unit']} | {'; '.join(notes)} |"
        )
    hangs = summary["hangs"]
    lines += ["", f"Hangs: {len(hangs)}" + "".join(
        f"\n- {h['type']} at {h['start']}, {h['duration']}" for h in hangs)]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("trace")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    summary = summarise(args.trace)
    if not summary["metrics"]:
        sys.exit(f"No {SUBSYSTEM} signposts found. Was tracing on? (-perfTracing YES for Release/Profile builds)")
    print(json.dumps(summary, indent=2) if args.json else markdown(summary))


if __name__ == "__main__":
    main()
