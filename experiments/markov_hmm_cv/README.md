# Page-boundary-safe HMM cryptanalysis

Requires Python 3.10+ and NumPy (`python -m pip install numpy`). The code does not use the real corpus unless you provide it. It never claims that statistical fit decrypts text.

## Input

Save rune **indices** from the repo's authoritative Gematria Primus table (not Unicode code points, not guessed ASCII letters) in `pages.json`:

```json
{"pages":[{"id":"page_1","indices":[0,7,14,3]},{"id":"page_2","indices":[9,4,11,2]}]}
```

At least five pages are required for 5-fold cross-validation. The full input should have 57 pages. The program rejects invalid indices and repeated page IDs. Each page is a separate observation sequence; no artificial page-crossing transitions are counted.

## Run

```sh
python hmm_cv.py --input pages.json --output results.json --alpha 0.5 --models 2 3 4 8 --iterations 30 --restarts 2 --synthetic
```

The executable compares independent uniform, fitted symmetric soft anti-repeat, and categorical-emission HMMs with 2, 3, 4, and 8 latent states. It fits the HMMs with scaled Baum–Welch, Dirichlet(0.5) pseudocounts for initial-state, transition, and emission distributions, independent randomized starts, and page-level CV splits. The held-out metric is natural-log likelihood **per rune** (including page-initial symbols), so all models use the same denominator. The report also preserves total log-likelihood and per-fold details. The synthetic control is generated from the fitted soft anti-repeat chain, with independent page starts and exact transition probabilities.

**Limitations:** HMMs with only 2–8 hidden states are not guaranteed to express a 29-symbol anti-repeat constraint. Therefore a poor HMM score does not disprove richer hidden-state mechanisms. The CV estimates predictive performance, not cipher identification or plaintext recovery. Run multiple seeds to assess optimizer variability; this CLI deliberately uses one fixed seed for reproducibility.
