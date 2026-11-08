#!/usr/bin/env python3
"""Page-safe HMM cross-validation for a 29-symbol ciphertext.

Input JSON: {"pages": [{"id":"57", "indices":[0,1,...]}, ...]}
Or top-level list of page objects. Uses NumPy, not a cryptographic library.
"""
import argparse
import json
import math
from pathlib import Path
import numpy as np

N = 29

def load_pages(path):
    raw = json.loads(Path(path).read_text(encoding='utf-8'))
    data = raw['pages'] if isinstance(raw, dict) else raw
    assert isinstance(data, list) and len(data) >= 5, 'Need >=5 pages for five folds'
    pages, ids = [], []
    for i, entry in enumerate(data):
        values = entry['indices'] if isinstance(entry, dict) else entry
        name = str(entry.get('id', i)) if isinstance(entry, dict) else str(i)
        if not isinstance(values, list) or len(values) < 2 or any(type(x) is not int or not 0 <= x < N for x in values):
            raise ValueError(f'Invalid rune indices in page {name}: expected integer array in [0,28] of length >= 2')
        pages.append(np.array(values, dtype=np.int16)); ids.append(name)
    if len(ids) != len(set(ids)):
        raise ValueError('Page identifiers must be unique')
    return pages, ids

def soft_fit(pages, alpha):
    repeats = sum(int(np.count_nonzero(p[1:] == p[:-1])) for p in pages)
    total = sum(len(p)-1 for p in pages)
    # Beta prior on Bernoulli repeat probability, with symmetric pseudocounts.
    r = (repeats + alpha) / (total + 2*alpha)
    return r

def soft_ll(page, r):
    repeats = int(np.count_nonzero(page[1:] == page[:-1]))
    diff = len(page)-1-repeats
    return -math.log(N) + repeats*math.log(r) + diff*math.log((1-r)/(N-1))

def make_hmm(k, rng):
    init = rng.dirichlet(np.ones(k)*2)
    transition = rng.dirichlet(np.ones(k)*3, size=k)
    emission = rng.dirichlet(np.ones(N)*3, size=k)
    return init, transition, emission

def forward(page, init, a, e):
    """Scaled forward probabilities and log P(page); independent page start."""
    t = len(page); k = len(init)
    f = np.empty((t,k), dtype=np.float64)
    c = np.empty(t, dtype=np.float64)
    v = init * e[:,page[0]]
    c[0] = v.sum()
    if c[0] <= 0: raise ArithmeticError('Zero forward scale')
    f[0] = v/c[0]
    for z in range(1,t):
        v = (f[z-1] @ a)*e[:,page[z]]
        c[z] = v.sum()
        if c[z] <= 0: raise ArithmeticError('Zero forward scale')
        f[z] = v/c[z]
    return f, c, float(np.log(c).sum())

def expected_counts(page, init, a, e):
    f,c,ll = forward(page,init,a,e)
    t,k = f.shape
    beta = np.ones(k)
    init_count = np.zeros(k)
    trans_count = np.zeros((k,k))
    emit_count = np.zeros((k,N))
    # Last state posterior = scaled forward at last observation.
    emit_count[:,page[-1]] += f[-1]
    for z in range(t-2,-1,-1):
        weighted = e[:,page[z+1]] * beta
        xi = f[z,:,None] * a * weighted[None,:] / c[z+1]
        trans_count += xi
        gamma = xi.sum(axis=1)
        emit_count[:,page[z]] += gamma
        if z == 0: init_count += gamma
        beta = (a @ weighted)/c[z+1]
    return ll,init_count,trans_count,emit_count

def train_hmm(pages,k,alpha,rng,max_iter,tol):
    init,a,e = make_hmm(k,rng)
    prev = -np.inf
    for iteration in range(max_iter):
        ic = np.zeros(k); tc = np.zeros((k,k)); ec = np.zeros((k,N)); total_ll=0.
        for page in pages:
            ll,i,t,ex = expected_counts(page,init,a,e)
            total_ll += ll; ic += i; tc += t; ec += ex
        new_init = (ic + alpha)/(ic.sum() + k*alpha)
        new_a = (tc + alpha)/(tc.sum(axis=1,keepdims=True) + k*alpha)
        new_e = (ec + alpha)/(ec.sum(axis=1,keepdims=True) + N*alpha)
        init,a,e = new_init,new_a,new_e
        if iteration and total_ll - prev >= 0 and total_ll - prev < tol: break
        prev = total_ll
    train_ll = sum(forward(p,init,a,e)[2] for p in pages)
    for mat in (init,a,e):
        assert np.all(np.isfinite(mat)) and np.all(mat>0)
    assert np.isclose(init.sum(),1) and np.allclose(a.sum(axis=1),1) and np.allclose(e.sum(axis=1),1)
    return (init,a,e), float(train_ll), iteration+1

