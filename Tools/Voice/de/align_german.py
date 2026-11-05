#!/usr/bin/env python3
"""
M2 of the German edition: which English dialog texts already have a German original?

Reads the dialog tables (NPCGreet, NPCText, NPCNews) of the MMMerge text LOD and of
Data/GermanT.lod, pairs the cells by table, row number and column, checks every pair
with cheap structural tests (numbers, placeholders, question marks, length ratio) and
writes

  texts_de_base.csv   one row per distinct English text (key as in texts.csv):
                      key, kind, source, status, reason, text_en, text_de_orig
  glossary_raw.csv    capitalised English words with how often the German original
                      keeps or replaces them (raw material for the glossary)
  coverage.txt        the numbers of the report

status: ok       German original found and passes the tests
        suspect  found, but a test fails (the pairing may be wrong): treated as open
        none     no German row, an empty one, or a copy of the English text

    python -I align_german.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --out work/

Quote marks, line breaks and spacing are not compared; the tests are deliberately
loose, so "ok" means "plausibly the same text", and the sample in M3 decides the rest.
"""

import argparse
import collections
import csv
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402

TABLES = (  # (LOD entry, kind, columns holding text, label)
    ("npcgreet.txt", "greeting", (1, 2), "NPCGreet"),
    ("npctext.txt", "topic", (1,), "NPCText"),
    ("npcnews.txt", "news", (1,), "NPCNews"),
)

RATIO_MIN, RATIO_MAX = 0.55, 2.4
_NUM = re.compile(rb"\d+")
_WORD = re.compile(r"\b[A-Z][a-zA-Z']{3,}\b")
_STOP = {"this", "that", "with", "what", "when", "where", "there", "their", "your", "have", "they", "will",
         "from", "then", "were", "been", "would", "could", "should", "about", "which", "these", "those",
         "well", "just", "now", "yes", "very", "please", "thank", "thanks", "hello", "welcome", "good", "come",
         "here", "again", "sorry", "perhaps", "maybe", "indeed", "also", "only", "even", "still", "some"}


def cell_id(raw: bytes) -> bytes:
    """Row number including an optional suffix ("381 M"), as the key that pairs English and German rows."""
    return raw.strip()


def table_cells(lod: dict, entry: str, cols):
    """{(row id, column): raw cell} of the first row with each id."""
    out = {}
    for r in ex.parse_table(lod[entry])[1:]:
        rid = cell_id(ex.cell(r, 0))
        if ex.row_id(rid) is None:
            continue
        for c in cols:
            out.setdefault((rid, c), ex.cell(r, c))
    return out


def check_pair(en: bytes, de: bytes):
    """Return (status, reason) for one English/German pair."""
    if not de.strip() or not ex.is_speech(de):
        return "none", "empty"
    en_n, de_n = ex.normalize(en), ex.normalize(de)
    if en_n == de_n:
        return "none", "copy of the English text"
    reasons = []
    if collections.Counter(_NUM.findall(en)) != collections.Counter(_NUM.findall(de)):
        reasons.append("numbers differ")
    if collections.Counter(ex._TOKEN.findall(en)) != collections.Counter(ex._TOKEN.findall(de)):
        reasons.append("placeholders differ")
    if (b"?" in en) != (b"?" in de):
        reasons.append("question mark differs")
    ratio = len(de_n) / max(1, len(en_n))
    if not (RATIO_MIN <= ratio <= RATIO_MAX) and len(en_n) > 30:
        reasons.append(f"length ratio {ratio:.2f}")
    return ("suspect", "; ".join(reasons)) if reasons else ("ok", "")


RANK = {"ok": 0, "suspect": 1, "none": 2}


