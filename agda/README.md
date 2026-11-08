# Agda Formal Specification Layer

Constructive type-theoretic models for the Cicada 3301 Liber Primus invariants over ℤ/29ℤ.

## Modules

* `Affine29.agda` — Modular kernels (`%`, `+_29_`, `*_29_`), opposite involution skeleton, and affine transform parameterised by multiplier `j` and addend `r`.
* `GematriaPrimus.agda` — Explicit definitions of the 29-rune alphabet. **J (ᛄ, index 11, prime 37, residue 8) and R (ᚱ, index 4, prime 11, residue 11) are fully defined with equality proofs.**

## Verification

```bash
agda agda/Affine29.agda
agda agda/GematriaPrimus.agda
```
