"""Tests for templates.py.

    python -I Tools/Voice/tests/test_templates.py

The real-data tests read the install named by the environment variable MM8_DIR
(default: the author's test install) and are skipped when it is missing.
"""

import collections
import os
import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import extract_texts as ex  # noqa: E402
import templates as T  # noqa: E402

GAME = Path(os.environ.get("MM8_DIR", r"C:\Users\slovi\Desktop\Might and Magic 8 MAW Mod 4.5"))
HAVE_GAME = (GAME / "Data" / "mmmerge.T.lod").exists()

DOMAINS = {"%05": ["morning", "day", "evening"], "%08": ["Hated", "Liked"], "%12": ["Hated", "Liked"],
           "%09": ["his", "her"], "%10": ["Lord", "Lady"], "%03": ["his", "her"], "%04": ["0", "200"]}


def row(text, source="NPCText 1"):
    return {"key": ex.text_key(text.encode("cp1252")), "text": text, "source": source, "n_sources": "1", "template": "1"}


class SpokenTextTests(unittest.TestCase):
    def test_names_and_classes_are_left_out(self):
        for text, want in (
            ("Back again, %02?", "Back again?"),
            ("Oh, Hullo %02. Nice %05, isn't it?", "Oh, Hullo. Nice %05, isn't it?"),
            ("%07 %02! What an honor!", "What an honor!"),
            ("Oh No! Please don't hurt me, %06 %02! I'll tell you anything!", "Oh No! Please don't hurt me! I'll tell you anything!"),
            ("Although I have not heard much about you, %02, I do not trust you.", "Although I have not heard much about you, I do not trust you."),
            ("Hmm. %02. I have sworn an oath.", "Hmm. I have sworn an oath."),
            ("Understood %06. I want to live.", "Understood. I want to live."),
            ("Ooooh, %06, no need to threaten me again.", "Ooooh, no need to threaten me again."),
            ("O Ho! %13! Er, %13. I think.", "O Ho! Er. I think."),
        ):
            self.assertEqual(T.drop_names(text), want, text)

    def test_the_npc_does_not_introduce_itself(self):
        for text, want in (
            ("Good %05! I'm %01. Pleased to meet you!", "Good %05! Pleased to meet you!"),
            ("Hi. Name's %01.", "Hi."),
            ("Peace, %06. My name is %14 %01.", "Peace."),
            ("Hello! My name is %01, and I am pleased to meet you, %02.", "Hello! I am pleased to meet you."),
            ("%02, I am %01. I am constrained by pacts.", "I am constrained by pacts."),
            ("<bowing> %01, at your service.", "At your service."),
        ):
            self.assertEqual(T.drop_names(text), want, text)

    def test_stage_directions_are_dropped(self):
        self.assertEqual(T.drop_names("HA! <drawing %03 sword> Threaten me, will you?"), "HA! Threaten me, will you?")
        self.assertEqual(T.drop_names("<sneer> Stinkin' goody two-shoes."), "Stinkin' goody two-shoes.")

    def test_an_adjective_in_front_of_the_name_keeps_a_noun(self):
        self.assertEqual(T.drop_names("The infamous %06 %02! I heard you."), "The infamous adventurer! I heard you.")
        self.assertEqual(T.drop_names("Ah, the famous and honorable %06 %02! Anything."), "Ah, the famous and honorable adventurer! Anything.")
        self.assertEqual(T.drop_names("Oh, the notorious %02. Yes."), "Oh, the notorious adventurer. Yes.")
        self.assertEqual(T.drop_names("Baaa, friend %02! Hello."), "Baaa, friend! Hello.")

    def test_lord_and_lady_stay_a_placeholder(self):
        self.assertEqual(T.drop_names("An honor, great %10. How may I serve you?"), "An honor, great %10. How may I serve you?")
        self.assertEqual(T.drop_names("Wonderful %10 %02! You have come."), "Wonderful %10! You have come.")

    def test_a_name_in_the_middle_of_a_sentence_is_not_guessed(self):
        # needs a line in data/template_speech.csv
        self.assertIn("%02", T.drop_names("Some call me...%02. Being famous, I walk alone."))


