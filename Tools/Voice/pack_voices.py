#!/usr/bin/env python3
"""
Bundle the voice pack: one zip with the recordings, names.tsv, templates.tsv and the
Lua module, in the folder layout of the game install, plus INSTALL.txt and a .sha256 file.

    python -I pack_voices.py --out ../../Data/Voices/MAW-NPCVoices-2026-10-30.zip

Defaults: recordings, names.tsv and templates.tsv from <repository>/Data/Voices, the module from
<repository>/Scripts/General/zzzMaw_NPCVoices.lua. Run it from Tools/Voice; it needs
no packages.
"""

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent

INSTALL = (
    "MAW NPC voices - voice pack\n"
    "===========================\n"
    "Unpack into the game folder (the one that holds MM8.exe), keeping the folders:\n"
    "  Scripts/General/zzzMaw_NPCVoices.lua   the player module\n"
    "  Data/Voices/NPC/<key>.ogg              one recording per dialog text\n"
    "  Data/Voices/NPC/<key>-m.ogg, -f.ogg    the same text in the other voice: every text has both\n"
    "  Data/Voices/names.tsv                  NPC names and their gender: the module picks the voice of the NPC's gender\n"
    "  Data/Voices/templates.tsv              patterns of the texts with names, percents ...: the hire pitches, 'Back again, <name>?'\n"
    "The module is on by default and follows the game's character voices slider (Options; level 0 = silent), one step louder\n"
    "  than the slider says because the recordings are a little quiet (console: MawVoices.BoostSteps = 0 for exactly the slider).\n"
    "A greeting starts one second late, so that the NPC's own hello sound is over.\n"
    "No setting files are touched. To switch it off in game, press Ctrl+F1 and run MawVoices.Enabled = false.\n"
    "The module writes NPCVoicesLog.txt next to MM8.exe (per line: NPC name and gender, 'alt' = other-voice recording, vol= the Sound and the character voices slider it read).\n"
    "Delete Scripts/General/zzzMaw_NPCVoices.lua, Data/Voices/NPC, names.tsv and templates.tsv to uninstall.\n"
    "Texts changed by other mods have no recording and stay silent; the voices are American English,\n"
    "one male (am_michael) and one female (af_heart) generic voice (Kokoro-82M, Apache-2.0).\n"
)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--voices", type=Path, default=HERE.parent.parent / "Data" / "Voices",
                    help="folder with NPC/ (the recordings), names.tsv and templates.tsv")
    ap.add_argument("--module", type=Path, default=HERE.parent.parent / "Scripts" / "General" / "zzzMaw_NPCVoices.lua")
    ap.add_argument("--out", required=True, type=Path, help="the zip to write (a .sha256 file goes next to it)")
    args = ap.parse_args(argv)

    npc_dir, names, patterns = args.voices / "NPC", args.voices / "names.tsv", args.voices / "templates.tsv"
    recordings = sorted(p for p in npc_dir.glob("*") if p.suffix in (".ogg", ".wav"))
    for needed, what in ((names, "names.tsv"), (patterns, "templates.tsv"), (args.module, "the Lua module")):
        if not needed.is_file():
            print(f"missing {what}: {needed}", file=sys.stderr)
            return 1
    if not recordings:
        print(f"no recordings in {npc_dir}", file=sys.stderr)
        return 1

    with zipfile.ZipFile(args.out, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        z.writestr("INSTALL.txt", INSTALL)
        z.write(args.module, "Scripts/General/zzzMaw_NPCVoices.lua")
        z.write(names, "Data/Voices/names.tsv")
        z.write(patterns, "Data/Voices/templates.tsv")
        for p in recordings:
            z.write(p, "Data/Voices/NPC/" + p.name)
    with zipfile.ZipFile(args.out) as z:
        if z.testzip() is not None:
            print("the zip is damaged", file=sys.stderr)
            return 1
        entries = len(z.namelist())
    digest = sha256(args.out)
    args.out.with_name(args.out.name + ".sha256").write_text(f"{digest} *{args.out.name}\n", encoding="ascii")
    print(f"{args.out}: {entries} entries, {args.out.stat().st_size / 1e6:.1f} MB, sha256 {digest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