def splits(num_pages,seed):
    rng = np.random.default_rng(seed)
    permutation = rng.permutation(num_pages)
    # pages, not runes, are the cross-validation unit.
    folds = np.array_split(permutation,5)
    assert sum(map(len,folds)) == num_pages
    for fold in folds:
        hold = set(fold.tolist())
        train = [i for i in range(num_pages) if i not in hold]
        assert hold.isdisjoint(train)
        yield train,fold.tolist()

def synthetic(lengths,r,seed):
    """Generate the exact symmetric first-order chain, resetting each page."""
    rng = np.random.default_rng(seed)
    pages=[]
    for length in lengths:
        p = np.empty(length,dtype=np.int16)
        p[0] = rng.integers(N)
        for i in range(1,length):
            if rng.random() < r: p[i] = p[i-1]
            else:
                v = int(rng.integers(N-1))
                p[i] = v + (v >= p[i-1])
        pages.append(p)
    return pages

def run_cv(pages,ids,models,alpha,seed,max_iter,restarts):
    results=[]
    for fold,(train_ids,test_ids) in enumerate(splits(len(pages),seed),1):
        train = [pages[i] for i in train_ids]
        test = [pages[i] for i in test_ids]
        chars = sum(map(len,test)); transitions = sum(len(p)-1 for p in test)
        row={'fold':fold,'held_out_page_ids':[ids[i] for i in test_ids],
             'held_out_symbols':chars,'held_out_transitions':transitions,'models':{}}
        uniform_ll = -chars*math.log(N)
        row['models']['uniform']={'log_likelihood':uniform_ll,'nats_per_symbol':uniform_ll/chars}
        r = soft_fit(train,alpha)
        sl = sum(soft_ll(p,r) for p in test)
        row['models']['soft']={'r_train':r,'q_relative':(N-1)*r/(1-r),
                               'log_likelihood':sl,'nats_per_symbol':sl/chars}
        for k in models:
            best = None
            for restart in range(restarts):
                rng=np.random.default_rng(seed+fold*100003+k*1009+restart)
                params,trl,it=train_hmm(train,k,alpha,rng,max_iter,1e-3)
                if best is None or trl > best[0]: best=(trl,params,it,restart)
            _,params,it,restart=best
            hll=sum(forward(p,*params)[2] for p in test)
            row['models'][f'hmm_{k}']={'log_likelihood':hll,'nats_per_symbol':hll/chars,
                                      'em_iterations':it,'best_restart':restart,
                                      'train_log_likelihood':best[0]}
        results.append(row)
        print(f'fold {fold}: '+ ' '.join(f'{name}={values["nats_per_symbol"]:.5f}' for name,values in row['models'].items()),flush=True)
    return results

def summarize(rows):
    names=list(rows[0]['models'])
    return {name:{'held_out_log_likelihood':sum(r['models'][name]['log_likelihood'] for r in rows),
                  'nats_per_symbol':sum(r['models'][name]['log_likelihood'] for r in rows)/sum(r['held_out_symbols'] for r in rows)}
            for name in names}

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--input',required=True,help='JSON with 57 page-wise arrays of rune indices 0..28')
    ap.add_argument('--output',default='hmm_results.json')
    ap.add_argument('--alpha',type=float,default=.5)
    ap.add_argument('--seed',type=int,default=3301)
    ap.add_argument('--iterations',type=int,default=30)
    ap.add_argument('--restarts',type=int,default=2)
    ap.add_argument('--synthetic',action='store_true',help='Additionally evaluate a synthetic chain, same page lengths, independent random seed')
    ap.add_argument('--models',type=int,nargs='+',default=[2,3,4,8])
    args=ap.parse_args()
    if args.alpha<=0 or args.iterations<1 or args.restarts<1 or any(k<1 for k in args.models):
        ap.error('alpha, iterations, restarts and model sizes must be positive')
    pages,ids=load_pages(args.input)
    report={'input_file':str(args.input),'page_count':len(pages),'rune_count':sum(map(len,pages)),
            'alpha':args.alpha,'seed':args.seed,'models':args.models,
            'scope':'within-page; every page has an independent initial state',
            'real':{}}
    real=run_cv(pages,ids,args.models,args.alpha,args.seed,args.iterations,args.restarts)
    report['real']={'folds':real,'summary':summarize(real)}
    if args.synthetic:
        fitted_r=soft_fit(pages,args.alpha)
        fake=synthetic([len(p) for p in pages],fitted_r,args.seed+987654)
        synthetic_rows=run_cv(fake,ids,args.models,args.alpha,args.seed,args.iterations,args.restarts)
        report['synthetic_control']={'generating_repeat_probability':fitted_r,
                                     'observed_repeats':sum(int(np.sum(p[1:]==p[:-1])) for p in fake),
                                     'folds':synthetic_rows,'summary':summarize(synthetic_rows)}
    Path(args.output).write_text(json.dumps(report,indent=2,allow_nan=False)+'\n',encoding='utf-8')
    print('Saved '+args.output)

if __name__=='__main__': main()
