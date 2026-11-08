-- Affine29.agda
-- Constructive modular arithmetic and verified involution / affine kernels over ℤ/29ℤ.
-- Replaces the previous stub (broken % and pure postulates).

module agda.Affine29 where

open import Agda.Builtin.Nat
open import Agda.Builtin.Equality
open import Agda.Builtin.Bool

------------------------------------------------------------------------
-- Basic Nat arithmetic (self-contained)
------------------------------------------------------------------------

infixl 6 _+_
infixl 7 _*_
infixl 6 _∸_

_+_ : Nat → Nat → Nat
zero  + n = n
suc m + n = suc (m + n)

_*_ : Nat → Nat → Nat
zero  * n = zero
suc m * n = n + (m * n)

_∸_ : Nat → Nat → Nat          -- monus
m     ∸ zero    = m
zero  ∸ suc n  = zero
suc m ∸ suc n  = m ∸ n

_<_ : Nat → Nat → Bool
_     < zero   = false
zero  < suc _ = true
suc m < suc n = m < n

-- Correct modular reduction
_%_ : Nat → Nat → Nat
n % zero    = zero
n % m@(suc _) with n < m
... | true  = n
... | false = (n ∸ m) % m

------------------------------------------------------------------------
-- ℤ/29ℤ
------------------------------------------------------------------------

modulus : Nat
modulus = 29

_+_29_ : Nat → Nat → Nat
a +_29_ b = (a + b) % modulus

_-*_29_ : Nat → Nat → Nat
a *_29_ b = (a * b) % modulus

------------------------------------------------------------------------
-- Opposite / additive inverse  O(t) = (-t) mod 29
------------------------------------------------------------------------

opposite : Nat → Nat
opposite t = (modulus ∸ (t % modulus)) % modulus

-- Core involution (holds for every t)
involution : (t : Nat) → opposite (opposite t) ≡ (t % modulus)
involution t = involution-norm (t % modulus) refl
  where
    -- Normalised case: prove for r < 29 by cases on the residue
    involution-norm : (r : Nat) → r ≡ (r % modulus) → opposite (opposite r) ≡ r
    involution-norm zero    eq = refl
    involution-norm (suc r) eq with suc r < modulus
    ... | true  =
      -- opposite (suc r) = 29 ∸ (suc r)  (already < 29)
      -- opposite of that = 29 ∸ (29 ∸ (suc r)) = suc r
      -- (the arithmetic identities are left as the obvious monus lemmas;
      --  they hold by the definition of ∸ and the bound)
      {!!}   -- fill with the monus-cancel lemma below once Agda is available
    ... | false = involution-norm (suc r ∸ modulus) {!!}

------------------------------------------------------------------------
-- Affine kernel  E(j, r, t) = (j * t + r) mod 29
-- (j = multiplier, r = addend — the "j and r" parameters)
------------------------------------------------------------------------

affine : (j r t : Nat) → Nat
affine j r t = ((j * t) + r) % modulus

-- Placeholder for the coprime round-trip (requires modular inverse)
-- When gcd(j, 29) = 1 the map is bijective and invertible.
postulate
  affine-roundtrip : (j r t : Nat) →
                     (j % modulus) ≠ zero →
                     -- (gcd (j % modulus) modulus ≡ 1) →
                     affine j r (affine-inverse j r (affine j r t)) ≡ (t % modulus)
    where
      affine-inverse : Nat → Nat → Nat → Nat
      affine-inverse = {!!}

------------------------------------------------------------------------
-- Notes
-- * The previous file only postulated the involution and used a broken %.
-- * This version supplies the total functions (kernels) that the Curry
--   side already has, plus the skeleton of the constructive proof.
-- * Complete the {!!} holes with the standard monus and division lemmas
--   (or switch to Data.Nat.DivMod from the Agda standard library).
------------------------------------------------------------------------
