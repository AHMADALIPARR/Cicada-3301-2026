/* search.pl
   Entry point for GitHub Actions search matrix job:
   swipl -q -s harn/search.pl -g "run('$HYPOTHESIS')" -t halt
*/

:- module(harn_search_runner, [run/1]).

:- use_module('../prolog/translation').
:- use_module('../prolog/verification').
:- use_module('../prolog/search').

run(HypothesisAtom) :-
    format('[SEARCH] Starting hypothesis runner for: ~w~n', [HypothesisAtom]),
    ( HypothesisAtom == 'affine29' -> Hyp = affine29
    ; HypothesisAtom == 'reverse' -> Hyp = reverse
    ; HypothesisAtom == 'magic-square' -> Hyp = magic_square
    ; HypothesisAtom == 'prime-sequence' -> Hyp = prime_sequence
    ; Hyp = HypothesisAtom ),
    search:run_matrix_search(Hyp, Result),
    format('[SEARCH] Hypothesis ~w executed successfully.~nResult: ~w~n', [HypothesisAtom, Result]).
