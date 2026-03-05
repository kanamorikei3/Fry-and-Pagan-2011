# ==========================================================
# Script: 03_sign_restrictions_mt.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Identification of structural shocks using Sign Restrictions.
#              The script implements the Median Target (MT) method to select
#               a single representative model that avoids the "pointwise median" trap.
# ==========================================================

# 1. Setup and Data Loading
set.seed(123) # For reproducibility
n_reps  <- 5000  # Number of iterations for the simulation
horizon <- 20    # IRF horizon

# Load the estimated VAR model from Script 02
if (!file.exists("data/var_model_fit.rds")) {
  stop("Error: 'var_model_fit.rds' not found. Please run 02_estimate_var.R first.")
}
var_fit <- readRDS("data/var_model_fit.rds")

# Extract basic model parameters
n_vars <- ncol(var_fit$y)
omega  <- cov(residuals(var_fit))
P      <- t(chol(omega)) # Cholesky factor (Lower triangular) such that P*P' = Omega

# Containers for accepted models
accepted_B <- list()
accepted_Q <- list()

# 2. Sign Restriction Simulation
# We identify a Monetary Policy (MP) shock using impact restrictions (h=0).
# Restrictions: FEDFUNDS (+) / CPI_infl (-) / y_gap (-)
message("Starting Sign Restriction checks (Iterations: ", n_reps, ")...")

for (i in 1:n_reps) {
  # (1) Generate a random orthogonal matrix Q using QR decomposition
  X <- matrix(rnorm(n_vars^2), n_vars, n_vars)
  Q <- qr.Q(qr(X))
  
  # Ensure Q is truly orthogonal and the transformation preserves Omega
  # B = P * Q  => B*B' = (P*Q)(P*Q)' = P*P' = Omega
  B <- P %*% Q
  
  # (2) Define Sign Restrictions for the MP shock (Assume 3rd column is MP)
  # Variables order: 1:y_gap, 2:CPI_infl, 3:FEDFUNDS
  cond_int  <- B[3,3] > 0  # Interest rate increases
  cond_gap  <- B[1,3] < 0  # Output gap decreases
  cond_infl <- B[2,3] < 0  # Inflation decreases
  
  # Check if the generated model satisfies all conditions
  if (cond_int && cond_gap && cond_infl) {
    accepted_B[[length(accepted_B) + 1]] <- B
    accepted_Q[[length(accepted_Q) + 1]] <- Q
  }
}

n_accepted <- length(accepted_B)
message("Number of accepted models: ", n_accepted)

# 3. Median Target (MT) Selection
# Fry and Pagan (2011) propose selecting the single model closest to the pointwise medians.
if (n_accepted > 0) {
  # Flatten the B matrices into a single matrix for comparison
  all_B_values <- do.call(cbind, lapply(accepted_B, as.numeric))
  
  # Calculate pointwise medians across all accepted models
  pointwise_medians <- apply(all_B_values, 1, median)
  
  # Calculate the Mean Squared Error (MSE) for each model relative to the median
  # distance = sum((B_i - median)^2)
  mse_distances <- apply(all_B_values, 2, function(x) sum((x - pointwise_medians)^2))
  
  # Identify the "Best" model index (the one with the minimum distance)
  best_index <- which.min(mse_distances)
  
  best_B <- accepted_B[[best_index]]
  best_Q <- accepted_Q[[best_index]]
  
  message("Median Target selection complete. Representative B matrix found.")
  print(best_B)
  
  # Save the best model parameters for plotting
  save(best_B, best_Q, horizon, n_vars, file = "data/mt_results.RData")
  
} else {
  stop("Zero models accepted. Consider relaxing restrictions or increasing n_reps.")
}