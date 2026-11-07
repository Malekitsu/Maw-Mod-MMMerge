#!/usr/bin/env python3
"""
Tests for Tools/Voice/de/check_translation.py and prepare_chunks.py (M3 of the German edition).

    python -I Tools/Voice/tests/test_check_translation.py
"""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))


def load(name):
    spec = importlib.util.spec_from_file_location(name, HERE.parent / "de" / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


ct = load("check_translation")
pc = load("prepare_chunks")


class Problems(unittest.TestCase):
    def test_good_translation(self):
        self.assertEqual(ct.problems("Welcome, %s. You owe me 5 gold!", "Willkommen, %s. Ihr schuldet mir 5 Gold!"), [])

    def test_missing_and_empty(self):
        self.assertEqual(ct.problems("Hello there.", None), ["missing"])
        self.assertEqual(ct.problems("Hello there.", "   "), ["empty"])

    def test_placeholder_number_question_marks(self):
        self.assertIn("placeholders", ct.problems("Hello %s.", "Hallo."))
        self.assertIn("numbers", ct.problems("Take 5 pearls.", "Nehmt 6 Perlen."))
        self.assertIn("question", ct.problems("Who are you?", "Wer seid Ihr."))
        self.assertIn("marks", ct.problems("[He bows.] Welcome.", "Er verbeugt sich. Willkommen."))

    def test_encoding_and_copy(self):
        self.assertIn("encoding", ct.problems("Hello there, friend.", "Hallo 中 Freund."))
        self.assertIn("copy", ct.problems("Hello there, friend.", "Hello there,  friend."))
        self.assertEqual(ct.problems("Anya Charo", "Anya Charo"), [])  # a bare name may stay
        self.assertEqual(ct.problems("Grüße", "Grüße, Mädchen"), [])  # umlauts are fine

    def test_length_only_for_longer_texts(self):
        self.assertEqual(ct.problems("Yes.", "Ja, natürlich, mit dem größten Vergnügen."), [])
        en = "This is a rather long sentence that says nothing in particular at all."
        self.assertIn("length", ct.problems(en, "Ja, gern."))

    def test_english_leftover(self):
        self.assertIn("english", ct.problems("You must find the key of the old tower and bring it to me.",
                                             "You must find the key of the alten Turm und bring it to me."))

    def test_glossary_warning_uses_a_stem(self):
        entries = [("temple of the sun", "Tempel der Sonne", "tempe")]
        self.assertEqual(ct.glossary_warnings("The Temple of the Sun.", "Der Tempel der Sonne.", entries), [])
        self.assertEqual(len(ct.glossary_warnings("The Temple of the Sun.", "Der Sonnenschrein.", entries)), 1)


class Chunks(unittest.TestCase):
    def test_cut_keeps_order_and_limit(self):
        rows = [{"en": "x" * 100, "n": i} for i in range(10)]
        chunks = pc.cut(rows, 400)
        self.assertEqual([r["n"] for c in chunks for r in c], list(range(10)))
        self.assertTrue(all(len(c) <= 3 for c in chunks))

    def test_sort_key_orders_by_row_number(self):
        a = {"kind": "topic", "source": "NPCText 9.1"}
        b = {"kind": "topic", "source": "NPCText 10.1"}
        self.assertLess(pc.sort_key(a), pc.sort_key(b))


class RunOnFiles(unittest.TestCase):
    def test_run_pairs_by_key(self):
        with tempfile.TemporaryDirectory() as d:
            work = Path(d)
            (work / "chunks").mkdir()
            rows = [{"key": "a", "kind": "topic", "source": "NPCText 1", "en": "Hello %s."},
                    {"key": "b", "kind": "topic", "source": "NPCText 2", "en": "Bye."}]
            (work / "chunks" / "in_01.jsonl").write_text("\n".join(json.dumps(r) for r in rows), encoding="utf-8")
            (work / "chunks" / "out_01.jsonl").write_text(json.dumps({"key": "a", "de": "Hallo %s."}), encoding="utf-8")
            inputs, outputs, errors, warns, bad, detail, extra, clash = ct.run(work, "chunks/in_*.jsonl", "chunks/out_*.jsonl")
            self.assertEqual(bad, ["b"])
            self.assertEqual(errors["missing"], 1)
            self.assertEqual(extra, [])


if __name__ == "__main__":
    unittest.main(verbosity=1)
