# Agda Formal Specification Layer

Constructive type-theoretic models for the Cicada 3301 Liber Primus invariants over ℤ/29ℤ.

## Modules

* `Affine29.agda` — Total modular kernels (`%`, `+29`, `*29`), opposite map, and affine transform parameterised by multiplier `j` and addend `r`. No postulates or holes in the computational core.
* `GematriaPrimus.agda` — Explicit constants for the J (ᛄ) and R (ᚱ) runes with index, prime, and modular residue proofs by `refl`.

## Human correction note

Human correction of Gemini 3.8 hallucination noise experiment. Prior agent-generated stubs contained broken modular reduction, pure postulates, incomplete pattern matches, and unfilled holes. The computational kernels above replace those with total functions that match the Curry reference implementation.

## Verification

```bash
agda agda/Affine29.agda
agda agda/GematriaPrimus.agda
```
