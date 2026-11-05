"""Builds Install_German.exe (PyInstaller, needs `pip install pyinstaller`): the installer with Python and its data inside.

    python build_exe.py <work folder> <texts_de_public.csv> <output folder>
"""
import subprocess, sys, shutil
from pathlib import Path
R = Path(__file__).resolve().parents[1]
work = Path(sys.argv[1]); public = Path(sys.argv[2]); out = Path(sys.argv[3])
data = work / "data"
shutil.rmtree(data, ignore_errors=True); data.mkdir(parents=True)
for p in list((R / "data").glob("*")) + [R / "de" / "data" / n for n in ("bad_pairs.csv", "mod_texts_de.csv", "mod_texts2_de.csv", "names_extra_de.csv", "ui_short_de.csv", "shop_de.csv")] + [public]:
    shutil.copy2(p, data / p.name)
# the data folder holds both Tools/Voice/data and Tools/Voice/de/data: the modules look in <their folder>/data
cmd = [sys.executable, "-m", "PyInstaller", "--onefile", "--console", "--name", "Install_German", "--distpath", str(out), "--workpath", str(work / "pyi"), "--specpath", str(work),
       "--paths", str(R), "--paths", str(R / "de"), "--add-data", f"{data};data", str(R / "de" / "install_german.py")]
sys.exit(subprocess.run(cmd).returncode)
