#!/usr/bin/env python3
"""
M3 of the German edition, step 3: check the translators' output against the English input.

    python -I check_translation.py --work work/ [--in 'chunks/in_*.jsonl'] [--out 'chunks/out_*.jsonl']

Pairs work/chunks/in_NN.jsonl with work/chunks/out_NN.jsonl by key. Errors (the text must be redone):
  missing         no German text for the key
  encoding        a character that cp1252 (the game's code page) cannot hold
  placeholders    %01, %s ... differ from the English text
  numbers         digits differ
  question        a question mark in only one of the texts
  marks           stage direction marks ([ ] * ::) differ in number
  length          German is much shorter or longer than the English text (texts over 30 characters)
  english         many common English words are left in the German text
  copy            German text equals the English text (bare names of up to four words without sentence marks are allowed)
  empty           nothing left but spaces
Warnings (written to the report, not redone): glossary terms with rule "uebersetzen" whose German form
does not appear, and key collisions between German texts and other texts.

Writes work/check_report<tag>.txt and work/bad_keys<tag>.txt (one key per line).
Exit code 0 = no errors.
"""

import argparse
import collections
import csv
import glob
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402

RATIO_MIN, RATIO_MAX = 0.6, 2.4
ENGLISH_WORDS = {"the", "you", "and", "of", "to", "is", "are", "your", "that", "with", "for", "this", "have", "will",
                 "not", "but", "from", "they", "what", "who", "can", "all", "has", "were", "was", "been", "would"}
_NUM = re.compile(r"\d+")
_WORDS = re.compile(r"[A-Za-z']+")
_MARKS = re.compile(r"\[|\]|\*|::")
_TOKEN = re.compile(r"%(?:[0-9]{1,2}|lu|l|s|d)?")


def encodable(text: str) -> bool:
    try:
        text.encode(ex.TEXT_ENCODING)
        return True
    except UnicodeEncodeError:
        return False


def problems(en: str, de) -> list:
    """List of error codes for one pair (empty = fine). `de` is None when the key is missing."""
    if de is None:
        return ["missing"]
    if not de.strip():
        return ["empty"]
    out = []
    if not encodable(de):
        out.append("encoding")
    if ex.normalize(en.encode(ex.TEXT_ENCODING, errors="replace")) == ex.normalize(de.encode(ex.TEXT_ENCODING, errors="replace")):
        if len(_WORDS.findall(de)) > 4 or re.search(r"[!?]|\.\s*$", de):  # a bare name or a short exclamation may stay as it is
            out.append("copy")
    if collections.Counter(_TOKEN.findall(en)) != collections.Counter(_TOKEN.findall(de)):
        out.append("placeholders")
    if collections.Counter(_NUM.findall(en)) != collections.Counter(_NUM.findall(de)):
        out.append("numbers")
    if ("?" in en) != ("?" in de):
        out.append("question")
    if len(_MARKS.findall(en)) != len(_MARKS.findall(de)):
        out.append("marks")
    if len(en) > 30:
        ratio = len(de) / len(en)
        if not (RATIO_MIN <= ratio <= RATIO_MAX):
            out.append("length")
    words = [w.lower() for w in _WORDS.findall(de)]
    if len(words) >= 6 and sum(w in ENGLISH_WORDS for w in words) >= max(3, len(words) // 6):
        out.append("english")
    return out


def load_glossary(path: Path):
    if not path.exists():
        return []
    entries = []
    for r in csv.DictReader(path.open(encoding="utf-8")):
        if r.get("regel") == "uebersetzen" and r.get("term_en") and r.get("term_de"):
            stem = max(re.findall(r"\w+", r["term_de"]), key=len, default="")
            if len(stem) >= 5:
                entries.append((r["term_en"].lower(), r["term_de"], stem[: max(4, len(stem) - 3)].lower()))
    return entries


def glossary_warnings(en: str, de: str, entries):
    low_en, low_de = en.lower(), de.lower()
    return [f"{t_en} -> {t_de}" for t_en, t_de, stem in entries if t_en in low_en and stem not in low_de]


def read_jsonl(path):
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def run(work: Path, in_glob: str, out_glob: str):
    entries = load_glossary(work / "glossary.csv") + load_glossary(work / "glossary_add.csv")
    inputs = {}
    for p in sorted(glob.glob(str(work / in_glob))):
        for r in read_jsonl(p):
            inputs[r["key"]] = {**r, "_file": Path(p).name}
    outputs = {}
    for p in sorted(glob.glob(str(work / out_glob))):
        for r in read_jsonl(p):
            outputs[r["key"]] = r["de"]
    errors, warns, bad = collections.Counter(), [], []
    detail = []
    for key, r in inputs.items():
        de = outputs.get(key)
        codes = problems(r["en"], de)
        if codes:
            bad.append(key)
            errors.update(codes)
            detail.append(f"{key} {r['source']} [{','.join(codes)}]")
        elif entries:
            for w in glossary_warnings(r["en"], de, entries):
                warns.append(f"{key} {r['source']}: {w}")
    extra = [k for k in outputs if k not in inputs]
    collisions = collections.defaultdict(list)
    for key, de in outputs.items():
        if de and key in inputs:
            collisions[ex.text_key(de.encode(ex.TEXT_ENCODING, errors="replace"))].append(key)
    clash = [(k, v) for k, v in collisions.items() if len(v) > 1 or k in inputs]
    return inputs, outputs, errors, warns, bad, detail, extra, clash


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--in", dest="in_glob", default="chunks/in_*.jsonl")
    ap.add_argument("--out", dest="out_glob", default="chunks/out_*.jsonl")
    ap.add_argument("--tag", default="", help="suffix for the report files, so parallel runs do not overwrite each other")
    args = ap.parse_args(argv)

    inputs, outputs, errors, warns, bad, detail, extra, clash = run(args.work, args.in_glob, args.out_glob)
    lines = [f"texts: {len(inputs)}  translated: {len(inputs) - errors['missing']}  with errors: {len(bad)}",
             "errors: " + (", ".join(f"{k}={n}" for k, n in errors.most_common()) or "none"),
             f"keys in output but not in input: {len(extra)}",
             f"glossary warnings: {len(warns)}",
             f"key collisions of German texts: {len(clash)}"]
    lines += ["", "-- errors --"] + detail + ["", "-- glossary warnings --"] + warns[:400]
    lines += ["", "-- collisions --"] + [f"{k}: {' '.join(v)}" for k, v in clash]
    (args.work / f"check_report{args.tag}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (args.work / f"bad_keys{args.tag}.txt").write_text("".join(k + "\n" for k in bad), encoding="utf-8")
    print("\n".join(lines[:5]))
    return 1 if bad or extra else 0


if __name__ == "__main__":
    sys.exit(main())
