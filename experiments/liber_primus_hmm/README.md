# Liber Primus: page-safe HMM cryptanalysis experiment

This is an **executable experiment**, not a claim of decryption. It fits categorical-emission HMMs with **2, 3, 4, 8** latent states, additive Dirichlet pseudocount **0.5**, **5-fold page-level** stratified cross-validation, held-out natural-log-likelihood, and two synthetic controls. Every page is a distinct sequence; EM resets its initial-state distribution per page. A soft anti-repeat Markov baseline is included because a standard HMM does not explicitly constrain adjacent observed symbols.

## Setup

```bash
python -m pip install 'numpy>=1.24'
python hmm_markov.py --selftest
python hmm_markov.py --input /path/to/cicada3301/liber-primus/dataset/liber_primus.json --output results.csv
```

Optional faster first pass: `--iterations 8 --controls none`. For more robust searches: `--iterations 60 --restarts 3`. Results may vary across local maxima but are reproducible with the same seed and software environment. Full CV with synthetic controls can be computationally expensive.

The parser supports the repo's `pages[].indices` integer arrays, filtering the solved pages 56/57 (AN END/PARABLE) by default. The **55 unsolved pages** are the correct experimental population; the dataset may also include a blank page 50. A warning appears when the loaded page count differs from 55. The flag `--include-solved` explicitly overrides that filter. Check original page numbers and indices if your JSON uses a different numbering convention.

## Exactly what is tested

- Baseline `uniform`: independent runes with probability 1/29.
- Baseline `soft`: train-estimated repeat probability r; next symbol repeats with probability r or is chosen uniformly from the other 28 values; first rune uniform.
- HMM: categorical emissions over 29 rune indices, learned transition matrix and initial-state distribution. Baum–Welch (scaled forward/backward) with additive smoothing. Best training-LL restart chosen **without looking at the held-out fold**.
- Controls: sequences drawn independently from uniform and from the same soft anti-repeat law at the measured overall rate; use exactly the original page lengths and the same CV protocol. These synthetic generators **do not include planted recoverable plaintext**.
- Output: CSV with one row for each fold/model/control and the held-out total LL and per-symbol LL. Use the summed held-out LL divided by summed held-out symbol counts to compare models. Larger (less negative) is better.

## Interpretation and limitations

A positive held-out gain demonstrates predictive modeling ability, **not** actual plaintext recovery, evidence of hidden language states, or proof of a particular cipher. Standard HMMs may have difficulty modeling an explicit one-step observed-symbol exclusion mechanism without many latent states. No page is split, no between-page transitions are counted, and zero-probability issues are prevented by positive pseudocounts. The self-test checks the forward probability against exhaustive hidden-path enumeration (for small input), emission and transition expected counts, normalization, synthetic alphabet bounds, and fold disjointness.

The source of the reported corpus structure is the public `Dukotah/cicada3301` repository; no corpus results are embedded in this package.
