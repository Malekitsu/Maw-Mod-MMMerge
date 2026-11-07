#!/usr/bin/env python3
"""
Turn the rows of extract_texts.py's CSV into audio files named <key>.ogg, which
Scripts/General/zzzMaw_NPCVoices.lua plays in game.

Two voices only: one male, one female (the CSV's `gender` column picks).
TTS: Kokoro-82M (Apache-2.0) through kokoro-onnx (MIT), fully local, CPU.
Model files: kokoro-v1.0.onnx and voices-v1.0.bin from
https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0

    python generate_voices.py texts.csv --out Data/Voices/NPC --model kokoro-v1.0.onnx --voices voices-v1.0.bin
    python generate_voices.py texts.csv --out ... --shard 0/4 ...    # one of 4 parallel processes
    python generate_voices.py texts.csv --out ... --dry-run          # plan only
    python generate_voices.py texts.csv --out ... --verify           # every selected row has a file?
    python generate_voices.py texts.csv --out ... --alt ...          # the other voice of every text, <key>-m/-f.ogg

Existing files are skipped, so an interrupted run is simply started again.
Rows with a run-time placeholder (%01, %s, ...) are skipped: the text the
game shows differs from the table text (see --templates).
Needs ffmpeg on PATH to write Ogg Vorbis; without it .wav files are written
(the Lua side accepts both).
"""

import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
import time
import wave
from pathlib import Path

DEFAULT_VOICE = {"m": "am_michael", "f": "af_heart"}
SAMPLE_RATE = 24000
TARGET_RMS = 0.09      # about -21 dBFS: both voices end up equally loud
PEAK_LIMIT = 0.89      # about -1 dBFS

# --------------------------------------------------------------------------
# Text preparation. The CSV text stays as the game shows it; only what is
# handed to the synthesizer is cleaned.

_REPLACE = [
    ("’", "'"), ("‘", "'"), ("“", '"'), ("”", '"'),
    ("—", ", "), ("–", ", "), ("--", ", "),
    ("…", "..."), (" ", " "),
]
# a single starred word is emphasis and stays spoken: With *pleasure*!
_EMPHASIS = re.compile(r"\*([\w'-]+)\*")
# stage directions are shown but not spoken: [Bill bows.]  *The woman nods.*  ::You receive a message::
_STAGE = re.compile(r"\[[^\]]*\]|\*[^*]*\*|::[^:]*::")
_CAPS = re.compile(r"\b[A-Z]{3,}\b")
_UNDERSCORES = re.compile(r"_{2,}")
_SPACES = re.compile(r"\s+")


def prepare_speech(text: str) -> str:
    for a, b in _REPLACE:
        text = text.replace(a, b)
    text = _EMPHASIS.sub(r"\1", text)
    text = _STAGE.sub(" ", text)
    text = text.replace("#", ", ")
    for ch in "[]*":
        text = text.replace(ch, " ")
    text = _UNDERSCORES.sub(" ", text)
    text = _CAPS.sub(lambda m: m.group(0).capitalize(), text)  # "HALT!" is a word, not letters
    text = text.replace("<", " ").replace(">", " ")
    text = re.sub(r"\s+([,.!?;:])", r"\1", text)
    text = re.sub(r",\s*,", ",", text)
    return _SPACES.sub(" ", text).strip(" ,")


def voice_for(row, voices) -> str:
    return voices.get(row["gender"], voices["m"])


def alt_gender(row) -> str:
    """The other voice: 'm' for a female default, 'f' for a male one."""
    return "m" if row["gender"] == "f" else "f"


def stem(row, alt: bool) -> str:
    """File name without extension: <key>, or <key>-m / <key>-f for the other voice (--alt)."""
    return f"{row['key']}-{alt_gender(row)}" if alt else row["key"]


# --------------------------------------------------------------------------

def select_rows(rows, args):
    wanted = set(args.keys.read_text(encoding="utf-8").split()) if getattr(args, "keys", None) else None
    out = []
    for row in rows:
        if wanted is not None and row["key"] not in wanted:
            continue
        if args.kind != "all" and row["kind"] not in args.kind.split(","):
            continue
        if row["template"] == "1" and not args.templates:
            continue
        out.append(row)
    # longest first, then by key: stable ranks, so shards split the work evenly
    out.sort(key=lambda r: (-len(r["text"]), r["key"]))
    if args.shard:
        i, n = args.shard
        out = [r for k, r in enumerate(out) if k % n == i]
    if args.limit:
        out = out[:args.limit]
    return out


