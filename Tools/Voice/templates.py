#!/usr/bin/env python3
"""
Recordings for the texts with run-time placeholders (%01, %02, %17, ...).

The game fills these in just before it shows the text, so the text on screen is
not the table text and has no recording of its own. This module prepares them:

  * names (the NPC's, the party's) and class names are left out of the spoken
    version ("Back again, Tracie?" is spoken "Back again?"),
  * words and numbers from a fixed set are spoken exactly, one recording per
    value: the percent a hireling takes (from the profession table), the time of
    day, the reputation word, the form of address (Lord/Lady), the price,
  * texts with any other placeholder (%s, %d, %lu: quest and arena code, where the
    values are not known here) and the stat sheets of the hirelings ("%01 takes
    5 percent ...", information rather than speech) stay silent.

For every template it writes the recordings to make (rows for generate_voices.py)
and a pattern file for the Lua module, which recognizes the shown text, reads the
values out of it and picks the recording.

    python templates.py --game "C:/.../Might and Magic 8 MAW Mod 4.5" --texts texts.csv \\
           --out-csv templates.csv --out-patterns templates.tsv [--report report.txt]

The spoken version comes from drop_names() when its rules resolve every name; any
other template needs a line in data/template_speech.csv (key, spoken, note), where
a spoken text of "-" means: leave it silent.
"""

import argparse
import csv
import itertools
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import extract_texts as ex  # noqa: E402

TOKEN = re.compile(r"%(?:[0-9]{1,2}|lu|l|s|d)")
NAME = r"(?:%01|%02|%13|%15|%16)"      # a person's name: the NPC (%01) or a party member
CLASS = r"(?:%06|%07)"                 # class name of a party member
SHOWN_NAMES = ("%01", "%02", "%13", "%15", "%16", "%06", "%07", "%14")  # tokens that must not be left in the spoken text
UNSUPPORTED = re.compile(r"%(?:lu|l|s|d)")
STAT_SHEET = re.compile(r"%01 (?:takes|costs)\b")
MAX_VARIANTS = 60                      # more recordings than this for one template: leave it silent

# displayed values of the placeholders that take one of a fixed set of values (Global.txt ids, see NPCNewsTopics.lua)
GLOBAL_WORDS = {
    "%03": (383, 384), "%09": (383, 384),   # his / her
    "%10": (388, 389),                      # Lord / Lady
    "%05": (395, 396, 397),                 # morning / day / evening
    "%08": (379, 392, 399, 402, 434), "%12": (379, 392, 399, 402, 434),  # reputation of the party / required by the NPC
}
ALIAS = {"%11": "%08"}                  # the party's reputation again
JOINT = ("%09", "%10")                  # his/her and Lord/Lady both follow the sex of the speaking character


def canonical(token: str) -> str:
    return ALIAS.get(token, token)


def number(x: float) -> str:
    """The way Lua's tostring prints a number: 10, 0.01, 12.5."""
    return "%.14g" % x


def load_domains(game: Path):
    """({token: [value, ...]}, {text key: [percent, ...]}) from the game's tables.

    The hire pitch and the description of a profession carry %17, the percent of the found gold the
    hireling takes (Cost / 100, see NPCFollowers.lua); the second map holds, per such text, the
    percents of the professions that show it."""
    lod = ex.read_lod(game / "Data" / "mmmerge.T.lod")
    glob = {ex.row_id(ex.cell(r, 0)): ex.decode(ex.cell(r, 1)) for r in ex.parse_table(lod["global.txt"])[1:]
            if ex.row_id(ex.cell(r, 0)) is not None}
    domains = {tok: [glob[i] for i in ids] for tok, ids in GLOBAL_WORDS.items()}
    npc_text = {ex.row_id(ex.cell(r, 0)): ex.cell(r, 1) for r in ex.parse_table(lod["npctext.txt"])[1:]
                if ex.row_id(ex.cell(r, 0)) is not None}
    percents, prices = {}, set()
    rows = ex.parse_table((game / "Data" / "Tables" / "NPC professions.txt").read_bytes())
    for r in rows[1:]:
        cost = ex.decode(ex.cell(r, 4)).strip()
        # the game reads the cost with tonumber(...) or 100 (NPCFollowers.lua)
        cost = float(cost) if cost.replace(".", "", 1).isdigit() else 100.0
        prices.add(number(cost))
        for col in (9, 10):  # Join Text, Description: the NPCText rows shown for this profession
            raw = npc_text.get(ex.row_id(ex.cell(r, col)))
            if raw:
                percents.setdefault(ex.text_key(raw), set()).add(number(cost / 100))
    domains["%04"] = sorted(prices, key=float)
    return domains, {k: sorted(v, key=float) for k, v in percents.items()}


