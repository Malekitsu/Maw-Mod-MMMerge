# NPC voices for MMMerge + MAW

This module voices nearly every NPC dialog text of Might and Magic 6/7/8 (as
merged by MMMerge): 3,803 of 3,881 distinct texts, see "What is voiced". Two
generic voices, one male and one female, are played automatically in game. The
idea comes from Morrowind's *Voices of Vvardenfell*; the audio is produced
locally with a free model and no cloud service.

MMMerge is a fan project that merges Might and Magic 6, 7 and 8 into one game
on the MM8 engine; MAW is a gameplay mod built on top of MMMerge. Everything
here was developed and tested against an install in a folder named "Might and
Magic 8 MAW Mod 4.5". The module needs the MMMerge/MAW scripts and the file
`ExeMods/soloud_x86.dll` (the SoLoud audio library, with which the module plays
the files), which that install contains.

```
Data/mmmerge.T.lod ─extract_texts.py─► texts.csv ─generate_voices.py─► Data/Voices/NPC/<key>.ogg ─qa_voices.py─► verified
                                                   (Kokoro-82M, CPU)            │
in game: text about to be shown ─CRC32 of the normalized text = key─► file exists? play : stay silent
                                 (Scripts/General/zzzMaw_NPCVoices.lua, SoLoud)
         NPC name ─Data/Voices/names.tsv─► gender ─► <key>-m.ogg / <key>-f.ogg preferred over <key>.ogg
         no file for the text? ─Data/Voices/templates.tsv─► pattern + values (percent, ...) ─► t<key>~<value>.ogg
         guard or monster: SpeakWithMonster ─► the news text of its group ─► same lookup
```

## Quick start

The voice pack is a zip (`MAW-NPCVoices-<date>.zip`, 675 MB) with four paths:
`Data/Voices/NPC` (the `.ogg` files), `Data/Voices/names.tsv` (NPC names in
lowercase and their gender), `Data/Voices/templates.tsv` (patterns of the texts
with names and numbers in them) and `Scripts/General/zzzMaw_NPCVoices.lua`.
It is not part of the Git repository; build it with `pack_voices.py` (last
command under "Rebuilding the audio") or get it from the author (GitHub:
slovi21). Unpack it into the folder that contains `MM8.exe` of a working
MMMerge/MAW install, keeping the folders. The zip also holds an `INSTALL.txt` next to those four
paths, which the game does not need. That is all. Uninstall by deleting those
four paths (and `INSTALL.txt`, if you kept it).

The module runs with its defaults: on, one step louder than the game's character voices slider (the recordings are a little quiet). To switch it
off for one session, open the debug console of MMExtension in game (Ctrl+F1,
described in `MMExtension.htm` in the game folder) and run
`MawVoices.Enabled = false`; the setting is lost at the next start.

Two settings in `MAWSettings.lua` (in the game folder, next to `MM8.exe`) are
meant to do this permanently, but they only take effect in a MAW release that
carries them: the repository's copy of `Scripts/General/zz_Maw-initialize.lua`
adds both to its settings list, the MAW 4.5 test install does not have them,
and the pack does not ship that file because it would replace the installed
one. In such a release the game creates `MAWSettings.lua` with these lines when
the file is missing; an existing `MAWSettings.lua` is read as it is, so add the
lines by hand:

```lua
npcVoices = true,        -- false switches the module off
npcVoiceVolume = 1.0,    -- relative to the game's character voices slider
```

Dialogs without a file stay silent. `NPCVoicesLog.txt` in the game folder lists
every dialog text with `play` or `missing`, followed by `| <NPC name> <m|f|?>`
(`m` or `f`: the gender found for the name in `names.tsv`; `?`: no gender known
for the name) and the word `alt` when the recording of the NPC's gender
(`<key>-m.ogg` / `<key>-f.ogg`) was used. Every text has its default recording
`<key>.ogg` and one file in the opposite voice: `<key>-f.ogg` if the default
voice is male, `<key>-m.ogg` if it is female. For an NPC of the default voice's
gender the plain file plays and the line has no `alt`. The fields of a line, in order: time,
kind of the message (`greeting` in the example), key, `play` or `missing`, the
text, then `|` and the NPC part just described, and at the end `vol=<a>,<b>`:
the Sound slider of the game (0-9) and the character voices slider (0-9), as the
game keeps them. The voice follows the second one. An example line (the NPC name
is made up):

