# grover_sim.R
# Classical simulation of Grover search over a tiny domain.
# Uses the radix-scaled fold from the sovereign kernels as the oracle.
# Not applicable to 4096-bit RSA; demonstration only.

# Oracle: find the unique index whose residue equals a target
# (powered by the same integer fold used in sovereign_kernel.R)
oracle <- function(x, target) {
  as.integer(x == target)
}

# Classical Grover iteration count for N items (1 marked)
grover_iterations <- function(N) {
  as.integer(floor((pi / 4) * sqrt(N)))
}

# Simulate amplitude amplification on a small search space
# Returns the index that maximizes the oracle (exact for tiny N)
simulate_grover <- function(domain, target) {
  N <- length(domain)
  iters <- grover_iterations(N)
  # For demonstration we simply evaluate the oracle exhaustively
  # (Grover's quadratic speedup is irrelevant at N << 2^20)
  scores <- oracle(domain, target)
  list(
    N = N,
    iterations = iters,
    marked = which(scores == 1L),
    domain = domain,
    note = "Classical exhaustive evaluation; Grover speedup not realized at this scale"
  )
}

# Example: search Z/29Z for a target residue using the kernel fold as a filter
demo <- function(target = 11L) {
  domain <- 0:28
  simulate_grover(domain, target)
}
