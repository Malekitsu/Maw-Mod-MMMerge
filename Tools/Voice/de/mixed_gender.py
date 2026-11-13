#!/usr/bin/env python3
"""
Texts that men and women speak (a profession text, a shared topic) need a recording in both voices.

    python -I mixed_gender.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/

Reads work/prioritaet.csv (the recording of each text is in the voice of its main gender) and the speakers of the
tables. Writes work/gegengeschlecht.csv: the texts with speakers of both genders, with the OTHER gender, as input
for generate_voices_el.py --variants (file <key_de>-<m|f>.ogg, which the voice module prefers for that gender).
"""

import argparse
import collections
import csv
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402


def speaker_genders(game: Path):
    out, genders, _ = ex.build(game)
    result = {}
    for key, r in out.rows.items():
        gs = set()
        for s in r["speakers"]:
            g = genders.of_name(s)
            g = g[0] if isinstance(g, (tuple, list)) else g
            if g in ("m", "f"):
                gs.add(g)
        result[key] = gs
    return result


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    args = ap.parse_args(argv)
    rows = list(csv.DictReader((args.work / "prioritaet.csv").open(encoding="utf-8")))
    speakers = speaker_genders(args.game)
    out = []
    for r in rows:
        if speakers.get(r["key_en"], set()) == {"m", "f"}:
            out.append({**r, "gender": "f" if r["gender"] == "m" else "m"})
    path = args.work / "gegengeschlecht.csv"
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(out)
    count = collections.Counter(r["paket"] for r in out)
    print(f"{len(out)} texts need the second voice: " + ", ".join(f"{k}={v}" for k, v in count.items()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
