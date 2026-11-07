#!/usr/bin/env python3
"""
German edition, last step of the installation (runs on the player's PC).

    python install_german.py [--game "C:/.../Might and Magic 8 MAW Mod 4.5"] [--language de|en] [--target OTHER_FOLDER]

The package MAW-German does not contain the original German texts and recordings of the game. This script creates them
from the files of the player's own installation:
  * dialog texts:   Data/GermanT.lod  ->  Data/Localization/de/10_NPCGreet.txt ... (with data/texts_de_public.csv)
  * interface:      Data/GermanT.lod  ->  Data/Localization/de/2x_*.txt, 3x_*.txt, shops/, items/ (export_ui.py)
  * party voices:   Data/GermanD.lod  ->  Data/Voices/Char_de/<id>.ogg (ffmpeg found) or .wav (no ffmpeg), chars_de.tsv
Needs only Python 3 (no extra packages). Without GermanT.lod / GermanD.lod the game stays English for those texts.
Exit code 0 = done, 1 = a file is missing or a check failed.
"""

import argparse
import csv
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
FROZEN = getattr(sys, "frozen", False)  # Install_German.exe (PyInstaller): lies in the game folder, the data are inside
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import extract_texts as ex  # noqa: E402

TABLES = ("npcgreet.txt", "npctext.txt", "npcnews.txt")


def german_originals(lod):
    """{key of the German text: text} of all dialog cells of GermanT.lod (the key as build_texts_de.py made it)."""
    out = {}
    for name in TABLES:
        if name not in lod:
            continue
        for r in ex.parse_table(lod[name])[1:]:
            for col in (1, 2):
                raw = ex.cell(r, col)
                if raw and ex.is_speech(raw):
                    text = ex.decode(raw).strip()
                    out[ex.text_key(text.encode(ex.TEXT_ENCODING, errors="replace"))] = text
    return out


def fill_texts(public: Path, target: Path, originals):
    """Writes texts_de.csv with the texts of origin "original" filled in; returns (rows, missing)."""
    with public.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    missing = 0
    for r in rows:
        if r["herkunft"] == "original":
            text = originals.get(r["key_de"])
            if text is None:
                missing += 1
                r["key_en"] = ""  # no German original in this installation: the dialog stays English
            else:
                r["text_de"] = text
    rows = [r for r in rows if r["key_en"]]
    with target.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    return len(rows), missing


def copy_tree(src: Path, dst: Path):
    n = 0
    for p in sorted(src.rglob("*")):
        if p.is_file():
            out = dst / p.relative_to(src)
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, out)
            n += 1
    return n


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", type=Path, default=Path(sys.executable).parent if FROZEN else HERE.parents[2], help="game folder (default: the folder this tool lies in)")
    ap.add_argument("--target", type=Path, help="write the files here instead of into the game folder (test)")
    ap.add_argument("--language", choices=["de", "en"])
    ap.add_argument("--ffmpeg", default="ffmpeg")
    ap.add_argument("--keep", action="store_true", help="keep the temporary folder")
    args = ap.parse_args(argv)
    if FROZEN and argv is None and len(sys.argv) == 1:  # double-click: the German edition on
        args.language = "de"
    game = args.game.resolve()
    target = (args.target or game).resolve()

    data = game / "Data"
    need = [data / "mmmerge.T.lod", data / "GermanT.lod", data / "Tables" / "Sounds.txt"]
    missing = [str(p) for p in need if not p.exists()]
    if missing:
        print("These files are missing, is this the game folder of Might and Magic 8 with MMMerge and MAW?")
        print("\n".join("  " + m for m in missing))
        return 1
    public = HERE / "data" / "texts_de_public.csv"
    if not public.exists():
        print(f"{public} is missing: the package is incomplete")
        return 1

    import export_localization as el  # noqa: E402
    import export_ui as eu  # noqa: E402
    import char_voices as cv  # noqa: E402

    work = Path(tempfile.mkdtemp(prefix="mawde_", dir=str(target)))
    try:
        # 1. dialog texts
        print("1/3 Dialog texts from GermanT.lod ...")
        originals = german_originals(ex.read_lod(data / "GermanT.lod"))
        n, miss = fill_texts(public, work / "texts_de.csv", originals)
        print(f"    {n} texts, {miss} without a German original in this installation (they stay English)")
        loc = work / "localization_de"
        counts, _unused = el.export(game, work, loc)
        print("    rows written: " + ", ".join(f"{t}={c}" for t, c in counts.items()))
        # 2. interface texts
        print("2/3 Interface texts from GermanT.lod ...")
        ui = work / "localization_de_ui"
        if eu.main(["--game", str(game), "--out", str(ui)]) != 0:
            print("    export_ui.py failed")
            return 1
        out = target / "Data" / "Localization" / "de"
        out.mkdir(parents=True, exist_ok=True)
        for sub in ("", "shops", "items"):  # an older numbering must not stay behind
            for old in (out / sub).glob("*.txt"):
                if old.name[:2].isdigit() and old.name != "13_GlobalTxt.txt":
                    old.unlink()
        copied = copy_tree(loc, out) + copy_tree(ui, out)
        print(f"    {copied} files written to {out}")
        # 3. party voices
        print("3/3 Party voices from GermanD.lod ...")
        if (data / "GermanD.lod").exists():
            wavs = not shutil.which(args.ffmpeg)
            cv_args = ["--game", str(game), "--work", str(work), "--ffmpeg", args.ffmpeg]
            if wavs:
                cv_args.append("--wav")
                print("    ffmpeg not found: the voices are written as .wav (larger, same sound)")
            if cv.main(cv_args) != 0:
                return 1
            copy_tree(work / "char_de", target / "Data" / "Voices" / "Char_de")
            shutil.copy2(work / "chars_de.tsv", target / "Data" / "Voices" / "chars_de.tsv")
        else:
            print("    Data/GermanD.lod not found: the party members keep their English voices")
    finally:
        if not args.keep:
            shutil.rmtree(work, ignore_errors=True)
    if args.language:
        import re
        path = target / "MAWSettings.lua"
        text = path.read_bytes().decode("utf-8")
        text = re.sub(r"^(\s*language\s*=\s*)\"[a-z]*\"", lambda m: m.group(1) + '"' + args.language + '"', text, count=1, flags=re.M)
        path.write_bytes(text.encode("utf-8"))
        print(f'MAWSettings.lua: language = "{args.language}"')
    print("Done.")
    return 0


if __name__ == "__main__":
    code = main()
    if FROZEN and len(sys.argv) == 1:
        input("Press Enter to close this window / Eingabetaste zum Schliessen: ")
    sys.exit(code)
