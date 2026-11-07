#!/usr/bin/env python3
"""
German edition: recordings of the skill teachers without the sentence that holds the numbers.

    <python with faster_whisper and numpy> teacher_cuts.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/

zzMAW-Skills.lua puts the player's own skill requirement and price into the teacher's text when the dialog opens, so the
shown text has no recording. The text without its last sentence that contains a digit stays the same. This script cuts
the recording of every teacher text at the start of that sentence (the cut is found with faster-whisper word times) and
saves it under the key of the shortened text: work/audio_de/<key>.ogg (also -m / -f variants).
The sentence rule is the same as tailShapes() in zzzMaw_NPCVoices.lua: a sentence ends at . ! ? followed by white
space, but not after a digit (the ordinal "10. Rang" does not end one).

Writes work/teacher_cuts_report.txt.
"""

import argparse
import csv
import re
import subprocess
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402

FADE = 0.08


def sentences(text: str):
    """[(start, end)] of the sentences; a sentence ends at . ! ? plus white space, not after a digit."""
    out, start, i = [], 0, 0
    while i < len(text):
        if text[i] in ".!?" and i + 1 < len(text) and text[i + 1].isspace() and not (i > 0 and text[i - 1].isdigit()):
            out.append((start, i + 1))
            j = i + 1
            while j < len(text) and text[j].isspace():
                j += 1
            start, i = j, j
        else:
            i += 1
    if start < len(text):
        out.append((start, len(text)))
    return out


def shortened(text: str):
    """The text without its last sentence that holds a digit (and what follows), or None."""
    spans = sentences(text)
    for k in range(len(spans) - 1, -1, -1):
        if re.search(r"\d", text[spans[k][0]:spans[k][1]]):
            return text[:spans[k][0]].rstrip() if k > 0 else None
    return None


def letters(s: str) -> int:
    return sum(c.isalpha() for c in s)


def decode(path: Path) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-ac", "1", "-ar", "16000", "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, "<i2").astype("float32") / 32768


def cut_time(model, audio: np.ndarray, prefix: str):
    segments, _ = model.transcribe(audio, language="de", word_timestamps=True)
    words = [w for s in segments for w in s.words]
    target, total = letters(prefix), 0
    best = None
    for k, w in enumerate(words):
        total += letters(w.word)
        diff = abs(total - target)
        if best is None or diff < best[0]:
            best = (diff, k)
        if total >= target:
            break
    if best is None or best[1] + 1 >= len(words):
        return None, 0
    k = best[1]
    gap_start, gap_end = words[k].end, words[k + 1].start
    return min(gap_start + 0.25, (gap_start + gap_end) / 2), best[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    args = ap.parse_args()
    from faster_whisper import WhisperModel
    model = WhisperModel("small", device="cpu", compute_type="int8")

    ids = set(range(298, 298 + 3 * 40))
    table = (args.game / "Data" / "Tables" / "Teacher topics.txt").read_bytes().decode("cp1252").splitlines()
    for line in table[1:]:
        cols = line.split(chr(9))
        if len(cols) > 4 and cols[4].strip().isdigit():
            ids.add(int(cols[4]))

    texts = {}
    with (args.work / "texts_de.csv").open(encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            m = re.match(r"NPCText (\d+)$", r["source"])
            if m and int(m.group(1)) in ids and r["kind"] == "topic":
                texts[int(m.group(1))] = r

    audio_dir = args.work / "audio_de"
    report, done = [], set()
    for tid, r in sorted(texts.items()):
        de = r["text_de"].replace(chr(13), "")
        prefix = shortened(de)
        if not prefix or letters(prefix) < 20:
            report.append(f"{tid}\tskipped\tno digit sentence or too short")
            continue
        key = ex.text_key(prefix.encode("cp1252", errors="replace"))
        for suffix in ("", "-m", "-f"):
            src = audio_dir / f"{r['key_de']}{suffix}.ogg"
            dst = audio_dir / f"{key}{suffix}.ogg"
            if not src.exists() or dst in done:
                continue
            seconds, miss = cut_time(model, decode(src), prefix)
            if seconds is None:
                report.append(f"{tid}\tfailed\t{src.name}")
                continue
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-t", f"{seconds:.3f}",
                            "-af", f"afade=t=out:st={max(seconds - FADE, 0):.3f}:d={FADE}", "-c:a", "libvorbis", str(dst)], check=True)
            done.add(dst)
            report.append(f"{tid}\tok\t{dst.name}\t{seconds:.2f}s\tletter diff {miss}\t{prefix[-40:]!r}")
    (args.work / "teacher_cuts_report.txt").write_text(chr(10).join(report) + chr(10), encoding="utf-8")
    print(len(done), "recordings;", sum(1 for x in report if "\tskipped" in x), "skipped;", sum(1 for x in report if "\tfailed" in x), "failed")


if __name__ == "__main__":
    main()