# ---------------------------------------------------------------------------
# the spoken version

_DIRECTION = re.compile(r"\s*<[^>]*>\s*")
_SENTENCE_END = re.compile(r"(?<=[.!?…])\s+")
_INTRO = re.compile(r"^(?:I'm|I am|My name is|Name's)\s+(?:%14\s+)?%01[.!]?$", re.I)
# a word that makes "<class> <name>" read as "the infamous adventurer"
_TITLE_WORD = r"(?:infamous|notorious|famous|honorable|wicked|mighty)"


def capitalize(s: str) -> str:
    return re.sub(r"^(\W*)([a-z])", lambda m: m.group(1) + m.group(2).upper(), s)


def drop_names(text: str) -> str:
    """Take the names and class names out of a template.

    Only forms that leave a sentence behind are handled (an address at the start or end of a sentence,
    in commas, "my name is ...", an adjective in front of the class and name); whatever else is left
    contains a name token and needs a line in the overrides file."""
    s = _DIRECTION.sub(" ", text).strip()
    s = re.sub(r"\s+", " ", s)
    # the address at the very start: "%02! ", "%07 %02. ", "%10 %02. ", "%02, ", "%13, eh? "
    s = re.sub(rf"^(?:{CLASS}\s+)?(?:%10\s+)?{NAME}(?:\.\.\.|[.,!?…]+)\s*", "", s)
    s = re.sub(rf"^{CLASS}[,!]\s*", "", s)
    # the NPC introducing itself
    s = re.sub(r"\bMy name is %01,? and ", "", s)
    s = " ".join(p for p in _SENTENCE_END.split(s) if not _INTRO.match(p.strip()))
    s = re.sub(r"(?<![\w%])%01, at your service", "At your service", s)
    # "the infamous <class> <name>" -> "the infamous adventurer"
    s = re.sub(rf"\b({_TITLE_WORD}(?: and {_TITLE_WORD})?) (?:%10 )?(?:{CLASS} {NAME}|{NAME}|{CLASS})", r"\1 adventurer", s, flags=re.I)
    s = re.sub(rf"\b(friend) {NAME}", r"\1", s, flags=re.I)
    # an address between commas or at the end of a sentence: "..., %02, ...", "..., %06 %02!"
    s = re.sub(rf",\s*(?:{CLASS}\s+{NAME}|{NAME}|{CLASS}),", ",", s)
    s = re.sub(rf",\s*(?:{CLASS}\s+)?(?:%10\s+)?{NAME}(?=[.!?…])", "", s)
    s = re.sub(rf",\s*{CLASS}(?=[.!?…])", "", s)
    # a sentence that is only a name: "O Ho! %13! Er, ..." / "Hmm. %02. I have ..."
    s = re.sub(rf"(?<=[.!?…])\s+(?:{CLASS}\s+)?{NAME}[.!?…]+(?=\s|$)", "", s)
    s = re.sub(rf"\s+(?:{CLASS}\s+)?{NAME}(?=[.!?…])", "", s)
    s = re.sub(rf"\s+{CLASS}(?=[.!?…])", "", s)
    s = re.sub(rf"\s+(?:{CLASS}\s+)?{NAME}(?=,)", "", s)
    s = re.sub(r"\s+([,.!?…])", r"\1", s)
    s = re.sub(r"([!?])\s*\1+", r"\1", s)
    s = re.sub(r"\s{2,}", " ", s)
    return capitalize(s.strip(" ,"))


def exact_tokens(spoken: str):
    """The (canonical) placeholders in the spoken text, in order of first appearance."""
    seen = []
    for tok in TOKEN.findall(spoken):
        tok = canonical(tok)
        if tok not in seen:
            seen.append(tok)
    return seen


