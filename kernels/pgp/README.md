# Mercury DAG PGP Reduction

Deterministic integer DAG reduction of the authentic Cicada 3301 PGP fingerprint.

- Key ID: `7A35090F`
- Fingerprint: `6D854CD7933322A601C3286D181F01E57A35090F`
- Field: \(\mathbb{Z}_{29}\) (same as Liber Primus / Gematria Primus)

The reduction re-uses the radix-scaled fold and DAG node style from `../sovereign_kernel.R`. It produces a reproducible integer invariant; it does not decrypt or factor the 4096-bit RSA modulus.

## Usage
```r
source("kernels/pgp/mercury_dag_pgp.R")
result <- evaluate_pgp_dag()
print(result)
```
