#!/usr/bin/env python3
"""
German edition: the shop, tavern, temple, bank, stable, boat and guild greetings of Might and Magic 7 (mm7.D.lod,
english only) in German.

    python shop_voices.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/ --genders genders.csv [--dry-run]

data/shop_de.csv holds the German text of each sound id (written from a transcript of the English recordings).
genders.csv (id;gender, m or f) says which voice speaks it; the same group of lines (a race and a house type) is one
speaker. Records <work>/char_de/<sound id>.ogg with the ElevenLabs voices of generate_voices_el.py; char_voices.py lists
the ids in chars_de.tsv, so the voice module plays them instead of the English sound.
"""

import argparse
import csv
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import generate_voices_el as el  # noqa: E402


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--genders", required=True, type=Path)
    ap.add_argument("--model", default="eleven_v4_turbo")
    ap.add_argument("--ffmpeg", default="ffmpeg")
    ap.add_argument("--quality", type=int, default=4)
    ap.add_argument("--reserve", type=int, default=1500)
    ap.add_argument("--variants", action="store_true",
                    help="record the other gender of every greeting as <id>-<m|f>.ogg (the module picks it by the gender of the house owner)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args(argv)
    text = {r["id"]: r["text_de"] for r in csv.DictReader((HERE / "data" / "shop_de.csv").open(encoding="utf-8"), delimiter=";")}
    gender = {r["id"]: r["gender"] for r in csv.DictReader(args.genders.open(encoding="utf-8"), delimiter=";")}
    out = args.work / "char_de"
    out.mkdir(parents=True, exist_ok=True)
    if args.variants:
        other = {"m": "f", "f": "m"}
        gender = {i: other[g] for i, g in gender.items()}  # the voice that is still missing
        stem = lambda i: f"{i}-{gender[i]}"  # noqa: E731
    else:
        stem = lambda i: i  # noqa: E731
    todo = [(i, t) for i, t in text.items() if i in gender and not (out / f"{stem(i)}.ogg").exists()]
    chars = sum(len(t) for _, t in todo)
    print(f"{len(todo)} greetings, {chars} characters, ~{int(chars * 0.22)} credits")
    if args.dry_run or not todo:
        return 0
    key = el.api_key()
    left, _ = el.credits_left(key)
    print("credits left:", left)
    spent = 0
    for i, t in todo:
        if left - spent < args.reserve:
            print("stopped: credit reserve reached")
            break
        pcm, cost = el.synthesize(key, el.VOICES.get(gender.get(i, "m"), el.VOICES["m"]), t, args.model)
        if el.to_ogg(pcm, out / f"{stem(i)}.ogg", args.ffmpeg, args.quality):
            spent += cost
    print(f"recorded, credits spent {spent}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
