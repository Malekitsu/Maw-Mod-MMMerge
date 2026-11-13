#!/usr/bin/env python3
"""
German edition: recordings for the texts with run-time placeholders (%01, %02, %05, %17, ...).

    python -I templates_de.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --work work/

Same job as Tools/Voice/templates.py, on the German texts: the game fills the placeholders in just before it shows
the text, so the shown text has no recording of its own. Names and class names are left out of the spoken version
("Ah, %16. Die Zeichen stehen dunkel." is spoken "Ah. Die Zeichen stehen dunkel."), words and numbers from a fixed set
are spoken exactly, one recording per value: time of day, his/her, Lord/Lady, reputation word (German words from
Data/GermanT.lod, shown through work/localization_de/13_GlobalTxt.txt), the percent a hireling takes.

Reads  work/texts_de.csv, work/prioritaet.csv, the game's tables.
Writes work/templates_de.csv (recordings to make: key = t<key_de>~<value>..., column paket), work/templates_de.tsv
(patterns for the module: Data/Voices/templates_de.tsv), work/localization_de/13_GlobalTxt.txt and
work/templates_de_report.txt (spoken version of every template and the silent ones).
A template whose names the rules cannot drop needs a line in data/template_speech_de.csv (key_de, spoken, note;
spoken "-" = silent).
"""

import argparse
import csv
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402
import templates as tp  # noqa: E402

NAME, CLASS = tp.NAME, tp.CLASS
INTRO = re.compile(r"^(?:Ich heiße|Mein Name ist|Ich bin|Man nennt mich|Mein Name lautet)\s+(?:%14\s+)?%01[.!]?$")
GLOBAL_IDS = (383, 384, 388, 389, 395, 396, 397, 379, 392, 399, 402, 434)


def drop_names(text: str) -> str:
    """German twin of templates.drop_names: only forms that leave a sentence behind."""
    s = tp._DIRECTION.sub(" ", text).strip()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(rf"^(?:{CLASS}\s+)?(?:%10\s+)?{NAME}(?:\.\.\.|[.,!?…]+)\s*", "", s)
    s = re.sub(rf"^{CLASS}[,!]\s*", "", s)
    s = " ".join(p for p in tp._SENTENCE_END.split(s) if not INTRO.match(p.strip()))
    s = re.sub(r"(?<![\w%])%01, zu Euren Diensten", "Zu Euren Diensten", s)
    s = re.sub(rf"\b(Freund|Freunde) {NAME}", r"\1", s)
    s = re.sub(rf",\s*(?:{CLASS}\s+{NAME}|{NAME}|{CLASS}),", ",", s)
    s = re.sub(rf",\s*(?:{CLASS}\s+)?(?:%10\s+)?{NAME}(?=[.!?…])", "", s)
    s = re.sub(rf",\s*{CLASS}(?=[.!?…])", "", s)
    s = re.sub(rf"(?<=[.!?…])\s+(?:{CLASS}\s+)?{NAME}[.!?…]+(?=\s|$)", "", s)
    s = re.sub(rf"\s+(?:{CLASS}\s+)?{NAME}(?=[.!?…])", "", s)
    s = re.sub(rf"\s+{CLASS}(?=[.!?…])", "", s)
    s = re.sub(rf"\s+(?:{CLASS}\s+)?{NAME}(?=,)", "", s)
    s = re.sub(r"\s+([,.!?…])", r"\1", s)
    s = re.sub(r"([!?])\s*\1+", r"\1", s)
    s = re.sub(r"\s{2,}", " ", s)
    return tp.capitalize(s.strip(" ,"))


