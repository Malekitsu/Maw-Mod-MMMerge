#!/usr/bin/env python3
"""
M3 of the German edition, step 4: merge the German originals and the checked translations into one table.

    python -I build_texts_de.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/ [--sample 100]

Reads  work/texts_de_base.csv       (align_german.py: status ok = a German original exists)
       work/chunks/in_*.jsonl and out_*.jsonl   (the translations of everything else)
Writes work/texts_de.csv            one row per distinct English text of the phase-1 set:
                                    key_en, key_de, kind, source, herkunft (original|ki), template,
                                    text_en, text_de
       work/stichprobe.md           a random sample of the AI translations for reading through
                                    (every text with a run-time placeholder is added)

Checks acceptance criterion K1: every text of the phase-1 set (all distinct dialog texts of NPCGreet, NPCText,
NPCNews and the Lua quest lines) has a German text, no placeholder is lost, and every row has an origin.
Exit code 0 = K1 holds.
"""

import argparse
import collections
import csv
import json
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import extract_texts as ex  # noqa: E402
import check_translation as ct  # noqa: E402

FIELDS = ["key_en", "key_de", "kind", "source", "herkunft", "template", "text_en", "text_de"]


def load_translations(work: Path):
    ins, outs = {}, {}
    for p in sorted((work / "chunks").glob("in_*.jsonl")):
        for r in ct.read_jsonl(p):
            ins[r["key"]] = r
    for p in sorted((work / "chunks").glob("out_*.jsonl")):
        for r in ct.read_jsonl(p):
            outs[r["key"]] = r["de"]
    return ins, outs


def load_overrides():
    """Hand-made corrections that win over the translators' output (data/overrides.csv: key_en, source, text_de, reason)."""
    path = HERE / "data" / "overrides.csv"
    if not path.exists():
        return {}
    return {r["key_en"]: r["text_de"] for r in csv.DictReader(path.open(encoding="utf-8"))}


FORCED_REASON = "wrong German original"


def load_forced():
    """Keys whose German original (found by row number) says something else than the English text of the mod: their
    override (data/overrides.csv, reason 'wrong German original') replaces the original."""
    path = HERE / "data" / "overrides.csv"
    if not path.exists():
        return set()
    return {r["key_en"] for r in csv.DictReader(path.open(encoding="utf-8")) if r["reason"].startswith(FORCED_REASON)}


def build(game: Path, work: Path):
    out, _, _ = ex.build(game)
    base = {r["key"]: r for r in csv.DictReader((work / "texts_de_base.csv").open(encoding="utf-8"))}
    ins, outs = load_translations(work)
    outs.update(load_overrides())
    forced = load_forced()
    rows, problems = [], []
    for key, r in out.rows.items():
        b = base.get(key)
        if b is not None and b["status"] == "ok" and key not in forced:
            herkunft, de = "original", b["text_de_orig"].strip()
            en = ex.decode(r["raw"]).strip()
        else:
            herkunft = "ki"
            de = outs.get(key)
            en = ins[key]["en"] if key in ins else ex.decode(r["raw"]).strip()
            if de is None:
                if r["kind"] != "global":  # GlobalTxt lines are German through the UI tables (export_ui.py), not here
                    problems.append(f"{key} {r['source']}: no translation")
                continue
        codes = ct.problems(en, de) if herkunft == "ki" else []
        if codes:
            problems.append(f"{key} {r['source']}: {','.join(codes)}")
        rows.append({"key_en": key, "key_de": ex.text_key(de.encode(ex.TEXT_ENCODING, errors="replace")),
                     "kind": r["kind"], "source": r["source"], "herkunft": herkunft, "template": r["template"],
                     "text_en": en, "text_de": de})
    return rows, problems


def write_sample(rows, path: Path, n: int, seed: int = 7):
    ki = [r for r in rows if r["herkunft"] == "ki"]
    rnd = random.Random(seed)
    picked = rnd.sample(ki, min(n, len(ki)))
    seen = {r["key_en"] for r in picked}
    picked += [r for r in ki if r["template"] and r["key_en"] not in seen][:40]
    lines = ["# Stichprobe der KI-Übersetzungen", "",
             f"{len(picked)} Texte, zufällig gewählt (Startwert {seed}) plus bis zu 40 Texte mit Platzhaltern. "
             "Links die Quelle, darunter Englisch und Deutsch.", ""]
    for i, r in enumerate(picked, 1):
        lines += [f"**{i}. {r['source']}** (Schlüssel {r['key_en']}, {r['kind']})", "",
                  "> EN: " + r["text_en"].replace("\n", " / "), ">", "> DE: " + r["text_de"].replace("\n", " / "), ""]
    path.write_text("\n".join(lines), encoding="utf-8")
    return len(picked)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--sample", type=int, default=100)
    args = ap.parse_args(argv)

    rows, problems = build(args.game, args.work)
    with (args.work / "texts_de.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        w.writeheader()
        w.writerows(rows)
    n = write_sample(rows, args.work / "stichprobe.md", args.sample)
    by = collections.Counter((r["kind"], r["herkunft"]) for r in rows)
    print(f"{len(rows)} rows -> texts_de.csv; sample of {n} -> stichprobe.md")
    print("  " + ", ".join(f"{k}/{h}={c}" for (k, h), c in sorted(by.items())))
    clash = collections.defaultdict(list)
    for r in rows:
        clash[r["key_de"]].append(r["key_en"])
    shared = sum(1 for v in clash.values() if len(v) > 1)
    print(f"  distinct German texts: {len(clash)} (shared by several English texts: {shared})")
    if problems:
        print(f"K1 FAILED: {len(problems)} problems")
        for p in problems[:30]:
            print("  " + p)
        return 1
    print("K1 holds: every phase-1 text has a German text, placeholders intact")
    return 0


if __name__ == "__main__":
    sys.exit(main())
