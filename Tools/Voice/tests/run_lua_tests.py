#!/usr/bin/env python3
"""
Lua regression tests for Scripts/General/zzzMaw_NPCVoices.lua, run in the
game's own LuaJIT (so the Lua 5.1/LuaJIT semantics are the real ones).

    python -I Tools/Voice/tests/run_lua_tests.py

1. keys_test.lua  - the Lua key equals extract_texts.py's key for every dialog
                    text of the install and for quoted / CRLF / padded variants
2. templates_test.lua - for every recording of a text with placeholders (templates.py)
                    the Lua pattern finds its key in the text the game would show
3. flow_test.lua  - greeting, topic, exit, volume, missing dll, errors ... against
                    a stubbed engine and a fake SoLoud

Needs the install (MM8_DIR, default: the author's test install) for lua51.dll
and the texts. lua51.dll is 32-bit, so the tests run in 32-bit PowerShell.
Exit code 0 = everything passed.
"""

import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]  # repository root: tests -> Voice -> Tools -> root
GAME = Path(os.environ.get("MM8_DIR", r"C:\Users\slovi\Desktop\Might and Magic 8 MAW Mod 4.5"))
POWERSHELL32 = r"C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
MODULE = ROOT / "Scripts" / "General" / "zzzMaw_NPCVoices.lua"

sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402
import templates  # noqa: E402


def write_cases(path: Path) -> int:
    out, _, _ = ex.build(GAME)
    n = 0
    with path.open("w", encoding="ascii") as f:
        for row in out.rows.values():
            raw = row["raw"]
            for variant in (raw, b'"' + raw + b'"', raw.replace(b"\n", b"\r\n"), b"  " + raw.replace(b" ", b"   ") + b"\n"):
                f.write(f"{variant.hex()} {ex.text_key(variant)}\n")
                n += 1
    return n


def write_template_cases(path: Path, app: Path) -> int:
    """templates.tsv into the scratch app directory; the shown text of every recording and its key into `path`."""
    out, _, _ = ex.build(GAME)
    rows = [r for r in out.rows.values() if r["template"]]
    domains, percents = templates.load_domains(GAME)
    _, patterns, _, _, cases = templates.build(rows, domains, percents, templates.load_overrides(templates.HERE / "data" / "template_speech.csv"))
    templates.write_patterns(patterns, app / "Data" / "Voices" / "templates.tsv")
    with path.open("w", encoding="ascii") as f:
        for key, text in cases:
            f.write(f"{text.encode('cp1252', 'replace').hex()} {key}\n")
    return len(cases)


def run_lua(script: Path, *params: str) -> tuple:
    cmd = [POWERSHELL32, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(HERE / "lua_host.ps1"),
           "-Dll", str(GAME / "ExeMods" / "MMExtension" / "lua51.dll"), "-Script", str(script),
           "-Params", "|".join(params)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr).strip()


def main() -> int:
    if not (GAME / "ExeMods" / "MMExtension" / "lua51.dll").exists():
        print(f"SKIP: no lua51.dll under {GAME} (set MM8_DIR)")
        return 0
    tmp = Path(tempfile.mkdtemp(prefix="mawvoice"))
    try:
        (tmp / "app" / "Data" / "Voices" / "NPC").mkdir(parents=True)
        cases = tmp / "cases.txt"
        n = write_cases(cases)
        print(f"{n} key cases written")
        template_cases = tmp / "template_cases.txt"
        print(f"{write_template_cases(template_cases, tmp / 'app')} template cases written")
        failed = 0
        for name, params in (("keys_test.lua", (str(MODULE), str(cases))),
                             ("templates_test.lua", (str(MODULE), str(tmp / "app") + "\\", str(template_cases))),
                             ("flow_test.lua", (str(MODULE), str(tmp / "app") + "\\"))):
            code, text = run_lua(HERE / "lua" / name, *params)
            print(f"{name}: {text}")
            failed += code != 0
        print("ALL PASSED" if not failed else f"{failed} FILE(S) FAILED")
        return 1 if failed else 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
