-- Affine29.curry
-- Module implementing modular arithmetic over Z_29 and affine transformations
-- for the 29-symbol Gematria Primus system.

module Affine29 where

-- Base 29 modulus
modulus :: Int
modulus = 29

-- Modular addition
modAdd :: Int -> Int -> Int
modAdd a b = (a + b) `mod` modulus

-- Modular subtraction
modSub :: Int -> Int -> Int
modSub a b = (a - b + modulus) `mod` modulus

-- Modular multiplication
modMul :: Int -> Int -> Int
modMul a b = (a * b) `mod` modulus

-- Opposite / Inversion transformation: O(t) = (-t) mod 29
opposite :: Int -> Int
opposite t = (modulus - (t `mod` modulus)) `mod` modulus

-- Affine transformation: E(a, b, t) = (a * t + b) mod 29
affineEncrypt :: Int -> Int -> Int -> Int
affineEncrypt a b t = (a * t + b) `mod` modulus

-- Extended Euclidean Algorithm to find modular inverse
modInverse :: Int -> Int -> Int
modInverse a m = extEuclid (a `mod` m) m 1 0
  where
    extEuclid 0 _ _ _ = error "Modular inverse does not exist"
    extEuclid 1 _ x _ = (x `mod` m + m) `mod` m
    extEuclid a' b' x0 x1 =
      let q = b' `div` a'
          r = b' `mod` a'
          xNext = x1 - q * x0
      in if r == 0
         then if a' == 1 then (x0 `mod` m + m) `mod` m else error "Modular inverse does not exist"
         else extEuclid r a' xNext x0

-- Affine decryption: D(a, b, c) = a^(-1) * (c - b) mod 29
affineDecrypt :: Int -> Int -> Int -> Int
affineDecrypt a b c =
  let aInv = modInverse a modulus
  in (aInv * ((c - b + modulus) `mod` modulus)) `mod` modulus

-- Involution property: O(O(t)) == t
prop_involution :: Int -> Bool
prop_involution t =
  let normT = t `mod` modulus
  in opposite (opposite normT) == normT

-- Affine round-trip property: D(a, b, E(a, b, t)) == t
prop_affineRoundTrip :: Int -> Int -> Int -> Bool
prop_affineRoundTrip a b t =
  let normT = t `mod` modulus
      coprime = (a `mod` modulus) /= 0 && gcd (a `mod` modulus) modulus == 1
  in if coprime
     then affineDecrypt a b (affineEncrypt a b normT) == normT
     else True
