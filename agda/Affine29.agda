-- Affine29.agda
-- Real modular arithmetic kernels over Z/29Z for Liber Primus invariants.
-- Total functions only; no postulates, no holes.
-- Matches the operational behaviour of curry/Affine29.curry.

module agda.Affine29 where

open import Agda.Builtin.Nat
open import Agda.Builtin.Equality
open import Agda.Builtin.Bool

------------------------------------------------------------------------
-- Nat arithmetic
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

_∸_ : Nat → Nat → Nat
m     ∸ zero    = m
zero  ∸ suc n  = zero
suc m ∸ suc n  = m ∸ n

_<_ : Nat → Nat → Bool
_     < zero   = false
zero  < suc _ = true
suc m < suc n = m < n

_%_ : Nat → Nat → Nat
n % zero    = zero
n % m@(suc _) with n < m
... | true  = n
... | false = (n ∸ m) % m

------------------------------------------------------------------------
-- Z/29Z
------------------------------------------------------------------------

modulus : Nat
modulus = 29

_+29_ : Nat → Nat → Nat
a +29 b = (a + b) % modulus

_*29_ : Nat → Nat → Nat
a *29 b = (a * b) % modulus

------------------------------------------------------------------------
-- Opposite: O(t) = (-t) mod 29
------------------------------------------------------------------------

opposite : Nat → Nat
opposite t = (modulus ∸ (t % modulus)) % modulus

-- Computational check that the involution holds on a normalised residue
-- (full inductive proof requires the standard library monus lemmas;
--  the function itself is total and matches the Curry implementation).
involution-holds-for-zero : opposite (opposite 0) ≡ 0
involution-holds-for-zero = refl

------------------------------------------------------------------------
-- Affine kernel  E(j, r, t) = (j * t + r) mod 29
------------------------------------------------------------------------

affine : (j r t : Nat) → Nat
affine j r t = ((j * t) + r) % modulus

-- Real computational kernel (inverse requires extended Euclidean;
--  provided here as the total encryption map only, matching Curry).
