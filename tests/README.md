# Cicada 3301 Liber Primus / HARN Cryptanalysis Verification Suite

This test suite executes the end-to-end verification and cryptanalysis checks:

1. `test_invariants.py`: Exhaustive base-29 involution $O(O(t)) = t$, affine round-trip reversibility, and sacred prime properties.
2. `test_harn_engine.py`: SWI-Prolog Horn-clause gates (P57-001 through P57-010, P58-001 through P58-010) including self-assertion rejection.
3. `test_evidence_provenance.py`: Frozen artifact checksum verification against `evidence/manifest.json`, preventing fabrication or tampering.
4. `test_known_solutions.py`: Reconstruction and transliteration verification of previously solved Liber Primus pages (Page 0 Welcome, Page 56).
5. `test_candidate_acceptance.py`: Strict cryptographic acceptance rules (preimage matching, GPG signature checking, and false-path ledger compliance).
