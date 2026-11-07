#!/usr/bin/env python3
"""
Release build (runs on the maker's PC): the two download packages and their checksums.

    python build_release.py --work work --game "C:/.../Might and Magic 8 MAW Mod 4.5" --out C:/mawrelease --version 1.0.0

Writes <out>/<version>/
    MAW-Voices-EN-<version>.zip    English NPC voices + voice module (Kokoro recordings, made on this PC)
    MAW-German-<version>.zip       German edition: texts, ElevenLabs voices, modules, tools, installer
    INSTALL_EN.txt, INSTALL_DE.txt, LICENSE.txt, SHA256SUMS.txt
Nothing is published. The German package holds NO original text or recording of the game (Data/GermanT.lod,
Data/GermanD.lod): install_german.py makes them from the player's own files. This script checks that before it
finishes (exit code 1 when the check fails).
"""

import argparse
import csv
import hashlib
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import extract_texts as ex  # noqa: E402
import package_de as pk  # noqa: E402

TOOLS_DE = ["install_german.py", "export_ui.py", "export_localization.py", "groups.py", "align_german.py", "char_voices.py"]
TOOLS_VOICE_DATA = ["global_speech_ids.txt", "lua_dialog_files.txt", "speakers.csv"]
DE_DATA = ["bad_pairs.csv", "mod_texts_de.csv", "mod_texts2_de.csv", "names_extra_de.csv", "ui_short_de.csv", "shop_de.csv"]
DOCS = HERE / "docs" / "release"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def public_texts(work: Path, target: Path) -> int:
    """work/texts_de.csv without the German originals (text_de of herkunft "original" is left empty)."""
    with (work / "texts_de.csv").open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    n = 0
    for r in rows:
        if r["herkunft"] == "original":
            r["text_de"] = ""
            n += 1
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    return n


def own_char_files(work: Path):
    """The recordings of work/char_de that are not from GermanD.lod: the shop greetings of data/shop_de.csv."""
    ids = {l.split(";")[0] for l in (HERE / "data" / "shop_de.csv").read_text(encoding="utf-8").splitlines()[1:]}
    return [p for p in sorted((work / "char_de").glob("*.ogg")) if re.sub(r"-[mf]$", "", p.stem) in ids]


def write_zip(path: Path, items):
    seen = set()
    with zipfile.ZipFile(path, "w", zipfile.ZIP_STORED) as z:
        for src, rel in items:
            if rel in seen:
                raise SystemExit(f"{rel} twice in {path.name}")
            seen.add(rel)
            z.write(src, rel)
    return seen


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--version", default="1.0.0")
    args = ap.parse_args(argv)
    work, game = args.work.resolve(), args.game.resolve()
    out = args.out / args.version
    out.mkdir(parents=True, exist_ok=True)

    audio, problems = pk.check(work)
    print(f"gate: {len(audio)} German recordings, {len(problems)} problems")
    if problems:
        return 1

    # ---- English voices
    en_items = [(ROOT / "Scripts" / "General" / "zzzMaw_NPCVoices.lua", "Scripts/General/zzzMaw_NPCVoices.lua")]
    en_items += [(p, f"Data/Voices/NPC/{p.name}") for p in sorted((game / "Data" / "Voices" / "NPC").glob("*.ogg"))]
    for name in ("names.tsv", "templates.tsv", "pics.tsv"):
        en_items.append((game / "Data" / "Voices" / name, f"Data/Voices/{name}"))
    docs = [(DOCS / n, n) for n in ("INSTALL_EN.txt", "INSTALL_DE.txt", "LICENSE.txt")]
    en_docs = [(DOCS / "INSTALL_VOICES_EN.txt", "INSTALL_EN.txt"), (DOCS / "LICENSE_VOICES_EN.txt", "LICENSE.txt")]  # English only
    en_zip = out / f"MAW-Voices-EN-{args.version}.zip"
    write_zip(en_zip, en_items + en_docs)

    # ---- German edition
    public = work / "texts_de_public.csv"
    hidden = public_texts(work, public)
    items = [(ROOT / "Scripts" / "General" / n, f"Scripts/General/{n}") for n in pk.LUA]
    items += [(work / "localization_de" / "13_GlobalTxt.txt", "Data/Localization/de/13_GlobalTxt.txt")]
    items += [(p, f"Data/Localization/de/map/{p.name}") for p in sorted((work / "localization_de_map").glob("*.tsv"))]
    items += [(work / "templates_de.tsv", "Data/Voices/templates_de.tsv"), (work / "pics.tsv", "Data/Voices/pics.tsv")]
    items += [(p, f"Data/Voices/NPC_de/{p.name}") for p in audio]
    items += [(p, f"Data/Voices/Char_de/{p.name}") for p in own_char_files(work)]
    items += [(ROOT / "Tools" / "Voice" / "extract_texts.py", "Tools/Voice/extract_texts.py")]
    items += [(ROOT / "Tools" / "Voice" / "data" / n, f"Tools/Voice/data/{n}") for n in TOOLS_VOICE_DATA]
    items += [(HERE / n, f"Tools/Voice/de/{n}") for n in TOOLS_DE]
    items += [(HERE / "data" / n, f"Tools/Voice/de/data/{n}") for n in DE_DATA]
    items += [(public, "Tools/Voice/de/data/texts_de_public.csv")]
    exe_dir = work / "exe"
    shutil.rmtree(exe_dir, ignore_errors=True)
    if subprocess.run([sys.executable, str(HERE / "build_exe.py"), str(work / "exe_build"), str(public), str(exe_dir)]).returncode != 0:
        print("building Install_German.exe failed (pip install pyinstaller)")
        return 1
    items += [(exe_dir / "Install_German.exe", "Install_German.exe")] + docs
    de_zip = out / f"MAW-German-{args.version}.zip"
    names = write_zip(de_zip, items)

    # ---- check: nothing of the original game in the German package
    allowed = {"Data/Localization/de/13_GlobalTxt.txt"}
    bad = [n for n in names if n.endswith(".wav") or "GermanT" in n or "GermanD" in n
           or (n.startswith("Data/Localization/de/") and n not in allowed and not n.startswith("Data/Localization/de/map/"))]
    originals = {r["text_de"] for r in csv.DictReader((work / "texts_de.csv").open(encoding="utf-8")) if r["herkunft"] == "original"}
    with zipfile.ZipFile(de_zip) as z:
        blob = z.read("Tools/Voice/de/data/texts_de_public.csv").decode("utf-8")
        leaked = sum(1 for t in list(originals)[:200] if len(t) > 40 and t in blob)
    if bad or leaked:
        print("CHECK FAILED: original material in the German package:", bad[:5], leaked)
        return 1
    print(f"check: {hidden} German originals left out of the table, no original file in the package")

    # ---- checksums
    sums = out / "SHA256SUMS.txt"
    files = [en_zip, de_zip] + [out / n for n in ("INSTALL_EN.txt", "INSTALL_DE.txt", "LICENSE.txt")]
    for _, n in docs:
        shutil.copy2(DOCS / n, out / n)
    sums.write_text("".join(f"{sha256(p)}  {p.name}\n" for p in files), encoding="utf-8")
    for p in files:
        print(f"{p.name}: {p.stat().st_size / 1e6:.1f} MB")
    print(f"{len(en_items)} files in the English, {len(items)} in the German package -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