def german_domains(game: Path):
    """Like templates.load_domains, with the German words of Data/GermanT.lod; also the German Global rows to localize."""
    domains, percents = tp.load_domains(game)
    de = ex.read_lod(game / "Data" / "GermanT.lod")
    glob = {ex.row_id(ex.cell(r, 0)): ex.decode(ex.cell(r, 1)) for r in ex.parse_table(de["global.txt"])[1:]
            if ex.row_id(ex.cell(r, 0)) is not None}
    domains = {tok: [glob[i] for i in ids] for tok, ids in tp.GLOBAL_WORDS.items()} | {"%04": domains["%04"]}
    return domains, percents, {i: glob[i] for i in GLOBAL_IDS}


def write_global(rows: dict, path: Path):
    lines = ["Table\tId\tField\tText"] + [f"GlobalTxt\t{i}\t\t{t}" for i, t in sorted(rows.items())]
    path.write_bytes(("\r\n".join(lines) + "\r\n").encode(ex.TEXT_ENCODING))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--overrides", type=Path, default=HERE / "data" / "template_speech_de.csv")
    args = ap.parse_args(argv)
    work = args.work

    texts = list(csv.DictReader((work / "texts_de.csv").open(encoding="utf-8")))
    prio = {r["key_de"]: r for r in csv.DictReader((work / "prioritaet.csv").open(encoding="utf-8"))}
    domains, percents_en, global_rows = german_domains(args.game)
    rows, percents = [], {}
    for r in texts:
        if r["template"] != "1":
            continue
        rows.append({"key": r["key_de"], "text": r["text_de"], "source": r["source"], "n_sources": "1"})
        if r["key_en"] in percents_en:
            percents[r["key_de"]] = percents_en[r["key_en"]]
    overrides = tp.load_overrides(args.overrides)
    tp.drop_names = drop_names
    stat = re.compile(r"%01\s+(?:nimmt|kostet)")  # description of a hireling: information rather than speech
    sheets = [r for r in rows if stat.search(r["text"])]
    rows = [r for r in rows if not stat.search(r["text"])]
    recordings, patterns, skipped, spoken_of, cases = tp.build(rows, domains, percents, overrides)
    skipped += [(r["key"], "stat sheet of a hireling, not speech", r["text"]) for r in sheets]

    # decimal comma in the spoken numbers (0.5 -> 0,5)
    for rec in recordings:
        rec["text"] = re.sub(r"(\d)\.(\d)", r"\1,\2", rec["text"])
        base = prio.get(rec["key"][1:].split("~")[0], {})
        rec["paket"] = base.get("paket", "maw")
        rec["gender"] = base.get("gender", rec["gender"])  # the speakers of the text, not the parity of the key
    out = work / "templates_de.csv"
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["key", "paket", "gender", "chars", "source", "text"], extrasaction="ignore")
        w.writeheader()
        w.writerows(recordings)
    tp.write_patterns(patterns, work / "templates_de.tsv")
    # for the Lua test (tests/run_german_template_tests.py): the shown text of every recording and its key
    (work / "templates_de_cases.txt").write_text("".join(f"{shown.encode('cp1252', 'replace').hex()} {key}" + chr(10) for key, shown in cases), encoding="ascii")
    (work / "localization_de").mkdir(exist_ok=True)
    write_global(global_rows, work / "localization_de" / "13_GlobalTxt.txt")
    with (work / "templates_de_report.txt").open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(f"{r['key']} [{r['source']}]\n  shown : {r['text']!r}\n  spoken: {spoken_of.get(r['key'])!r}\n")
        f.write("\nSILENT\n")
        for key, why, text in skipped:
            f.write(f"{key}: {why}: {text!r}\n")
    by = {}
    for rec in recordings:
        by.setdefault(rec["paket"], [0, 0])
        by[rec["paket"]][0] += 1
        by[rec["paket"]][1] += rec["chars"]
    print(f"{len(rows)} templates: {len(patterns)} voiced with {len(recordings)} recordings, {len(skipped)} silent")
    for p, (n, c) in sorted(by.items()):
        print(f"  {p}: {n} recordings, {c} characters, ~{int(c * 0.22)} credits")
    return 0


if __name__ == "__main__":
    sys.exit(main())
