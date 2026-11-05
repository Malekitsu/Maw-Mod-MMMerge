#!/usr/bin/env python3
"""
Writes data/lua_quests_de.csv (English;German) from work/lua_quest_en.csv (extract_lua_quest_texts.py) and the
German texts below, in the order of the English list. "backslash n" stands for a line break, as in the other files.

    python make_lua_quests_de.py
"""

from pathlib import Path

HERE = Path(__file__).resolve().parent
BS = chr(92)
N = BS + "n"

GERMAN = [
    "Telelokator aufladen",
    "Gegenstand orten",
    "Person orten",
    "Monster orten",
    "Willkommen in der Arena, Krieger! Es mag anders sein, als Ihr es in Erinnerung habt. Bereitet Euch vor, schärft Eure Fertigkeiten und stellt Euch der Herausforderung. Zeigt Eure Stärke, Eure Taktik und Eure Entschlossenheit. Der Kampf erwartet Euch!",
    "Endlose Arena",
    "Startstufe ",
    "Los geht's!",
    "Dimensionskarten",
    "Druidenreif",
    "Die Pilger, die zum Druidenkreis wollten, suchten mehr als alte Steine. Man sagt, die Druiden der Ahnen hätten dort ein Relikt hinterlassen, den Druidenreif der Macht. Der Sonnentempel möchte ihn in Sicherheit bringen, bevor er in falsche Hände fällt. Der Kreis liegt nordöstlich von hier. Wenn Ihr den Reif findet, bringt ihn mir, und der Tempel wird Euch belohnen.",
    "Ihr habt den Reif nicht. Der Druidenkreis liegt nordöstlich von hier; sucht dort danach.",
    "Der Druidenreif der Macht! Wie viele Pilger haben ihr Leben gegeben, nur um ihn einmal zu sehen... Der Sonnentempel wird ihn sicher verwahren. Nehmt die Dankbarkeit des Tempels an, und dieses Amulett.",
    "Der Reif ist in sicheren Händen. Der Sonnentempel wird Eure Hilfe nicht vergessen.",
    "Den Druidenreif der Macht im Druidenkreis finden und zu Dantillion in Murmurwoods bringen.",
    "Wenn Ihr einen neuen Weg einschlagen und Eure Fertigkeiten zurücksetzen wollt, seid Ihr hier richtig.",
    "Fertigkeiten zurücksetzen",
    "Wenn Ihr zustimmt, werden alle Fertigkeiten, die Ihr besitzt, auf den Anfang zurückgesetzt, auf die Stufe eines Anfängers, und alle Punkte, die Ihr in diese Fertigkeiten gesteckt habt, werden Euch zurückgegeben." + N + N + "Sobald Eure Fertigkeit die nötige Stufe erreicht, wird Euch die Meisterschaft darin erneut verliehen, falls Ihr sie zuvor schon hattet." + N + N + "Für diese Dienstleistung ist ein Tribut von 1000 Gold für jede erreichte Stufe zu entrichten",
    "Ich möchte zurücksetzen",
    "Eure Fertigkeitspunkte wurden zurückgesetzt!",
    "Kopfgeld",
]


def main():
    english = [line.rsplit(";", 2)[0] for line in (HERE / "work" / "lua_quest_en.csv").read_text(encoding="utf-8").splitlines() if line]
    assert len(english) == len(GERMAN), (len(english), len(GERMAN))
    rows = ["English;German"] + [f"{e};{g}" for e, g in zip(english, GERMAN)]
    (HERE / "data" / "lua_quests_de.csv").write_text(chr(10).join(rows) + chr(10), encoding="utf-8")
    # the file the language module reads: English<TAB>German, cp1252
    out = HERE / "work" / "localization_de_map"
    out.mkdir(parents=True, exist_ok=True)
    body = (chr(13) + chr(10)).join(f"{e}{chr(9)}{g}" for e, g in zip(english, GERMAN)) + chr(13) + chr(10)
    (out / "lua_quests.tsv").write_bytes(body.encode("cp1252"))
    print(len(GERMAN), "texts")


main()
