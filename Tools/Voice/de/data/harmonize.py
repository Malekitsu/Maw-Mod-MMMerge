#!/usr/bin/env python3
"""
Vereinheitlicht Begriffe in den uebersetzten Paketen work/chunks/out_*.jsonl.

Aufruf (aus Tools/Voice/de):   python -I work\\harmonize.py [--dry-run]

- Legt vor dem ersten Lauf eine Sicherung an (Kopie von work/chunks, wird nie ueberschrieben):
  chunks_backup_pre_harmonize (Lauf 1, Pakete 01-11), chunks_backup_pre_harmonize2 (Lauf 2, alle Pakete).
- Ersetzt abweichende Formen durch die in work/glossary_add.csv festgelegte Form. Grundlage ist die
  explizite Tabelle RULES unten (abweichende Form -> endgueltige Form, inklusive Beugungsformen).
- Ersetzt nur ganze Woerter bzw. Wortgruppen (keine Treffer mitten in einem Wort).
- Schreibt die Dateien als UTF-8 mit ensure_ascii=False zurueck (nur, wenn sich etwas geaendert hat)
  und meldet je Ersetzung die Zahl der Stellen. Platzhalter, Zahlen und Zeilenumbrueche bleiben
  unangetastet, weil die Regeln nur Wortgruppen ohne diese Zeichen enthalten.
- Wiederholbar: ein zweiter Lauf meldet 0 Ersetzungen. Neue Abweichungen einfach als Zeile in RULES ergaenzen.
- Am Ende steht eine Restpruefung: Formen, die nicht mehr vorkommen sollten.
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

WORK = Path(__file__).resolve().parent
CHUNKS = WORK / "chunks"
BACKUP = WORK / "chunks_backup_pre_harmonize"
BACKUP2 = WORK / "chunks_backup_pre_harmonize2"  # Stand vor dem zweiten Lauf (alle Pakete 01-33)

W0 = r"(?<![\w-])"  # kein Wortzeichen davor
W1 = r"(?![\w])"    # kein Wortzeichen danach

# (Bezeichnung, Regex, Ersatz). Reihenfolge ist wichtig: spezielle Regeln vor allgemeinen.
RULES = [
    # --- Tularean-Wald (Tularean bleibt, Bindestrich, "Wald")
    ("Tularean-Wald", r"Tulareanischen Waldes", "Tularean-Waldes"),
    ("Tularean-Wald", r"Tulareanischen Wald", "Tularean-Wald"),
    ("Tularean-Wald", r"Tularea-Waldes", "Tularean-Waldes"),
    ("Tularean-Wald", r"Tularea-Wald", "Tularean-Wald"),
    ("Tularean-Wald", r"des Tularean Forests?", "des Tularean-Waldes"),
    ("Tularean-Wald", r"Tularean Forest", "Tularean-Wald"),
    # --- Grabhuegel (Barrow Downs); Hügelgräber bleibt fuer Barrows
    ("Grabhügel", r"Spukhaus in den Hügelgräbern", "Spukhaus in den Grabhügeln"),
    ("Grabhügel", r"in den Hügelgräberhügeln", "in den Grabhügeln"),
    ("Grabhügel", r"verlassenen Barrow Downs", "verlassenen Grabhügeln"),
    ("Grabhügel", r"den Barrow Downs", "den Grabhügeln"),
    ("Grabhügel", r"der Barrow Downs", "der Grabhügel"),
    ("Grabhügel", r"Barrow Downs", "Grabhügel"),
    # --- die Grube (Pit)
    ("Grube", r"die Hall of the Pit", "die Halle der Grube"),
    ("Grube", r"Hall of the Pit", "Halle der Grube"),
    ("Grube", r"die Pit" + W1, "die Grube"),
    ("Grube", r"der Pit" + W1, "der Grube"),
    # --- Nebelwälle (Walls of Mist), Insel Mist
    ("Nebelwälle", r"Nebelwänden", "Nebelwällen"),
    ("Nebelwälle", r"Nebelwände", "Nebelwälle"),
    ("Nebelwälle", r"Walls of Mist", "Nebelwälle"),
    ("Insel Mist", r"Island of Mist", "Insel Mist"),
    # --- Minen der Roten Zwerge
    ("Minen der Roten Zwerge", r"Roten Zwergenminen", "Minen der Roten Zwerge"),
    ("Minen der Roten Zwerge", r"Minen des Roten Zwergs", "Minen der Roten Zwerge"),
    ("Mine der Roten Zwerge", r"Mine des Roten Zwergs", "Mine der Roten Zwerge"),
    # --- Schloß <Name> statt Burg <Name>
    ("Schloß X", r"südlich der Burg (Gryphonheart|Lambent|Gloaming|Darkmoor|Ironfist|Harmondale|Kriegspire|Stone|Temper|Alamos|Stromgard)", r"südlich des Schlosses \1"),
    ("Schloß X", r"der Burg (Gryphonheart|Lambent|Gloaming|Darkmoor|Ironfist|Harmondale|Kriegspire|Stone|Temper|Alamos|Stromgard)", r"des Schlosses \1"),
    ("Schloß X", r"\bBurg (Gryphonheart|Lambent|Gloaming|Darkmoor|Ironfist|Harmondale|Kriegspire|Stone|Temper|Alamos|Stromgard)", r"Schloß \1"),
    ("Schloß (alte Rechtschreibung)", W0 + r"Schloss" + W1, "Schloß"),
    # --- Champion = Erster Ritter (Glossar)
    ("Erster Ritter", r"zu Champions ehrenhalber", "zu Ersten Rittern ehrenhalber"),
    ("Erster Ritter", r"zu Champions", "zu Ersten Rittern"),
    ("Erster Ritter", r"Champions ehrenhalber", "Erste Ritter ehrenhalber"),
    ("Erster Ritter", r"Euch Champions nennen", "Euch Erste Ritter nennen"),
    ("Erster Ritter", r"Champions genannt werden", "Erste Ritter genannt werden"),
    ("Erster Ritter", r"Champions zu werden", "Erste Ritter zu werden"),
    ("Erster Ritter", r"Champions werden", "Erste Ritter werden"),
    ("Erster Ritter", r"Licht, Champions!", "Licht, Erste Ritter!"),
    ("Erster Ritter", r"ein Champion sein", "ein Erster Ritter sein"),
    ("Erster Ritter", r"zum Champion befördern", "zum Ersten Ritter befördern"),
    # --- Große Druiden (zwei Wörter); Ehren-Ränge: Einwortränge "Ehren-X" (Bindestrich), Mehrwortränge "X ehrenhalber"
    ("Große Druiden ehrenhalber", r"alle Ehren-Großdruiden", "alle Großen Druiden ehrenhalber"),
    ("Große Druiden ehrenhalber", r"Ehren-Großdruiden", "Große Druiden ehrenhalber"),
    ("Große Druiden", W0 + r"Großdruiden" + W1, "Große Druiden"),
    ("Ehren-Priester", r"Priestern (des Lichts|der Dunkelheit) ehrenhalber", r"Ehren-Priestern \g<1>"),
    ("Ehren-Priester", r"Ehrenpriester", "Ehren-Priester"),
    ("Ehren-Schurke", r"Ehrengaunern", "Ehren-Schurken"),
    ("Ehren-Druide", r"Ehrendruiden", "Ehren-Druiden"),
    ("Ehren-Zauberer", r"Ehrenzauberer", "Ehren-Zauberer"),
    ("Ehren-Lich", r"Ehrenliche", "Ehren-Liche"),
    ("Ehren-Kreuzritter", r"Ehrenkreuzritter", "Ehren-Kreuzritter"),
    ("Ehren-Held", r"Ehrenhelden", "Ehren-Helden"),
    ("Ehren-Hohepriester", r"Ehrenhohenpriestern", "Ehren-Hohenpriestern"),
    ("Ehren-Magier", r"Ehrenmagiers", "Ehren-Magiers"),
    ("Ehren-X (statt X ehrenhalber)", W0 + r"(Kriegsmagiern|Kriegsmagier|Scharfschützen|Kavaliere|Kavalieren|Kavalier|Jäger|Kopfgeldjäger|Priestern|Priester|Zauberer|Liche) ehrenhalber", r"Ehren-\g<1>"),
    # --- Oscillation Overthruster bleibt englisch
    ("Oscillation Overthruster", r"Oszillations-Überstoßer", "Oscillation Overthruster"),
    # --- Meuchelmörder (Assassin) / Schurke (Rogue)
    ("Meuchelmörder", r"ein Assassine", "ein Meuchelmörder"),
    ("Meistermeuchelmörder", r"Meisterattentäter", "Meistermeuchelmörder"),
    ("Schurke", r"Euch Gauner nennen", "Euch Schurken nennen"),
    ("Schurke", r"Gauner stehlen", "Schurken stehlen"),
    ("Schurke", r"zu Gaunern befördern", "zu Schurken befördern"),
    ("Schurke", r"Titel eines Gauners", "Titel eines Schurken"),
    # --- Lords (nicht Herren)
    ("Lords von Harmondale", r"Herren von Harmondale", "Lords von Harmondale"),
    ("Lords", r"neue Herren ihr Amt", "neue Lords ihr Amt"),
    ("Lords", r"Reden nichts ausrichten, meine Herren", "Reden nichts ausrichten, meine Lords"),
    # --- Sonstiges
    ("Meduse", r"einer Art Medusa" + W1, "einer Art Meduse"),
    ("Wachturm", r"auf Watchtower" + W1, "auf Wachturm"),
    ("Wachturm", W0 + r"Watchtower" + W1, "Wachturm"),
    ("Herr (Mr.)", r"\bMr\. (?=[A-Z])", "Herr "),
    ("Weißklippenhöhlen", r"White Cliff Caves", "Weißklippenhöhlen"),
    ("Gezeitenhöhlen", r"Tidewater Caverns", "Gezeitenhöhlen"),
    # ================= zweiter Lauf (alle Pakete 01-33), Entscheidungen siehe glossary_add.csv =================
    # --- Scavenger Hunt = Schatzsuche
    ("Schatzsuche", W0 + r"Schnitzeljagd" + W1, "Schatzsuche"),
    # --- Gilde des Selbst (Self Guild) bleibt von Seelengilde (Spirit Guild) getrennt
    ("Gilde des Selbst", r"gegenüber der Seelengilde zum Experten in der Meditation", "gegenüber der Gilde des Selbst zum Experten in der Meditation"),
    # --- Circus of the Sun = Zirkus der Sonne
    ("Zirkus der Sonne", r"Circus of the Sun", "Zirkus der Sonne"),
    # --- Star Lake bleibt englisch (MM7-Ortsname wie Silver Cove)
    ("Star Lake", W0 + r"Sternensee" + W1, "Star Lake"),
    # --- Brunnen der Magie (Fountain of Magic)
    ("Brunnen der Magie", r"der sagenumwobenen Fountain of Magic", "des sagenumwobenen Brunnens der Magie"),
    ("Brunnen der Magie", r"Die Fountain of Magic soll", "Der Brunnen der Magie soll"),
    ("Brunnen der Magie", r"Fountain of Magic", "Brunnen der Magie"),
    # --- Schloß X: restliche englische Formen
    ("Schloß X (Castle X)", r"\bCastle (Gryphonheart|Lambent|Gloaming|Darkmoor|Ironfist|Harmondale|Kriegspire|Stone|Temper|Alamos|Stromgard)", r"Schloß \1"),
    # --- allgemein 'das Schloß' statt 'Burg' (nicht bei 'ihrer Burg hat das Schloß ...': dort Wortspiel mit Türschloß)
    ("Schloß (allgemein)", r"Eure Burg" + W1, "Euer Schloß"),
    ("Schloß (allgemein)", r"zu Eurer Burg", "zu Eurem Schloß"),
    ("Schloß (allgemein)", r"Euch die Burg gefallen", "Euch das Schloß gefallen"),
    ("Schloß (allgemein)", r"die Burg zu säubern", "das Schloß zu säubern"),
    ("Schloß (allgemein)", r"in der Burg auf, sonst", "im Schloß auf, sonst"),
    ("Schloß (allgemein)", r"unter der Burg haben", "unter dem Schloß haben"),
    ("Schloß (allgemein)", r"aus der Burg vertrieben", "aus dem Schloß vertrieben"),
    ("Schloß (allgemein)", r"in einer Burg nahe New Sorpigal", "in einem Schloß nahe New Sorpigal"),
    ("Schloß (allgemein)", r"Wir nehmen Burg,", "Wir nehmen Schloß,"),
    # --- Temple Stone (Eigenname) bleibt englisch
    ("Temple Stone", W0 + r"Tempel Stone" + W1, "Temple Stone"),
    # --- Gilde der Nekromanten (Glossar), nicht Nekromantengilde
    ("Gilde der Nekromanten", W0 + r"Nekromantengilde" + W1, "Gilde der Nekromanten"),
    # --- Plural von Lich = Liche
    ("Liche", r"Buch der Lichs", "Buch der Liche"),
    ("Liche", r"Lichs sind mächtig", "Liche sind mächtig"),
    # --- Ehren-Druiden / Ehren-Erzdruiden (Einwortränge mit Bindestrich)
    ("Ehren-Druide", r"zu Erzdruiden ehrenhalber", "zu Ehren-Erzdruiden"),
    ("Ehren-Druide", r"zu Druiden ehrenhalber", "zu Ehren-Druiden"),
    # --- Villain = Bösewicht (Rangtitel)
    ("Bösewicht", r"Schurke von außerordentlichem Rang", "Bösewicht von außerordentlichem Rang"),
    # --- Lords von Harmondale
    ("Lords von Harmondale", r"rechtmäßigen Herrscher von Harmondale", "rechtmäßigen Lords von Harmondale"),
]

# Formen, die nach dem Lauf nicht mehr vorkommen sollten (nur Warnung).
RESIDUE = [
    r"Champions?" + W1, r"Barrow Downs", r"Tularean Forest", r"Tulareanisch", r"Tularea-", r"\bBurg [A-Z]",
    r"Ehren(?!titel|-)[a-zäöü]+", r"Großdruide", r"Gauner", r"Assassine", r"\bPit\b", r"Walls of Mist",
    r"Island of Mist", r"Watchtower", r"\bMr\.", r"Oszillation", r"Nebelwänd", r"Hügelgräberhügel",
    r"Schnitzeljagd", r"Sternensee", r"Circus of", r"Fountain of", r"\bCastle\b", r"Tempel Stone",
    r"Nekromantengilde", r"\bBurg\b(?! hat das Schloß)",
]


def compiled(rules):
    return [(label, re.compile(rx), rep) for label, rx, rep in rules]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="nur zaehlen, nichts schreiben")
    args = ap.parse_args()

    if not args.dry_run and not BACKUP2.exists():
        shutil.copytree(CHUNKS, BACKUP2)
        print("Sicherung angelegt:", BACKUP2)

    rules = compiled(RULES)
    counts = {}
    changed_files = 0
    total = 0
    residue = {}
    for path in sorted(CHUNKS.glob("out_*.jsonl")):
        out_lines = []
        changed = False
        with open(path, encoding="utf-8") as f:
            for line in f:
                raw = line.rstrip("\n")
                if not raw.strip():
                    out_lines.append(line)
                    continue
                d = json.loads(raw)
                text = d["de"]
                orig = text
                for label, rx, rep in rules:
                    text, n = rx.subn(rep, text)
                    if n:
                        key = (label, rx.pattern, rep)
                        counts[key] = counts.get(key, 0) + n
                        total += n
                for rx in RESIDUE:
                    for m in re.finditer(rx, text):
                        residue.setdefault(rx, []).append((path.name, d["key"], text[max(0, m.start() - 25):m.end() + 25].replace("\n", " ")))
                if text != orig:
                    d["de"] = text
                    changed = True
                    out_lines.append(json.dumps(d, ensure_ascii=False) + "\n")
                else:
                    out_lines.append(line)
        if changed:
            changed_files += 1
            if not args.dry_run:
                with open(path, "w", encoding="utf-8", newline="") as f:
                    f.writelines(out_lines)

    for (label, pat, rep), n in counts.items():
        print(f"{n:4d}  [{label}]  {pat}  ->  {rep}")
    print(f"Ersetzungen gesamt: {total} in {changed_files} Dateien" + (" (Trockenlauf)" if args.dry_run else ""))
    if residue:
        print("Restpruefung (bitte ansehen):")
        for rx, hits in residue.items():
            print(f"  {rx}: {len(hits)}")
            for h in hits[:5]:
                print("     ", h)
    else:
        print("Restpruefung: keine unerwuenschten Formen mehr.")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
