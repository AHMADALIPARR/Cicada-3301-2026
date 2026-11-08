/* search.pl
   Search algorithms and hypothesis evaluation across the Liber Primus search space.
*/

:- module(search, [
    search_hypothesis/3,
    run_matrix_search/2
]).

:- use_module(translation).
:- use_module(verification).

% 1. Base-29 affine transformations
search_hypothesis(affine29, Tokens, Result) :-
    findall(candidate(A, B, Decoded),
            ( between(1, 28, A),
              between(0, 28, B),
              maplist(affine_decrypt(A, B), Tokens, Decoded) ),
            Candidates),
    length(Candidates, Total),
    Result = search_result(affine29, Total, Candidates).

% 2. Reversal and opposite-token compositions
search_hypothesis(reverse, Tokens, Result) :-
    reverse(Tokens, Rev),
    maplist(mod29_opposite, Tokens, Opp),
    maplist(mod29_opposite, Rev, RevOpp),
    Result = search_result(reverse, 3, [Rev, Opp, RevOpp]).

% 3. Magic-square-derived traversals
search_hypothesis(magic_square, Tokens, Result) :-
    % Verify or generate 5x5 / square grid traversal order
    length(Tokens, Len),
    Result = search_result(magic_square, 1, [len(Len)]).

% 4. Prime-sequence and numerical-grid relationships
search_hypothesis(prime_sequence, Tokens, Result) :-
    maplist(rune_prime, Tokens, Primes),
    Result = search_result(prime_sequence, 1, [primes(Primes)]).

run_matrix_search(HypothesisName, Result) :-
    % Mock representative sample tokens
    SampleTokens = [0, 1, 2, 3, 4, 5],
    search_hypothesis(HypothesisName, SampleTokens, Result).
