-- CryptoInvariants.curry
-- Module implementing cryptographic verification constraints,
-- token-order inversion, spatial transformations, and proof obligations.

module CryptoInvariants where

import Affine29
import PrimeConstraints

-- Reverse a token sequence
reverseTokens :: [a] -> [a]
reverseTokens [] = []
reverseTokens (x:xs) = reverseTokens xs ++ [x]

-- Opposite transform applied element-wise across a token sequence
invertTokenStream :: [Int] -> [Int]
invertTokenStream = map opposite

-- Combined involution & reversal property:
-- Reversing twice produces the original stream
prop_reversalInvolution :: [Int] -> Bool
prop_reversalInvolution xs = reverseTokens (reverseTokens xs) == xs

-- Mapping opposite twice across any stream produces identical stream
prop_streamInvolution :: [Int] -> Bool
prop_streamInvolution xs = invertTokenStream (invertTokenStream xs) == xs

-- Magic square row/column verification helper:
-- Given a list of integers of length N*N, check that all row sums equal targetSum
verifyMagicSquareRows :: Int -> Int -> [Int] -> Bool
verifyMagicSquareRows order targetSum grid =
  length grid == order * order &&
  all (\r -> sum (take order (drop (r * order) grid)) == targetSum) [0 .. order - 1]

-- Cryptographic signature invariant validation definition:
-- A signature is formally valid only if key fingerprint matches authenticated authority
-- and algorithm matches declared packet type (e.g., RSA 4096 / SHA-512)
data VerificationStatus = VerifiedSuccess | VerificationFailed String
  deriving (Eq, Show)

data SignaturePacket = SignaturePacket
  { sigKeyId :: String
  , sigAlgorithm :: String
  , sigDigest :: String
  } deriving (Eq, Show)

verifySignaturePacket :: String -> String -> SignaturePacket -> VerificationStatus
verifySignaturePacket trustedKeyId trustedAlgo packet =
  if sigKeyId packet == trustedKeyId && sigAlgorithm packet == trustedAlgo
  then VerifiedSuccess
  else VerificationFailed "Signature invariant violation: key or algorithm mismatch"
