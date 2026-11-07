#!/usr/bin/env python3
"""
German edition, phase 2: the texts of the user interface (labels, shops, spells, quests ...) from Data/GermanT.lod.

    python -I export_ui.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --out work/localization_de_ui

The original German tables of Might and Magic 8 (GermanT.lod) are paired with the tables of the merged game
(mmmerge.T.lod) by row number, like align_german.py does for the dialogs. A German cell is used when
  * it differs from the English one (not a copy),
  * numbers, placeholders and question marks agree and the length ratio is plausible (align_german.check_pair).
Everything else stays English: texts that the mod added, texts the mod changed, texts without a German original.
Writes <out>/2n_<Table>.txt in the format zzzMaw_Language.lua reads ("Table<TAB>Id<TAB>Field<TAB>Text", cp1252, CRLF,
backslash-n, backslash-t and double backslash as escapes), <out>/99_Names.txt (name swaps, see renames()) and
<out>/../ui_report.txt with the numbers per table.
"""

import argparse
import collections
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import align_german as ag  # noqa: E402
import groups  # noqa: E402
import extract_texts as ex  # noqa: E402

TAB = chr(9)
BS = chr(92)
CRLF = chr(13) + chr(10)
LONG = []  # (table, id, field, English, German) of the texts that are still much longer than the English
HEADER = TAB.join(["Table", "Id", "Field", "Text"])

# (LOD entry, Game table, {field: column}, row id: "col0" = number in column 0, "ordinal" = position after the header)
TABLES = [
    ("global.txt", "GlobalTxt", {"": 1}, "col0"),
    ("npctopic.txt", "NPCTopic", {"": 1}, "col0", (5,)),
    ("trans.txt", "TransTxt", {"": 1}, "col0", (2,)),
    ("mapstats.txt", "MapStats", {"Name": 1}, "col0", (2,)),
    ("spells.txt", "SpellsTxt", {"Name": 2, "ShortName": 4, "Description": 5, "Normal": 6, "Expert": 7, "Master": 8, "GM": 9}, "col0"),
    ("awards.txt", "AwardsTxt", {"": 1}, "col0"),
    ("autonote.txt", "AutonoteTxt", {"": 1}, "col0"),
    ("quests.txt", "QuestsTxt", {"": 1}, "col0", (3,)),
    ("history.txt", "HistoryTxt", {"Text": 1, "Title": 3}, "col0", (2,)),
    ("scroll.txt", "ScrollTxt", {"": 1}, "col0"),
    ("stats.txt", "StatsDescriptions", {"": 1}, "ordinal"),
    ("skilldes.txt", "SkillDescriptions", {"": 1}, "ordinal"),
    ("skilldes.txt", "SkillDesNormal", {"": 2}, "ordinal"),
    ("skilldes.txt", "SkillDesExpert", {"": 3}, "ordinal"),
    ("skilldes.txt", "SkillDesMaster", {"": 4}, "ordinal"),
    ("skilldes.txt", "SkillDesGM", {"": 5}, "ordinal"),
]


SHORT_TABLES = ("GlobalTxt", "NPCTopic", "Houses")  # labels and menus: narrow panels, the German must not run longer than needed
GOLD = "Goldst" + chr(252) + "ck"


def shorten(game: str, text: str) -> str:
    """Rules that shorten the German of the labels without changing the meaning (Goldstuecke -> Gold, as in English)."""
    if game not in SHORT_TABLES:
        return text
    text = text.replace(GOLD + "en", "Gold").replace(GOLD + "e", "Gold").replace(GOLD, "Gold")
    return text


