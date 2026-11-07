#!/usr/bin/env python3
"""
M6 of the German edition: write the German texts as the files the language module reads.

    python -I export_localization.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/ --out work/localization_de

Reads  work/texts_de.csv (build_texts_de.py) and the text tables of Data/mmmerge.T.lod.
Writes <out>/10_NPCGreet.txt, 11_NPCText.txt, 12_NPCNews.txt: one row per table cell whose English text is in
the set, "Table<TAB>Id<TAB>Field<TAB>Text", cp1252, CRLF, header line first, \\n \\t \\\\ as escapes
(Scripts/General/zzzMaw_Language.lua reads them). A text that several cells share is written once per cell.
Field is empty for NPCText and NPCNews, and 0 / 1 for the two greetings of an NPCGreet row.
Exit code 0 = every German text was written to at least one cell.
"""

import argparse
import csv
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import extract_texts as ex  # noqa: E402
import groups  # noqa: E402

HEADER = "Table\tId\tField\tText"


def escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t").replace("\r", "")


def cells(lod):
    """(table, id, field, raw bytes) for every dialog text cell of the three tables."""
    for r in ex.parse_table(lod["npcgreet.txt"])[1:]:
        gid = ex.row_id(ex.cell(r, 0))
        if gid is not None:
            for col in (1, 2):
                yield "NPCGreet", gid, str(col - 1), ex.cell(r, col)
    for r in ex.parse_table(lod["npctext.txt"])[1:]:
        tid = ex.row_id(ex.cell(r, 0))
        if tid is not None:
            yield "NPCText", tid, "", ex.cell(r, 1)
    for r in ex.parse_table(lod["npcnews.txt"])[1:]:
        nid = ex.row_id(ex.cell(r, 0))
        if nid is not None:
            yield "NPCNews", nid, "", ex.cell(r, 1)


def export(game: Path, work: Path, out: Path):
    german = {r["key_en"]: r["text_de"] for r in csv.DictReader((work / "texts_de.csv").open(encoding="utf-8"))}
    lod = ex.read_lod(game / "Data/mmmerge.T.lod")
    # the dialogs of the people of shops and huts go to <out>/shops/ (groups.py): German only for German shops
    shop_cells, _shop_topics = groups.compute(game, lod)
    lines = {"NPCGreet": [], "NPCText": [], "NPCNews": []}
    shops = {"NPCGreet": [], "NPCText": [], "NPCNews": []}
    used = set()
    # dialog cells that the hand-made rows (data/mod_texts*_de.csv, export_ui.py) set: not written here as well
    hand = set()
    for name in ("mod_texts_de.csv", "mod_texts2_de.csv"):
        path = HERE / "data" / name
        if path.exists():
            for line in path.read_text(encoding="utf-8").splitlines():
                parts = line.split(";", 2)
                if parts[0] in lines and len(parts) > 1 and parts[1].isdigit():
                    hand.add((parts[0], int(parts[1])))
    for table, ident, field, raw in cells(lod):
        if not ex.is_speech(raw) or (table, ident) in hand:
            continue
        key = ex.text_key(raw)
        text = german.get(key)
        if text is None:
            continue
        used.add(key)
        (shops if (table, ident) in shop_cells else lines)[table].append(f"{table}\t{ident}\t{field}\t{escape(text)}")
    out.mkdir(parents=True, exist_ok=True)
    (out / "shops").mkdir(exist_ok=True)
    for number, table in ((10, "NPCGreet"), (11, "NPCText"), (12, "NPCNews")):
        body = "\r\n".join([HEADER] + lines[table]) + "\r\n"
        (out / f"{number}_{table}.txt").write_bytes(body.encode(ex.TEXT_ENCODING))
        body = "\r\n".join([HEADER] + shops[table]) + "\r\n"
        (out / "shops" / f"{number}_{table}.txt").write_bytes(body.encode(ex.TEXT_ENCODING))
    print("shops group:", {t: len(v) for t, v in shops.items()})
    return {t: len(v) + len(shops[t]) for t, v in lines.items()}, set(german) - used


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args(argv)
    counts, unused = export(args.game, args.work, args.out)
    print("rows written: " + ", ".join(f"{t}={n}" for t, n in counts.items()) + f" (total {sum(counts.values())})")
    if unused:
        print(f"{len(unused)} German texts have no cell in the tables (Lua quest lines are not exported here)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
