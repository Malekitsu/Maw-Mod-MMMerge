#!/usr/bin/env python3
"""
Quality gate for generated voice files. Objective checks only (nobody listens
to 10 hours of audio): every file must decode, have a plausible length for its
text, a sane level, no clipping and no long dropouts.

    python qa_voices.py texts.csv --dir Data/Voices/NPC --report qa_report.csv --bad-keys bad_keys.txt

Needs numpy and ffmpeg. Exit code 0 = every selected row has a clean file.
Regenerate failures with:  generate_voices.py ... --keys bad_keys.txt --force

Checks per file
  missing / undecodable / shorter than 0.4 s
  speed       spoken characters (stage directions do not count) per second outside 9..32
              (texts over 40 characters); a cut-off
              or runaway synthesis shows up here
  level       RMS outside -30..-14 dBFS (the generator levels to about -21)
  clipping    samples at full scale
  dropout     a silence of more than 3.5 s inside the file
"""

import argparse
import csv
import importlib.util
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np

_spec = importlib.util.spec_from_file_location("generate_voices", Path(__file__).resolve().parent / "generate_voices.py")
_gv = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_gv)

RATE = 24000
LIMITS = {"cps": (9.0, 32.0), "rms_db": (-30.0, -14.0), "max_gap_s": 3.5, "min_s": 0.4}


def decode(path: Path):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
                       capture_output=True)
    if r.returncode != 0 or not r.stdout:
        return None
    return np.frombuffer(r.stdout, dtype="<f4")


def longest_gap(x) -> float:
    """Longest run of near-silence (seconds) between the first and the last sound."""
    win = RATE // 50  # 20 ms
    n = len(x) // win
    if n == 0:
        return 0.0
    env = np.sqrt(np.mean(x[: n * win].reshape(n, win) ** 2, axis=1))
    loud = np.where(env > 0.004)[0]
    if loud.size == 0:
        return len(x) / RATE
    gaps = np.diff(loud) - 1
    return float(gaps.max() * win / RATE) if gaps.size else 0.0


def check(row, directory: Path, alt: bool = False):
    key = _gv.stem(row, alt)
    path = next((directory / f"{key}{e}" for e in (".ogg", ".wav") if (directory / f"{key}{e}").exists()), None)
    res = {"key": row["key"], "chars": len(_gv.prepare_speech(row["text"])), "seconds": 0.0, "cps": 0.0, "rms_db": 0.0, "peak": 0.0,
           "max_gap_s": 0.0, "flags": []}
    if path is None:
        res["flags"].append("missing")
        return res
    x = decode(path)
    if x is None:
        res["flags"].append("undecodable")
        return res
    res["seconds"] = len(x) / RATE
    if res["seconds"] < LIMITS["min_s"]:
        res["flags"].append("too-short")
    res["cps"] = res["chars"] / max(res["seconds"], 1e-6)
    if res["chars"] > 40 and not LIMITS["cps"][0] <= res["cps"] <= LIMITS["cps"][1]:
        res["flags"].append("speed")
    active = x[np.abs(x) > 0.02]
    rms = float(np.sqrt(np.mean(active ** 2))) if active.size else 0.0
    res["rms_db"] = 20 * np.log10(rms) if rms > 0 else -99.0
    if not LIMITS["rms_db"][0] <= res["rms_db"] <= LIMITS["rms_db"][1]:
        res["flags"].append("level")
    res["peak"] = float(np.max(np.abs(x)))
    if res["peak"] >= 0.999:
        res["flags"].append("clipping")
    res["max_gap_s"] = longest_gap(x)
    if res["max_gap_s"] > LIMITS["max_gap_s"]:
        res["flags"].append("dropout")
    return res


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv", type=Path)
    ap.add_argument("--dir", required=True, type=Path, help="directory with the audio files")
    ap.add_argument("--report", type=Path, help="write all metrics here")
    ap.add_argument("--bad-keys", type=Path, help="write the keys of failing files here")
    ap.add_argument("--templates", action="store_true", help="also rows with run-time placeholders")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--alt", action="store_true", help="check the other-voice files (<key>-m / <key>-f) instead")
    args = ap.parse_args(argv)

    with args.csv.open(encoding="utf-8", newline="") as f:
        rows = [r for r in csv.DictReader(f) if args.templates or r["template"] != "1"]
    # texts made only of stage directions have nothing to speak and get no file
    rows = [r for r in rows if _gv.prepare_speech(r["text"])]
    with ThreadPoolExecutor(args.jobs) as pool:
        results = list(pool.map(lambda r: check(r, args.dir, args.alt), rows))

    bad = [r for r in results if r["flags"]]
    total = sum(r["seconds"] for r in results)
    print(f"{len(results)} rows, {len(results) - len(bad)} clean, {len(bad)} flagged, {total / 3600:.2f} h of audio")
    counts = {}
    for r in bad:
        for fl in r["flags"]:
            counts[fl] = counts.get(fl, 0) + 1
    for fl, n in sorted(counts.items()):
        print(f"  {fl}: {n}")
    by_key = {r["key"]: r for r in rows}
    for r in bad[:25]:
        print(f"  {r['key']} {','.join(r['flags']):14} {r['seconds']:6.1f}s {r['cps']:5.1f} cps {r['rms_db']:6.1f} dB  "
              f"{by_key[r['key']]['text'][:60]}")
    if args.report:
        with args.report.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["key", "chars", "seconds", "cps", "rms_db", "peak", "max_gap_s", "flags"])
            for r in results:
                w.writerow([r["key"], r["chars"], f"{r['seconds']:.2f}", f"{r['cps']:.1f}", f"{r['rms_db']:.1f}",
                            f"{r['peak']:.3f}", f"{r['max_gap_s']:.2f}", " ".join(r["flags"])])
    if args.bad_keys:
        args.bad_keys.write_text("\n".join(r["key"] for r in bad) + ("\n" if bad else ""), encoding="utf-8")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