class ValueTests(unittest.TestCase):
    def test_every_combination_gets_a_recording(self):
        found = T.variants("Good %05! It costs %04 gold.", DOMAINS)
        self.assertEqual(len(found), 6)
        self.assertEqual(found[0], ("~morning~0", "Good morning! It costs 0 gold."))
        self.assertEqual(len({suffix for suffix, _ in found}), 6)

    def test_the_party_reputation_is_one_value(self):
        found = T.variants("Your reputation is %11, not %08.", DOMAINS)
        self.assertEqual([text for _, text in found], ["Your reputation is Hated, not Hated.", "Your reputation is Liked, not Liked."])

    def test_lord_and_his_follow_the_same_character(self):
        found = T.variants("Bring %09 band, my %10.", DOMAINS)
        self.assertEqual([text for _, text in found], ["Bring his band, my Lord.", "Bring her band, my Lady."])
        self.assertEqual(found[0][0], "~his~lord")

    def test_percent_comes_from_the_text_s_professions(self):
        found = T.variants("I take %17 percent.", DOMAINS, ["0.5", "2"])
        self.assertEqual([suffix for suffix, _ in found], ["~0.5", "~2"])

    def test_unknown_values_give_no_variants(self):
        self.assertIsNone(T.variants("I take %17 percent.", DOMAINS))
        self.assertIsNone(T.variants("The %14 is here.", DOMAINS))

    def test_shown_text_has_every_placeholder_filled_in(self):
        text = "Hi %02, nice %05. You %11, I take %17."
        self.assertEqual(T.shown(text, {"%05": "day", "%08": "Liked", "%17": "3"}), "Hi Aldric, nice day. You Liked, I take 3.")

    def test_slug(self):
        self.assertEqual(T.slug("Hated"), "hated")
        self.assertEqual(T.slug("0.01"), "0.01")
        self.assertEqual(T.slug(" a  b "), "a_b")


class PatternTests(unittest.TestCase):
    def test_pattern_captures_only_the_values_that_vary(self):
        pattern, captures = T.lua_pattern('Good %05! I\'m %01. It costs %04 gold (really).', {"%05", "%04"})
        self.assertEqual(captures, ["%05", "%04"])
        self.assertEqual(pattern, "^good (.-)! i'm .-%. it costs (.-) gold %(really%)%.$")

    def test_the_party_reputation_has_one_name(self):
        _, captures = T.lua_pattern("You %11, I mean %08.", {"%08"})
        self.assertEqual(captures, ["%08", "%08"])

    def test_pattern_is_in_normalized_form(self):
        pattern, _ = T.lua_pattern('"HELLO"\n there   %02', set())
        self.assertEqual(pattern, "^hello there .-$")


class BuildTests(unittest.TestCase):
    def build(self, rows, overrides=None, percents=None):
        return T.build(rows, DOMAINS, percents or {}, overrides or {})

    def test_recordings_patterns_and_cases(self):
        r = row("Back again, %02? Good %05.")
        recordings, patterns, skipped, _, cases = self.build([r])
        self.assertEqual(skipped, [])
        self.assertEqual([x["key"] for x in recordings], ["t" + r["key"] + s for s in ("~morning", "~day", "~evening")])
        self.assertEqual(recordings[0]["text"], "Back again? Good morning.")
        self.assertEqual(recordings[0]["kind"], "template")
        self.assertEqual(recordings[0]["template"], 0)  # generate_voices.py takes it without --templates
        self.assertEqual(len(patterns), 1)
        self.assertEqual(patterns[0][0], r["key"])
        self.assertEqual(patterns[0][2:], ("05", "05"))
        self.assertEqual(cases[0], ("t" + r["key"] + "~morning", "Back again, Aldric? Good morning."))

    def test_voice_follows_the_key_like_for_other_texts(self):
        r = row("Hello %02.")
        gender = "m" if int(r["key"], 16) % 2 == 0 else "f"
        self.assertEqual(self.build([r])[0][0]["gender"], gender)

    def test_what_stays_silent(self):
        rows = [row("Kill the %s and take %lu gold."), row("Weapon repair. %01 takes %17 percent of all gold you find."),
                row("Some call me...%02. Being famous."), row("I take %17 percent."), row("%02. <spits>")]
        recordings, patterns, skipped, _, _ = self.build(rows)
        self.assertEqual((recordings, patterns), ([], []))
        self.assertEqual([why.split(":")[0] for _, why, _ in skipped], [
            "placeholder with unknown values", "stat sheet of a hireling, not speech", "name left in the sentence",
            "no known values for a placeholder", "nothing left to say"])

    def test_override_replaces_the_rules(self):
        r = row("Some call me...%02. Being famous.")
        recordings, *_ = self.build([r], {r["key"]: "Some call me... Being famous."})
        self.assertEqual(recordings[0]["text"], "Some call me... Being famous.")

    def test_override_dash_leaves_it_silent(self):
        r = row("Hello %02.")
        recordings, _, skipped, _, _ = self.build([r], {r["key"]: "-"})
        self.assertEqual(recordings, [])
        self.assertEqual(skipped[0][1], "left silent by choice")

    def test_override_with_a_placeholder_the_text_lacks_stays_silent(self):
        r = row("Hello %02.")
        recordings, _, skipped, _, _ = self.build([r], {r["key"]: "Hello at %05."})
        self.assertEqual(recordings, [])
        self.assertEqual(skipped[0][1], "override uses a placeholder the text does not have")

    def test_a_character_outside_the_code_page_stays_silent(self):
        r = {"key": "0000beef", "text": "Hello � %02.", "source": "NPCText 1", "n_sources": "1", "template": "1"}
        recordings, _, skipped, _, _ = self.build([r])
        self.assertEqual(recordings, [])
        self.assertEqual(skipped[0][1], "character that is not in the game's code page")

    def test_too_many_variants_stay_silent(self):
        domains = dict(DOMAINS, **{"%04": [str(i) for i in range(100)]})
        r = row("It costs %04.")
        self.assertEqual(T.build([r], domains, {}, {})[0], [])

    def test_hire_pitch_uses_the_percent_of_its_professions(self):
        r = row("I'll join you for 200 gold and %17 percent of the gold we find.")
        recordings, patterns, *_ = self.build([r], percents={r["key"]: ["2", "3"]})
        self.assertEqual([x["key"] for x in recordings], ["t" + r["key"] + "~2", "t" + r["key"] + "~3"])
        self.assertEqual(patterns[0][1:], ("^i'll join you for 200 gold and (.-) percent of the gold we find%.$", "17", "17"))

    def test_longer_patterns_come_first(self):
        short, long_ = row("Hello %02."), row("Hello there, %02, how are you doing today?")
        patterns = self.build([short, long_])[1]
        self.assertEqual([p[0] for p in patterns], [long_["key"], short["key"]])

    def test_patterns_file_is_cp1252_with_tabs(self):
        import tempfile
        r = row("Wait… %02.")  # U+2026 is byte 0x85 in cp1252
        patterns = self.build([r])[1]
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "templates.tsv"
            T.write_patterns(patterns, path)
            line = path.read_bytes().split(b"\n")[0]
        self.assertEqual(line.split(b"\t")[1], b"^wait\x85 .-%.$")
        self.assertEqual(len(line.split(b"\t")), 4)


