#!/usr/bin/env python3
"""
build_quran_asset.py - generate the bundled offline Qur'an text asset.

Fetches the complete Uthmani text and the Saheeh International translation
from alquran.cloud (two calls, not 114), and writes a compact JSON to
assets/quran/quran.json.

It is written UNCOMPRESSED on purpose. Flutter assets are deflated inside the
APK/AAB already, so gzipping here would not shrink the download, and shipping
plain JSON avoids a runtime gzip decode and keeps the web build working
(dart:io is unavailable there). It is parsed off the UI isolate; see
quran_offline_text.dart.

Run from the project root:
    python tool/build_quran_asset.py

The output is committed to the repo. This script only needs re-running if the
edition changes, which it does not - the text is fixed.

Format (deliberately terse; every byte ships to every user):
    {"v": 1,
     "e": {"ar": "quran-uthmani", "en": "en.sahih"},
     "s": [ [ ["<arabic>", "<translation>"], ... ],   # surah 1, verse 1..n
            ...                                        # 114 surahs
          ]}

Verse numbers are the array index + 1. The mushaf-wide global number is a
running count, so neither is stored.
"""

import json
import os
import sys
import urllib.request

API = "https://api.alquran.cloud/v1/quran/{}"
AR_EDITION = "quran-uthmani"
EN_EDITION = "en.sahih"
OUT = os.path.join("assets", "quran", "quran.json")


def fetch(edition):
    url = API.format(edition)
    print(f"fetching {url} ...", flush=True)
    req = urllib.request.Request(url, headers={"User-Agent": "ehsan-pathways-build/1.0"})
    with urllib.request.urlopen(req, timeout=180) as r:
        payload = json.loads(r.read().decode("utf-8"))
    if payload.get("code") != 200:
        raise SystemExit(f"API returned code {payload.get('code')} for {edition}")
    surahs = payload["data"]["surahs"]
    if len(surahs) != 114:
        raise SystemExit(f"expected 114 surahs, got {len(surahs)}")
    return surahs


def main():
    ar = fetch(AR_EDITION)
    en = fetch(EN_EDITION)

    out_surahs = []
    total_verses = 0
    for i in range(114):
        a_ayahs = ar[i]["ayahs"]
        e_ayahs = en[i]["ayahs"]
        if len(a_ayahs) != len(e_ayahs):
            raise SystemExit(
                f"surah {i + 1}: {len(a_ayahs)} arabic vs {len(e_ayahs)} english"
            )
        verses = []
        for j in range(len(a_ayahs)):
            verses.append([a_ayahs[j]["text"], e_ayahs[j]["text"]])
        out_surahs.append(verses)
        total_verses += len(verses)

    if total_verses != 6236:
        raise SystemExit(f"expected 6236 verses, got {total_verses}")

    doc = {"v": 1, "e": {"ar": AR_EDITION, "en": EN_EDITION}, "s": out_surahs}
    raw = json.dumps(doc, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as f:
        f.write(raw)

    print(f"\n114 surahs, {total_verses} verses")
    print(f"{len(raw) / 1_048_576:.2f} MB  -> {OUT}")
    print("(deflated to roughly 0.6 MB inside the APK/AAB by asset packaging)")
    print("\nThe basmalah is left exactly as the API returns it; "
          "stripLeadingBasmalah() in quran_text.dart handles it at read time, "
          "as it already does for the network path.")


if __name__ == "__main__":
    sys.exit(main())
