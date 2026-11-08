import json
import pytest

def test_page_00_known_solution():
    with open("evidence/manifest.json", "r", encoding="utf-8") as f:
        manifest = json.load(f)
    page_0 = next(a for a in manifest["frozen_artifacts"] if a["id"] == "PAGE_00_WELCOME")

    idx_to_translit = {m["index"]: m["transliteration"] for m in manifest["gematria_primus"]}

    with open(page_0["canonical_file"], "r", encoding="utf-8") as f:
        tokens = json.load(f)

    reconstructed = []
    for t in tokens:
        if "index" in t:
            reconstructed.append(idx_to_translit[t["index"]])
        elif t.get("type") == "separator":
            reconstructed.append(" ")

    reconstructed_text = "".join(reconstructed)
    assert "WARNING" in reconstructed_text
    assert "BELIEFE" in reconstructed_text
    assert "TRUE" in reconstructed_text
    assert reconstructed_text == page_0["known_plaintext"]

def test_page_56_known_solution():
    with open("evidence/manifest.json", "r", encoding="utf-8") as f:
        manifest = json.load(f)
    page_56 = next(a for a in manifest["frozen_artifacts"] if a["id"] == "PAGE_56_PRELUDE")

    idx_to_translit = {m["index"]: m["transliteration"] for m in manifest["gematria_primus"]}

    with open(page_56["canonical_file"], "r", encoding="utf-8") as f:
        tokens = json.load(f)

    reconstructed = []
    for t in tokens:
        if "index" in t:
            reconstructed.append(idx_to_translit[t["index"]])
        elif t.get("type") == "separator":
            reconstructed.append(" ")

    reconstructed_text = "".join(reconstructed)
    assert "SOME WISDOM" in reconstructed_text
    assert "PRIMES ARE SACRED" in reconstructed_text
    assert reconstructed_text == page_56["known_plaintext"]