def existing(out: Path, key: str) -> bool:
    """A finished, non-empty file. Files are written under a .part name first, so a killed run leaves no half file."""
    for ext in (".ogg", ".wav"):
        p = out / f"{key}{ext}"
        if p.exists() and p.stat().st_size > 0:
            return True
    return False


def level(samples):
    """Same RMS for every file, peaks kept below the limit."""
    import numpy as np
    x = np.asarray(samples, dtype="float32")
    active = x[np.abs(x) > 0.02]
    rms = float(np.sqrt(np.mean(active ** 2))) if active.size else 0.0
    if rms <= 0:
        return x
    gain = TARGET_RMS / rms
    peak = float(np.max(np.abs(x)))
    if peak * gain > PEAK_LIMIT:
        gain = PEAK_LIMIT / peak
    return x * gain


def write_ogg(pcm: bytes, path: Path, ffmpeg: str, quality: int) -> bool:
    part = path.with_name(path.name + ".part")
    cmd = [ffmpeg, "-v", "error", "-y", "-f", "s16le", "-ar", str(SAMPLE_RATE), "-ac", "1", "-i", "-",
           "-c:a", "libvorbis", "-q:a", str(quality), "-f", "ogg", str(part)]
    r = subprocess.run(cmd, input=pcm, capture_output=True)
    if r.returncode == 0 and part.exists() and part.stat().st_size > 0:
        os.replace(part, path)
        return True
    part.unlink(missing_ok=True)
    return False


