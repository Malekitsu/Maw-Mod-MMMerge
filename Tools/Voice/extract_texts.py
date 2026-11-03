#!/usr/bin/env python3
"""
Extract every NPC dialog text of an MMMerge install into one CSV that
generate_voices.py turns into audio. Read-only on game files.

    python -I extract_texts.py --game "C:/path/to/MM8" --out texts.csv
    python -I extract_texts.py --game ... --report          # counts only
    python -I extract_texts.py --game ... --list-guessed     # speaker names that were only guessed

Sources (all from Data/mmmerge.T.lod):
  NPCGreet.txt   greetings, columns "Greeting 1/2"          kind "greeting"
  NPCText.txt    answers to topics, quest and hire texts   kind "topic"
  NPCNews.txt    news told by street NPCs                  kind "news"
  Lua quests     dialog strings in the scripts listed in data/lua_dialog_files.txt   kind "lua"

Every table row is taken, whether or not some script is known to reach it:
the lines are looked up by text at run time, so an unreachable text costs
nothing but disk space.

Key: CRC32 of the normalized text (see normalize()). The Lua side
(Scripts/General/zzzMaw_NPCVoices.lua) computes the same key from the text the
game is about to show, so audio files are found by text, not by table index.
A text that MAW or a quest script changed has no file and stays silent.
Keep normalize() and the Lua normalize() identical.

Gender (which of the two voices speaks a text) comes from the speakers of the
text: the Owner columns of the tables, the topic owner of the Global.EVT event
that shows the text, and the NPCData rows whose topics lead to it. A name is
resolved by data/speakers.csv, then title words (Queen, Sir, ...), then the
first-name lists of Data/Tables/NPC names.txt. Texts without any known speaker
(generic profession texts, news) get a gender from the key's parity, which is
stable and splits them evenly.
"""

import argparse
import collections
import csv
import re
import struct
import sys
import zlib
from pathlib import Path

TEXT_ENCODING = "cp1252"  # what the game's text tables are stored in
HERE = Path(__file__).resolve().parent

# --------------------------------------------------------------------------
# key: must match normalize()/crc32 in zzzMaw_NPCVoices.lua byte for byte

_WS = re.compile(rb"[ \t\r\n\v\f]+")


def normalize(raw: bytes) -> bytes:
    """Drop quotes, collapse whitespace, trim, lowercase ASCII only."""
    raw = raw.replace(b'"', b"")
    raw = _WS.sub(b" ", raw).strip(b" ")
    return raw.lower()  # bytes.lower() only touches A-Z


def text_key(raw: bytes) -> str:
    return f"{zlib.crc32(normalize(raw)) & 0xFFFFFFFF:08x}"


# --------------------------------------------------------------------------
# LOD reader (MM8 "MMVIII" layout)

def read_lod(path: Path) -> dict:
    """Return {lowercase entry name: bytes} for a text LOD."""
    data = path.read_bytes()
    if data[:4] != b"LOD\0":
        raise ValueError(f"{path}: not a LOD file")
    _name, folder_off, _size, _unk, count = struct.unpack_from("<16sIIII", data, 0x100)
    entries = {}
    for i in range(count):
        name, off, size, _unk = struct.unpack_from("<64sIII", data, folder_off + i * 0x4C)
        name = name.split(b"\0", 1)[0].decode("latin-1")
        raw = data[folder_off + off: folder_off + off + size]
        unpacked_size = struct.unpack_from("<I", raw, 88)[0]
        entries[name.lower()] = zlib.decompress(raw[96:]) if unpacked_size else raw[96:]
    return entries


# --------------------------------------------------------------------------
# Tables: tab separated, rows end with CRLF, Excel-style quoted cells.
# Line breaks inside a cell are a bare LF, quoted or not.

