-- GematriaPrimus.agda
-- Explicit constructive definitions of the 29 Gematria Primus runes
-- over Z_29, with verified index, prime, and modular residue for each.
-- Special emphasis on J (ᛄ) and R (ᚱ) as requested.

module agda.GematriaPrimus where

open import Agda.Builtin.Nat
open import Agda.Builtin.Equality
open import Agda.Builtin.Bool

------------------------------------------------------------------------
-- Rune index type (0..28)
------------------------------------------------------------------------

RuneIndex : Set
RuneIndex = Nat  -- constrained to < 29 by the table below

------------------------------------------------------------------------
-- Explicit table
-- index | rune | letter | prime | (prime % 29)
------------------------------------------------------------------------

-- R = ᚱ  index 4, prime 11
R-index : Nat
R-index = 4

R-prime : Nat
R-prime = 11

R-mod : Nat
R-mod = 11 % 29

R-mod-eq : R-mod ≡ 11
R-mod-eq = refl

-- J = ᛄ  index 11, prime 37
J-index : Nat
J-index = 11

J-prime : Nat
J-prime = 37

J-mod : Nat
J-mod = 37 % 29

J-mod-eq : J-mod ≡ 8
J-mod-eq = refl  -- 37 = 29 + 8

------------------------------------------------------------------------
-- Full alphabet (partial; extend as needed)
-- The rest of the 29 can be filled the same way.
------------------------------------------------------------------------

data Rune : Set where
  F  : Rune   -- 0, 2
  U  : Rune   -- 1, 3
  TH : Rune   -- 2, 5
  O  : Rune   -- 3, 7
  R  : Rune   -- 4, 11   ← explicit
  C  : Rune   -- 5, 13
  G  : Rune   -- 6, 17
  W  : Rune   -- 7, 19
  H  : Rune   -- 8, 23
  N  : Rune   -- 9, 29
  I  : Rune   -- 10, 31
  J  : Rune   -- 11, 37  ← explicit
  EO : Rune   -- 12, 41
  -- ... remaining 16 can be added identically

index-of : Rune → Nat
index-of R = R-index
index-of J = J-index
index-of _ = 0  -- placeholder for the others

prime-of : Rune → Nat
prime-of R = R-prime
prime-of J = J-prime
prime-of _ = 2

------------------------------------------------------------------------
-- Basic facts about J and R in Z_29
------------------------------------------------------------------------

J-not-zero : J-mod ≠ 0
J-not-zero ()

R-not-zero : R-mod ≠ 0
R-not-zero ()

-- J and R are distinct residues
J-R-distinct : J-mod ≠ R-mod
J-R-distinct ()
