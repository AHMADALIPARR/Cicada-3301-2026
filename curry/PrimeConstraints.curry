-- PrimeConstraints.curry
-- Module implementing prime-index mappings and finite modular sequences
-- for Liber Primus cryptanalysis.

module PrimeConstraints where

-- The 29 primes corresponding to the 29 runes of Gematria Primus
gematriaPrimes :: [Int]
gematriaPrimes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109]

-- Map index 0..28 to prime value
indexToPrime :: Int -> Int
indexToPrime idx =
  if idx >= 0 && idx < 29
  then gematriaPrimes !! idx
  else error "Index out of Gematria Primus range"

-- Prime-index mapping modulo 29: P(idx) mod 29
primeMod29 :: Int -> Int
primeMod29 idx = (indexToPrime idx) `mod` 29

-- Modular stream keystream generation from prime sequences
primeKeystream :: Int -> [Int]
primeKeystream len = take len (map (`mod` 29) (cycle gematriaPrimes))

-- Check whether an integer is prime
isPrime :: Int -> Bool
isPrime n
  | n <= 1    = False
  | n <= 3    = True
  | otherwise = null [x | x <- [2 .. intSqrt n], n `mod` x == 0]
  where
    intSqrt m = floorSqrt m 1
    floorSqrt target curr
      | curr * curr > target = curr - 1
      | otherwise            = floorSqrt target (curr + 1)

-- Verify that all 29 gematria values are prime numbers
prop_allGematriaPrimesArePrime :: Bool
prop_allGematriaPrimesArePrime = all isPrime gematriaPrimes

-- Totient function for prime p: phi(p) = p - 1
totientPrime :: Int -> Int
totientPrime p =
  if isPrime p then p - 1 else error "totientPrime requires prime argument"