def parse_table(raw: bytes) -> list:
    rows, row, cell = [], [], bytearray()
    i, n = 0, len(raw)
    at_cell_start, quoted = True, False
    while i < n:
        c = raw[i]
        if quoted:
            if c == 0x22:  # "
                if raw[i + 1: i + 2] == b'"':
                    cell += b'"'
                    i += 2
                    continue
                nxt = raw[i + 1: i + 2]
                if nxt in (b"\t", b"\r", b""):
                    quoted = False
                else:
                    cell += b'"'  # stray quote inside a quoted cell: keep it
            else:
                cell += bytes((c,))
            i += 1
            continue
        if at_cell_start and c == 0x22:
            quoted, at_cell_start = True, False
            i += 1
            continue
        at_cell_start = False
        if c == 0x09:
            row.append(bytes(cell))
            cell, at_cell_start = bytearray(), True
        elif c == 0x0D and raw[i + 1: i + 2] == b"\n":
            row.append(bytes(cell))
            rows.append(row)
            row, cell, at_cell_start = [], bytearray(), True
            i += 1
        else:
            cell += bytes((c,))
        i += 1
    if cell or row:
        row.append(bytes(cell))
        rows.append(row)
    return rows


def cell(row, i) -> bytes:
    return row[i] if i < len(row) else b""


def as_int(b: bytes):
    try:
        return int(b.strip() or b"x")
    except ValueError:
        return None


def row_id(b: bytes):
    """Row number of a dialog table; some rows carry a suffix ("381 M" = the Monday joke)."""
    m = re.match(rb"\s*(\d+)", b)
    return int(m.group(1)) if m else None


def decode(b: bytes) -> str:
    return b.decode(TEXT_ENCODING, errors="replace")


def speech_text(raw: bytes) -> str:
    """Text as it should be spoken: no quote marks, one line."""
    return _WS.sub(b" ", raw.replace(b'"', b"")).strip().decode(TEXT_ENCODING, errors="replace")


_TOKEN = re.compile(rb"%(?:[0-9]{1,2}|lu|l|s|d)?")


def has_placeholder(raw: bytes) -> bool:
    """%01, %s, ... are filled in by the engine: the shown text is not the table text."""
    return bool(_TOKEN.search(raw))


def is_speech(raw: bytes) -> bool:
    return len(re.findall(rb"[A-Za-z]", raw)) >= 2


# --------------------------------------------------------------------------
# Speakers and gender

FEMALE_WORDS = {"queen", "lady", "sister", "mother", "princess", "priestess", "duchess", "mrs", "mrs.", "miss",
                "madam", "ms", "ms.", "dame", "witch", "maiden", "empress", "countess", "matron", "baroness",
                "heroine", "goddess", "wife", "daughter", "girl", "woman", "waitress", "barmaid"}
MALE_WORDS = {"king", "lord", "sir", "brother", "father", "mr", "mr.", "prince", "duke", "count", "baron",
              "emperor", "monk", "priest", "wizard", "husband", "son", "boy", "man", "butler", "squire"}


def load_firstnames(tables_dir: Path) -> dict:
    """First name (lowercase) -> 'm'|'f' from the street-NPC name lists."""
    out = {}
    path = tables_dir / "NPC names.txt"
    if path.exists():
        for r in parse_table(path.read_bytes())[1:]:
            for col, g in ((0, "m"), (1, "f")):
                name = decode(cell(r, col)).strip().lower()
                if name:
                    out.setdefault(name, g)
    return out


def load_speaker_table(path: Path) -> dict:
    """data/speakers.csv: name,gender[,scope]. scope "first" matches the first word of a name."""
    out = {}
    if path.exists():
        with path.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                if row.get("gender") in ("m", "f", "x"):
                    scope = (row.get("scope") or "full").strip() or "full"
                    out[(scope, row["name"].strip().lower())] = row["gender"]
    return out


