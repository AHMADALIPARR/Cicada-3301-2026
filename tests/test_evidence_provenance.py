import hashlib
import json
import pytest

def test_frozen_artifacts_integrity():
    with open("evidence/manifest.json", "r", encoding="utf-8") as f:
        manifest = json.load(f)

    for art in manifest["frozen_artifacts"]:
        raw_path = art["raw_file"]
        with open(raw_path, "rb") as f:
            data = f.read()
        digest = hashlib.sha256(data).hexdigest()
        assert digest == art["sha256"], f"Integrity check failed for {art['id']}: expected {art['sha256']}, got {digest}"

def test_provenance_index_integrity():
    with open("evidence/provenance_index.json", "r", encoding="utf-8") as f:
        index = json.load(f)
    assert len(index["nodes"]) > 0
    assert len(index["edges"]) > 0
    assert "PAGE_00_WELCOME" in index["fingerprint_index"].values()