def slug(value: str) -> str:
    """File-name-safe form of a value: lowercase, runs of anything else become _ ."""
    return re.sub(r"[^a-z0-9.]+", "_", value.lower()).strip("_")


def combos(spoken: str, domains: dict, percent_values=None):
    """[{token: value}] for every combination of the values of the placeholders in the spoken text.

    None when a placeholder has no known set of values."""
    tokens = exact_tokens(re.sub(r"%11", "%08", spoken))
    groups = []  # (tokens, [value tuple, ...])
    for tok in tokens:
        if tok in JOINT and all(j in tokens for j in JOINT):
            if tok == JOINT[0]:
                groups.append((JOINT, list(zip(*(domains[j] for j in JOINT)))))
            continue
        pool = percent_values if tok == "%17" and percent_values else domains.get(tok)
        if not pool:
            return None
        groups.append(((tok,), [(v,) for v in pool]))
    out = []
    for combo in itertools.product(*(values for _, values in groups)):
        out.append({tok: val for (toks, _), vals in zip(groups, combo) for tok, val in zip(toks, vals)})
    return out


def variants(spoken: str, domains: dict, percent_values=None):
    """[(stem suffix, spoken text with the values in)] for every combination of the exact values."""
    spoken = re.sub(r"%11", "%08", spoken)
    found = combos(spoken, domains, percent_values)
    if found is None:
        return None
    tokens = exact_tokens(spoken)
    out = []
    for values in found:
        text = spoken
        for tok in tokens:
            text = text.replace(tok, values[tok])
        out.append(("".join("~" + slug(values[tok]) for tok in tokens), text))
    return out


SAMPLE = {"%01": "Tracie", "%02": "Aldric", "%13": "Aldric", "%15": "Aldric", "%16": "Aldric",
          "%06": "Knight", "%07": "Knight", "%14": "Smith"}


def shown(template_text: str, values: dict) -> str:
    """What the game puts on the screen: the template with every placeholder filled in.

    `values` holds the exact placeholders (canonical names); the names get sample names."""
    def fill(m):
        tok = m.group(0)
        return values.get(canonical(tok)) or SAMPLE.get(tok, "x")
    return TOKEN.sub(fill, template_text)


# ---------------------------------------------------------------------------
# the pattern for the Lua module

_LUA_MAGIC = re.compile(r"([\^$()%.\[\]*+\-?])")


def lua_pattern(template_text: str, captured):
    """(Lua pattern over the normalized shown text, [token, ...] in capture order).

    Only the placeholders in `captured` (canonical names) get a capture; the others match any text."""
    norm = ex.normalize(template_text.encode("cp1252", "replace")).decode("cp1252", "replace")
    pattern, tokens, pos = "^", [], 0
    for m in TOKEN.finditer(norm):
        pattern += _LUA_MAGIC.sub(r"%\1", norm[pos:m.start()])
        tok = canonical(m.group(0))
        if tok in captured:
            pattern += "(.-)"
            tokens.append(tok)
        else:
            pattern += ".-"
        pos = m.end()
    pattern += _LUA_MAGIC.sub(r"%\1", norm[pos:]) + "$"
    return pattern, tokens


# ---------------------------------------------------------------------------

def load_overrides(path: Path):
    """data/template_speech.csv: key,spoken,note (the spoken version of a template with the placeholders it keeps; - = silent)."""
    out = {}
    if path.exists():
        with path.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                out[row["key"]] = row["spoken"]
    return out


