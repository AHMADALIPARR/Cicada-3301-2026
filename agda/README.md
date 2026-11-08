# Agda Formal Specification Layer

Constructive type-theoretic models for the Cicada 3301 Liber Primus invariants over ℤ/29ℤ.

## Modules

* `Affine29.agda` — Real modular kernels (correct `%`, `+29`, `*29`) together with the opposite map and the affine transform parameterised by the multiplier `j` and the addend `r`. The involution `O(O(t)) ≡ t mod 29` is stated constructively; the affine round-trip is sketched for the coprime case.

## Verification

```bash
agda agda/Affine29.agda
```

(The file still contains a few holes for the monus-cancellation lemmas. They are the standard ones; filling them requires either a few lines of induction or the Agda standard library.)
