#!/usr/bin/env python3
"""
German edition: the voices of the party members (Data/Tables/Character voices.txt).

    python -I char_voices.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/

Every voice set (a column of the table) has about 106 sounds: greetings (Hello1-6), remarks about items, monsters,
hunger, gold, keys ..., and grunts. Data/GermanD.lod holds the German original recordings for 29 of the 79 sets (the
sets of Might and Magic 8); the others (the sets of Might and Magic 6/7 and of the mod) exist only in English.
The German recordings cost nothing, so each set without one gets the German voice of a set of the same sex and race:
the donors are spread over the sets, so different characters keep different voices.

Writes work/char_de/<donor sound id>.ogg  (the German recording, converted from the wav of GermanD.lod)
       work/chars_de.tsv                  ("target sound id<TAB>file stem": what to play instead of that sound)
       work/chars_de_report.txt           (voice set -> own German / donor set, sex, race)
The voice module reads chars_de.tsv (Data/Voices/chars_de.tsv) and plays <stem>.ogg from Data/Voices/Char_de/.
"""

import argparse
import collections
import csv
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402


def table(path: Path):
    return list(csv.reader(path.open(encoding="cp1252"), delimiter="\t"))


def set_profiles(portraits):
    """{voice set: (sex, race)} from Character portraits.txt (Def voice, Def sex, Race); the first portrait wins."""
    head = portraits[0]
    iv, isx, ir = head.index("Def voice"), head.index("Def sex"), head.index("Race")
    out = {}
    for r in portraits[1:]:
        if len(r) > ir and r[iv].isdigit():
            out.setdefault(int(r[iv]), (r[isx], r[ir]))
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--ffmpeg", default="ffmpeg")
    ap.add_argument("--quality", default="4")
    ap.add_argument("--no-convert", action="store_true", help="write only the tables, convert nothing")
    ap.add_argument("--wav", action="store_true", help="copy the wav of the LOD as it is (no ffmpeg needed; the voice module plays .wav too)")
    args = ap.parse_args(argv)
    tables = args.game / "Data" / "Tables"

    names = {}
    for r in table(tables / "Sounds.txt"):
        if len(r) > 1 and r[1].isdigit():
            names[int(r[1])] = r[0].lower()
    voices = table(tables / "Character voices.txt")
    profiles = set_profiles(table(tables / "Character portraits.txt"))
    lods = {k: ex.read_lod(args.game / "Data" / f"{k}.lod") for k in ("GermanD", "mm8.D", "mm7.D", "mm6.D", "mmmerge.D")}

    def wav(lod, name):
        d = lods[lod]
        return d.get(name + ".wav") or d.get(name)

    def english(name):
        return next((w for k in ("mm8.D", "mmmerge.D", "mm7.D", "mm6.D") if (w := wav(k, name))), None)

    def german(sound_id):
        """The German recording of a sound, or None (missing, or the same wav as the English one)."""
        name = names.get(sound_id)
        if not name:
            return None
        de = wav("GermanD", name)
        if de is None or de == english(name):
            return None
        return de

    rows = [(r[0], [int(v) if v.strip().isdigit() else 0 for v in r[1:80]]) for r in voices[1:] if r and r[0]]
    nsets = 79
    own = {s: sum(1 for _, ids in rows if ids[s] and german(ids[s])) for s in range(nsets)}
    german_sets = [s for s in range(nsets) if own[s] >= 60]  # a set with German recordings of its own
    donors_by = collections.defaultdict(list)
    for s in german_sets:
        sex, race = profiles.get(s, ("0", "0"))
        donors_by[(sex, race)].append(s)
        donors_by[(sex, None)].append(s)

    def donor_list(s):
        sex, race = profiles.get(s, ("0", "0"))
        same = donors_by.get((sex, race)) or donors_by.get((sex, None)) or german_sets
        wide = donors_by.get((sex, None)) or german_sets
        start = s % len(same)
        return [same[(start + i) % len(same)] for i in range(len(same))] + [d for d in wide if d not in same]

    mapping, used, report = {}, set(), []
    for s in range(nsets):
        donors = [s] + donor_list(s) if s in german_sets else donor_list(s)
        chosen = donors[0] if s not in german_sets else s
        report.append(f"set {s}: sex/race {profiles.get(s, '?')}, German of its own {own[s]}, voice of set {chosen}")
        for _, ids in rows:
            if not ids[s]:
                continue
            for d in donors:
                did = ids[d]
                if did and german(did):
                    mapping[ids[s]] = did
                    used.add(did)
                    break

    # the other sounds with a German original (story events, "welcome adventurer"): the German recording of the same sound
    in_sets = set(mapping)
    for sound_id in names:
        if sound_id not in in_sets and names[sound_id].startswith(("event", "welcome")) and german(sound_id):  # speech only, not effects
            mapping[sound_id] = sound_id
            used.add(sound_id)
    # the greetings of the shops of Might and Magic 7 (shop_voices.py records <id>.ogg into char_de)
    shops = HERE / "data" / "shop_de.csv"
    shop_ids = set()
    if shops.exists():
        for line in shops.read_text(encoding="utf-8").splitlines()[1:]:
            if line.split(";")[0].isdigit():
                mapping[int(line.split(";")[0])] = int(line.split(";")[0])
                # only the greetings of shops are the group "shops" (German only for German shops): the sound names of
                # Sounds.txt say the house ("human armor shop 01"); guilds, temples, taverns, banks ... stay German
                if re.search(r"(alchemy|armor|magic|weapon) ?shop", names.get(int(line.split(";")[0]), "")):
                    shop_ids.add(int(line.split(";")[0]))
    # the shop greetings of Might and Magic 8 are the "event" sounds of the shop houses: events 13 to 18 (weapons), 19 to 24
    # (armor), 25 to 28 (alchemists), 44 to 48 (magic). Event 49 is shared by one magic shop and several guilds: base.
    for sound_id in mapping:
        if re.match(r"event(1[3-9]|2[0-8]|4[4-8])_", names.get(sound_id, "")):
            shop_ids.add(sound_id)
    out = args.work / "char_de"
    out.mkdir(parents=True, exist_ok=True)
    # third column "s": a shop greeting, German only when the player chose German shops
    (args.work / "chars_de.tsv").write_text("".join(f"{t}\t{d}\t{'s' if t in shop_ids else ''}\n" for t, d in sorted(mapping.items())), encoding="ascii")
    (args.work / "chars_de_report.txt").write_text("\n".join(report) + "\n", encoding="utf-8")
    print(f"{len(german_sets)} sets with German recordings, {nsets - len(german_sets)} sets get a donor voice; "
          f"{len(mapping)} sounds mapped to {len(used)} recordings")
    if args.no_convert:
        return 0
    tmp = args.work / "char_de_wav"
    tmp.mkdir(exist_ok=True)
    done = 0
    for did in sorted(used):
        if args.wav:
            (out / f"{did}.wav").write_bytes(german(did))
            done += 1
            continue
        target = out / f"{did}.ogg"
        if target.exists():
            continue
        src = tmp / f"{did}.wav"
        src.write_bytes(german(did))
        r = subprocess.run([args.ffmpeg, "-loglevel", "error", "-y", "-i", str(src), "-c:a", "libvorbis", "-q:a", args.quality,
                            str(target)], capture_output=True)
        if r.returncode != 0:
            print(f"ffmpeg failed for {did}: {r.stderr.decode(errors='replace')[:100]}")
        done += 1
    print(f"converted {done} recordings into {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
