# Mercury DAG PGP Reduction

Deterministic integer DAG reduction of the authentic Cicada 3301 PGP fingerprint.

- Key ID: `7A35090F`
- Fingerprint: `6D854CD7933322A601C3286D181F01E57A35090F`
- Field: \(\mathbb{Z}_{29}\)

## Files
- `mercury_dag_pgp.R` — radix-scaled fold and DAG trace of the fingerprint
- `verify_known.R` — fingerprint check against the published 2012 signed message text
- `grover_sim.R` — classical simulation of Grover search on a tiny domain (Z/29Z). Uses the same integer fold style as `sovereign_kernel.R`. Not applicable to 4096-bit RSA.

## Usage
```r
source("kernels/pgp/verify_known.R")
print(check_fingerprint())

source("kernels/pgp/grover_sim.R")
print(demo(11))
```

Keyservers were unreachable at the time of writing. Signature verification still requires a local gpg install and the public key. Grover's algorithm does not make factoring 4096-bit RSA practical.
