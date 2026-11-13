"""Tests for the parts of generate_voices.py that need no model.

    python -I Tools/Voice/tests/test_generate.py
"""

import importlib.util
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("gv", HERE.parent / "generate_voices.py")
gv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gv)


class PrepareSpeechTests(unittest.TestCase):
    def test_typographic_characters(self):
        self.assertEqual(gv.prepare_speech("I don’t work!"), "I don't work!")
        self.assertEqual(gv.prepare_speech("Wha—who is it?"), "Wha, who is it?")
        self.assertEqual(gv.prepare_speech("Hmm…you're late."), "Hmm...you're late.")

    def test_all_caps_words_become_words(self):
        self.assertEqual(gv.prepare_speech("HALT! Who goes there?"), "Halt! Who goes there?")
        self.assertEqual(gv.prepare_speech("I want A drink."), "I want A drink.")  # short words stay

    def test_underscore_runs_and_angle_brackets(self):
        self.assertEqual(gv.prepare_speech("You must have a deck. _______"), "You must have a deck.")
        self.assertEqual(gv.prepare_speech("Ahh <gulp> yes."), "Ahh gulp yes.")

    def test_stage_directions_are_not_spoken(self):
        self.assertEqual(gv.prepare_speech("I am the Master Thief. [Bill bows.] Welcome."), "I am the Master Thief. Welcome.")
        self.assertEqual(gv.prepare_speech("*The woman glances you over* Yes?"), "Yes?")
        self.assertEqual(gv.prepare_speech("::You receive a message:: My Lords."), "My Lords.")
        self.assertEqual(gv.prepare_speech("Stray * star and [ bracket"), "Stray star and bracket")

    def test_single_starred_word_is_emphasis(self):
        self.assertEqual(gv.prepare_speech("With *pleasure*?! Here it goes. *She nods slowly.* Fine."),
                         "With pleasure?! Here it goes. Fine.")
        self.assertEqual(gv.prepare_speech("*The Telelocator brightens up.* It's *our* day."), "It's our day.")

    def test_hash_separated_lists(self):
        self.assertEqual(gv.prepare_speech("Heroes#Goobers#Teleloc"), "Heroes, Goobers, Teleloc")

    def test_whitespace(self):
        self.assertEqual(gv.prepare_speech("  Two   spaces \n here . "), "Two spaces here.")

    def test_only_punctuation_becomes_empty(self):
        self.assertEqual(gv.prepare_speech(" , -- "), "")


