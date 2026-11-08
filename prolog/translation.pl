/* translation.pl
   Base-29 Gematria Primus translation, modular arithmetic,
   and rune dictionary definitions.
*/

:- module(translation, [
    gematria/4,
    rune_index/2,
    rune_prime/2,
    rune_translit/2,
    mod29_add/3,
    mod29_sub/3,
    mod29_mul/3,
    mod29_opposite/2,
    mod29_inv/2,
    affine_encrypt/4,
    affine_decrypt/4
]).

% gematria(Index, Rune, Translit, Prime)
gematria(0,  "ᚠ", "F",   2).
gematria(1,  "ᚢ", "U",   3).
gematria(2,  "ᚦ", "TH",  5).
gematria(3,  "ᚩ", "O",   7).
gematria(4,  "ᚱ", "R",   11).
gematria(5,  "ᚳ", "C",   13).
gematria(6,  "ᚷ", "G",   17).
gematria(7,  "ᚹ", "W",   19).
gematria(8,  "ᚻ", "H",   23).
gematria(9,  "ᚾ", "N",   29).
gematria(10, "ᛁ", "I",   31).
gematria(11, "ᛄ", "J",   37).
gematria(12, "ᛇ", "EO",  41).
gematria(13, "ᛈ", "P",   43).
gematria(14, "ᛉ", "X",   47).
gematria(15, "ᛋ", "S",   53).
gematria(16, "ᛏ", "T",   59).
gematria(17, "ᛒ", "B",   61).
gematria(18, "ᛖ", "E",   67).
gematria(19, "ᛗ", "M",   71).
gematria(20, "ᛚ", "L",   73).
gematria(21, "ᛝ", "ING", 79).
gematria(22, "ᛟ", "OE",  83).
gematria(23, "ᛞ", "D",   89).
gematria(24, "ᚪ", "A",   97).
gematria(25, "ᚫ", "AE",  101).
gematria(26, "ᚣ", "Y",   103).
gematria(27, "ᛡ", "IA",  107).
gematria(28, "ᛠ", "EA",  109).

rune_index(Rune, Index) :- gematria(Index, Rune, _, _).
rune_prime(Index, Prime) :- gematria(Index, _, _, Prime).
rune_translit(Index, Translit) :- gematria(Index, _, Translit, _).

mod29_add(A, B, R) :- R is (A + B) mod 29.
mod29_sub(A, B, R) :- R is (A - B + 29) mod 29.
mod29_mul(A, B, R) :- R is (A * B) mod 29.
mod29_opposite(T, R) :- R is (29 - (T mod 29)) mod 29.

% Modular inverse modulo 29 (for units in Z_29)
mod29_inv(A, Inv) :-
    between(1, 28, Inv),
    1 is (A * Inv) mod 29,
    !.

affine_encrypt(A, B, T, C) :-
    C is (A * T + B) mod 29.

affine_decrypt(A, B, C, T) :-
    mod29_inv(A, Inv),
    T is (Inv * (C - B + 29)) mod 29.