_NPC_SUFFIX = re.compile(r"[,\s]*\bNPC\s*\d+.*$|\s+\(\d+\)$|\s+\d+$", re.I)
# Owner cells that hold a note instead of a speaker ("Expert Alchemy (3)", "Hint Alvar", ...)
_GENERIC = re.compile(
    r"^(\d+|grand master\b|master\b|expert\b|exper\b|used to be\b|hint\b|plane of\b|monster hunt\b|topic\b|various$|"
    r"pirates$|ore traders$|runaway chaos|cleric promo|.*\bpromo$|.*\bclue\b.*|.*\b(finished|first)$|.*membership$|"
    r"niles missing message|necro guard if|your conscience|adventurer\b)", re.I)


def clean_name(name: str) -> str:
    return _NPC_SUFFIX.sub("", name.strip()).strip()


class Genders:
    """Name -> 'm'|'f'. 'weight' says how sure: 2 = looked up, 1 = guessed male."""

    def __init__(self, speaker_table: dict, firstnames: dict):
        self.table, self.first = speaker_table, firstnames

    def of_name(self, name: str):
        """(gender, weight) or None for texts' speaker cells that are notes, not names."""
        name = clean_name(name)
        if not name or _GENERIC.match(name):
            return None
        key = name.lower()
        words = re.findall(r"[a-z.'\-]+", key)
        for scope, k in (("full", key), ("first", words[0] if words else "")):
            g = self.table.get((scope, k))
            if g == "x":
                return None
            if g:
                return g, 2
        if any(w in FEMALE_WORDS for w in words):
            return "f", 2
        if any(w in MALE_WORDS for w in words):
            return "m", 2
        if words and words[0] in self.first:
            return self.first[words[0]], 2
        return "m", 1

    def of_text(self, key: str, speakers):
        """(gender, basis): weighted majority of the speakers, else key parity."""
        votes = collections.Counter()
        best_weight = 0
        for s in speakers:
            r = self.of_name(s)
            if r:
                votes[r[0]] += r[1]
                best_weight = max(best_weight, r[1])
        if votes:
            ranked = votes.most_common()
            tie = len(ranked) > 1 and ranked[0][1] == ranked[1][1]
            basis = "name" if best_weight == 2 else "name-guess"
            return ranked[0][0], basis + ("-tie" if tie else "")
        return ("m" if int(key, 16) % 2 == 0 else "f"), "parity"


# --------------------------------------------------------------------------
# NPCData / Global.EVT

def load_npcs(table: bytes):
    """NPCData.txt: two header rows; # Name Pic A B C 2DLoc Prof Greet Join EvA..EvF Notes."""
    npcs = {}
    for r in parse_table(table)[2:]:
        idx = as_int(cell(r, 0))
        if idx is None:
            continue
        npcs[idx] = {
            "name": decode(cell(r, 1)).strip(),
            "pic": as_int(cell(r, 2)) or 0,
            "greet": as_int(cell(r, 8)) or 0,
            "events": [e for e in (as_int(cell(r, k)) for k in range(10, 16)) if e],
        }
    return npcs


def global_set_messages(evt: bytes) -> dict:
    """{event id: [NPCText index, ...]} for every SetMessage (0x1E) in Global.EVT."""
    result, p = {}, 0
    while p < len(evt):
        size = evt[p]
        rec = evt[p + 1: p + 1 + size]
        p += 1 + size
        if len(rec) < 8:
            continue
        evt_id, _seq, cmd = struct.unpack_from("<HBB", rec, 0)
        if cmd == 0x1E:
            result.setdefault(evt_id, []).append(struct.unpack_from("<i", rec, 4)[0])
    return result


# --------------------------------------------------------------------------
# Dialog strings written in Lua quest scripts (data/lua_dialog_files.txt)

_LUA_LONG_OPEN = re.compile(r"\[(=*)\[")
_LUA_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}


