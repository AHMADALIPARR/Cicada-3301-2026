/* closure.pl
   Formal closure statements, FalsePathMarker recording,
   and immutable ledger updates.
*/

:- module(closure, [
    record_closure/4,
    is_false_path/2,
    export_closure_json/3
]).

:- dynamic false_path/2.

record_closure(CandidateId, Status, Reason, ClosureRecord) :-
    ClosureRecord = closure_statement(CandidateId, Status, Reason),
    ( Status = false_path ->
      assertz(false_path(CandidateId, Reason))
    ; true ).

is_false_path(CandidateId, Reason) :-
    false_path(CandidateId, Reason).

export_closure_json(CandidateId, Status, Reason) :-
    format('{"candidate_id": "~w", "status": "~w", "reason": "~w"}~n',
           [CandidateId, Status, Reason]).
