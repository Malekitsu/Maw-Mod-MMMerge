#!/usr/bin/env python3
"""
Lua test for the German templates: for every recording of a template text (de/templates_de.py) the voice module,
in German mode, finds the file from the text the game shows.

    python -I Tools/Voice/tests/run_german_template_tests.py
Needs de/work/templates_de.tsv and templates_de_cases.txt (python -I Tools/Voice/de/templates_de.py ...).
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

WORK = rlt.ROOT / "Tools" / "Voice" / "de" / "work"
WRAPPER = 'MawLanguage = {Active = "de"}\nlocal f = assert(loadfile(...))\nreturn f(select(2, ...))\n'


def main() -> int:
    if not (rlt.GAME / "ExeMods" / "MMExtension" / "lua51.dll").exists() or not (WORK / "templates_de.tsv").exists():
        print("SKIP: no game folder or no work/templates_de.tsv")
        return 0
    tmp = Path(tempfile.mkdtemp(prefix="mawtde"))
    try:
        voices = tmp / "app" / "Data" / "Voices"
        voices.mkdir(parents=True)
        shutil.copy(WORK / "templates_de.tsv", voices / "templates_de.tsv")
        wrapper = tmp / "wrapper.lua"
        wrapper.write_text(WRAPPER, encoding="ascii")
        code, text = rlt.run_lua(wrapper, str(HERE / "lua" / "templates_test.lua"), str(rlt.MODULE),
                                 str(tmp / "app") + "\\", str(WORK / "templates_de_cases.txt"))
        print(f"templates_test.lua (German): {text}")
        print("ALL PASSED" if code == 0 else "FAILED")
        return code
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
