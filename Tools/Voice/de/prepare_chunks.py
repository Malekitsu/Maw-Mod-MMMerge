#!/usr/bin/env python3
"""
M3 of the German edition, step 1: cut the open texts (no German original, or a doubtful one,
plus the Lua quest lines) into work packages for the translators.

    python -I prepare_chunks.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/ [--chars 16000]

Reads  work/texts_de_base.csv (from align_german.py)
Writes work/chunks/in_NN.jsonl   one JSON object per line: key, kind, source, speakers, gender, en
       work/style_sample.jsonl   a few aligned original pairs as a style reference

The packages are ordered by kind and table row, so neighbouring rows (usually one NPC) stay together.
"""

import argparse
import csv
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402


def sort_key(row):
    m = re.search(r"(\d+)(?:\.(\d+))?", row["source"])
    num = int(m.group(1)) if m else 0
    sub = int(m.group(2) or 0) if m else 0
    return ({"topic": 0, "greeting": 1, "news": 2, "lua": 3}.get(row["kind"], 4), row["source"].split(" ")[0], num, sub)


def open_rows(game: Path, work: Path):
    """Open rows as dicts: key, kind, source, speakers, gender, en (the text exactly as in the table, cp1252 decoded)."""
    out, _, _ = ex.build(game)
    base = {r["key"]: r for r in csv.DictReader((work / "texts_de_base.csv").open(encoding="utf-8"))}
    rows = []
    for key, r in out.rows.items():
        b = base.get(key)
        if b is not None and b["status"] == "ok":
            continue
        rows.append({"key": key, "kind": r["kind"], "source": r["source"], "speakers": r["speakers"][:3],
                     "gender": r["gender"], "en": ex.decode(r["raw"]).strip()})
    rows.sort(key=sort_key)
    return rows


def cut(rows, max_chars):
    chunks, cur, size = [], [], 0
    for r in rows:
        n = len(r["en"]) + 80
        if cur and size + n > max_chars:
            chunks.append(cur)
            cur, size = [], 0
        cur.append(r)
        size += n
    if cur:
        chunks.append(cur)
    return chunks


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--chars", type=int, default=16000, help="characters of English text per package")
    args = ap.parse_args(argv)

    rows = open_rows(args.game, args.work)
    chunks = cut(rows, args.chars)
    cdir = args.work / "chunks"
    cdir.mkdir(parents=True, exist_ok=True)
    for old in cdir.glob("in_*.jsonl"):
        old.unlink()
    for i, chunk in enumerate(chunks, 1):
        with (cdir / f"in_{i:02d}.jsonl").open("w", encoding="utf-8", newline="\n") as f:
            for r in chunk:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")

    base = list(csv.DictReader((args.work / "texts_de_base.csv").open(encoding="utf-8")))
    sample = [r for r in base if r["status"] == "ok" and 120 < len(r["text_en"]) < 420][::37][:14]
    with (args.work / "style_sample.jsonl").open("w", encoding="utf-8", newline="\n") as f:
        for r in sample:
            f.write(json.dumps({"kind": r["kind"], "en": r["text_en"], "de": r["text_de_orig"]}, ensure_ascii=False) + "\n")
    print(f"{len(rows)} open texts, {sum(len(r['en']) for r in rows)} characters -> {len(chunks)} packages in {cdir}")


if __name__ == "__main__":
    main()
