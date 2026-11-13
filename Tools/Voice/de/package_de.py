#!/usr/bin/env python3
"""
M6 of the German edition: check the German files and install or pack them.

    python -I package_de.py --work work/ --game "C:/.../Might and Magic 8 MAW Mod 4.5" [--install] [--zip OUT.zip]
                            [--language de]

The package holds
    Scripts/General/zzzMaw_Language.lua, zzzMaw_NPCVoices.lua   (language switch, voice module)
    Data/Localization/de/10_NPCGreet.txt, 11_NPCText.txt, 12_NPCNews.txt   (export_localization.py)
    Data/Voices/NPC_de/<key_de>.ogg                             (generate_voices_el.py)
Checks (exit code 1 when one fails): every recording is named like the key of a German text of the tables,
the files of the three tables exist, and no file name is used twice.
--install copies everything into the game folder (the old Data/Localization/de/00_spike.txt is removed);
--language de (or en) writes the setting language = ... into MAWSettings.lua of that folder.
"""

import argparse
import csv
import re
import shutil
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
LUA = ["zzzMaw_Language.lua", "zzzMaw_LanguageUI.lua", "zzzMaw_LanguageMenu.lua", "zzzMaw_NPCVoices.lua", "ExtraQuickSpells.lua"]  # ExtraQuickSpells: Keybinds page with 12 slots
LOC = ["10_NPCGreet.txt", "11_NPCText.txt", "12_NPCNews.txt", "13_GlobalTxt.txt"]


def check(work: Path):
    problems = []
    loc = work / "localization_de"
    for name in LOC:
        if not (loc / name).exists():
            problems.append(f"missing {loc / name}")
    keys = {r["key_de"] for r in csv.DictReader((work / "texts_de.csv").open(encoding="utf-8"))}
    cuts = work / "teacher_cuts_report.txt"  # shortened teacher recordings (teacher_cuts.py): keys of text parts
    if cuts.exists():
        for line in cuts.read_text(encoding="utf-8").splitlines():
            cols = line.split(chr(9))
            if len(cols) > 2 and cols[1] == "ok":
                keys.add(re.sub(r"-[mf]$", "", cols[2][:-4]))
    audio = sorted((work / "audio_de").glob("*.ogg"))
    for p in audio:
        stem = re.sub(r"-[mf]$", "", p.stem)  # <key>-m / <key>-f: second voice of a text both genders speak
        if re.match(r"t[0-9a-f]{8}(~|$)", stem):  # t<key>~<value>: a template filled in with that value (templates_de.py)
            stem = stem[1:9]
        if stem not in keys:
            problems.append(f"recording {p.name} matches no German text")
        if p.stat().st_size == 0:
            problems.append(f"recording {p.name} is empty")
    return audio, problems


def files(work: Path, audio):
    out = [(ROOT / "Scripts" / "General" / n, f"Scripts/General/{n}") for n in LUA]
    out += [(work / "localization_de" / n, f"Data/Localization/de/{n}") for n in LOC]
    out += [(p, f"Data/Localization/de/{p.name}") for p in sorted((work / "localization_de_ui").glob("*.txt"))]  # export_ui.py
    out += [(p, f"Data/Localization/de/map/{p.name}") for p in sorted((work / "localization_de_map").glob("*.tsv"))]  # English -> German of texts made in Lua
    # the groups: German only when chosen on the settings page (shops: shops and huts; items: items and tooltips)
    for group in ("shops", "items"):
        for folder in ("localization_de", "localization_de_ui"):
            out += [(p, f"Data/Localization/de/{group}/{p.name}") for p in sorted((work / folder / group).glob("*.txt"))]
    out += [(work / "templates_de.tsv", "Data/Voices/templates_de.tsv")]
    out += [(p, f"Data/Voices/NPC_de/{p.name}") for p in audio]
    out += [(work / "chars_de.tsv", "Data/Voices/chars_de.tsv")]  # party member voices (char_voices.py)
    out += [(work / "pics.tsv", "Data/Voices/pics.tsv")]  # portrait -> sex (extract_texts.py --pics)
    out += [(p, f"Data/Voices/Char_de/{p.name}") for p in sorted((work / "char_de").glob("*.ogg"))]
    return out


def set_language(game: Path, value: str):
    path = game / "MAWSettings.lua"
    text = path.read_bytes().decode("utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    line = f'    language = "{value}",                    -- "de" German (Data/Localization/de and Data/Voices/NPC_de), "en" English'
    if re.search(r"^\s*language\s*=", text, re.M):
        text = re.sub(r"^\s*language\s*=.*$", line, text, flags=re.M)
    else:
        text = text.replace("return {", "return {" + nl + "    -- Language" + nl + line, 1)
    path.write_bytes(text.encode("utf-8"))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--game", type=Path)
    ap.add_argument("--install", action="store_true")
    ap.add_argument("--zip", type=Path)
    ap.add_argument("--language", choices=["de", "en"])
    args = ap.parse_args(argv)

    audio, problems = check(args.work)
    print(f"{len(audio)} recordings, {len(problems)} problems")
    for p in problems[:20]:
        print("  " + p)
    if problems:
        return 1
    items = files(args.work, audio)
    if args.install:
        if not args.game:
            sys.exit("--install needs --game")
        old = args.game / "Data" / "Localization" / "de" / "00_spike.txt"
        old.unlink(missing_ok=True)
        for src, rel in items:
            dst = args.game / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
        wanted = {rel for _, rel in items}
        for sub in ("", "shops/", "items/"):
            for old in (args.game / "Data" / "Localization" / "de" / sub).glob("*.txt"):  # files of an older numbering
                if f"Data/Localization/de/{sub}{old.name}" not in wanted:
                    old.unlink()
                    print(f"removed old {sub}{old.name}")
        print(f"installed {len(items)} files into {args.game}")
        for n in LUA:  # the game folder once kept an older voice module without the German folder
            if (args.game / "Scripts" / "General" / n).read_bytes() != (ROOT / "Scripts" / "General" / n).read_bytes():
                sys.exit(f"{n} in the game folder differs from the repository after install")
    if args.language:
        if not args.game:
            sys.exit("--language needs --game")
        set_language(args.game, args.language)
        print(f"MAWSettings.lua: language = {args.language}")
    if args.zip:
        with zipfile.ZipFile(args.zip, "w", zipfile.ZIP_STORED) as z:
            for src, rel in items:
                z.write(src, rel)
        print(f"{args.zip}: {args.zip.stat().st_size // 1024 // 1024} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
