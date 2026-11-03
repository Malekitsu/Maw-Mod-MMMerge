"""Tests for extract_texts.py.

    python -I Tools/Voice/tests/test_extract.py

The real-data tests read the install named by the environment variable MM8_DIR
(default: the author's test install) and are skipped when it is missing.
"""

import collections
import importlib.util
import os
import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("ex", HERE.parent / "extract_texts.py")
ex = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ex)

GAME = Path(os.environ.get("MM8_DIR", r"C:\Users\slovi\Desktop\Might and Magic 8 MAW Mod 4.5"))
HAVE_GAME = (GAME / "Data" / "mmmerge.T.lod").exists()


class KeyTests(unittest.TestCase):
    def test_known_key(self):
        # NPCGreet 15.2; the file for it exists in the 2026-10-26 in-game test
        self.assertEqual(ex.text_key(b"Good day."), "27e01aa3")

    def test_normalization_ignores_quotes_whitespace_and_case(self):
        base = ex.text_key(b"Good day.\nWelcome back.")
        for variant in (b'"Good day.\nWelcome back."', b"good DAY.\r\nwelcome   back.", b"  Good day. Welcome back.\n"):
            self.assertEqual(ex.text_key(variant), base)

    def test_normalization_keeps_other_characters(self):
        self.assertNotEqual(ex.text_key(b"Good day."), ex.text_key(b"Good day"))
        self.assertNotEqual(ex.text_key(b"caf\xe9"), ex.text_key(b"cafe"))  # only A-Z are lowercased

    def test_placeholders(self):
        self.assertTrue(ex.has_placeholder(b"Hullo %02."))
        self.assertTrue(ex.has_placeholder(b"%s gold"))
        self.assertFalse(ex.has_placeholder(b"Plain text."))


class TableTests(unittest.TestCase):
    def test_quoted_multiline_cell_and_doubled_quotes(self):
        raw = b'#\tText\r\n1\t"He said ""hi""\nand left."\tx\r\n2\tplain\nsecond line\ty\r\n'
        rows = ex.parse_table(raw)
        self.assertEqual(len(rows), 3)
        self.assertEqual(rows[1][1], b'He said "hi"\nand left.')
        self.assertEqual(rows[2][1], b"plain\nsecond line")
        self.assertEqual(rows[2][2], b"y")

    def test_last_row_without_newline(self):
        self.assertEqual(ex.parse_table(b"a\tb\r\nc\td"), [[b"a", b"b"], [b"c", b"d"]])

    def test_speech_text(self):
        self.assertEqual(ex.speech_text(b'"Line one\nline two"'), "Line one line two")
        self.assertFalse(ex.is_speech(b"?!"))
        self.assertTrue(ex.is_speech(b"Hi"))


class LuaScannerTests(unittest.TestCase):
    SRC = "\n".join([
        '-- a comment with "a quoted string inside it"',
        'local a = "A spoken line of the quest giver, long enough."',
        "local b = 'Single quoted: it\\'s four words at least, yes.'",
        "local c = [[Long bracket text spans",
        "several lines and has words enough.]]",
        '--[[ block comment "Ignored string that is long enough to count." ]]',
        'local d = "too short"',
        'local e = "%s. World: %s." -- placeholders are kept, flagged later',
        'asm = "nop nop nop nop nop jmp absolute 0x4bb3f0"',
    ])

    def test_literals_and_comments(self):
        values = [v for _, v in ex.lua_literals(self.SRC)]
        self.assertIn("A spoken line of the quest giver, long enough.", values)
        self.assertIn("Single quoted: it's four words at least, yes.", values)
        self.assertIn("Long bracket text spans\nseveral lines and has words enough.", values)
        self.assertFalse(any("Ignored string" in v or "quoted string inside" in v for v in values))

    def test_dialog_filter(self):
        found = [t for _, t in ex.lua_dialog_strings(self.SRC)]
        self.assertEqual(len(found), 3)
        self.assertFalse(any("jmp" in t or t == "too short" for t in found))

    def test_line_numbers(self):
        lines = {t[:8]: n for n, t in ex.lua_dialog_strings(self.SRC)}
        self.assertEqual(lines["A spoken"], 2)
        self.assertEqual(lines["Long bra"], 4)


