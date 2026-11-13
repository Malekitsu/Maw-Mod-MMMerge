#!/usr/bin/env python3
"""
M5 of the German edition: sort the dialog texts into recording packages by game (MM7 first).

    python -I prioritize.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/

MMMerge keeps the texts of MM6, MM7 and MM8 in one table, with no game tag. The game is derived from
  1. the NPC numbers in NPCData: 1-341 = MM8, 342-797 = MM7, 798 and up = MM6 (checked against place names)
  2. the NPCText number for texts no NPC points to: up to 929 = MM8, 930-1699 = MM7, 1700-2199 = MM6,
     from 2200 on = additions of MAW (all games)
  3. place-name keywords for street news (NPCNews has no NPC and no game link)

Writes work/prioritaet.csv: key_en, key_de, paket, chars, source, gender (m/f), template (0/1), with paket one of
  mm7, mm7-news, mm8, mm6, maw, news
and prints the number of texts and characters per package. Order of recording: mm7, mm7-news, maw, news, mm8, mm6.
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

ORDER = ["mm7", "mm7-news", "maw", "news", "mm8", "mm6"]
MM7_WORDS = re.compile(r"Harmondale|Tatalia|Bracada|Deyja|Erathia|Avlee|Steadwick|Nighon|Tularean|Pierpont|Stone City|Eofol|Celeste|Barrow Downs|Mount Nighon")
OTHER_WORDS = re.compile(r"Enroth|Sweet Water|Free Haven|Blackshire|Kriegspire|Stromgard|Jadame|Alvar|Dagger|Ravage|Paradise Valley|Ravenshore|Lincoln|Shadowspire|Murmurwoods")


def npc_game(i: int) -> str:
    return "mm8" if i < 342 else ("mm7" if i <= 797 else "mm6")


def text_number_game(n: int) -> str:
    return "mm8" if n < 930 else ("mm7" if n < 1700 else ("mm6" if n < 2200 else "maw"))


def classify(row, name_ids) -> str:
    votes = collections.Counter(npc_game(i) for s in row["speakers"] for i in name_ids.get(s, []))
    if row["kind"] == "news":
        text = ex.decode(row["raw"])
        if MM7_WORDS.search(text) and not OTHER_WORDS.search(text):
            return "mm7-news"
        return "news"
    if row["kind"] == "lua":
        return "maw"
    if votes:
        game = votes.most_common(1)[0][0]
        m = re.match(r"NPCText (\d+)", row["source"])
        if m and game == "mm8" and int(m.group(1)) >= 2200:
            return "maw"
        return game
    m = re.match(r"NPCText (\d+)", row["source"])
    return text_number_game(int(m.group(1))) if m else "maw"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    args = ap.parse_args(argv)

    out, _, lod = ex.build(args.game)
    npcs = ex.load_npcs(lod["npcdata.txt"])
    name_ids = collections.defaultdict(list)
    for i, v in npcs.items():
        name_ids[v["name"]].append(i)
    de = {r["key_en"]: r for r in csv.DictReader((args.work / "texts_de.csv").open(encoding="utf-8"))}

    rows = []
    for key, r in out.rows.items():
        if key not in de:  # GlobalTxt lines: German through the UI tables
            continue
        rows.append({"key_en": key, "key_de": de[key]["key_de"], "paket": classify(r, name_ids),
                     "chars": len(de[key]["text_de"]), "source": r["source"], "gender": r["gender"],
                     "template": r["template"]})
    rows.sort(key=lambda r: (ORDER.index(r["paket"]), r["source"]))
    with (args.work / "prioritaet.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["key_en", "key_de", "paket", "chars", "source", "gender", "template"])
        w.writeheader()
        w.writerows(rows)
    total = collections.Counter(), collections.Counter()
    for r in rows:
        total[0][r["paket"]] += 1
        total[1][r["paket"]] += r["chars"]
    acc = 0
    for p in ORDER:
        acc += total[1][p]
        print(f"{p:9} {total[0][p]:5} Texte {total[1][p]:8} Zeichen   kumuliert {acc}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
