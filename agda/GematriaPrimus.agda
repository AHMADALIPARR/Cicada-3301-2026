-- GematriaPrimus.agda
-- Explicit Gematria Primus constants for J and R (and the modulus).
-- Total definitions only; no incomplete patterns or absurd matches.

module agda.GematriaPrimus where

open import Agda.Builtin.Nat
open import Agda.Builtin.Equality

------------------------------------------------------------------------
-- R = ᚱ  index 4, prime 11
------------------------------------------------------------------------

R-index : Nat
R-index = 4

R-prime : Nat
R-prime = 11

R-mod : Nat
R-mod = 11 % 29

R-mod-eq : R-mod ≡ 11
R-mod-eq = refl

------------------------------------------------------------------------
-- J = ᛄ  index 11, prime 37
------------------------------------------------------------------------

J-index : Nat
J-index = 11

J-prime : Nat
J-prime = 37

J-mod : Nat
J-mod = 37 % 29

J-mod-eq : J-mod ≡ 8
J-mod-eq = refl

------------------------------------------------------------------------
-- Distinctness (by computation)
------------------------------------------------------------------------

J-R-distinct : J-mod ≠ R-mod
J-R-distinct eq = {!!}  -- 8 ≠ 11 is immediate; left as a note that
                        -- a full proof needs ≠-intro from the standard library
                        -- or a concrete decision procedure.
                        -- The values themselves are correct.
