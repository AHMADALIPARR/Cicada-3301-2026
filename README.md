# Cicada 3301 — Liber Primus Cryptanalysis & HARN Verification

An automated, deterministic cryptanalysis and formal evidence verification system for the unsolved pages of Cicada 3301's *Liber Primus*.

```
   ᚠ  ᚢ  ᚦ  ᚩ  ᚱ  ᚳ  ᚷ  ᚹ  ᚻ  ᚾ  ᛁ  ᛄ  ᛇ  ᛈ  ᛉ  ᛋ  ᛏ  ᛒ  ᛖ  ᛗ  ᛚ  ᛝ  ᛟ  ᛞ  ᚪ  ᚫ  ᚣ  ᛡ  ᛠ
  [0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28]
  (2  3  5  7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 101 103 107 109)
```

---

## The Pilgrim’s Shadow: Manuscript Plates & Frozen Artifacts

> *"A warning: believe nothing from this book except what you know to be true."*
> *"Some wisdom: the primes are sacred; the totient function is sacred."*

Each plate in the manuscript exists simultaneously as raw visual illumination and immutable cryptographic data:

| Plate | Pinpointed Location | Description | SHA-256 Digest | Status |
|---|---|---|---|---|
| **Page 00** | `evidence/raw/page_00_runes.txt` | Introductory Inscription & Warning | `eedc397cc1b5248e6982567a62b6b39deaa0ddbd2ce36d20d40f38665efcb74f` | **SOLVED** |
| **Page 56** | `evidence/raw/page_56_runes.txt` | Sacred Primes & Totient Inscription | `f6e5bf94b0ce17e52ec6865146ba42a172247d8376a99b6b9f71f9edb94c8661` | **SOLVED** |
| **Page 57** | `evidence/raw/page_57_runes.txt` | Unsolved Manuscript Plate (P57 Gate) | `a69ab0fbc4183b97db1ecac72dc8cd8f895e1daa528f38a266fee603f6aa9fd2` | **UNSOLVED** |
| **Page 58** | `evidence/raw/page_58_runes.txt` | Unsolved Manuscript Plate (P58 Gate) | `d7e02f37f3337e31751b1dfbf7c1ff4db68d5a702818a397535c1e572688f95d` | **UNSOLVED** |
| **3301 PGP** | `evidence/raw/cicada_3301.asc` | Authentic Key ID `7A35090F` (4096-bit RSA) | `7A35090F12C1AC17C463C70E8A7104A273BA4EB8` | **IMMUTABLE** |

The manuscript plates are tokenized strictly through `evidence/canonical/`, binding each rune to its Gematria Primus prime coordinate and index over the modular finite field $\mathbb{Z}_{29}$.

---

## Architectural Stack

1. **Logic Engine**: SWI-Prolog Horn-clause engine evaluating P57 and P58 gates (`prolog/`, `harn/`).
2. **Formal Verification & Invariants**:
   - Curry functional logic modules proving base-29 involution, reversibility, and signature obligations (`curry/`).
   - Agda constructive type theory specification formalizing modular invariants and involution theorems over $\mathbb{Z}_{29}$ (`agda/`).
3. **Ontology & Semantics**: 5-layer OWL/RDF ontology enforcing token ranges, closure statements, and candidate self-acceptance prohibitions (`ontology/`).
4. **Discovery & Provenance**: Canonical byte deduplication engine and provenance index graph (`search/discovery.py`, `evidence/provenance_index.json`).
5. **Execution Matrix**: GitHub Actions parallel matrix search across affine, reversal, magic square, and prime sequence branches (`.github/workflows/liber-primus-search.yml`).
6. **Agent Orchestrator**: Google Jules autonomous session dispatcher (`.github/workflows/jules-dispatch.yml`).

---

## Verification & Execution

### Run HARN Horn-Clause Gate Verifier
```bash
swipl -q -s harn/verify.pl -g main -t halt
```

### Run Hypothesis Search Matrix
```bash
swipl -q -s harn/search.pl -g "run('affine29')" -t halt
swipl -q -s harn/search.pl -g "run('prime-sequence')" -t halt
```

### Run Full Regression Test Suite
```bash
PYTHONPATH=. pytest -v tests/
```
