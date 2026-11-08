#!/usr/bin/env python3
"""Page-safe 29-symbol HMM cross-validation for Liber Primus.

Requires NumPy. No plaintext recovery is attempted.
"""
from __future__ import annotations
import argparse
import csv
import json
import math
from pathlib import Path
import sys
import numpy as np

ALPHABET = 29
KS = (2, 3, 4, 8)


def load_pages(path: Path, include_solved: bool = False) -> list[tuple[str, np.ndarray]]:
    obj = json.loads(path.read_text(encoding="utf-8"))
    records = obj.get("pages") if isinstance(obj, dict) else obj
    if not isinstance(records, list):
        raise ValueError("Expected JSON object with pages[] or a list of page records")
    pages = []
    for n, rec in enumerate(records):
        if not isinstance(rec, dict):
            raise ValueError(f"pages[{n}] must be a JSON object")
        # Canonical LP2: page numbers 0..54 unsolved; 55 may be blank in
        # alternative mappings, and 56/57 are solved AN END and PARABLE.
        page_num = rec.get("page_number", rec.get("page", rec.get("number", n)))
        if isinstance(page_num, dict):
            page_num = page_num.get("number", n)
        try:
            numeric_page = int(page_num)
        except (ValueError, TypeError):
            numeric_page = n
        tags = " ".join(str(rec.get(k, "")) for k in ("title", "name", "status", "label", "plaintext" )).lower()
        solved = (rec.get("solved") is True or rec.get("is_solved") is True or
                  str(rec.get("status", "")).lower() == "solved" or
                  numeric_page in (56, 57) or "an end" in tags or "parable" in tags)
        if solved and not include_solved:
            continue
        indices = rec.get("indices")
        if indices is None:
            # Support wrappers that place the data under content.
            content = rec.get("content")
            if isinstance(content, dict):
                indices = content.get("indices")
        if indices is None:
            if numeric_page == 50 or not rec.get("runes", "").strip():
                continue
            raise ValueError(f"Page {page_num}: missing indices; rebuild canonical dataset")
        arr = np.asarray(indices)
        if arr.ndim != 1:
            raise ValueError(f"Page {page_num}: indices not one-dimensional")
        if arr.size == 0:
            continue
        if not np.issubdtype(arr.dtype, np.integer):
            raise ValueError(f"Page {page_num}: indices must be integers")
        if np.any((arr < 0) | (arr >= ALPHABET)):
            raise ValueError(f"Page {page_num}: rune index outside 0..28")
        pages.append((str(page_num), arr.astype(np.int16)))
    if len(pages) < 5:
        raise ValueError("Need at least five nonempty pages for 5-fold CV")
    return pages


def folds_by_page(pages, n_folds: int, seed: int):
    # Deterministic randomized page-level stratification by length: distribute
    # long and short pages without splitting any sequence.
    rng = np.random.default_rng(seed)
    order = list(rng.permutation(len(pages)))
    order.sort(key=lambda i: -len(pages[i][1]))  # stable ties random
    bins = [[] for _ in range(n_folds)]
    sizes = [0] * n_folds
    for i in order:
        j = min(range(n_folds), key=lambda z: (sizes[z], len(bins[z]), z))
        bins[j].append(i)
        sizes[j] += len(pages[i][1])
    assert all(bins)
    assert sorted(i for b in bins for i in b) == list(range(len(pages)))
    return bins


def normalize(v, axis=-1):
    v = np.asarray(v, dtype=np.float64)
    return v / v.sum(axis=axis, keepdims=True)


def init_hmm(k: int, alpha: float, rng):
    pi = rng.dirichlet(np.full(k, alpha + 1))
    A = rng.dirichlet(np.full(k, alpha + 1), size=k)
    B = rng.dirichlet(np.full(ALPHABET, alpha + 1), size=k)
    return pi, A, B


def check_hmm(pi, A, B):
    k = len(pi)
    assert pi.shape == (k,) and A.shape == (k, k) and B.shape == (k, ALPHABET)
    assert np.all(np.isfinite(pi)) and np.all(np.isfinite(A)) and np.all(np.isfinite(B))
    assert np.min(pi) > 0 and np.min(A) > 0 and np.min(B) > 0
    assert np.isclose(pi.sum(), 1, atol=1e-9)
    assert np.allclose(A.sum(axis=1), 1, atol=1e-9)
    assert np.allclose(B.sum(axis=1), 1, atol=1e-9)


def forward(obs, pi, A, B):
    """Scaled forward pass, exact sequence log likelihood and alphas."""
    length = len(obs)
    k = len(pi)
    f = np.empty((length, k), dtype=np.float64)
    scale = np.empty(length, dtype=np.float64)
    v = pi * B[:, obs[0]]
    scale[0] = v.sum()
    assert scale[0] > 0
    f[0] = v / scale[0]
    for t in range(1, length):
        v = (f[t - 1] @ A) * B[:, obs[t]]
        scale[t] = v.sum()
        assert scale[t] > 0
        f[t] = v / scale[t]
    return float(np.log(scale).sum()), f, scale