@unittest.skipUnless(HAVE_GAME, "game install not found (set MM8_DIR)")
class RealDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.out, _, _ = ex.build(GAME)
        cls.rows = [r for r in cls.out.rows.values() if r["template"]]
        domains, percents = T.load_domains(GAME)
        cls.domains, cls.percents = domains, percents
        cls.result = T.build(cls.rows, domains, percents, T.load_overrides(T.HERE / "data" / "template_speech.csv"))

    def test_domains_are_what_the_game_shows(self):
        self.assertEqual(self.domains["%10"], ["Lord", "Lady"])
        self.assertEqual(self.domains["%05"], ["morning", "day", "evening"])
        self.assertEqual(len(self.domains["%08"]), 5)
        self.assertIn("200", self.domains["%04"])

    def test_the_hire_pitches_are_voiced(self):
        pitch = ex.text_key(b"I'll happily join you for 200 gold and %17 percent of all the gold we find. I'll fix any weapon you ask me to while I work for you.")
        recordings = [r for r in self.result[0] if r["key"].startswith("t" + pitch)]
        self.assertEqual([r["key"] for r in recordings], ["t" + pitch + "~2"])
        self.assertIn("2 percent of all the gold we find", recordings[0]["text"])

    def test_every_recording_is_clean_speech(self):
        recordings = self.result[0]
        self.assertGreater(len(recordings), 500)
        for r in recordings:
            self.assertNotRegex(r["text"], r"%[0-9a-z]|<|>", r["key"])  # a literal "100%" is fine
            self.assertTrue(ex.is_speech(r["text"].encode("cp1252", "replace")), r["key"])
        self.assertEqual(len({r["key"] for r in recordings}), len(recordings))

    def test_nothing_is_lost_without_a_reason(self):
        voiced = {p[0] for p in self.result[1]}
        silent = {key: why for key, why, _ in self.result[2]}
        self.assertEqual(voiced | set(silent), {r["key"] for r in self.rows})
        self.assertEqual(voiced & set(silent), set())
        counts = collections.Counter(why.split(":")[0] for why in silent.values())
        self.assertEqual(counts["name left in the sentence"], 0)  # every one is in the overrides file
        self.assertEqual(counts["no known values for a placeholder"], 0)
        self.assertGreater(len(voiced), 190)

    def test_the_hirelings_stat_sheets_stay_silent(self):
        sheets = [k for k, why, _ in self.result[2] if why.startswith("stat sheet")]
        self.assertGreaterEqual(len(sheets), 40)

    def test_each_case_shows_a_text_its_own_pattern_accepts(self):
        # the Lua side of this is tests/lua/templates_test.lua; here the same patterns are tried as Python regexes
        patterns = {p[0]: p for p in self.result[1]}
        recordings = {r["key"]: r for r in self.result[0]}
        for key, shown in self.result[4]:
            self.assertIn(key, recordings)
            pattern = patterns[recordings[key]["key"].split("~")[0][1:]][1]
            norm = ex.normalize(shown.encode("cp1252", "replace")).decode("cp1252", "replace")
            regex = re.sub(r"%(.)", lambda m: re.escape(m.group(1)), pattern).replace("(.-)", "(.*?)").replace(".-", ".*?")
            self.assertRegex(norm, regex, key)


if __name__ == "__main__":
    unittest.main(verbosity=2)