def build(rows, domains, percents, overrides):
    """-> (recordings, patterns, skipped, spoken, cases). rows: the template rows of texts.csv.

    cases: (key of a recording, the text the game shows when that recording is meant), for tests."""
    recordings, patterns, skipped, spoken_of, cases = [], [], [], {}, []
    for row in rows:
        text, key = row["text"], row["key"]
        if UNSUPPORTED.search(text):
            skipped.append((key, "placeholder with unknown values", text))
            continue
        if STAT_SHEET.search(text):
            skipped.append((key, "stat sheet of a hireling, not speech", text))
            continue
        if overrides.get(key) == "-":
            skipped.append((key, "left silent by choice", text))
            continue
        spoken = overrides.get(key) or drop_names(text)
        spoken_of[key] = spoken
        if "�" in text or "�" in spoken:
            skipped.append((key, "character that is not in the game's code page", spoken))
            continue
        if not {canonical(t) for t in TOKEN.findall(spoken)} <= {canonical(t) for t in TOKEN.findall(text)}:
            skipped.append((key, "override uses a placeholder the text does not have", spoken))
            continue
        if any(t in SHOWN_NAMES for t in TOKEN.findall(spoken)):
            skipped.append((key, "name left in the sentence: needs an override", spoken))
            continue
        found = variants(spoken, domains, percents.get(key))
        if not found:
            skipped.append((key, "no known values for a placeholder", spoken))
            continue
        if len(found) > MAX_VARIANTS:
            skipped.append((key, f"{len(found)} variants", spoken))
            continue
        if not ex.is_speech(spoken.encode("cp1252", "replace")):
            skipped.append((key, "nothing left to say", spoken))
            continue
        exact = exact_tokens(spoken)
        pattern, captures = lua_pattern(text, set(exact))
        patterns.append((key, pattern, ",".join(t[1:] for t in captures), ",".join(t[1:] for t in exact)))
        values_list = combos(spoken, domains, percents.get(key))
        for (suffix, said), values in zip(found, values_list):
            recordings.append({
                "key": "t" + key + suffix, "kind": "template", "source": row["source"], "n_sources": row["n_sources"],
                # same voice rule as the other texts without a speaker: even key -> male
                "gender": "m" if int(key, 16) % 2 == 0 else "f", "basis": "parity", "speakers": "",
                "template": 0, "chars": len(said), "text": said,
            })
            cases.append(("t" + key + suffix, shown(text, values)))
    patterns.sort(key=lambda p: (-len(p[1]), p[0]))  # the most specific pattern first
    return recordings, patterns, skipped, spoken_of, cases


def make(game: Path, texts: Path, overrides: Path = HERE / "data" / "template_speech.csv"):
    """build() for the template rows of texts.csv, with the values from the game's tables. -> (rows, build's result)"""
    with texts.open(encoding="utf-8", newline="") as f:
        rows = [r for r in csv.DictReader(f) if r["template"] == "1"]
    domains, percents = load_domains(game)
    return rows, build(rows, domains, percents, load_overrides(overrides))


def write_patterns(patterns, path: Path):
    """templates.tsv for the Lua module: key, pattern, captures, suffix; cp1252 like the game's texts."""
    path.write_bytes(("\n".join("\t".join(p) for p in patterns) + "\n").encode("cp1252", "replace"))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path)
    ap.add_argument("--texts", required=True, type=Path, help="texts.csv of extract_texts.py")
    ap.add_argument("--out-csv", type=Path, help="the recordings to make, for generate_voices.py")
    ap.add_argument("--out-patterns", type=Path, help="templates.tsv for the Lua module")
    ap.add_argument("--overrides", type=Path, default=HERE / "data" / "template_speech.csv")
    ap.add_argument("--report", type=Path, help="original and spoken version of every template, and the silent ones")
    args = ap.parse_args(argv)

    rows, (recordings, patterns, skipped, spoken_of, _) = make(args.game, args.texts, args.overrides)
    print(f"{len(rows)} templates: {len(patterns)} voiced with {len(recordings)} recordings, {len(skipped)} silent", file=sys.stderr)
    if args.out_csv:
        with args.out_csv.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=ex.FIELDS, extrasaction="ignore")
            w.writeheader()
            w.writerows(recordings)
    if args.out_patterns:
        write_patterns(patterns, args.out_patterns)
    if args.report:
        by_key = {r["key"]: r for r in rows}
        voiced = {p[0] for p in patterns}
        out = [f"VOICED {len(patterns)}"]
        for key in sorted(voiced):
            out.append(f"{key}  {by_key[key]['text']}\n      => {spoken_of[key]}")
        out.append(f"\nSILENT {len(skipped)}")
        for key, why, text in skipped:
            out.append(f"{key} [{why}]\n      {by_key[key]['text']}\n      => {spoken_of.get(key, '')}")
        args.report.write_text("\n".join(out), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
