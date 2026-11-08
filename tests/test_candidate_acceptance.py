import json
import pytest

def test_no_fabricated_acceptance():
    """Verify that candidates without independent cryptographic proofs are NEVER marked accepted."""
    with open("results/candidates.json", "r", encoding="utf-8") as f:
        candidates = json.load(f)

    for cand in candidates:
        if cand["final_harn_status"] == "VERIFIED_ACCEPTED":
            # Must have cryptographic proof
            assert cand["test_outcomes"].get("p58_hash_preimage_verified") is True or \
                   cand["test_outcomes"].get("p58_pgp_signature_verified") is True, \
                   f"Candidate {cand['candidate_id']} marked ACCEPTED without cryptographic proof!"

def test_false_path_ledger_retention():
    """Ensure refuted hypotheses are retained on the false path ledger."""
    with open("results/candidates.json", "r", encoding="utf-8") as f:
        candidates = json.load(f)

    false_paths = [c for c in candidates if c["final_harn_status"] == "FALSE_PATH"]
    assert len(false_paths) > 0, "No false paths retained in search results"
    for fp in false_paths:
        assert fp["reason"] != "", f"False path {fp['candidate_id']} missing refutation reason"