```
07:44:27 greeting cb42bf10 play    Nice to see you again, how are you doing on the hunt? | Keri f alt
```

The log is appended to, starts over when it grows beyond 1 MB, and is written
unless `MawVoices.Log` is set to `false` (default `true`).

## Rebuilding the audio

In the commands below, `python` for `generate_voices.py` and `qa_voices.py`
means the venv interpreter described under "Setup used" after the block.

```bash
python -I extract_texts.py --game "<your install folder>" --out texts.csv --names ../../Data/Voices/names.tsv
# the texts with placeholders: recordings to make (templates.csv, same columns as texts.csv) and the patterns for the module
python -I templates.py --game "<your install folder>" --texts texts.csv --out-csv templates.csv --out-patterns ../../Data/Voices/templates.tsv --report templates-report.txt
python generate_voices.py texts.csv --out ../../Data/Voices/NPC --model kokoro-v1.0.onnx --voices voices-v1.0.bin --shard 0/4 --threads 4   # one shard = one quarter of the rows: run it four times, --shard 0/4 to 3/4, in parallel (own terminal each)
python generate_voices.py texts.csv --out ../../Data/Voices/NPC --verify                  # every selected row has a file?
python qa_voices.py texts.csv --dir ../../Data/Voices/NPC --report qa.csv --bad-keys bad.txt
python generate_voices.py texts.csv --out ../../Data/Voices/NPC --model kokoro-v1.0.onnx --voices voices-v1.0.bin --keys bad.txt --force   # redo the flagged ones
# the same text in the other voice, for every text (<key>-m.ogg / <key>-f.ogg), again 4 shards
python generate_voices.py texts.csv --out ../../Data/Voices/NPC --model kokoro-v1.0.onnx --voices voices-v1.0.bin --alt --shard 0/4 --threads 4
python generate_voices.py texts.csv --out ../../Data/Voices/NPC --alt --verify
python qa_voices.py texts.csv --dir ../../Data/Voices/NPC --alt --report qa-alt.csv
# the same for templates.csv: both voices, each in 4 shards (--shard 0/4 to 3/4, as above), then --verify and qa_voices.py, each without and with --alt
python generate_voices.py templates.csv --out ../../Data/Voices/NPC --model kokoro-v1.0.onnx --voices voices-v1.0.bin --shard 0/4 --threads 4
python generate_voices.py templates.csv --out ../../Data/Voices/NPC --model kokoro-v1.0.onnx --voices voices-v1.0.bin --alt --shard 0/4 --threads 4
python generate_voices.py templates.csv --out ../../Data/Voices/NPC --verify
python generate_voices.py templates.csv --out ../../Data/Voices/NPC --alt --verify
python qa_voices.py templates.csv --dir ../../Data/Voices/NPC --report qa-templates.csv
python qa_voices.py templates.csv --dir ../../Data/Voices/NPC --alt --report qa-templates-alt.csv
# the voice pack: recordings, names.tsv, templates.tsv, the Lua module and INSTALL.txt in one zip, plus a .sha256 file
python -I pack_voices.py --out ../../Data/Voices/MAW-NPCVoices-<date>.zip
```

Run these from the folder `Tools/Voice` (the tests below are run from the
repository root). The paths in the commands are relative to that folder: the
model files `kokoro-v1.0.onnx` and `voices-v1.0.bin` (see "Setup used") have to
lie there. The recordings, `names.tsv` and `templates.tsv` go to `Data/Voices` in
the repository root (`../../Data/Voices` from there; the folder is not tracked
by Git); `pack_voices.py` reads them from the same folder and writes the zip
there. A "selected" row is a row that passes the filters of the run:
rows of `texts.csv` with placeholders are skipped unless `--templates` is given
(the rows of `templates.csv` are ready-made spoken versions and need no flag),
and `--kind`, `--keys` and `--shard` narrow the selection further.

