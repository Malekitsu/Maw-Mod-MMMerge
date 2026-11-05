#!/usr/bin/env python3
"""
M5 of the German edition: record the German dialog texts with ElevenLabs (cloud, API).

    python -I generate_voices_el.py --work work/ --out work/audio_de --paket mm7 --limit 50 [--spread]

Reads  work/prioritaet.csv (prioritize.py) and work/texts_de.csv, in the order of the packages
       mm7, mm7-news, maw, news, mm8, mm6.
Writes <out>/<key_de>.ogg, the file name the language module looks for (CRC32 of the German text), plus
       work/el_log.csv with one line per request: key, paket, chars, credits, status.

The API key comes from the environment variable ELEVENLABS_API_KEY (user level on Windows; never stored in a file).
A run stops by itself when the credits left would fall below --reserve. Finished files are skipped, so the run can
be repeated or continued with the next package. Texts with run-time placeholders (%01 ...) are not recorded.
The text handed to the voice is cleaned like in the English pipeline (stage directions in [ ] * * :: :: are not spoken).
"""

import argparse
import concurrent.futures
import csv
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import generate_voices as gv  # noqa: E402  (prepare_speech, level, write_ogg of the English pipeline)

API = "https://api.elevenlabs.io"
VOICES = {"m": "87AwpS6yC86wa2WglbsK",   # Michael Danisch - Deep and Soulful
          "f": "XtxuRNfvtd45OyWcp5jr"}   # Sarah - Storyteller
ORDER = ["mm7", "mm7-news", "maw", "news", "mm8", "mm6"]
CHAR_MULTIPLIER = {"eleven_v4_turbo": 0.5, "eleven_turbo_v2_5": 0.5, "eleven_flash_v2_5": 0.5, "eleven_v4": 1.0}


def api_key() -> str:
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key and sys.platform == "win32":
        import winreg
        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as h:
                key = winreg.QueryValueEx(h, "ELEVENLABS_API_KEY")[0]
        except OSError:
            key = None
    if not key:
        sys.exit("ELEVENLABS_API_KEY is not set")
    return key