def write_wav(pcm: bytes, path: Path):
    part = path.with_name(path.name + ".part")
    with wave.open(str(part), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(pcm)
    os.replace(part, path)


def parse_shard(s: str):
    i, n = s.split("/")
    i, n = int(i), int(n)
    if not 0 <= i < n:
        raise argparse.ArgumentTypeError("--shard needs I/N with 0 <= I < N")
    return i, n


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("csv", type=Path, help="output of extract_texts.py")
    ap.add_argument("--out", required=True, type=Path, help="usually <MM8>/Data/Voices/NPC")
    ap.add_argument("--model", type=Path, help="kokoro-v1.0.onnx")
    ap.add_argument("--voices", type=Path, help="voices-v1.0.bin")
    ap.add_argument("--voice-m", default=DEFAULT_VOICE["m"])
    ap.add_argument("--voice-f", default=DEFAULT_VOICE["f"])
    ap.add_argument("--kind", default="all", help="all, or comma list of greeting,topic,news")
    ap.add_argument("--templates", action="store_true", help="also rows with run-time placeholders")
    ap.add_argument("--keys", type=Path, help="only the keys listed in this file (qa_voices.py --bad-keys)")
    ap.add_argument("--limit", type=int, default=0, help="stop after this many rows (0 = all)")
    ap.add_argument("--shard", type=parse_shard, help="I/N: process only every N-th row, starting at I")
    ap.add_argument("--threads", type=int, default=0, help="ONNX threads for this process (0 = library default)")
    ap.add_argument("--speed", type=float, default=1.0)
    ap.add_argument("--quality", type=int, default=4, help="Ogg Vorbis quality, 0-10")
    ap.add_argument("--manifest-dir", type=Path, help="where per-shard manifests go (default: <out>/../manifest)")
    ap.add_argument("--alt", action="store_true",
                    help="record the other voice (<key>-m / <key>-f) of every selected text; "
                         "the Lua module picks the recording of the gender of the NPC in the dialog")
    ap.add_argument("--force", action="store_true", help="regenerate files that already exist")
    ap.add_argument("--dry-run", action="store_true", help="print the plan, synthesize nothing")
    ap.add_argument("--verify", action="store_true", help="check that every selected row has a file")
    args = ap.parse_args(argv)

    voices = {"m": args.voice_m, "f": args.voice_f}

    def voice_of(row):
        return voices[alt_gender(row)] if args.alt else voice_for(row, voices)

    with args.csv.open(encoding="utf-8", newline="") as f:
        rows = select_rows(list(csv.DictReader(f)), args)

    if args.verify:
        rows = [r for r in rows if prepare_speech(r["text"])]  # a text of stage directions only has nothing to speak
        missing = [r for r in rows if not existing(args.out, stem(r, args.alt))]
        print(f"{len(rows)} rows selected, {len(rows) - len(missing)} with a file, {len(missing)} missing")
        for r in missing[:20]:
            print("  missing", r["key"], r["source"], r["text"][:60])
        return 1 if missing else 0

    if args.dry_run:
        by_voice = {}
        for r in rows:
            by_voice.setdefault(voice_of(r), []).append(r)
        for v, rs in by_voice.items():
            print(f"{v}: {len(rs)} rows, {sum(len(r['text']) for r in rs)} characters")
        for r in rows[:10]:
            print(f"  {stem(r, args.alt)}  {voice_of(r):11} {prepare_speech(r['text'])[:80]}")
        return 0

    if not (args.model and args.voices):
        ap.error("--model and --voices are required unless --dry-run/--verify")
    import numpy as np
    import onnxruntime as rt
    from kokoro_onnx import Kokoro

    opts = rt.SessionOptions()
    if args.threads:
        opts.intra_op_num_threads = args.threads
        opts.inter_op_num_threads = 1
    session = rt.InferenceSession(str(args.model), sess_options=opts, providers=["CPUExecutionProvider"])
    tts = Kokoro.from_session(session, str(args.voices))
    ffmpeg = shutil.which("ffmpeg")
    args.out.mkdir(parents=True, exist_ok=True)
    for stale in args.out.glob("*.part"):  # left behind by a killed run (may belong to a running shard: only old ones)
        if time.time() - stale.stat().st_mtime > 600:
            stale.unlink(missing_ok=True)
    manifest_dir = args.manifest_dir or args.out.parent / "manifest"
    manifest_dir.mkdir(parents=True, exist_ok=True)
    tag = f"{args.shard[0]}of{args.shard[1]}" if args.shard else "all"
    if args.alt:
        tag = "alt-" + tag
    manifest = manifest_dir / f"manifest-{tag}.csv"
    new_manifest = not manifest.exists()

    done = failed = 0
    audio_seconds = 0.0
    started = time.time()
    with manifest.open("a", encoding="utf-8", newline="") as mf:
        mw = csv.writer(mf)
        if new_manifest:
            mw.writerow(["key", "file", "voice", "audio_s", "chars", "gen_s"])
        for n, row in enumerate(rows, 1):
            key = stem(row, args.alt)
            if not args.force and existing(args.out, key):
                continue
            voice = voice_of(row)
            speech = prepare_speech(row["text"])
            if not speech:
                continue
            t0 = time.time()
            try:
                samples, rate = tts.create(speech, voice=voice, speed=args.speed, lang="en-us")
                if rate != SAMPLE_RATE:
                    raise ValueError(f"unexpected sample rate {rate}")
                pcm = (np.clip(level(samples), -1.0, 1.0) * 32767).astype("<i2").tobytes()
                target = args.out / f"{key}.ogg"
                if ffmpeg and write_ogg(pcm, target, ffmpeg, args.quality):
                    final = target
                else:
                    final = args.out / f"{key}.wav"
                    write_wav(pcm, final)
            except Exception as exc:  # one bad text must not stop a multi-hour run
                failed += 1
                print(f"FAILED {key} {row['source']}: {exc!r}", file=sys.stderr)
                continue
            length = len(samples) / rate
            done += 1
            audio_seconds += length
            mw.writerow([key, final.name, voice, f"{length:.2f}", len(row["text"]), f"{time.time() - t0:.2f}"])
            mf.flush()
            if done % 25 == 0:
                wall = time.time() - started
                print(f"[{tag}] {n}/{len(rows)} done={done} failed={failed} audio={audio_seconds / 60:.1f} min "
                      f"wall={wall / 60:.1f} min rtf={wall / max(audio_seconds, 1):.2f}", file=sys.stderr, flush=True)
    wall = time.time() - started
    print(f"[{tag}] finished: {done} files, {failed} failed, {audio_seconds / 60:.1f} min audio in {wall / 60:.1f} min",
          file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
