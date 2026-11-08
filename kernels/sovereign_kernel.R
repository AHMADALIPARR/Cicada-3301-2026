# sovereign_kernel.R
# Pure base-R kernel for deterministic integer training and DAG state-folding
# Zero dependencies. No external packages.

# Deterministic integer matrix multiplication
sovereign_matmul <- function(A, B) {
  # Enforce integer typing to prevent floating point drift
  storage.mode(A) <- "integer"
  storage.mode(B) <- "integer"
  return(A %*% B)
}

# Radix-scaled residual projection fold
# Computes the projection fold matching the exact routed prediction head
radix_scaled_fold <- function(residuals, base = 10L) {
  storage.mode(residuals) <- "integer"
  scale_factors <- as.integer(base ^ (seq_along(residuals) - 1))
  return(sum(residuals * scale_factors))
}

# Explicit backward DAG node reduction
# Transposes the forward activation to compute the exact gradient match
backward_dag_node <- function(upstream_gradient, forward_activation) {
  grad_update <- sovereign_matmul(upstream_gradient, t(forward_activation))
  return(grad_update)
}

# Integer training step evaluation returning max absolute error
evaluate_training_step <- function(W_frozen, X, Y_target, learning_rate = 1L) {
  # Forward reduction pass
  Y_pred <- sovereign_matmul(W_frozen, X)
  
  # Calculate exact absolute error
  error <- Y_pred - Y_target
  
  # Backward pass mapping to DAG node
  gradient <- backward_dag_node(error, X)
  
  # Update step
  W_updated <- W_frozen - (learning_rate * gradient)
  
  return(list(
    W_new = W_updated,
    max_abs_error = max(abs(error))
  ))
}
