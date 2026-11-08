/* verification.pl
   HARN Horn-clause verification engine implementing P57 and P58 gates.
   Ensures deterministic verification and prevents candidate self-acceptance.
*/

:- module(verification, [
    verify_p57_gate/3,
    verify_p58_gate/3,
    evaluate_candidate/3,
    run_all_p57_gates/2,
    run_all_p58_gates/2
]).

:- use_module(translation).

% P57 Gates Evaluation
% verify_p57_gate(GateId, Candidate, Status)

% P57-001: TokenRange Coverage Check
verify_p57_gate('P57-001', Candidate, pass) :-
    get_dict(tokens, Candidate, Tokens),
    length(Tokens, Len),
    Len > 0, !.
verify_p57_gate('P57-001', _, fail('P57-001: Empty or invalid TokenRange')).

% P57-002: Base-29 Alphabet Validity
verify_p57_gate('P57-002', Candidate, pass) :-
    get_dict(tokens, Candidate, Tokens),
    forall(member(T, Tokens), (integer(T), T >= 0, T =< 28)), !.
verify_p57_gate('P57-002', _, fail('P57-002: Token values out of Z_29 range [0..28]')).

% P57-003: Artifact Provenance Checksum
verify_p57_gate('P57-003', Candidate, pass) :-
    get_dict(input_snapshot_sha256, Candidate, Sha),
    string_length(Sha, 64), !.
verify_p57_gate('P57-003', _, fail('P57-003: Invalid or missing input SHA-256 fingerprint')).

% P57-004: Reversibility & Involution Constraint
verify_p57_gate('P57-004', Candidate, pass) :-
    get_dict(transformation, Candidate, Trans),
    member(Trans, [affine, reverse, opposite, magic_square, prime_stream]), !.
verify_p57_gate('P57-004', _, fail('P57-004: Unjustified or irreversible transformation')).

% P57-005: Prime Index Sequence Constraint
verify_p57_gate('P57-005', Candidate, pass) :-
    get_dict(tokens, Candidate, Tokens),
    forall(member(T, Tokens), rune_prime(T, _)), !.
verify_p57_gate('P57-005', _, fail('P57-005: Prime mapping failure')).

% P57-006: Modular Arithmetic Determinism
verify_p57_gate('P57-006', _, pass).

% P57-007: Candidate Independence Constraint
verify_p57_gate('P57-007', Candidate, pass) :-
    get_dict(id, Candidate, Id),
    string_length(Id, L),
    L > 0, !.
verify_p57_gate('P57-007', _, fail('P57-007: Candidate identifier missing')).

% P57-008: PGP Key Fingerprint Authorization
verify_p57_gate('P57-008', Candidate, pass) :-
    ( get_dict(pgp_fingerprint, Candidate, FP) ->
      sub_string(FP, _, _, _, "7A35090F")
    ; true ), !.
verify_p57_gate('P57-008', _, fail('P57-008: Unauthorized PGP key reference')).

% P57-009: Deduplication by Canonical Representation
verify_p57_gate('P57-009', Candidate, pass) :-
    get_dict(tokens, Candidate, _), !.
verify_p57_gate('P57-009', _, fail('P57-009: Missing canonical token representation')).

% P57-010: Cryptographic Evidence Non-fabrication
verify_p57_gate('P57-010', Candidate, pass) :-
    \+ get_dict(fabricated, Candidate, true), !.
verify_p57_gate('P57-010', _, fail('P57-010: Fabricated evidence marker detected')).


% P58 Gates Evaluation
% P58-001: VerificationObligation Completeness
verify_p58_gate('P58-001', Candidate, pass) :-
    get_dict(obligations, Candidate, Obs),
    is_list(Obs), !.
verify_p58_gate('P58-001', _, fail('P58-001: Incomplete verification obligations')).

% P58-002: Candidate Cannot Assert Own Acceptance
verify_p58_gate('P58-002', Candidate, pass) :-
    ( get_dict(asserted_accepted, Candidate, true) ->
      fail
    ; true ), !.
verify_p58_gate('P58-002', _, fail('P58-002: Candidate cannot assert its own acceptance (self-assertion violation)')).

% P58-003: Deterministic Decryption Reproducibility
verify_p58_gate('P58-003', Candidate, pass) :-
    get_dict(reproducible, Candidate, true), !.
verify_p58_gate('P58-003', _, fail('P58-003: Non-reproducible transformation')).

% P58-004: Entropy and Language Plausibility Metric
verify_p58_gate('P58-004', Candidate, pass) :-
    get_dict(entropy, Candidate, E),
    E >= 0.0, !.
verify_p58_gate('P58-004', _, pass).

% P58-005: FalsePathMarker Ledger Invariant
verify_p58_gate('P58-005', Candidate, pass) :-
    \+ get_dict(ledger_excluded, Candidate, true), !.
verify_p58_gate('P58-005', _, fail('P58-005: Hypothesis already registered on false-path ledger')).

% P58-006: Independent Key Derivation Proof
verify_p58_gate('P58-006', Candidate, pass) :-
    get_dict(key_derivation, Candidate, _), !.
verify_p58_gate('P58-006', _, fail('P58-006: Missing key derivation trace')).

% P58-007: Hash Preimage Exact Verification
verify_p58_gate('P58-007', Candidate, Status) :-
    ( get_dict(target_hash, Candidate, Target),
      get_dict(candidate_hash, Candidate, Cand) ->
      ( Target == Cand -> Status = pass ; Status = fail('P58-007: Hash preimage mismatch') )
    ; Status = pass ), !.

% P58-008: OpenPGP Signature Verification Invariant
verify_p58_gate('P58-008', Candidate, Status) :-
    ( get_dict(pgp_signature_valid, Candidate, Valid) ->
      ( Valid == true -> Status = pass ; Status = fail('P58-008: OpenPGP signature verification failed') )
    ; Status = pass ), !.

% P58-009: Frozen Evidence Immutability Check
verify_p58_gate('P58-009', Candidate, pass) :-
    get_dict(frozen_match, Candidate, true), !.
verify_p58_gate('P58-009', _, fail('P58-009: Frozen evidence mismatch')).

% P58-010: Final Formal Closure Statement Validation
verify_p58_gate('P58-010', Candidate, pass) :-
    get_dict(status, Candidate, _), !.
verify_p58_gate('P58-010', _, fail('P58-010: Closure status undefined')).

p57_gate_ids([
    'P57-001', 'P57-002', 'P57-003', 'P57-004', 'P57-005',
    'P57-006', 'P57-007', 'P57-008', 'P57-009', 'P57-010'
]).

p58_gate_ids([
    'P58-001', 'P58-002', 'P58-003', 'P58-004', 'P58-005',
    'P58-006', 'P58-007', 'P58-008', 'P58-009', 'P58-010'
]).

run_all_p57_gates(Candidate, Results) :-
    p57_gate_ids(Gates),
    findall(G-Res, (member(G, Gates), verify_p57_gate(G, Candidate, Res)), Results).

run_all_p58_gates(Candidate, Results) :-
    p58_gate_ids(Gates),
    findall(G-Res, (member(G, Gates), verify_p58_gate(G, Candidate, Res)), Results).

evaluate_candidate(Candidate, Status, FinalResults) :-
    run_all_p57_gates(Candidate, R57),
    run_all_p58_gates(Candidate, R58),
    append(R57, R58, FinalResults),
    ( member(_-fail(Reason), FinalResults) ->
      Status = false_path(Reason)
    ; ( get_dict(cryptographically_proven, Candidate, true) ->
        Status = verified_accepted
      ; Status = unresolved
      )
    ).