def expected_counts(obs, pi, A, B):
    ll, f, scale = forward(obs, pi, A, B)
    n, k = f.shape
    g = np.ones(k, dtype=np.float64)
    transition_counts = np.zeros((k, k))
    emission_counts = np.zeros((k, ALPHABET))
    for t in range(n - 1, -1, -1):
        posterior = f[t] * g
        posterior /= posterior.sum()
        emission_counts[:, obs[t]] += posterior
        if t == 0:
            pi_count = posterior.copy()
        else:
            # xi[i,j] = p(z[t-1]=i,z[t]=j | observations)
            right = B[:, obs[t]] * g
            xi = (f[t - 1, :, None] * A) * right[None, :]
            xi /= xi.sum()
            transition_counts += xi
            g = (A @ right) / scale[t]
    assert np.isclose(emission_counts.sum(), n, atol=1e-6)
    assert np.isclose(transition_counts.sum(), n-1, atol=1e-6)
    return ll, pi_count, transition_counts, emission_counts


def fit_hmm(sequences, k, alpha, iterations, tol, rng):
    pi, A, B = init_hmm(k, alpha, rng)
    hist = []
    for it in range(iterations):
        pc = np.zeros(k)
        ac = np.zeros((k, k))
        bc = np.zeros((k, ALPHABET))
        objective = 0.0
        for x in sequences:
            ll, p, a, b = expected_counts(x, pi, A, B)
            pc += p
            ac += a
            bc += b
            objective += ll
        hist.append(objective)
        # Additive Dirichlet pseudocount smoothing (not MAP alpha-1).
        pi = normalize(pc + alpha)
        A = normalize(ac + alpha, axis=1)
        B = normalize(bc + alpha, axis=1)
        check_hmm(pi, A, B)
        if it > 0 and (objective - hist[-2]) >= 0 and (objective - hist[-2]) < tol:
            break
    return (pi, A, B), hist


def ll_hmm(pages, model):
    return sum(forward(x, *model)[0] for x in pages)


def estimate_repeat_rate(sequences):
    repeats = sum(int(np.sum(x[1:] == x[:-1])) for x in sequences)
    transitions = sum(len(x) - 1 for x in sequences)
    if transitions == 0:
        raise ValueError("No transitions")
    return repeats / transitions, repeats, transitions


def ll_soft(pages, r):
    r = float(np.clip(r, 1e-12, 1-1e-12))
    rr = math.log(r)
    other = math.log((1-r)/(ALPHABET-1))
    return sum(-math.log(ALPHABET) + int(np.sum(x[1:] == x[:-1])) * rr +
               int(np.sum(x[1:] != x[:-1])) * other for x in pages)


def ll_uniform(pages):
    return -sum(len(x) for x in pages) * math.log(ALPHABET)


def simulate_uniform(lengths, rng):
    return [rng.integers(0, ALPHABET, size=n, dtype=np.int16) for n in lengths]


def simulate_soft(lengths, r, rng):
    out = []
    for n in lengths:
        x = np.empty(n, dtype=np.int16)
        x[0] = rng.integers(ALPHABET)
        for t in range(1, n):
            if rng.random() < r:
                x[t] = x[t-1]
            else:
                u = int(rng.integers(ALPHABET-1))
                x[t] = u + (u >= x[t-1])
        out.append(x)
    return out


def selftest():
    rng = np.random.default_rng(23)
    for k in KS:
        pi, A, B = init_hmm(k, 0.5, rng)
        check_hmm(pi, A, B)
        x = np.array([0, 2, 2, 28], dtype=np.int16)
        ll, *_ = forward(x, pi, A, B)
        # Brute-force sum across all hidden paths for short sequences.
        import itertools
        brute = 0.0
        for z in itertools.product(range(k), repeat=len(x)):
            p = pi[z[0]] * B[z[0], x[0]]
            for t in range(1, len(x)):
                p *= A[z[t-1], z[t]] * B[z[t], x[t]]
            brute += p
        assert math.isclose(math.exp(ll), brute, rel_tol=1e-10)
        ll2, pc, ac, bc = expected_counts(x, pi, A, B)
        assert math.isclose(ll2, ll, abs_tol=1e-10)
        assert np.isclose(pc.sum(), 1)
        assert np.isclose(ac.sum(), len(x)-1)
        assert np.isclose(bc.sum(), len(x))
    lengths = [30, 34, 37, 29, 41]
    soft = simulate_soft(lengths, 0.02, rng)
    independent = simulate_uniform(lengths, rng)
    assert all(len(x) == n for x, n in zip(soft, lengths))
    assert all(np.all((x >= 0) & (x < ALPHABET)) for x in independent)
    assert all(np.all((x >= 0) & (x < ALPHABET)) for x in soft)
    folds = folds_by_page([(str(i), a) for i, a in enumerate(soft)], 5, 11)
    assert sorted(j for fold in folds for j in fold) == list(range(5))
    model, history = fit_hmm(soft, 2, 0.5, 3, 1e-5, rng)
    check_hmm(*model)
    assert np.isfinite(ll_hmm(soft, model)) and len(history) >= 1
    print("SELFTEST PASS: brute-force forward LL, normalization, EM counts, page folds, generators")