def load_overrides(path: Path):
    """data/ui_short_de.csv: Table;Id;Field;German (semicolon separated, utf-8): hand-made short versions."""
    out = {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            parts = line.split(";", 3)
            if len(parts) == 4 and parts[0] != "Table":
                out[(parts[0], parts[1], parts[2])] = parts[3].replace(BS + "n", chr(10))
    return out


OVERRIDES = {}
BAD_ROWS = set()  # (table, row id) whose German original does not match the English text of the mod


def escape(text: str) -> str:
    return text.replace(BS, BS + BS).replace(chr(10), BS + "n").replace(TAB, BS + "t").replace(chr(13), "")


def rows_of(lod, entry, ordinal):
    """{row id: row} of a table; ordinal rows are numbered from 0 after the header line."""
    out = {}
    table = ex.parse_table(lod[entry])
    for pos, r in enumerate(table[1:]):
        if ordinal:
            out.setdefault(pos, r)
        else:
            rid = ex.row_id(ex.cell(r, 0))
            if rid is not None:
                out.setdefault(rid, r)
    return out


MAX_ID = {"GlobalTxt": 749, "StatsDescriptions": 7, "TransTxt": 271}  # the game's arrays end there (the language log showed the rows beyond as errors)


def lenient_ok(en: bytes, de: bytes) -> bool:
    """A pair that check_pair doubts only because of numbers written out ("Wait 1 Hour" / "Eine Stunde warten") or
    because the German uses fewer placeholders than the English (extra arguments of a printf format are ignored)."""
    reasons = ag.check_pair(en, de)[1].split("; ")
    if collections.Counter(ex._TOKEN.findall(de)) - collections.Counter(ex._TOKEN.findall(en)):
        return False  # a placeholder the game does not pass
    return all(r.startswith(("numbers differ", "placeholders differ")) for r in reasons if r)


def pair_table(en_lod, de_lod, entry, game, fields, ordinal, anchors=()):
    en_rows, de_rows = rows_of(en_lod, entry, ordinal), rows_of(de_lod, entry, ordinal)
    lines, stat = [], collections.Counter()
    for rid, en_row in en_rows.items():
        if rid > MAX_ID.get(game, 10 ** 9):
            continue
        de_row = de_rows.get(rid)
        if (game, str(rid)) in BAD_ROWS:
            de_row = None  # a reviewer found that this German text says something else (data/bad_pairs.csv)
            stat["bad"] += 1
        if de_row is not None and any(
                ex.decode(ex.cell(en_row, a)).strip().lower() != ex.decode(ex.cell(de_row, a)).strip().lower() for a in anchors):
            de_row = None  # the merged game numbers this row differently: no German original for it
            stat["moved"] += 1
        for field, col in fields.items():
            en = ex.cell(en_row, col)
            if not en.strip() or not any(ch.isalpha() for ch in ex.decode(en)):
                continue
            de = ex.cell(de_row, col) if de_row is not None else b""
            status, _ = ag.check_pair(en, de)
            if status == "suspect" and game == "GlobalTxt" and lenient_ok(en, de):
                status = "ok"
            stat[status] += 1
            if status == "ok" and "placeholder" not in ex.decode(de).lower():
                text = OVERRIDES.get((game, str(rid), field)) or shorten(game, ex.decode(de))
                lines.append(TAB.join([game, str(rid), field, escape(text)]))
                if game in SHORT_TABLES and len(text) >= 22 and len(text) > 1.5 * len(ex.decode(en)):
                    LONG.append((game, rid, field, ex.decode(en), text))
    return lines, stat


HOUSE_TITLES = {"Guildmaster": "Gildenmeister", "Clerk": "Schreiber", "Shopkeeper": "Ladenbesitzer", "Merchant": "H" + chr(228) + "ndler"}


U = chr(252)
HOUSE_NAMES = {
    "House": "Haus", "Empty House": "Leeres Haus", "Hostel": "Herberge", "Throne Room": "Thronsaal", "Tent": "Zelt",
    "Wagon": "Wagen", "The Adventurer's Inn": "Das Abenteurer-Gasthaus", "Guild Caravans": "Gildenkarawanen",
    "Town Hall": "Rathaus", "Arbiter": "Schiedsrichter", "Prison": "Gef" + chr(228) + "ngnis",
    "Flooded House": chr(220) + "berflutetes Haus", "The Depository": "Das Depot", "Healer's Tent": "Zelt des Heilers",
    "Temple of Dark": "Tempel der Dunkelheit", "Temple of Light": "Tempel des Lichts", "Temple of the Sun": "Tempel der Sonne",
    "Temple of the Moon": "Tempel des Mondes", "Temple of Baa": "Tempel des Baa", "Abandoned Temple": "Verlassener Tempel",
    "Castle of Air": "Schloss der Luft", "Castle Harmondale": "Schloss Harmondale",
    "Guild of Bounty Hunters": "Gilde der Kopfgeldj" + chr(228) + "ger", "Smugglers' Guild": "Schmugglergilde",
    "Protection Services": "Schutzdienste", "Buccaneers' Lair": "Piratenversteck", "Blades' End": "Klingenende",
    "Duelists' Edge": "Duellantenklinge", "Berserkers' Fury": "Wut der Berserker", "King's Library": "Bibliothek des K" + chr(246) + "nigs",
}
ELEMENTS = {"Fire": "Feuer", "Air": "Luft", "Water": "Wasser", "Earth": "Erde", "Spirit": "Seele", "Mind": "Geist", "Body": "K" + chr(246) + "rper"}
RANKS = {"Initiate": "Anf" + chr(228) + "nger", "Adept": "Adept", "Expert": "Experte", "Master": "Meister", "Grandmaster": "Gro" + chr(223) + "meister"}
RE_GUILD = re.compile("^(Initiate|Adept|Expert|Master|Grandmaster) Guild of (Fire|Air|Water|Earth|Spirit|Mind|Body)$")
RE_NAMED = [(re.compile("^([A-Za-z']+) Residence$"), "Residenz {}"), (re.compile("^([A-Za-z']+) Estate$"), "Anwesen {}"),
            (re.compile("^([A-Za-z']+) Cottage$"), "Haus {}"), (re.compile("^House ([A-Za-z0-9']+)$"), "Haus {}")]
RE_POSS = [(re.compile("^([A-Za-z]+)'s? House$"), "Haus"), (re.compile("^([A-Za-z]+)'s? Home$"), "Heim")]


def house_name(name: str):
    """German name of a house of Might and Magic 6/7 or of the mod that has no German original, for the common
    kinds (generic houses, guilds, temples, "<name> Residence"); None for shop names, which stay as they are."""
    if name in HOUSE_NAMES:
        return HOUSE_NAMES[name]
    m = RE_GUILD.match(name)
    if m:
        return f"{ELEMENTS[m.group(2)]}gilde ({RANKS[m.group(1)]})"
    for pattern, form in RE_NAMED:
        m = pattern.match(name)
        if m:
            return form.format(m.group(1))
    for pattern, word in RE_POSS:
        m = pattern.match(name)
        if m:
            owner = m.group(1)
            return f"{word} {owner}" if False else (owner + ("'" if owner[-1] in "sxz" else "s") + " " + word)
    return None


def dedupe(out: Path):
    """A text that the hand-made rows (the ModTexts file) set again replaces the older row in the other files: which file
    the game reads last must not decide."""
    mods = {}
    for folder in (out, out / "shops", out / "items"):
        for f in folder.glob("*ModTexts.txt"):
            for line in f.read_bytes().decode("cp1252").splitlines()[1:]:
                p = line.split(TAB)
                if len(p) >= 3:
                    mods[(p[0], p[1], p[2])] = f
    for folder in (out, out / "shops", out / "items"):
        for f in folder.glob("*.txt"):
            if f.name.endswith("ModTexts.txt") or f.name.startswith("99"):
                continue
            lines = f.read_bytes().decode("cp1252").splitlines()
            keep = [lines[0]] + [x for x in lines[1:] if tuple(x.split(TAB)[:3]) not in mods]
            if len(keep) != len(lines):
                f.write_bytes((CRLF.join(keep) + CRLF).encode("cp1252"))


def pair_merchant(en_lod, de_lod):
    """The merchant's sentences (merchant.txt: a row per situation, a column per action Buy, Sell, Repair, Identify).
    Game.MerchantTxt[column][row] with both counted from 0, so the lines are 'MerchantTxt<TAB>column<TAB>row<TAB>text'."""
    en_t, de_t = ex.parse_table(en_lod["merchant.txt"]), ex.parse_table(de_lod["merchant.txt"])
    lines = []
    for r in range(1, len(en_t)):
        for c in range(1, 5):
            en = ex.cell(en_t[r], c)
            de = ex.cell(de_t[r], c) if r < len(de_t) and len(de_t[r]) > c else b""
            if not any(ch.isalpha() for ch in ex.decode(en)) or ex.decode(en).strip() == "n/a":
                continue
            if lenient_ok(en, de) or ag.check_pair(en, de)[0] == "ok":
                lines.append(TAB.join(["MerchantTxt", str(c - 1), str(r - 1), escape(ex.decode(de))]))
    return lines


def pair_houses(en_lod, de_lod):
    """The houses of the merged game are numbered differently from the German original. A house is paired by its
    row number only when type and owner agree there; otherwise by type + owner name when that is unique in the
    German table. Name, owner name and title come from the German row; the titles are also carried over to every
    house with the same English title (Innkeep -> Gastwirt), the houses of Might and Magic 6 and 7 included."""
    er, dr = rows_of(en_lod, "2devents.txt", False), rows_of(de_lod, "2devents.txt", False)

    def key(r):
        return ex.decode(ex.cell(r, 2)).strip(), ex.decode(ex.cell(r, 6)).strip()

    by_key = collections.defaultdict(list)
    for rid, r in dr.items():
        by_key[key(r)].append(rid)
    lines, titles, stat = [], collections.defaultdict(collections.Counter), collections.Counter()
    for rid, en_row in er.items():
        k = key(en_row)
        d = dr.get(rid)
        if d is None or key(d) != k:
            ids = by_key.get(k, [])
            d = dr[ids[0]] if len(ids) == 1 and k[1] else None
        if d is not None:
            stat["paired"] += 1
            for field, col in (("Name", 5), ("OwnerName", 6), ("OwnerTitle", 7)):
                en, de = ex.cell(en_row, col), ex.cell(d, col)
                if ag.check_pair(en, de)[0] == "ok" and "placeholder" not in ex.decode(de).lower():
                    text = OVERRIDES.get(("Houses", str(rid), field)) or shorten("Houses", ex.decode(de))
                    lines.append(TAB.join(["Houses", str(rid), field, escape(text)]))
                    if field == "OwnerTitle":
                        titles[ex.decode(en).strip()][ex.decode(de).strip()] += 1
        else:
            stat["alone"] += 1
    named = {ln.split(TAB)[1] for ln in lines if ln.split(TAB)[2] == "Name"}
    for rid, en_row in er.items():  # houses without a German original: the common kinds by rule
        name = ex.decode(ex.cell(en_row, 5)).strip()
        if str(rid) not in named and name and name != "Placeholder":
            german = house_name(name)
            if german:
                lines.append(TAB.join(["Houses", str(rid), "Name", escape(german)]))
                stat["by rule"] += 1
    swap = {en: c.most_common(1)[0][0] for en, c in titles.items() if en}
    for en, de in HOUSE_TITLES.items():
        swap.setdefault(en, de)
    done = {(ln.split(TAB)[1]) for ln in lines if ln.split(TAB)[2] == "OwnerTitle"}
    for rid, en_row in er.items():
        title = ex.decode(ex.cell(en_row, 7)).strip()
        if title in swap and str(rid) not in done:
            lines.append(TAB.join(["Houses", str(rid), "OwnerTitle", escape(swap[title])]))
            stat["title only"] += 1
    return lines, stat


def renames(en_lod, de_lod):
    """(English, German) pairs for the name arrays that the game fills from Global.txt, Stats.txt, SkillDes.txt and
    Class.txt (SkillNames, StatsNames, ClassNames, NPCProfNames): the module swaps equal text. An English text with two
    different German renderings is left out. Also the class descriptions: (class id, German text)."""
    pairs = collections.defaultdict(set)
    en_g, de_g = rows_of(en_lod, "global.txt", False), rows_of(de_lod, "global.txt", False)
    for rid, en_row in en_g.items():
        de_row = de_g.get(rid)
        if de_row is None:
            continue
        en, de = ex.cell(en_row, 1), ex.cell(de_row, 1)
        if ag.check_pair(en, de)[0] == "ok" and len(en) < 40:
            pairs[ex.decode(en)].add(ex.decode(de))
    for entry in ("stats.txt", "skilldes.txt"):
        en_t, de_t = rows_of(en_lod, entry, True), rows_of(de_lod, entry, True)
        for pos, en_row in en_t.items():
            de_row = de_t.get(pos)
            if de_row is not None and ag.check_pair(ex.cell(en_row, 0), ex.cell(de_row, 0))[0] == "ok":
                pairs[ex.decode(ex.cell(en_row, 0))].add(ex.decode(ex.cell(de_row, 0)))
    de_class = {ex.decode(ex.cell(r, 2)).strip(): r for r in rows_of(de_lod, "class.txt", True).values()}
    classes = []
    for pos, en_row in rows_of(en_lod, "class.txt", True).items():
        name = ex.decode(ex.cell(en_row, 0)).strip()
        de_row = de_class.get(name)
        if de_row is not None and ex.decode(ex.cell(de_row, 0)).strip():
            pairs[name].add(ex.decode(ex.cell(de_row, 0)).strip())
            if ag.check_pair(ex.cell(en_row, 1), ex.cell(de_row, 1))[0] == "ok":
                classes.append((pos, ex.decode(ex.cell(de_row, 1))))
    swaps = sorted((en, next(iter(de))) for en, de in pairs.items() if len(de) == 1 and en != next(iter(de)))
    return swaps, classes


def write_file(path: Path, lines):
    body = CRLF.join([HEADER] + lines) + CRLF
    path.write_bytes(body.encode(ex.TEXT_ENCODING, errors="replace"))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args(argv)
    en_lod = ex.read_lod(args.game / "Data" / "mmmerge.T.lod")
    de_lod = ex.read_lod(args.game / "Data" / "GermanT.lod")
    args.out.mkdir(parents=True, exist_ok=True)
    OVERRIDES.update(load_overrides(HERE / "data" / "ui_short_de.csv"))
    bad_csv = HERE / "data" / "bad_pairs.csv"
    if bad_csv.exists():
        for line in bad_csv.read_text(encoding="utf-8").splitlines():
            parts = line.split(";")
            if len(parts) >= 2 and parts[1].isdigit():
                BAD_ROWS.add((parts[0], parts[1]))
    report = []
    number = 20
    # the group "shops" (groups.py) goes to <out>/shops/: the language module applies it only for German shops
    shop_houses = groups.shop_house_ids(en_lod)
    # a topic is in the group exactly when the answers it opens are: label and answer must be in the same language
    _shop_cells, shop_topics = groups.compute(args.game, en_lod)
    for group in ("shops", "items"):
        (args.out / group).mkdir(exist_ok=True)
        for old in (args.out / group).glob("*.txt"):
            old.unlink()

    def is_shop(line):
        cols = line.split(TAB)
        rid = ex.as_int(cols[1].encode("ascii"))
        if cols[0] == "MerchantTxt":
            return True
        if cols[0] == "Houses":
            return True  # every house name (guilds, taverns, temples too) can be set back to English
        if cols[0] == "GlobalTxt":
            return rid in groups.SHOP_GLOBAL
        if cols[0] == "NPCTopic":
            return rid in shop_topics
        return False

    def is_item(line):
        cols = line.split(TAB)
        return cols[0] == "GlobalTxt" and ex.as_int(cols[1].encode("ascii")) in groups.ITEM_GLOBAL

    def write(path, lines):
        shop = [x for x in lines if is_shop(x)]
        item = [x for x in lines if is_item(x)]
        write_file(path, [x for x in lines if not is_shop(x) and not is_item(x)])
        if shop:
            write_file(path.parent / "shops" / path.name, shop)
        if item:
            write_file(path.parent / "items" / path.name, item)
    for entry, game, fields, kind, *anchor in TABLES:
        lines, stat = pair_table(en_lod, de_lod, entry, game, fields, kind == "ordinal", anchor[0] if anchor else ())
        write(args.out / f"{number}_{game}.txt", lines)
        number += 1
        report.append(f"{game:20} {entry:14} taken={len(lines):5} ok={stat['ok']:5} suspect={stat['suspect']:5} none={stat['none']:5} moved={stat['moved']:5}")
    lines = pair_merchant(en_lod, de_lod)
    write(args.out / f"{number + 2}_MerchantTxt.txt", lines)
    report.append(f"{'MerchantTxt':20} merchant.txt   taken={len(lines):5} of 24")
    lines, stat = pair_houses(en_lod, de_lod)
    write(args.out / f"{number}_Houses.txt", lines)
    report.append(f"{'Houses':20} 2devents.txt   taken={len(lines):5} paired={stat['paired']} alone={stat['alone']} by rule={stat['by rule']} title only={stat['title only']}")
    # translated here, no German original (see dump_untranslated.py): mod_texts_de.csv "Table;Id;German",
    # mod_texts2_de.csv "Table;Id;Field;German"
    lines = []
    for name, cols in (("mod_texts2_de.csv", 4), ("mod_texts_de.csv", 3)):  # the hand-made rows last: they win
        extra = HERE / "data" / name
        if extra.exists():
            for line in extra.read_text(encoding="utf-8").splitlines():
                parts = line.split(";", cols - 1)
                if len(parts) == cols and parts[0] != "Table":
                    field = parts[2] if cols == 4 else ""
                    lines.append(TAB.join([parts[0], parts[1], field, parts[-1]]))
    if lines:
        write(args.out / f"{number + 1}_ModTexts.txt", lines)
        report.append(f"{'ModTexts':20} mod_texts_de.csv  taken={len(lines):5}")
    dedupe(args.out)
    swaps, classes = renames(en_lod, de_lod)
    # data/names_extra_de.csv (English;German): names the original German game does not have (mod skills) and
    # shortened ones; they win over the swaps found above
    extra_names = {}
    names_csv = HERE / "data" / "names_extra_de.csv"
    if names_csv.exists():
        for line in names_csv.read_text(encoding="utf-8").splitlines():
            parts = line.split(";", 1)
            if len(parts) == 2 and parts[0] != "English":
                extra_names[parts[0]] = parts[1]
    swaps = [(en, extra_names.pop(en, de)) for en, de in swaps]
    swaps += sorted(extra_names.items())
    lines = [TAB.join(["Rename", "0", en, escape(de)]) for en, de in swaps]
    lines += [TAB.join(["ClassDescriptions", str(i), "", escape(t)]) for i, t in classes]
    write(args.out / "99_Names.txt", lines)
    report.append(f"{'Rename':20} names           swaps={len(swaps)} class descriptions={len(classes)}")
    (args.out.parent / "ui_long.txt").write_text(chr(10).join(f"{g};{i};{f};{e};{d}" for g, i, f, e, d in LONG) + chr(10), encoding="utf-8")
    report.append(f"still much longer than the English: {len(LONG)} (work/ui_long.txt)")
    (args.out.parent / "ui_report.txt").write_text(chr(10).join(report) + chr(10), encoding="utf-8")
    print(chr(10).join(report))
    return 0


if __name__ == "__main__":
    sys.exit(main())