def lua_literals(src: str):
    """(offset, value) of every string literal in Lua source, comments skipped."""
    i, n, out = 0, len(src), []
    while i < n:
        if src.startswith("--", i):
            m = _LUA_LONG_OPEN.match(src, i + 2)
            if m:
                end = src.find("]" + m.group(1) + "]", i)
                i = n if end < 0 else end + len(m.group(1)) + 2
            else:
                j = src.find("\n", i)
                i = n if j < 0 else j
            continue
        c = src[i]
        if c in "\"'":
            j, buf = i + 1, []
            while j < n and src[j] != c and src[j] != "\n":
                if src[j] == "\\" and j + 1 < n:
                    nxt = src[j + 1]
                    if nxt.isdigit():  # \ddd decimal escape
                        k = j + 1
                        while k < n and k < j + 4 and src[k].isdigit():
                            k += 1
                        buf.append(chr(int(src[j + 1:k]) & 0xFF))
                        j = k
                    else:
                        buf.append(_LUA_ESCAPES.get(nxt, nxt))
                        j += 2
                else:
                    buf.append(src[j])
                    j += 1
            out.append((i, "".join(buf)))
            i = j + 1
            continue
        m = _LUA_LONG_OPEN.match(src, i)
        if m:
            close = "]" + m.group(1) + "]"
            end = src.find(close, i)
            body = src[m.end(): end if end >= 0 else n]
            out.append((i, body[1:] if body.startswith("\n") else body))
            i = n if end < 0 else end + len(close)
            continue
        i += 1
    return out


def lua_dialog_strings(src: str):
    """(line, text) of the literals that read like spoken lines: 4+ words, 25+ characters, plain ASCII, no code."""
    found = []
    for off, val in lua_literals(src):
        if len(val) < 25 or len(val.split()) < 4 or len(re.findall(r"[A-Za-z]", val)) < 15:
            continue
        if any(ord(ch) > 126 or (ord(ch) < 32 and ch not in "\n\t") for ch in val):
            continue
        if re.search(r"\b(nop|push|pop|jmp|mov|call)\b", val):  # asm snippets for mem.asmpatch
            continue
        found.append((src.count("\n", 0, off) + 1, val))
    return found


def load_lua_file_list(path: Path):
    if not path.exists():
        return []
    lines = (ln.split("#", 1)[0].strip() for ln in path.read_text(encoding="utf-8").splitlines())
    return [ln for ln in lines if ln]


def load_global_ids(path: Path):
    """data/global_speech_ids.txt: ids of the Global.txt rows an NPC says."""
    return {int(ln) for ln in load_lua_file_list(path) if ln.isdigit()}


# --------------------------------------------------------------------------

class Collector:
    """One output row per distinct key; texts shared by several rows are merged."""

    def __init__(self):
        self.rows = collections.OrderedDict()
        self.cells = collections.Counter()  # kind -> non-empty speech cells seen
        self.collisions = []  # (key, text A, text B): two different texts with one key

    def add(self, raw: bytes, kind: str, source: str, speakers):
        if not is_speech(raw):
            return
        self.cells[kind] += 1
        key = text_key(raw)
        row = self.rows.get(key)
        if row is None:
            row = self.rows[key] = {
                "key": key, "kind": kind, "source": source, "n_sources": 0, "speakers": [],
                "template": int(has_placeholder(raw)), "text": speech_text(raw), "norm": normalize(raw), "raw": raw,
            }
        elif row["norm"] != normalize(raw):
            self.collisions.append((key, row["text"], speech_text(raw)))
        row["n_sources"] += 1
        for s in speakers:
            if s and s not in row["speakers"]:
                row["speakers"].append(s)


