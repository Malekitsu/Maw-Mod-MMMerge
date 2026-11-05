#!/usr/bin/env python3
"""
Lua test for Scripts/General/zzzMaw_Language.lua in the game's own LuaJIT:
German rows replace the English texts only for language = "de", escapes and
umlauts (cp1252) survive, bad rows are skipped, and the voice module computes the
same key for a German text as extract_texts.py does.

    python -I Tools/Voice/tests/run_language_tests.py
"""

import importlib.util
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("rlt", HERE / "run_lua_tests.py")
rlt = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rlt)

ROOT = rlt.ROOT
LANG = ROOT / "Scripts" / "General" / "zzzMaw_Language.lua"

GERMAN = [
    "Grüße, Fremder!\nSchön, dass Ihr da seid.",
    "Äpfel, Öl, Übung",
    "Tab\tund \\ Strich",
    "„Ihr seid Held“, sagte die Königin.",
]


def real_texts():
    """Every 7th German text of the real table (work/texts_de.csv, not in the repo): all umlaut and quote cases."""
    path = ROOT / "Tools" / "Voice" / "de" / "work" / "texts_de.csv"
    if not path.exists():
        return []
    import csv
    return [r["text_de"] for r in list(csv.DictReader(path.open(encoding="utf-8")))[::7]]


def main() -> int:
    if not (rlt.GAME / "ExeMods" / "MMExtension" / "lua51.dll").exists():
        print(f"SKIP: no lua51.dll under {rlt.GAME} (set MM8_DIR)")
        return 0
    tmp = Path(tempfile.mkdtemp(prefix="mawlang"))
    try:
        keys = tmp / "keys.txt"
        with keys.open("w", encoding="ascii") as f:
            for text in GERMAN + real_texts():
                raw = text.encode("cp1252")
                f.write(f"{raw.hex()} {rlt.ex.text_key(raw)}\n")
        work = tmp / "app"
        work.mkdir()
        code, text = rlt.run_lua(HERE / "lua" / "language_test.lua", str(LANG), str(rlt.MODULE), str(work) + "\\", str(keys))
        print(f"language_test.lua: {text}")
        code2, text2 = rlt.run_lua(HERE / "lua" / "ui_test.lua", str(ROOT / "Scripts" / "General" / "zzzMaw_LanguageUI.lua"))
        print(f"ui_test.lua: {text2}")
        code = code or code2
        print("ALL PASSED" if code == 0 else "FAILED")
        return code
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