def build_pairs(game: Path, german_lod: Path = None, lod_rel: str = "Data/mmmerge.T.lod"):
    """Return {key: row} for every distinct English dialog text of the tables."""
    en_lod = ex.read_lod(game / lod_rel)
    de_lod = ex.read_lod(german_lod or game / "Data" / "GermanT.lod")
    rows = collections.OrderedDict()
    for entry, kind, cols, label in TABLES:
        en_cells = table_cells(en_lod, entry, cols)
        de_cells = table_cells(de_lod, entry, cols) if entry in de_lod else {}
        for (rid, col), en in en_cells.items():
            if not ex.is_speech(en):
                continue
            key = ex.text_key(en)
            de = de_cells.get((rid, col), b"")
            status, reason = check_pair(en, de)
            row = rows.get(key)
            cand = {"key": key, "kind": kind, "source": f"{label} {rid.decode()}.{col}", "status": status,
                    "reason": reason, "text_en": ex.decode(en), "text_de_orig": ex.decode(de) if status != "none" else "",
                    "template": int(ex.has_placeholder(en)), "n_sources": 1}
            if row is None:
                rows[key] = cand
            else:
                row["n_sources"] += 1
                if RANK[status] < RANK[row["status"]]:
                    cand["n_sources"] = row["n_sources"]
                    rows[key] = cand
    return rows


def glossary(rows):
    """Capitalised English words and whether the aligned German original keeps them."""
    kept, gone = collections.Counter(), collections.Counter()
    for r in rows.values():
        if r["status"] != "ok":
            continue
        de_low = r["text_de_orig"].lower()
        for w in set(_WORD.findall(r["text_en"])):
            if w.lower() in _STOP:
                continue
            (kept if w.lower() in de_low else gone)[w] += 1
    return kept, gone


def report(rows):
    lines = []
    tot = collections.Counter()
    for kind in ("greeting", "topic", "news"):
        sel = [r for r in rows.values() if r["kind"] == kind]
        c = collections.Counter(r["status"] for r in sel)
        tot.update(c)
        lines.append(f"{kind:9} distinct={len(sel):5} ok={c['ok']:5} suspect={c['suspect']:4} none={c['none']:5}")
    lines.append(f"{'total':9} distinct={sum(tot.values()):5} ok={tot['ok']:5} suspect={tot['suspect']:4} none={tot['none']:5}")
    chars = collections.Counter()
    for r in rows.values():
        chars[r["status"]] += len(ex.speech_text(r["text_en"].encode(ex.TEXT_ENCODING, errors="replace")))
    lines.append(f"characters ok={chars['ok']} suspect={chars['suspect']} none={chars['none']} "
                 f"(open = suspect + none = {chars['suspect'] + chars['none']})")
    why = collections.Counter()
    for r in rows.values():
        if r["status"] == "suspect":
            for part in r["reason"].split("; "):
                why[part.split(" ")[0] + " " + (part.split(" ")[1] if " " in part else "")] += 1
    lines.append("suspect reasons: " + ", ".join(f"{k.strip()}={n}" for k, n in why.most_common()))
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--german", type=Path, help="German text LOD (default Data/GermanT.lod of --game)")
    ap.add_argument("--out", required=True, type=Path, help="output folder")
    args = ap.parse_args(argv)

    rows = build_pairs(args.game, args.german)
    args.out.mkdir(parents=True, exist_ok=True)
    fields = ["key", "kind", "source", "n_sources", "template", "status", "reason", "text_en", "text_de_orig"]
    with (args.out / "texts_de_base.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows.values())
    kept, gone = glossary(rows)
    with (args.out / "glossary_raw.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["term", "kept_in_german", "absent_in_german", "verdict"])
        for term in sorted(set(kept) | set(gone), key=lambda t: -(kept[t] + gone[t])):
            k, g = kept[term], gone[term]
            verdict = "stays English" if k >= 3 * max(1, g) else "translated" if g >= 3 * max(1, k) else "mixed"
            w.writerow([term, k, g, verdict])
    text = report(rows)
    (args.out / "coverage.txt").write_text(text + "\n", encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
