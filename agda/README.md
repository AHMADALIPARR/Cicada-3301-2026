# Agda Formal Specification Layer

This directory provides the Agda constructive type theory and formal verification models for the Cicada 3301 Liber Primus cryptographic invariants.

## Modules

* `Affine29.agda`: Formal constructive specification of modular arithmetic over $\mathbb{Z}_{29}$ and the involution theorem $O(O(t)) \equiv t$.

## Verification

When an Agda installation is present:
```bash
agda agda/Affine29.agda
```