class FileTests(unittest.TestCase):
    def test_empty_file_is_not_finished(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            (out / "0000000a.ogg").write_bytes(b"")
            self.assertFalse(gv.existing(out, "0000000a"))
            (out / "0000000a.ogg").write_bytes(b"x")
            self.assertTrue(gv.existing(out, "0000000a"))

    def test_wav_is_written_through_a_part_file(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            gv.write_wav(b"\0\0" * 100, out / "0000000b.wav")
            self.assertEqual(sorted(p.name for p in out.iterdir()), ["0000000b.wav"])

    def test_failed_encoding_leaves_nothing_behind(self):
        import sys
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            # python.exe is not ffmpeg: it rejects the arguments, like a failing encoder
            self.assertFalse(gv.write_ogg(b"\0\0" * 100, out / "0000000c.ogg", sys.executable, 4))
            self.assertEqual(list(out.iterdir()), [])


class SelectionTests(unittest.TestCase):
    ROWS = [
        {"key": "0000000a", "kind": "greeting", "template": "0", "text": "short", "gender": "m"},
        {"key": "0000000b", "kind": "topic", "template": "0", "text": "a much longer text", "gender": "f"},
        {"key": "0000000c", "kind": "news", "template": "1", "text": "Hello %02", "gender": "m"},
        {"key": "0000000d", "kind": "topic", "template": "0", "text": "mid length", "gender": "f"},
    ]

    class A:
        kind = "all"
        templates = False
        shard = None
        limit = 0
        keys = None

    def test_templates_are_skipped_by_default(self):
        keys = [r["key"] for r in gv.select_rows(self.ROWS, self.A)]
        self.assertNotIn("0000000c", keys)

    def test_longest_first(self):
        keys = [r["key"] for r in gv.select_rows(self.ROWS, self.A)]
        self.assertEqual(keys, ["0000000b", "0000000d", "0000000a"])

    def test_shards_partition_the_rows(self):
        parts = []
        for i in range(2):
            a = self.A()
            a.shard = (i, 2)
            parts.append({r["key"] for r in gv.select_rows(self.ROWS, a)})
        self.assertEqual(parts[0] | parts[1], {"0000000a", "0000000b", "0000000d"})
        self.assertEqual(parts[0] & parts[1], set())

    def test_keys_file_restricts_the_rows(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "keys.txt"
            path.write_text("0000000a\n0000000d\n", encoding="utf-8")
            a = self.A()
            a.keys = path
            self.assertEqual({r["key"] for r in gv.select_rows(self.ROWS, a)}, {"0000000a", "0000000d"})

    def test_voice_follows_gender(self):
        voices = {"m": "vm", "f": "vf"}
        self.assertEqual(gv.voice_for({"gender": "f"}, voices), "vf")
        self.assertEqual(gv.voice_for({"gender": "m"}, voices), "vm")

    def test_alt_records_the_other_voice_of_every_text(self):
        # even a text with a known speaker: hints and rumors name an owner but any street NPC tells them
        rows = [
            {"key": "0000000a", "kind": "topic", "template": "0", "text": "known", "gender": "m", "basis": "name"},
            {"key": "0000000b", "kind": "topic", "template": "0", "text": "guessed", "gender": "m", "basis": "name-guess"},
            {"key": "0000000c", "kind": "topic", "template": "0", "text": "parity", "gender": "f", "basis": "parity"},
            {"key": "0000000d", "kind": "topic", "template": "1", "text": "template %01", "gender": "f", "basis": "parity"},
        ]
        a = self.A()
        a.alt = True
        picked = gv.select_rows(rows, a)
        self.assertEqual({r["key"] for r in picked}, {"0000000a", "0000000b", "0000000c"})  # placeholders stay out
        self.assertEqual({r["key"]: gv.stem(r, True) for r in picked},
                         {"0000000a": "0000000a-f", "0000000b": "0000000b-f", "0000000c": "0000000c-m"})
        self.assertEqual(gv.stem(rows[0], False), "0000000a")  # the default file keeps the plain key


class PackTests(unittest.TestCase):
    def test_pack_has_the_game_layout_and_a_checksum(self):
        import hashlib
        import tempfile
        import zipfile
        pspec = importlib.util.spec_from_file_location("pv", HERE.parent / "pack_voices.py")
        pv = importlib.util.module_from_spec(pspec)
        pspec.loader.exec_module(pv)
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / "v" / "NPC").mkdir(parents=True)
            (d / "v" / "NPC" / "0000000a.ogg").write_bytes(b"a")
            (d / "v" / "NPC" / "0000000a-f.ogg").write_bytes(b"b")
            (d / "v" / "NPC" / "0000000b.wav").write_bytes(b"c")
            (d / "v" / "NPC" / "0000000c.ogg.part").write_bytes(b"half")  # a killed run's leftover is not packed
            (d / "v" / "names.tsv").write_bytes(b"keri\tf\n")
            (d / "v" / "templates.tsv").write_bytes(b"0000000a\t^hi$\t\t\n")
            (d / "mod.lua").write_bytes(b"-- module")
            out = d / "pack.zip"
            self.assertEqual(pv.main(["--voices", str(d / "v"), "--module", str(d / "mod.lua"), "--out", str(out)]), 0)
            with zipfile.ZipFile(out) as z:
                self.assertEqual(sorted(z.namelist()), [
                    "Data/Voices/NPC/0000000a-f.ogg", "Data/Voices/NPC/0000000a.ogg", "Data/Voices/NPC/0000000b.wav",
                    "Data/Voices/names.tsv", "Data/Voices/templates.tsv", "INSTALL.txt", "Scripts/General/zzzMaw_NPCVoices.lua"])
            line = (d / "pack.zip.sha256").read_text(encoding="ascii")
            self.assertEqual(line.split()[0], hashlib.sha256(out.read_bytes()).hexdigest())

    def test_pack_refuses_without_names_or_patterns_file(self):
        import tempfile
        pspec = importlib.util.spec_from_file_location("pv", HERE.parent / "pack_voices.py")
        pv = importlib.util.module_from_spec(pspec)
        pspec.loader.exec_module(pv)
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / "v" / "NPC").mkdir(parents=True)
            (d / "v" / "NPC" / "0000000a.ogg").write_bytes(b"a")
            (d / "mod.lua").write_bytes(b"x")
            args = ["--voices", str(d / "v"), "--module", str(d / "mod.lua"), "--out", str(d / "p.zip")]
            self.assertEqual(pv.main(args), 1)
            (d / "v" / "names.tsv").write_bytes(b"keri\tf\n")
            self.assertEqual(pv.main(args), 1)  # templates.tsv is missing too
            (d / "v" / "templates.tsv").write_bytes(b"x\n")
            self.assertEqual(pv.main(args), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
