#!/usr/bin/env python3
"""
Lists the English rows of the game tables that have no German text (export_ui.py left them out).

    python dump_untranslated.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --ui work/localization_de_ui --out work/untranslated_en.csv

Output: Table;Id;Field;English (utf-8, semicolon separated, line breaks written as backslash-n). The German goes into
data/mod_texts_de.csv (Table;Id;German) or data/mod_texts2_de.csv (Table;Id;Field;German); export_ui.py takes it from there.
"""

import argparse
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import export_ui as eu  # noqa: E402
import extract_texts as ex  # noqa: E402

SKIP = ("StatsDescriptions", "SkillDescriptions", "SkillDesNormal", "SkillDesExpert",
        "SkillDesMaster", "SkillDesGM", "HistoryTxt")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--ui", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args()
    lod = ex.read_lod(args.game / "Data" / "mmmerge.T.lod")
    done = set()
    for f in list(args.ui.glob("*.txt")) + list((args.ui / "shops").glob("*.txt")):
        for line in f.read_bytes().decode("cp1252").splitlines()[1:]:
            parts = line.split(eu.TAB)
            if len(parts) >= 3:
                done.add((parts[0], parts[1], parts[2]))
    out = []
    for entry, game, fields, kind, *_ in eu.TABLES:
        if game in SKIP:
            continue
        for rid, row in eu.rows_of(lod, entry, kind == "ordinal").items():
            if rid > eu.MAX_ID.get(game, 10 ** 9):
                continue
            for field, col in fields.items():
                text = ex.decode(ex.cell(row, col))
                if (game, str(rid), field) in done or not any(c.isalpha() for c in text):
                    continue
                out.append(";".join([game, str(rid), field, text.replace(chr(10), eu.BS + "n").replace(chr(13), "")]))
    args.out.write_text(chr(10).join(out) + chr(10), encoding="utf-8")
    counts = {}
    for line in out:
        counts[line.split(";", 1)[0]] = counts.get(line.split(";", 1)[0], 0) + 1
    print(len(out), "rows", counts)


if __name__ == "__main__":
    main()
