# mercury_dag_pgp.R
# DAG integer reduction of the Cicada 3301 PGP fingerprint
# Pure base-R. Zero external dependencies.
# Maps the 40-hex fingerprint to Z/29Z residues and applies
# the same radix-scaled fold used in sovereign_kernel.R.

# Authentic Cicada 3301 key material (public)
key_id     <- "7A35090F"
fingerprint <- "6D854CD7933322A601C3286D181F01E57A35090F"

# Convert hex fingerprint to integer vector
hex_to_ints <- function(hex) {
  chars <- strsplit(hex, "")[[1]]
  as.integer(strtoi(chars, 16L))
}

# Map to Z/29Z residues (same field as Liber Primus)
to_mod29 <- function(v) {
  storage.mode(v) <- "integer"
  v %% 29L
}

# Radix-scaled fold (identical to sovereign_kernel.R)
radix_scaled_fold <- function(residuals, base = 10L) {
  storage.mode(residuals) <- "integer"
  scale_factors <- as.integer(base ^ (seq_along(residuals) - 1))
  sum(residuals * scale_factors)
}

# Explicit backward DAG node on the fingerprint tensor
# Treats the fingerprint as a 1-D activation and applies
# the same matmul-style reduction used for gradients.
backward_dag_fingerprint <- function(fp_mod) {
  # Outer product style reduction (rank-1 update)
  n <- length(fp_mod)
  grad <- matrix(0L, n, n)
  for (i in seq_len(n)) {
    grad[i, ] <- fp_mod[i] * fp_mod
  }
  storage.mode(grad) <- "integer"
  grad
}

# Full evaluation: produce deterministic invariant
evaluate_pgp_dag <- function() {
  raw <- hex_to_ints(fingerprint)
  mod <- to_mod29(raw)
  fold <- radix_scaled_fold(mod)
  dag  <- backward_dag_fingerprint(mod)
  list(
    key_id = key_id,
    fingerprint = fingerprint,
    residues = mod,
    radix_fold = fold,
    dag_trace = sum(diag(dag)),
    max_abs = max(abs(mod))
  )
}
