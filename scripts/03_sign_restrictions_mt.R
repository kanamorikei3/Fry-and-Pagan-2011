# ==========================================================
# Script: 03_sign_restrictions_mt.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Identification of structural shocks using Sign Restrictions.
#              Implements the Haar-measure-consistent QR decomposition (Rubio-Ramirez et al., 2010)
#              and the standardized Median Target (MT) method (Fry and Pagan, 2011).
# ==========================================================

# 1. Setup and Data Loading
set.seed(123) 
n_reps  <- 5000  # Number of simulation draws
horizon <- 20    # IRF horizon for subsequent plotting

# Load the estimated VAR results (var_fit and omega) from Script 02
if (!file.exists("data/var_model_fit.rds")) {
  stop("Error: 'var_model_fit.rds' not found. Please run 02_estimate_var.R first.")
}
var_results <- readRDS("data/var_model_fit.rds")
var_fit <- var_results$model
omega   <- var_results$omega

n_vars <- var_fit$K 
P      <- t(chol(omega)) # Cholesky factor (Lower triangular)

# Containers for models that satisfy sign restrictions
accepted_B <- list()
accepted_Q <- list()

# 2. Sign Restriction Simulation (Algorithm: Rubio-Ramirez et al., 2010)
message("Executing Sign Restriction checks (Iterations: ", n_reps, ")...")

for (i in 1:n_reps) {
  # (1) Generate a random orthogonal matrix Q using QR decomposition
  X <- matrix(rnorm(n_vars^2), n_vars, n_vars)
  qr_X <- qr(X)
  Q <- qr.Q(qr_X)
  R <- qr.R(qr_X)
  
  # Ensure Q is drawn from a uniform Haar distribution by adjusting signs
  # This step is critical for unbiased structural identification.
  Q <- Q %*% diag(sign(diag(R)))
  
  # Contemporaneous structural impact matrix: B = P * Q
  B <- P %*% Q
  
  # (2) Define Sign Restrictions for a Monetary Policy (MP) Shock
  # Assumed variable order: 1:y_gap, 2:CPI_infl, 3:FEDFUNDS
  # Restriction: Shock to FEDFUNDS (Column 3)
  cond_int  <- B[3,3] > 0  # Interest rate (FEDFUNDS) increases
  cond_gap  <- B[1,3] < 0  # Output (y_gap) decreases
  cond_infl <- B[2,3] < 0  # Inflation (CPI_infl) decreases
  
  if (cond_int && cond_gap && cond_infl) {
    accepted_B[[length(accepted_B) + 1]] <- B
    accepted_Q[[length(accepted_Q) + 1]] <- Q
  }
}

n_accepted <- length(accepted_B)
message("Identification successful. Accepted models: ", n_accepted)

# 3. Median Target (MT) Selection (Fry and Pagan, 2011)
# Selecting the single model closest to the pointwise medians, 
# standardized by the standard deviation of each response to account for scale differences.
if (n_accepted > 0) {
  # Convert list of matrices into a single numeric matrix [ (n_vars^2) x n_accepted ]
  all_B_values <- do.call(cbind, lapply(accepted_B, as.numeric))
  
  # Calculate pointwise medians and standard deviations across accepted models
  pointwise_medians <- apply(all_B_values, 1, median)
  pointwise_sd      <- apply(all_B_values, 1, sd)
  
  # Guard against division by zero (for restricted elements with zero variance)
  pointwise_sd[pointwise_sd < 1e-10] <- 1e-10
  
  # Calculate Standardized MSE (Distance) for each model i:
  # Distance_i = sum( [(B_i,j - median_j) / sd_j]^2 )
  mse_distances <- apply(all_B_values, 2, function(x) {
    sum(((x - pointwise_medians) / pointwise_sd)^2)
  })
  
  # Select the 'Representative Model' (Median Target)
  best_index <- which.min(mse_distances)
  best_B     <- accepted_B[[best_index]]
  best_Q     <- accepted_Q[[best_index]]
  
  message("MT selection complete. Best model index: ", best_index)
  
  # Export the unique structural shock parameters for Script 04
  save(best_B, best_Q, horizon, var_fit, file = "data/mt_results.RData")
  
} else {
  stop("Zero models accepted. Try increasing n_reps or reviewing sign logic.")
}