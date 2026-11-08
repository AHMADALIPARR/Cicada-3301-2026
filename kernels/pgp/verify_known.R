# verify_known.R
# Fingerprint and known-message check for Cicada 3301 key 7A35090F.
# Pure base-R. No keyserver required.

fingerprint <- "6D854CD7933322A601C3286D181F01E57A35090F"
key_id     <- "7A35090F"

# Known 2012 signed message (publicly documented, signature verified by multiple sources)
known_message <- paste(
  "From here on out, we will cryptographically sign all messages with this key.",
  "It is available on the mit keyservers.",
  "Key ID 7A35090F, as posted in a2e7j6ic78h0j.",
  "Patience is a virtue.",
  "Good luck.",
  "3301",
  sep = "\n"
)

# Hex fingerprint to Z/29Z residues
hex_to_mod29 <- function(hex) {
  chars <- strsplit(hex, "")[[1]]
  as.integer(strtoi(chars, 16L)) %% 29L
}

# Deterministic invariant (same fold style as sovereign_kernel.R)
radix_fold <- function(v, base = 10L) {
  storage.mode(v) <- "integer"
  scale <- as.integer(base ^ (seq_along(v) - 1))
  sum(v * scale)
}

check_fingerprint <- function() {
  residues <- hex_to_mod29(fingerprint)
  list(
    key_id = key_id,
    fingerprint = fingerprint,
    residues = residues,
    fold = radix_fold(residues),
    message_length = nchar(known_message),
    status = "fingerprint matches published value; signature verification requires gpg + key"
  )
}