def run_cv(pages, args, control_name):
    partitions = folds_by_page(pages, 5, args.seed)
    results = []
    for fold, test_idx in enumerate(partitions, start=1):
        train_idx = [i for i in range(len(pages)) if i not in set(test_idx)]
        train = [pages[i][1] for i in train_idx]
        test = [pages[i][1] for i in test_idx]
        n = sum(map(len, test))
        r, repeats, transitions = estimate_repeat_rate(train)
        baseline = [("uniform", ll_uniform(test)), ("soft", ll_soft(test, r))]
        for name, ll in baseline:
            results.append(dict(control=control_name, fold=fold, model=name, states=0,
                                pages=len(test), symbols=n, transitions=sum(len(x)-1 for x in test),
                                train_repeat_rate=r, ll=ll, ll_per_symbol=ll/n,
                                iterations=0, restart=0))
        for k in KS:
            best_model, best_train_ll, best_restart, best_iterations = None, -math.inf, None, None
            for restart in range(args.restarts):
                # Reproducible but independent seeds for each fold/model/control/restart.
                rng = np.random.default_rng(args.seed + fold * 100_003 + k * 1009 + restart * 37 +
                                            (0 if control_name == "real" else (1 if control_name == "uniform" else 2))*10000019)
                model, history = fit_hmm(train, k, args.alpha, args.iterations, args.tol, rng)
                train_ll = ll_hmm(train, model)
                if train_ll > best_train_ll:
                    best_model, best_train_ll, best_restart, best_iterations = model, train_ll, restart, len(history)
            ll = ll_hmm(test, best_model)
            results.append(dict(control=control_name, fold=fold, model="hmm", states=k,
                                pages=len(test), symbols=n, transitions=sum(len(x)-1 for x in test),
                                train_repeat_rate=r, ll=ll, ll_per_symbol=ll/n,
                                iterations=best_iterations, restart=best_restart))
            print(f"{control_name} fold={fold} K={k} testLL={ll:.3f} n={n}", flush=True)
    return results


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input", type=Path, help="Canonical dataset/liber_primus.json")
    p.add_argument("--output", type=Path, default=Path("markov_cv_results.csv"))
    p.add_argument("--seed", type=int, default=3301)
    p.add_argument("--alpha", type=float, default=0.5)
    p.add_argument("--iterations", type=int, default=25)
    p.add_argument("--restarts", type=int, default=1)
    p.add_argument("--tol", type=float, default=1e-4)
    p.add_argument("--include-solved", action="store_true", help="Explicitly include solved pages (not recommended)")
    p.add_argument("--controls", choices=("none", "both"), default="both")
    p.add_argument("--selftest", action="store_true")
    args = p.parse_args()
    if not (args.alpha > 0 and args.iterations >= 1 and args.restarts >= 1):
        p.error("alpha, iterations, restarts must be positive")
    if args.selftest:
        selftest()
        if args.input is None:
            return
    if args.input is None:
        p.error("--input required unless --selftest only")
    pages = load_pages(args.input, args.include_solved)
    print(f"Loaded {len(pages)} pages, {sum(len(x) for _, x in pages)} symbols, "
          f"{sum(len(x)-1 for _, x in pages)} within-page transitions", flush=True)
    if not args.include_solved and len(pages) != 55:
        print("WARNING: expected 55 unsolved canonical LP2 pages; inspect data selection", file=sys.stderr)
    results = run_cv(pages, args, "real")
    if args.controls == "both":
        lengths = [len(x) for _, x in pages]
        r, _, _ = estimate_repeat_rate([x for _, x in pages])
        rng = np.random.default_rng(args.seed + 424242)
        for name, synthetic in (("uniform", simulate_uniform(lengths, rng)),
                                ("soft", simulate_soft(lengths, r, rng))):
            control_pages = [(page_id, x) for (page_id, _), x in zip(pages, synthetic)]
            results.extend(run_cv(control_pages, args, name))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(results[0]))
        writer.writeheader()
        writer.writerows(results)
    print(f"Saved {len(results)} rows to {args.output}")
    for group in ("real", "uniform", "soft"):
        selection = [row for row in results if row["control"] == group]
        if not selection:
            continue
        for model in ("uniform", "soft", "hmm"):
            for k in ((2, 3, 4, 8) if model == "hmm" else (0,)):
                sub = [v for v in selection if v["model"] == model and v["states"] == k]
                if sub:
                    print(f"{group:7} {model:7} K={k} held-out LL/symbol="
                          f"{sum(v['ll'] for v in sub)/sum(v['symbols'] for v in sub):.6f}")

if __name__ == "__main__":
    main()
