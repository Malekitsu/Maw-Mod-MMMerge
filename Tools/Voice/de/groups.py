"""
German edition: which texts belong to the groups that the player can switch (settings page Sprache / Language).

Group "shops" (Data/Localization/de/shops/): German only with the option "Läden, Hütten". It holds the texts of shops
and huts: names, owners and titles of those houses, the labels of the shop screens, the merchant's sentences, and the
topics, greetings and dialogs of the people who live or work there. Houses of other types (temples, taverns, guilds,
banks, town halls ...), the main-story places that are houses of the type House (throne rooms, hostels ...), the
skill teachers and everything the player meets outside of shops and huts belong to the base texts (always German).

Group "items" (Data/Localization/de/items/): German only with the option "Gegenstände, Tooltips": the labels of the
item info (type, charges, value, state ...). Item names and descriptions will go there once they are translated.
"""

import re
import struct
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402

SHOP_TYPES = {"House", "Armor Shop", "Magic Shop", "Weapon Shop", "Alchemist"}

# houses of the type House that are no huts: story places, hostels, throne rooms, the inn of the party, placeholders
NOT_HUT = re.compile(r"Hostel|Inn\b|Library|Throne|Leader's Room|Guildhouse|Council|placeholder|Arbiter", re.I)

# NPCs of the main story that live in rooms of the type House (oracle, quest givers, Lord Markham ...): never in the group
STORY_NPCS = {4, 11, 15, 17, 51, 52, 53, 62, 314, 340, 388}

# GlobalTxt ids of the shop screens (buy, sell, identify, repair, steal, what to pick ...). Not 292, 294 (skill names),
# 400 (the button of the guilds), 160, 155, 120, 293: those are used outside of shops too.
SHOP_GLOBAL = {113, 134, 152, 159, 161, 179, 181, 185, 191, 195, 196, 197, 198, 199, 200, 446, 448, 539, 540, 541, 542, 543}

# GlobalTxt ids of the item info (type, charges, value, state of an item)
ITEM_GLOBAL = {32, 187, 232, 463, 464, 465, 651}


def shop_house_ids(lod) -> set:
    """Ids of the houses of the shop types and the huts (2devents.txt: column 0 = id, 2 = type, 5 = name)."""
    out = set()
    for r in ex.parse_table(lod["2devents.txt"])[2:]:
        hid = ex.as_int(ex.cell(r, 0))
        if hid is None or ex.decode(ex.cell(r, 2)).strip() not in SHOP_TYPES:
            continue
        if NOT_HUT.search(ex.decode(ex.cell(r, 5))):
            continue
        out.add(hid)
    return out


def norm(name: str) -> str:
    return ex.clean_name(name).strip().lower()


def shop_npc_names(lod, houses: set) -> set:
    """Lowercase names of the NPCs whose 2D location (npcdata.txt column 6) is a house of the group."""
    where = {}  # name -> True while every NPC of that name lives in such a house
    for r in ex.parse_table(lod["npcdata.txt"])[2:]:
        name = norm(ex.decode(ex.cell(r, 1)))
        where[name] = where.get(name, True) and ex.as_int(ex.cell(r, 6)) in houses
    return {name for name, inside in where.items() if inside}  # a name that is shared with an NPC elsewhere stays out


def all_npc_names(lod) -> set:
    """Lowercase names of all NPCs of npcdata.txt."""
    return {norm(ex.decode(ex.cell(r, 1))) for r in ex.parse_table(lod["npcdata.txt"])[2:]}


def is_shop_text(speakers, shop_names: set, all_names: set) -> bool:
    """Fallback for a text no NPC row reaches: it belongs to the group when every NPC named as its speaker lives in a
    shop or hut. Speaker cells that are no NPC name (notes like 'James Quest Hint') are ignored; at least one NPC must
    speak it."""
    npcs = [norm(x) for x in speakers if x.strip() and norm(x) in all_names]
    return bool(npcs) and all(n in shop_names for n in npcs)


def teacher_ids(game: Path):
    """(topic ids, text ids) of Data/Tables/Teacher topics.txt: the skill teachers' topics and the texts they open."""
    topics, texts = set(), set()
    path = game / "Data" / "Tables" / "Teacher topics.txt"
    if path.exists():
        for line in path.read_bytes().decode("cp1252").splitlines()[1:]:
            c = line.split(chr(9))
            if len(c) > 4 and c[0].strip().isdigit() and c[4].strip().isdigit():
                topics.add(int(c[0]))
                texts.add(int(c[4]))
    return topics, texts


_TOPIC = re.compile(r"SetNPCTopic\s*[\{\(]\s*(?:NPC\s*=\s*)?(\d+)\s*,\s*(?:Index\s*=\s*)?\d+\s*,\s*(?:Event\s*=\s*)?(\d+)")
_GREET = re.compile(r"SetNPCGreeting\s*[\{\(]\s*(?:NPC\s*=\s*)?(\d+)\s*,\s*(?:Greeting\s*=\s*)?(\d+)")


