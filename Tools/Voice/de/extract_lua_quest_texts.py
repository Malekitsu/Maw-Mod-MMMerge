#!/usr/bin/env python3
"""
Lists the English texts that the quest scripts of the mod give to Quest{} / Greeting{} (Texts = {Topic = ..., Give = ...}).

    python extract_lua_quest_texts.py --scripts "C:/.../Scripts" --out work/lua_quest_en.csv

Output: English;Key;File (utf-8, semicolon separated; line breaks written as backslash-n). The German goes into
data/lua_quests_de.csv (English;German); package_de.py installs it as Data/Localization/de/map/lua_quests.tsv, which
zzzMaw_LanguageUI.lua applies to the texts before Quest{} sees them.
"""

import argparse
import re
from pathlib import Path

BS = chr(92)
KEYS = ("Topic", "Give", "Done", "Undone", "Ungive", "After", "Text", "TextSeen", "Greet", "FirstGreet", "Quest",
        "Award", "Reward", "Fail", "Failed", "Start", "Intro", "Ask", "Answer", "Texts")
FILES = ["Global/*.lua", "General/NPCMercenaries.lua", "General/BountyHunt.lua"]
STRING = re.compile(r"\b(" + "|".join(KEYS) + r")\s*=\s*(\"(?:[^\"" + BS + BS + r"]|" + BS + BS + r".)*\"|\[\[.*?\]\])", re.S)


def unquote(lit: str) -> str:
    if lit.startswith("[["):
        return lit[2:-2]
    body = lit[1:-1]
    return body.replace(BS + 'n', chr(10)).replace(BS + '"', '"').replace(BS + BS, BS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scripts", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args()
    seen, rows = set(), []
    for pattern in FILES:
        for path in sorted(args.scripts.glob(pattern)):
            text = path.read_text(encoding="utf-8", errors="replace")
            for m in STRING.finditer(text):
                en = unquote(m.group(2))
                if re.search(r"[A-Za-z]{3,} [A-Za-z]|^[A-Z][a-z]+", en) and en not in seen and not en.startswith(("evt.", "Game.")):
                    seen.add(en)
                    rows.append(";".join([en.replace(chr(10), BS + "n"), m.group(1), path.name]))
    args.out.write_text(chr(10).join(rows) + chr(10), encoding="utf-8")
    print(len(rows), "texts")


if __name__ == "__main__":
    main()