class GenderTests(unittest.TestCase):
    def setUp(self):
        table = ex.load_speaker_table(HERE.parent / "data" / "speakers.csv")
        self.g = ex.Genders(table, {"aaron": "m", "alice": "f"})

    def test_sources_of_gender(self):
        self.assertEqual(self.g.of_name("Queen Catherine"), ("f", 2))      # title word
        self.assertEqual(self.g.of_name("Sir Charles Quixote"), ("m", 2))
        self.assertEqual(self.g.of_name("Alice Smith"), ("f", 2))          # first-name list
        self.assertEqual(self.g.of_name("Pascella Tisk"), ("f", 2))        # data/speakers.csv
        self.assertEqual(self.g.of_name("Brekish Onefang"), ("m", 1))      # guessed

    def test_notes_and_generic_roles_have_no_gender(self):
        for name in ("Expert Alchemy (3)", "Hint Alvar", "Monster hunt 1", "Guard", "13", ""):
            self.assertIsNone(self.g.of_name(name), name)

    def test_npc_suffix_is_removed(self):
        self.assertEqual(self.g.of_name("Dierdra Wallace NPC 513"), ("f", 2))
        self.assertEqual(self.g.of_name("Aznog Black, NPC 409"), ("m", 1))

    def test_text_without_speaker_uses_key_parity_and_is_stable(self):
        self.assertEqual(self.g.of_text("00000002", []), ("m", "parity"))
        self.assertEqual(self.g.of_text("00000003", []), ("f", "parity"))

    def test_lookup_outweighs_guess(self):
        self.assertEqual(self.g.of_text("00000002", ["Brekish Onefang", "Alice Smith"])[0], "f")

    def test_names_file_for_the_lua_module(self):
        import tempfile
        npcs = {1: {"name": "Queen Catherine"}, 2: {"name": "Brekish Onefang"}, 3: {"name": "Dierdra Wallace NPC 513"},
                4: {"name": "Zed-Én"}}
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "names.tsv"
            ex.export_names(self.g, npcs, path)
            lines = path.read_bytes().decode("cp1252").splitlines()
        got = dict(line.split("\t") for line in lines)
        self.assertEqual(got["queen catherine"], "f")         # whole name, title word resolved
        self.assertEqual(got["dierdra wallace"], "f")         # NPC suffix removed, lowercase
        self.assertEqual(got["alice"], "f")                   # first-name list
        self.assertEqual(got["aaron"], "m")
        self.assertEqual(got["pascella"], "f")                # data/speakers.csv, scope first
        self.assertNotIn("brekish onefang", got)              # guessed names are not exported
        self.assertEqual(lines, sorted(lines))                # stable file
        self.assertTrue(all(v in ("m", "f") for v in got.values()))


@unittest.skipUnless(HAVE_GAME, "game install not found (set MM8_DIR)")
class RealDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.out, cls.genders, cls.lod = ex.build(GAME)

    def test_every_table_row_is_parsed(self):
        # independent of the parser: rows start with "<number>\t" after a CRLF
        for name, minimum in (("npcgreet.txt", 300), ("npctext.txt", 2700), ("npcnews.txt", 900)):
            raw = self.lod[name]
            by_regex = len(re.findall(rb"(?:^|\r\n)\d+[^\t\r\n]*\t", raw))
            parsed = sum(1 for r in ex.parse_table(raw) if ex.row_id(ex.cell(r, 0)) is not None)
            self.assertEqual(parsed, by_regex, name)
            self.assertGreaterEqual(parsed, minimum, name)

    def test_no_stray_rows(self):
        # a broken quote would swallow or split rows: every row must start with a number
        for name in ("npcgreet.txt", "npctext.txt", "npcnews.txt"):
            rows = ex.parse_table(self.lod[name])[1:]
            bad = [r[0][:20] for r in rows if ex.row_id(ex.cell(r, 0)) is None]
            self.assertEqual(bad, [], name)

    def test_every_dialog_cell_is_in_the_output(self):
        wanted = set()
        for name, cols in (("npcgreet.txt", (1, 2)), ("npctext.txt", (1,)), ("npcnews.txt", (1,))):
            for r in ex.parse_table(self.lod[name])[1:]:
                if ex.row_id(ex.cell(r, 0)) is None:
                    continue
                for c in cols:
                    if ex.is_speech(ex.cell(r, c)):
                        wanted.add(ex.text_key(ex.cell(r, c)))
        table_rows = {k for k, r in self.out.rows.items() if r["kind"] in ("greeting", "topic", "news")}
        self.assertEqual(wanted, table_rows)
        self.assertGreater(len(wanted), 3500)

    def test_lua_dialogs_are_added(self):
        lua = [r for r in self.out.rows.values() if r["kind"] == "lua"]
        self.assertGreaterEqual(len(lua), 10)
        self.assertTrue(all(r["source"].startswith("Lua ") for r in lua))

    def test_npc_lines_of_the_global_table_are_added(self):
        glob = {r["key"]: r for r in self.out.rows.values() if r["kind"] == "global"}
        self.assertEqual(len(glob), 13)
        # the game shows this refusal with its typo: the key is that of the shown text
        self.assertEqual(glob[ex.text_key("I cannot join you, you're party is full".encode("cp1252"))]["source"], "GlobalTxt 533")

    def test_no_collisions_no_missing_gender(self):
        self.assertEqual(self.out.collisions, [])
        self.assertEqual([r["key"] for r in self.out.rows.values() if r["gender"] not in ("m", "f")], [])

    def test_both_voices_are_used_substantially(self):
        n = collections.Counter(r["gender"] for r in self.out.rows.values())
        self.assertGreater(n["f"], 800)
        self.assertGreater(n["m"], 800)

    def test_poc_files_keep_their_keys(self):
        # keys of the first in-game test (2026-10-26)
        for key in ("3726f23e", "cadcf083", "dc453c9d", "e6239cc0", "368c9301", "fdc033f0"):
            self.assertIn(key, self.out.rows)


if __name__ == "__main__":
    unittest.main(verbosity=2)