def build(game: Path, lod_rel: str = "Data/mmmerge.T.lod", speakers_csv: Path = None, lua_files: Path = None,
          global_ids: Path = None):
    lod = read_lod(game / lod_rel)
    npcs = load_npcs(lod["npcdata.txt"])
    messages = global_set_messages(lod["global.evt"])

    greet_npcs = collections.defaultdict(list)
    for npc in npcs.values():
        if npc["greet"]:
            greet_npcs[npc["greet"]].append(npc["name"])
    event_npcs = collections.defaultdict(list)  # NPCText index -> NPC names via NPCData events
    for npc in npcs.values():
        for ev in npc["events"]:
            for t in messages.get(ev, []):
                event_npcs[t].append(npc["name"])
    topic_owner = collections.defaultdict(list)  # NPCText index -> owner(s) of the topic that shows it
    for r in parse_table(lod["npctopic.txt"])[1:]:
        ev, owner = as_int(cell(r, 0)), decode(cell(r, 5)).strip()
        for t in messages.get(ev, []):
            if owner:
                topic_owner[t].append(owner)

    out = Collector()
    for r in parse_table(lod["npcgreet.txt"])[1:]:
        gid = row_id(cell(r, 0))
        if gid is None:
            continue
        speakers = [decode(cell(r, 4)).strip()] + greet_npcs.get(gid, [])
        for col in (1, 2):
            out.add(cell(r, col), "greeting", f"NPCGreet {gid}.{col}", speakers)
    for r in parse_table(lod["npctext.txt"])[1:]:
        tid = row_id(cell(r, 0))
        if tid is None:
            continue
        speakers = [decode(cell(r, 3)).strip()] + topic_owner.get(tid, []) + event_npcs.get(tid, [])
        out.add(cell(r, 1), "topic", f"NPCText {tid}", speakers)
    for r in parse_table(lod["npcnews.txt"])[1:]:
        nid = row_id(cell(r, 0))
        if nid is None:
            continue
        out.add(cell(r, 1), "news", f"NPCNews {nid}", [])

    wanted = load_global_ids(global_ids or HERE / "data" / "global_speech_ids.txt")
    for r in parse_table(lod["global.txt"])[1:]:
        gid = row_id(cell(r, 0))
        if gid in wanted:
            out.add(cell(r, 1), "global", f"GlobalTxt {gid}", [])

    scripts = game / "Scripts"
    for rel in load_lua_file_list(lua_files or HERE / "data" / "lua_dialog_files.txt"):
        path = scripts / rel
        if not path.exists():
            continue
        for line, text in lua_dialog_strings(path.read_text(encoding="utf-8", errors="replace")):
            out.add(text.encode("ascii"), "lua", f"Lua {rel}:{line}", [])

    genders = Genders(load_speaker_table(speakers_csv or HERE / "data" / "speakers.csv"),
                      load_firstnames(game / "Data" / "Tables"))
    for row in out.rows.values():
        row["gender"], row["basis"] = genders.of_text(row["key"], row["speakers"])
    return out, genders, lod


def guessed_names(out: Collector, genders: Genders):
    """Speaker names no table, title word or first-name list knows (they count as male, weight 1)."""
    names = collections.Counter()
    for row in out.rows.values():
        for s in row["speakers"]:
            r = genders.of_name(s)
            if r and r[1] == 1:
                names[clean_name(s)] += 1
    return names


_ASCII_LOWER = {c: c + 32 for c in range(65, 91)}  # A-Z only, like normalize() and the Lua module


def export_names(genders: Genders, npcs: dict, path: Path) -> int:
    """names.tsv for the Lua module: 'lowercase name<TAB>m|f', one per line (cp1252).

    Whole NPC names (titles resolved) and first names; names the resolver only guessed are
    left out, so the module falls back to the default voice for them."""
    found = {}

    def put(name, gender):
        key = clean_name(name).translate(_ASCII_LOWER).strip()
        if key and key not in found:
            found[key] = gender

    for npc in npcs.values():
        r = genders.of_name(npc["name"])
        if r and r[1] == 2:
            put(npc["name"], r[0])
    for (_scope, name), gender in genders.table.items():
        if gender in ("m", "f"):
            put(name, gender)
    for name, gender in genders.first.items():
        put(name, gender)
    lines = "".join(f"{k}\t{g}\n" for k, g in sorted(found.items()))
    path.write_bytes(lines.encode(TEXT_ENCODING, errors="replace"))
    return len(found)