def later_assignments(game: Path, lod):
    """Topics and greetings that scripts give to an NPC later: [(npc, event)], [(npc, greeting)]. From the commands
    SetNPCTopic (0x27) and SetNPCGreeting (0x32) of Global.EVT and from the Lua scripts of the map events."""
    topics, greets = [], []
    evt = lod["global.evt"]
    p = 0
    while p < len(evt):
        size = evt[p]
        rec = evt[p + 1: p + 1 + size]
        p += 1 + size
        if len(rec) < 12:
            continue
        cmd = rec[3]
        if cmd == 0x27 and len(rec) >= 13:
            topics.append((struct.unpack_from("<i", rec, 4)[0], struct.unpack_from("<i", rec, 9)[0]))
        elif cmd == 0x32:
            greets.append((struct.unpack_from("<i", rec, 4)[0], struct.unpack_from("<i", rec, 8)[0]))
    scripts = game / "Scripts"
    if scripts.exists():
        for path in scripts.rglob("*.lua"):
            text = path.read_text(encoding="utf-8", errors="replace")
            if "SetNPC" not in text:
                continue
            topics += [(int(a), int(b)) for a, b in _TOPIC.findall(text)]
            greets += [(int(a), int(b)) for a, b in _GREET.findall(text)]
    return topics, greets


def compute(game: Path, lod):
    """(shop_cells, shop_topics): the dialog cells ("NPCGreet" / "NPCText", row id) and the NPCTopic rows (event id) of
    the group "shops".

    The group follows the NPCs: a cell is in it when an NPC that speaks it lives in a shop or hut (npcdata.txt: the
    greeting number and the event numbers of each NPC, plus what scripts give them later; the texts that an event sets
    with SetMessage). So everything one NPC says - greeting, topic labels, answers - is in one language. The skill
    teachers (Teacher topics.txt) are never in the group: the mod moves them into guilds, temples and taverns. A cell
    shared by an NPC of the group and an NPC elsewhere is in the group (a table row can be in one place only). A cell no
    NPC reaches (generic texts, texts of scripts) is decided by the speaker names found by extract_texts."""
    houses = shop_house_ids(lod)
    npcs = shop_npc_names(lod, houses)
    everyone = all_npc_names(lod)
    messages = ex.global_set_messages(lod["global.evt"])
    teacher_topics, teacher_texts = teacher_ids(game)
    later_topics, later_greets = later_assignments(game, lod)

    rows = []  # (npc id, lives in a shop or hut, greeting, events)
    for r in ex.parse_table(lod["npcdata.txt"])[2:]:
        i = ex.as_int(ex.cell(r, 0))
        events = {ex.as_int(ex.cell(r, c)) for c in range(10, 16)} - {None, 0}
        rows.append((i, ex.as_int(ex.cell(r, 6)) in houses, ex.as_int(ex.cell(r, 8)), events))
    owned = {}
    for i, _inside, _greet, events in rows:
        owned.setdefault(i, set()).update(events)
    for npc, ev in later_topics:
        owned.setdefault(npc, set()).add(ev)
    trainers = {i for i, evs in owned.items() if evs & teacher_topics}
    inside_of = {i: inside and i not in trainers and i not in STORY_NPCS for i, inside, _g, _e in rows}

    greet_flags, event_flags = {}, {}
    for i, _inside, greet, _events in rows:
        if greet:
            greet_flags.setdefault(greet, []).append(inside_of[i])
    for npc, greet in later_greets:
        if greet and npc in inside_of:
            greet_flags.setdefault(greet, []).append(inside_of[npc])
    for npc, evs in owned.items():
        for ev in evs:
            event_flags.setdefault(ev, []).append(inside_of.get(npc, False))
    text_flags = {}
    for ev, flags in event_flags.items():
        for tid in messages.get(ev, []):
            text_flags.setdefault(tid, []).extend(flags)

    collected, _genders, _lod = ex.build(game)
    by_key = {k: is_shop_text(row["speakers"], npcs, everyone) for k, row in collected.rows.items()}

    def decide(flags, key):
        if flags:
            return any(flags)
        return by_key.get(key, False)

    cells = set()
    for r in ex.parse_table(lod["npcgreet.txt"])[1:]:
        gid = ex.row_id(ex.cell(r, 0))
        if gid is None:
            continue
        keys = [ex.text_key(ex.cell(r, c)) for c in (1, 2) if ex.is_speech(ex.cell(r, c))]
        if keys and decide(greet_flags.get(gid), keys[0]):
            cells.add(("NPCGreet", gid))
    texts = {}
    for r in ex.parse_table(lod["npctext.txt"])[1:]:
        tid = ex.row_id(ex.cell(r, 0))
        if tid is not None and ex.is_speech(ex.cell(r, 1)):
            texts[tid] = ex.text_key(ex.cell(r, 1))
            if tid not in teacher_texts and decide(text_flags.get(tid), texts[tid]):
                cells.add(("NPCText", tid))
    topics = set()
    for r in ex.parse_table(lod["npctopic.txt"])[1:]:
        rid = ex.row_id(ex.cell(r, 0))
        if rid is None or rid in teacher_topics:
            continue
        if event_flags.get(rid):
            inside = any(event_flags[rid])
        else:
            answers = [t for t in messages.get(rid, []) if t in texts]
            inside = all(("NPCText", t) in cells for t in answers) if answers else \
                is_shop_text([ex.decode(ex.cell(r, 5))], npcs, everyone)
        if inside:
            topics.add(rid)
    return cells, topics