def request(path: str, key: str, body: dict = None, timeout: int = 120):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(API + path, data=data, headers={"xi-api-key": key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read(), dict(r.headers)


def credits_left(key: str):
    raw, _ = request("/v1/user/subscription", key)
    sub = json.loads(raw)
    return sub["character_limit"] - sub["character_count"], sub["character_count"]


def synthesize(key: str, voice: str, text: str, model: str, retries: int = 4):
    """PCM 24 kHz mono and the credits the request cost."""
    body = {"text": text, "model_id": model, "language_code": "de"}
    for attempt in range(retries):
        try:
            pcm, headers = request(f"/v1/text-to-speech/{voice}?output_format=pcm_24000", key, body)
            cost = int(headers.get("character-cost") or headers.get("Character-Cost") or 0)
            return pcm, cost
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:200]
            if e.code in (429, 500, 502, 503) and attempt < retries - 1:
                time.sleep(2 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {e.code}: {detail}")
        except (urllib.error.URLError, TimeoutError) as e:
            if attempt < retries - 1:
                time.sleep(2 * (attempt + 1))
                continue
            raise RuntimeError(f"network: {e}")


def to_ogg(pcm: bytes, path: Path, ffmpeg: str, quality: int) -> bool:
    import numpy as np
    x = np.frombuffer(pcm, dtype="<i2").astype("float32") / 32768
    y = gv.level(x)
    out = (np.clip(y, -1, 1) * 32767).astype("<i2").tobytes()
    return gv.write_ogg(out, path, ffmpeg, quality)


def select(rows, texts, pakete, limit, spread, out: Path, suffix: str = ""):
    todo = []
    for p in pakete:
        group = [r for r in rows if r["paket"] == p and r["template"] != "1"]
        if spread and limit:
            step = max(1, len(group) // limit)
            group = group[::step]
        todo += group
    todo = [r for r in todo if not (out / (f"{r['key_de']}-{r['gender']}.ogg" if suffix else f"{r['key_de']}.ogg")).exists()]
    return todo[:limit] if limit else todo


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--paket", default="mm7", help="comma separated: " + ", ".join(ORDER))
    ap.add_argument("--limit", type=int, default=0, help="at most this many texts (0 = all of the packages)")
    ap.add_argument("--spread", action="store_true", help="with --limit: spread the texts evenly over the package")
    ap.add_argument("--variants", action="store_true",
                    help="record work/gegengeschlecht.csv (mixed_gender.py): the second voice of texts that men and "
                         "women speak, as <key_de>-<m|f>.ogg")
    ap.add_argument("--templates", action="store_true",
                    help="record work/templates_de.csv (templates_de.py): the texts with placeholders, one file per value")
    ap.add_argument("--model", default="eleven_v4_turbo")
    ap.add_argument("--reserve", type=int, default=2000, help="stop when fewer credits would be left")
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--ffmpeg", default="ffmpeg")
    ap.add_argument("--quality", type=int, default=4, help="Vorbis quality")
    ap.add_argument("--dry-run", action="store_true", help="count texts and estimate the cost, call nothing")
    args = ap.parse_args(argv)

    source = "templates_de.csv" if args.templates else "gegengeschlecht.csv" if args.variants else "prioritaet.csv"
    rows = list(csv.DictReader((args.work / source).open(encoding="utf-8")))
    texts = {r["key_en"]: r["text_de"] for r in csv.DictReader((args.work / "texts_de.csv").open(encoding="utf-8"))}
    if args.templates:  # the spoken text is in the file, the file name is the key itself
        for r in rows:
            r["key_en"], r["key_de"], r["template"] = r["key"], r["key"], "0"
            texts[r["key"]] = r["text"]
    args.out.mkdir(parents=True, exist_ok=True)
    todo = select(rows, texts, args.paket.split(","), args.limit, args.spread, args.out, "-" if args.variants else "")
    if args.variants:
        for r in todo:
            r["key_de"] += "-" + r["gender"]
    jobs = []
    for r in todo:
        speech = gv.prepare_speech(texts[r["key_en"]])
        if speech:
            jobs.append((r, speech))
    mult = CHAR_MULTIPLIER.get(args.model, 1.0)
    estimate = int(sum(len(s) for _, s in jobs) * mult)
    print(f"{len(jobs)} texts, {sum(len(s) for _, s in jobs)} characters, estimated {estimate} credits ({args.model})")
    if args.dry_run or not jobs:
        return 0

    key = api_key()
    left, used0 = credits_left(key)
    print(f"credits left: {left}")
    if estimate > left - args.reserve:
        print(f"note: the estimate exceeds the credits left (reserve {args.reserve}); the run stops in time")

    log_path = args.work / "el_log.csv"
    new_log = not log_path.exists()
    spent = 0
    done = failed = 0
    stop = False
    with log_path.open("a", newline="", encoding="utf-8") as lf:
        log = csv.writer(lf)
        if new_log:
            log.writerow(["key_de", "paket", "chars", "credits", "status"])

        def work(job):
            r, speech = job
            pcm, cost = synthesize(key, VOICES.get(r["gender"], VOICES["m"]), speech, args.model)
            ok = to_ogg(pcm, args.out / f"{r['key_de']}.ogg", args.ffmpeg, args.quality)
            return r, speech, cost, ok

        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            pending = iter(jobs)
            running = set()
            while True:
                while not stop and len(running) < args.workers:
                    job = next(pending, None)
                    if job is None:
                        break
                    if (spent + len(job[1]) * mult) > left - args.reserve:
                        stop = True
                        break
                    running.add(pool.submit(work, job))
                if not running:
                    break
                finished, running = concurrent.futures.wait(running, return_when=concurrent.futures.FIRST_COMPLETED)
                for f in finished:
                    try:
                        r, speech, cost, ok = f.result()
                    except RuntimeError as e:
                        failed += 1
                        print("failed:", e)
                        continue
                    spent += cost
                    done += ok
                    failed += not ok
                    log.writerow([r["key_de"], r["paket"], len(speech), cost, "ok" if ok else "ffmpeg"])
                    lf.flush()
    left_after, used1 = credits_left(key)
    print(f"done {done}, failed {failed}, credits spent {spent} (account: {used1 - used0}), left {left_after}")
    if stop:
        print("stopped early: credit reserve reached")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