def export_pics(genders: Genders, npcs: dict, path: Path) -> int:
    """pics.tsv for the Lua module: 'portrait number<TAB>m|f' for portraits whose NPCs with a known gender agree.

    Used for an NPC whose name names.tsv does not know: the same portrait means the same sex."""
    votes = collections.defaultdict(collections.Counter)
    for npc in npcs.values():
        r = genders.of_name(npc["name"])
        if r and r[1] == 2 and npc["pic"]:
            votes[npc["pic"]][r[0]] += 1
    lines = []
    for pic, c in sorted(votes.items()):
        top, n = c.most_common(1)[0]
        if top in ("m", "f") and n == sum(c.values()):
            lines.append(f"{pic}{chr(9)}{top}{chr(10)}")
    path.write_bytes("".join(lines).encode("ascii"))
    return len(lines)


FIELDS = ["key", "kind", "source", "n_sources", "gender", "basis", "speakers", "template", "chars", "text"]


def write_csv(out: Collector, path: Path):
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
        w.writeheader()
        for row in out.rows.values():
            w.writerow({**row, "speakers": "; ".join(row["speakers"]), "chars": len(row["text"])})


def report(out: Collector, genders: Genders) -> str:
    rows = list(out.rows.values())
    lines = []
    for kind in ("greeting", "topic", "news", "global", "lua"):
        sel = [r for r in rows if r["kind"] == kind]
        lines.append(f"{kind:9} cells={out.cells[kind]:5} distinct={len(sel):5} chars={sum(len(r['text']) for r in sel):7} "
                     f"templates={sum(r['template'] for r in sel):4}")
    total = sum(len(r["text"]) for r in rows)
    plain = sum(len(r["text"]) for r in rows if not r["template"])
    lines.append(f"total     distinct={len(rows)} chars={total} (without placeholders: {plain})")
    by = collections.Counter((r["gender"], r["basis"]) for r in rows)
    lines.append("gender    " + ", ".join(f"{g}/{b}={n}" for (g, b), n in sorted(by.items())))
    lines.append(f"no gender: {sum(1 for r in rows if r['gender'] not in ('m', 'f'))}")
    lines.append(f"key collisions: {len(out.collisions)}")
    lines.append(f"speaker names guessed as male: {len(guessed_names(out, genders))}")
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, type=Path, help="MM8 install with MMMerge")
    ap.add_argument("--lod", default="Data/mmmerge.T.lod", help="text LOD, relative to --game")
    ap.add_argument("--speakers", type=Path, help="gender table (default data/speakers.csv)")
    ap.add_argument("--out", type=Path)
    ap.add_argument("--names", type=Path, help="also write names.tsv (name -> m|f) for the Lua module")
    ap.add_argument("--pics", type=Path, help="also write pics.tsv (portrait -> m|f) for the Lua module")
    ap.add_argument("--report", action="store_true", help="print counts")
    ap.add_argument("--list-guessed", action="store_true", help="print speaker names that were only guessed (male)")
    args = ap.parse_args(argv)

    out, genders, lod = build(args.game, args.lod, args.speakers)
    if args.list_guessed:
        for name, n in sorted(guessed_names(out, genders).items()):
            print(f"{name}\t{n}")
    if args.out:
        write_csv(out, args.out)
        print(f"{len(out.rows)} distinct texts -> {args.out}", file=sys.stderr)
    if args.names:
        n = export_names(genders, load_npcs(lod["npcdata.txt"]), args.names)
        print(f"{n} names -> {args.names}", file=sys.stderr)
    if args.pics:
        n = export_pics(genders, load_npcs(lod["npcdata.txt"]), args.pics)
        print(f"{n} portraits -> {args.pics}", file=sys.stderr)
    if args.report or not (args.out or args.list_guessed or args.names or args.pics):
        print(report(out, genders))


if __name__ == "__main__":
    main()