Setup used: a Python 3.13 venv (kokoro-onnx 0.6.1 needs 3.10–3.13), created with
`py -3.13 -m venv venv` (any folder works, for example `Tools/Voice/venv`; keep
it out of Git) and filled with
`venv\Scripts\python.exe -m pip install kokoro-onnx==0.6.1`. In the commands
above, `python` for `generate_voices.py` and `qa_voices.py` means that venv's
`venv\Scripts\python.exe` (they import kokoro-onnx, onnxruntime and numpy);
`extract_texts.py`, `templates.py` and the tests run with any plain Python 3. Further needs:
model files `kokoro-v1.0.onnx` (310 MiB = 325 MB) and
`voices-v1.0.bin` (28 MB) from
<https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0>,
ffmpeg on PATH. Keep work folders short: Windows tools fail on paths over 260
characters. The extractor, `templates.py` and the Python tests
`test_extract.py`, `test_generate.py` and `test_templates.py` run on plain
Python 3 without packages; `run_lua_tests.py`
and `soloud_check.ps1` need the game install (see Tests).

## Files

Paths in this table are relative to `Tools/Voice` in the repository.

| File | What it does |
|---|---|
| `extract_texts.py` | Reads `mmmerge.T.lod` (read-only) and writes one CSV row per distinct dialog text: key, kind, source, gender, speakers, text. With `--names` it also writes `names.tsv` (lowercase name, tab, `m` or `f`) for the Lua module. |
| `templates.py` | For the texts with run-time placeholders: writes the spoken version of each (names left out, one recording per value of a percent, reputation word, time of day, ...) as `templates.csv` and the patterns the module uses to recognize the shown text as `templates.tsv`. |
| `generate_voices.py` | Synthesizes the rows with Kokoro-82M, one male and one female voice, levelled to the same loudness, written as Ogg Vorbis. Shardable, resumable, `--verify`, `--keys`; `--alt` records the other voice. |
| `qa_voices.py` | Objective quality gate over the generated files (decodes, length per text, level, clipping, dropouts). |
| `pack_voices.py` | Bundles the recordings, `names.tsv`, `templates.tsv`, the Lua module and `INSTALL.txt` into the voice-pack zip and writes its `.sha256`. |
| `data/speakers.csv` | Hand-made gender table for speaker names. Columns `name,gender,scope,note`: `gender` is `m` or `f`, or `x` for a generic role without gender (ignored); `scope` is `first` (the entry matches by first name) or `full` (whole name). Example row: `aerie,f,first,`. |
| `data/lua_dialog_files.txt` | Lua quest scripts whose spoken lines are voiced too. |
| `data/global_speech_ids.txt` | The rows of `Global.txt` that an NPC says (for example the refusal when the party is full), with a comment for each. |
| `data/template_speech.csv` | Columns `key,spoken,note`: the spoken version of the few templates whose names `templates.py` cannot leave out by its rules; a spoken text of `-` leaves the template silent. |
| `tests/` | `test_extract.py`, `test_generate.py`, `test_templates.py` (plain Python), `run_lua_tests.py` (Lua in the game's own LuaJIT), `soloud_check.ps1` (loads every file with the game's `soloud_x86.dll`). |
| `docs/projekt/` | Milestone plan, project state and decision log (German). |
| `../../Scripts/General/zzzMaw_NPCVoices.lua` | In game: computes the key of each dialog text, plays the matching file (the recording of the NPC's gender first) with SoLoud, recognizes texts with filled-in placeholders, speaks the sayings of guards and monsters, starts greetings one second late, stops on exit. |
| `../../Scripts/General/zz_Maw-initialize.lua` | Settings `npcVoices` and `npcVoiceVolume`. |

## What is voiced

Every row of three tables of `mmmerge.T.lod`, whether or not a script is known
to reach it, the 13 rows of `Global.txt` that an NPC says, and the spoken lines
of five MAW Lua quest scripts. The sayings of guards and monsters are not extra
texts: they are rows of `NPCNews.txt`, picked per monster group.

| Kind | Source | Distinct texts | Voiced as they stand | Voiced from a template | Not voiced |
|---|---|---|---|---|---|
| greeting | `NPCGreet.txt`, columns Greeting 1/2 | 495 | 494 | 1 | 0 |
| topic | `NPCText.txt` (answers to topics, quest, trainer and hire texts) | 2,468 | 2,190 | 203 | 75 |
| news | `NPCNews.txt` (what street NPCs tell) | 889 | 888 | 1 | 0 |
| global | `Global.txt` (for example the refusal when the party is full) | 13 | 13 | 0 | 0 |
| lua | five MAW quest scripts | 16 | 13 | 0 | 3 |
| | | 3,881 | 3,598 | 205 | 78 |

The 3,598 texts without placeholders have 720,737 characters. The 205 templates
have 653 recordings (76,607 characters): one for every combination of values
that can appear in them (up to 50 per text; see "Known limits" for combinations
without a recording). Together, 3,803 texts (98 %) are voiced; they cover 4,214 of the
4,296 places in the tables where a text occurs: many texts are shared by
several NPCs.

**Templates.** Some table texts contain placeholders (`%01`, `%02`, `%17`, ...)
that the game replaces just before it shows the text: "Back again, %02?" is
shown as "Back again, Tracie?". The shown text has no recording of its own, so
`templates.py` prepares the text and the module recognizes it:

- Names are left out of the recording: the NPC's own name, the names of the
  party members and their class names ("Back again?"). A few texts need a
  hand-written spoken version (`data/template_speech.csv`), for example "The
  infamous %06 %02!" becomes "The infamous adventurer!".
- Values from a fixed set are spoken exactly, one recording per value: the
  percent a hireling takes (`%17`, the profession's cost divided by 100, as in
  `NPCFollowers.lua`), the time of day (`%05`), the reputation word (`%08`,
  `%11`, `%12`), "Lord" or "Lady" (`%10`) and the price (`%04`). A text with
  several of them has one recording for every combination (up to 50).
- The module compares a shown text that has no recording of its own with the
  patterns in `templates.tsv`, reads the values out of it and plays
  `t<key>~<value>~...`. The hire dialog adds a note in brackets after the
  hireling's sales pitch (its offer text) ("(... Click again to hire ...)"); it is not spoken.
- Silent: 25 texts of quest and arena code whose placeholders (`%s`, `%d`,
  `%lu`) can be anything, 51 stat sheets of hirelings ("%01 takes %17 percent
  of all gold you find", information rather than speech) and one template that
  is only a stage direction: 25 + 51 + 1 = 77 templates.

Not voiced, on purpose, together 78 texts: those 77 templates and one further
text, without placeholders, that consists of stage directions only (77 + 1 =
78; in the table above 75 of them are topic texts and 3 are Lua texts). Not
counted at all, because they are not in these sources: signs and inscriptions,
book and scroll texts, journal and award notes, UI strings. Details and
reasons: `docs/projekt/ENTSCHEIDUNGEN.md` (in German).

## Result (2026-10-30)

| | |
|---|---|
| Audio files | 8,502 in `Data/Voices/NPC` (679 MB = 678,920,306 bytes as Ogg Vorbis quality level 4, mono, 24 kHz; the zip with the module, `names.tsv` and `templates.tsv` is 675 MB): 4,251 default recordings (3,598 texts and 653 recordings of templates) plus 4,251 second recordings (`<key>-m.ogg` / `<key>-f.ogg`), one of each voice for every recording |
| Playing time | default recordings 13.76 h (median 9.8 s, longest 79.7 s), second recordings 13.37 h; the 653 template recordings are 1.36 h and 1.38 h of it |
| Voices (default) | male 2,689 files (9.26 h), female 1,562 files (4.50 h); hours are rounded, so the parts need not add up exactly |
| Generation | 4 parallel processes on the CPU: for the first 3,585 texts 2 h 2 min for the default set and 2 h 17 min in two runs for the second recordings; for the 13 rows of `Global.txt` a few minutes; for the 653 template recordings 13 min and 12 min; 0 failures |
| `generate_voices.py --verify` | 3,598 of 3,598 texts and 653 of 653 template recordings have a default file and a second file |
| `qa_voices.py` | 3,598 clean and 3,598 clean (with `--alt`) for `texts.csv`, 653 and 653 clean for `templates.csv`, 0 flagged |
| `tests/soloud_check.ps1` (the game's own decoder) | 8,502 loaded, 0 rejected |

## The key — why lookup is by text

`key = CRC32(normalize(text))`, 8 hex digits. `normalize` removes `"`,
collapses `[ \t\r\n\v\f]+` to one space, trims, lowercases A–Z only, all on
the raw cp1252 bytes. Python (`extract_texts.normalize`) and Lua
(`zzzMaw_NPCVoices.lua normalize`) must stay byte-identical; `run_lua_tests.py`
checks this for every text and for quoted, CRLF and padded variants.

Keying by text instead of table index means: when MAW, a quest script or the
multiplayer module replaces a text, there is simply no file and the line stays
silent — never a stale recording. Collisions among ~3,900 texts: none
(checked on every extraction).

## Voices and gender

Two voices, both American English: male `am_michael`, female `af_heart`
(Kokoro v1.0). No voice is cloned from a real person.

The default voice of a text follows its speakers. They come from three places,
listed in the `speakers` column of `texts.csv` in this order: the owner cell of
the text's own row (`NPCGreet.txt` and `NPCText.txt` each have a column that
names who says the line), the owner of the topic whose event shows the text
(`NPCTopic.txt` names an owner per topic), and the NPCs in `NPCData.txt` whose
greeting or events lead to the text (that file lists every named NPC with its
greeting and up to six events). The rules, in this order:

1. Each speaker name is looked up in `data/speakers.csv`, then by title words
   (Queen, Sir, Sister, ...), then in the first-name lists of `NPC names.txt`.
   A name found this way counts with weight 2.
2. A name that rule 1 does not know counts as male ("guessed") with weight 1.
   Owner cells that are notes instead of names (for example `Hint Alvar`,
   `Expert Alchemy (3)` or a bare number) and the generic roles marked `x` in
   `speakers.csv` are ignored.
3. The weighted majority of all speakers of the text decides. On a tie the
   speaker listed first (in the order above) wins.
4. A text without any known speaker (generic profession texts, news) takes its
   gender from the key's parity: the key read as a hexadecimal number, even =
   male, odd = female. Each text therefore always has the same voice, and
   within this group the split is about even.

Result: 2,386 male and 1,212 female texts (the overall split leans male because
the 897 texts decided only by guessed names all count as male; they come from
about 470 distinct guessed names). Of the 3,598 voiced texts, 987 are
decided by known speaker names (rule 1), 42 by a tie, 897 only by guessed names
(rule 2) and 1,672 (46 %) by the parity (rule 4), because no speaker is known
for them. The recordings made from templates have no speaker either and follow
the parity of the template's key. `extract_texts.py --list-guessed` prints the guessed names
(about 470, mostly rare); fix by an entry in `data/speakers.csv`, re-extract
and regenerate the affected keys.

**At run time the NPC decides.** The rules above fix only the default voice,
and a text is often told by another NPC than the one they found: generic texts
are shared by many NPCs, and hints or rumors name an owner (`James Hint`,
`Grant Valandir`) although every street NPC tells them. The first in-game tests
showed women with male voices for exactly these texts. So every text has a
second recording in the other voice, named `<key>-m.ogg` or `<key>-f.ogg` (a
template recording `t<key>~2.ogg` gets `t<key>~2-m.ogg` / `-f.ogg`). The
module reads the name of the NPC in the dialog (`t.NPC.Name` of
`events.EnterAnyNPC`), looks it up in `Data/Voices/names.tsv` — the whole name
first (`queen catherine`), then its first word (`keri brown` → `keri`) — and
plays the recording of that gender. `names.tsv` (1,427 names) is made by
`extract_texts.py --names` from the same resolver as rules 1 and 2, leaving out
the names that were only guessed. If the NPC has no name or its name is not
listed, the plain `<key>.ogg` plays. The log shows which one was used.

Licences: Kokoro-82M weights Apache-2.0, kokoro-onnx MIT, so the licences of
the tools do not restrict shipping the generated audio (the rights to the
dialog texts themselves are not covered here). espeak-ng (GPL-3, pulled in by
`espeakng-loader`) only converts text to phonemes on the generating machine
and is not part of the voice pack.

Speech text is prepared before synthesis (`prepare_speech`): typographic
characters and dashes become plain punctuation, ALL-CAPS words become words,
and stage directions are dropped (`[Bill bows.]`, `*The woman nods.*`,
`::You receive a telepathic message::`) — they stay in the shown text. A
single starred word is emphasis and is spoken (`With *pleasure*!`).

## The Lua module

- `events.DrawNPCGreeting` only remembers the table `t` it receives; the next
  `Tick` (the game's per-frame update) reads `t.Text`, because later handlers
  (`LocalizationAndQuests.lua` quest greetings, the multiplayer `Evt.lua`) may
  still replace it. Street news comes through the same hook.
- Topic answers and every other message of an open NPC dialog: each `Tick`
  between `EnterAnyNPC` and `ExitNPC`/`ExitAnyNPC` compares `Game.NPCMessage`
  with its last value; a change plays the new text. No engine patch.
- A greeting starts `MawVoices.GreetingDelay` seconds (default 1.0) after it
  appears, because the NPC says its own "hello" first. A topic click, leaving
  the dialog or switching the module off drops a greeting that still waits;
  topic answers start at once. A guard's saying waits as long as a greeting. The wait uses `os.clock()`, which measures wall
  time in the game's Lua runtime (checked with the game's `lua51.dll`).
- The voice follows the NPC's gender (see "At run time the NPC decides").
- A shown text without a recording of its own is matched against the patterns
  of `Data/Voices/templates.tsv` (see "What is voiced", Templates); the match
  yields the key `t<key>~<value>...` of the recording. The patterns are Lua
  patterns over the normalized text, tried longest first; `tests/lua/templates_test.lua`
  checks every recording against the text the game would show.
- Guards and monsters: `events.SpeakWithMonster` is not an NPC dialog and does
  not set `Game.NPCMessage`. The module takes the monster's group, looks up the
  news number in `NPCGroup.txt` (the same lookup as `GetNPCGroupNews` in
  `NPCNewsTopics.lua`) and plays that `NPCNews` text after the greeting delay (the guard says its own "hello" first), unless a script
  has set `t.Result` (`t` is the table the game passes to the event handler;
  `Result` is the message the game is going to show, and a script may replace it
  with its own text, which the module then speaks instead; an empty string shows
  nothing).
- One own SoLoud instance, created on first use. Volume = (the game's character
  voices slider (second byte of `Game.SoundVolume`, 0–9) + `MawVoices.BoostSteps`,
  default 1) / 9 × `npcVoiceVolume`; level 0 means no decoding at all. The boost
  makes the voice play one slider step louder than the slider says: the recordings
  have a median level of -24 dBFS and decoded peaks up to 0.92 (a sample of 400),
  so at the top (10/9 of full volume) about 1 % of the files touch full scale for
  a moment, by at most 0.2 dB (not audible). `MawVoices.BoostSteps = 0` plays at
  the slider, 2 is two steps louder (at the top slider position that is 11/9 of
  full volume and can clip); no new recordings are needed for any of it.
  The Sound slider (first
  byte) and the music slider (third byte) are not used: the log of the fifth
  in-game test showed the Sound slider standing at 1 while the player moved the
  voices slider (9, 1, 8) and heard the game's voices follow it.
- A dialog is never harmed by this module: the tick work runs in `pcall`, and
  after 20 errors the module switches itself off.
- Console: `MawVoices.Key(text)`, `MawVoices.TemplateKey(text)` (the key of the
  recording for a shown text with filled-in placeholders, or `nil`),
  `MawVoices.Play(text)` (at once, no delay),
  `MawVoices.Stop()`, `MawVoices.GenderOf(name)`, `MawVoices.Enabled = false`,
  `MawVoices.Log = false`, `MawVoices.GreetingDelay = 0`.
- For developers: it is a plain `General/` script, not a MawCore module, so it
  can be removed by deleting one file. (MawCore is MAW's own set of core modules
  in `Scripts/Modules/MawCore/`, loaded by `MawCoreMain.lua`.) Moving the
  module into MawCore would put the SoLoud binding into `Engine.lua`: by the
  rule in the header of `MawCoreMain.lua`, only `Engine.lua` may use `mem.*`,
  the direct memory access to the game.

## How topic texts reach the screen (why the module polls `Game.NPCMessage`)

"Polling" means the module looks at `Game.NPCMessage` again on every `Tick`
instead of being told when it changes. File references below (line numbers as
in the MMMerge scripts of the 2026-10-29 test install):

1. Clicking a topic runs the global event with the topic's number (the number
   of a topic in `NPCTopic.txt` is the id of the event in `Global.EVT` that
   runs when it is clicked); MMMerge raises
   `events.ClickNPCTopic(i)` just before it
   (`Scripts/Structs/After/RemoveNPCTablesLimits.lua:290/303`).
2. The compiled event executes `SetMessage` (event command `0x1E` of the evt
   event scripts;
   `Scripts/Core/evt.lua:951`). `Global.EVT` holds 1,943 of them for 1,529
   distinct ids; id 0 means "no text", the other 1,528 are NPCText entries
   with a text. Of the 2,690 NPCText rows that have a text, only these 1,528
   are shown by an event of `Global.EVT`; the rest may be triggered by Lua
   scripts or not at all. Decision E2 in `docs/projekt/ENTSCHEIDUNGEN.md` (the
   decision log is in German): all NPCText rows are voiced anyway, including
   those no event of `Global.EVT` reaches, because Lua scripts may show them
   (2,690 rows with a text; identical texts are merged, which gives the 2,468
   distinct texts of the table under "What is voiced").
3. The engine keeps the text to display in `Game.NPCMessage` (`[0xFFD458]`,
   `Scripts/Structs/00 structs.lua:271`). Lua `Message()`
   (`Scripts/Structs/After/Functions.lua:86`) ends in the same place.
4. Hooking the evt interpreter (`0x443895`) would see every `SetMessage`, but
   the multiplayer module already installs its own hook at that address while
   the multiplayer module is active, and a second hook there would conflict with it.
   Polling `Game.NPCMessage` needs no patch and covers compiled events, Lua
   `Message()` and `Question()`.

## Tests

```bash
python -I Tools/Voice/tests/test_extract.py     # parser, keys, genders, Lua scanner, completeness against the install
python -I Tools/Voice/tests/test_generate.py    # speech preparation, selection, sharding, the voice pack
python -I Tools/Voice/tests/test_templates.py   # spoken versions of the templates, values, patterns
python -I Tools/Voice/tests/run_lua_tests.py    # Lua keys == Python keys; template patterns find every recording; dialog flow with a fake SoLoud, in the game's LuaJIT
```

The game's `lua51.dll` is LuaJIT 2.1.0-beta3 (`run_lua_tests.py` prints this).
The real-data tests read the install named by the environment variable
`MM8_DIR` (default: `C:\Users\slovi\Desktop\Might and Magic 8 MAW Mod 4.5`, the
author's test install; set the variable to your own install) and skip when it
is missing; a skipped test checked nothing. In PowerShell,
`$env:MM8_DIR = "<your install folder>"` sets the variable for the current
window. Start `run_lua_tests.py` as shown above: it calls the 32-bit
PowerShell (`C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe`) itself,
because the game's `lua51.dll` is 32-bit and cannot be loaded by 64-bit Python.
`soloud_check.ps1` has to be started in that 32-bit PowerShell by hand, with
`-ExecutionPolicy Bypass` for the single call if scripts are blocked:

```powershell
C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools\Voice\tests\soloud_check.ps1 -Dll "<game>\ExeMods\soloud_x86.dll" -Dir "<game>\Data\Voices\NPC"
```

## Known limits

- Tried in game on 2026-10-30. First run (default set only): it works;
  findings: the greeting overlapped the NPC's own "hello", and women often had
  the male voice. Second run (greeting delay and second recordings for the
  2,598 texts without a speaker known by name, i.e. not decided by rule 1 of
  "Voices and gender": 3,585 texts at that time minus 987; today 2,611 of
  3,598): the delay was right; hint texts told by
  women among the roaming street NPCs of the start town still had the male
  voice, because they had no second recording. Since then every text has one.
  Third run: the women's voices were right; two findings: a guard did not
  speak, and the sales pitch of an NPC that can be hired ("Join") had no voice. The
  first led to the guard connection and to the 13 rows of `Global.txt`; the
  second to the voicing of texts with placeholders (the sales pitch carries
  the hireling's percent).
  Fourth run: everything fitted except the guards, which spoke too early, in the
  middle of their own "hello" sound. They now wait as long as a greeting. This
  change is covered by tests only, which use a simulated SoLoud;
  `soloud_check.ps1` only loads the files. It has not been heard in game yet.
  The same run found that the generated voice did not follow the volume
  setting: it stayed as loud as the game's voices at slider position 1-2 of 10.
  The cause: the module followed the Sound slider (stuck at 1 in that game, so
  always 1/9), while the player moves the character voices slider. The module now
  follows the voices slider; the log shows both sliders (`vol=`), in the game
  console `print(MawVoices.VolumeInfo())` shows them too, and `MawVoices.Volume = 1.5`
  makes the voice louder. Fifth run: the volume follows the slider. The player
  asked for a slightly higher basic volume; the module now plays one slider step
  louder (`MawVoices.BoostSteps = 1`), a play-time gain, so the recordings stay as
  they are. The player confirmed in game that the volume fits.
- Nobody has listened to all 27 hours. The quality gate is objective (decodes,
  plausible speed, level, no clipping, no dropouts); wrong stress or a
  mispronounced invented name is possible.
- The gender of the NPC decides, but only if its name is in `names.tsv`. For
  NPCs with rare or invented names (about 470 are only guessed) the plain
  `<key>.ogg` plays. Its voice was fixed when the text was generated: the
  gender of the known speaker, male for guessed names, a parity split for
  texts without any speaker.
- Texts with placeholders: names are not spoken, so the sentence is shorter than
  the shown one ("Back again?" for "Back again, Tracie?"). 78 texts stay
  silent (see "What is voiced"). A combination of values without a recording
  (the reputation texts have up to 50 of them; only some can occur in the game)
  stays silent too; the log then shows `missing` with the `t<key>~...` key.
- One text (key `b564972a` in `texts.csv`, Verdant's Telelocator ritual) has a
  typo in the source data: a closing `”` (U+201D) stands where `*` belongs.
  As a result, the spoken part is mistaken for a stage direction and dropped,
  and the stage direction is read instead: the recording says "Verdant opens
  her eyes with a gasp. Aw, crap." and misses the Telelocator's lines ("Targets
  found. Realms: Attuned. ...").
- Guard and monster sayings (`SpeakWithMonster`) are connected since the third
  in-game test, which found them silent. The fourth test found them working but
  too early; the wait before they speak is new and has not been heard in game
  yet. A monster whose group has no news number, or a script that sets its own
  message, stays silent.
- Voice quality is Kokoro's: clear, a little uniform, no race-specific timbres
  for lizardmen, minotaurs or dragons. Pronunciation of invented names follows
  the English rules of espeak-ng.
