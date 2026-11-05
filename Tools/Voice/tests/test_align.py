#!/usr/bin/env python3
"""
Tests for Tools/Voice/de/align_german.py (M2 of the German edition).

    python -I Tools/Voice/tests/test_align.py

check_pair is tested with made-up texts; the real-data tests read the install named
by the environment variable MM8_DIR (default: the author's test install) and skip when
it is missing.
"""

import importlib.util
import os
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
spec = importlib.util.spec_from_file_location("align_german", HERE.parent / "de" / "align_german.py")
ag = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ag)

GAME = Path(os.environ.get("MM8_DIR", r"C:\Users\slovi\Desktop\Might and Magic 8 MAW Mod 4.5"))


class CheckPair(unittest.TestCase):
    def test_plausible_pair_is_ok(self):
        en = b"You must bring 5 pearls to the Temple, %s."
        de = b"Ihr m\xfc\xdft 5 Perlen zum Tempel bringen, %s."
        self.assertEqual(ag.check_pair(en, de), ("ok", ""))

    def test_empty_german_is_none(self):
        self.assertEqual(ag.check_pair(b"Hello there, friend.", b"")[0], "none")
        self.assertEqual(ag.check_pair(b"Hello there, friend.", b"  \r\n")[0], "none")

    def test_copy_of_english_is_none(self):
        self.assertEqual(ag.check_pair(b'"Hello there, friend."', b"Hello there,  friend.")[0], "none")

    def test_number_mismatch_is_suspect(self):
        status, reason = ag.check_pair(b"Bring me 5 pearls, please.", b"Bringt mir 7 Perlen, bitte sehr.")
        self.assertEqual(status, "suspect")
        self.assertIn("numbers", reason)

    def test_placeholder_mismatch_is_suspect(self):
        status, reason = ag.check_pair(b"Welcome, %s. How are you today?", b"Willkommen. Wie geht es Euch heute?")
        self.assertEqual(status, "suspect")
        self.assertIn("placeholders", reason)

    def test_question_mark_mismatch_is_suspect(self):
        status, reason = ag.check_pair(b"Do you have the key?", b"Ihr habt den Schl\xfcssel.")
        self.assertEqual(status, "suspect")
        self.assertIn("question", reason)

    def test_length_ratio_is_checked_only_for_longer_texts(self):
        self.assertEqual(ag.check_pair(b"Yes, of course.", b"Ja, nat\xfcrlich, selbstverst\xe4ndlich, sehr gern.")[0], "ok")
        long_en = b"This is a rather long sentence that talks about nothing in particular at all."
        self.assertEqual(ag.check_pair(long_en, b"Ja, nat\xfcrlich, gern.")[0], "suspect")


@unittest.skipUnless((GAME / "Data" / "GermanT.lod").exists(), "no install (set MM8_DIR)")
class RealData(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = ag.build_pairs(GAME)

    def test_every_english_text_appears_once(self):
        out, _, _ = ag.ex.build(GAME)
        keys = {k for k, r in out.rows.items() if r["kind"] != "lua"}
        self.assertEqual(set(self.rows), keys)

    def test_known_pair_is_aligned(self):
        row = next(r for r in self.rows.values() if r["source"] == "NPCText 1.1")
        self.assertEqual(row["status"], "ok")
        self.assertIn("Freunde", row["text_de_orig"])

    def test_statuses_are_complete(self):
        self.assertTrue(all(r["status"] in ag.RANK for r in self.rows.values()))
        self.assertGreater(sum(r["status"] == "ok" for r in self.rows.values()), 900)


if __name__ == "__main__":
    unittest.main(verbosity=1)
