# ==========================================================
# Script: 04_plot_irf.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Calculate and visualize Impulse Response Functions (IRFs)
#              using the representative model selected by the MT method.
# ==========================================================

# 1. Environment Setup and Data Loading
library(vars)

# Load estimated VAR model and MT identification results
if (!file.exists("data/var_model_fit.rds") || !file.exists("data/mt_results.RData")) {
  stop("Error: Required data files not found. Please run scripts 01-03 first.")
}

var_fit <- readRDS("data/var_model_fit.rds")
load("data/mt_results.RData") # Loads best_B, best_Q, horizon, n_vars

# Extract variable names and lag length
varnames <- colnames(var_fit$y)
p_opt    <- var_fit$p

# 2. Impulse Response Function (IRF) Calculation
# We perform a recursive simulation based on the structural matrix (best_B)
# Formula: IRF(h) = sum_{p=1}^P (Phi_p * IRF(h-p))
irf_mt <- array(0, dim = c(horizon + 1, n_vars, n_vars))
irf_mt[1, , ] <- best_B # Set Impact Response (h=0)

# Extract reduced-form coefficient matrices [n_vars x (n_vars * p)]
phi_matrices <- Bcoef(var_fit) 

for (h in 2:(horizon + 1)) {
  for (p in 1:p_opt) {
    if (h - p > 0) {
      # Extract the p-th lag coefficient matrix
      Ap <- phi_matrices[, ((p-1)*n_vars + 1):(p*n_vars)]
      irf_mt[h, , ] <- irf_mt[h, , ] + Ap %*% irf_mt[h-p, , ]
    }
  }
}

# 3. Plotting and Exporting
# We visualize the responses to the identified Monetary Policy shock (Shock 3).
if (!dir.exists("output")) dir.create("output")

# Open graphic device for high-quality PNG export
file_name <- "output/irf_mp_shock_mt.png"
png(file_name, width = 1200, height = 450, res = 120)

# Set plotting layout (1 row, 3 columns)
par(mfrow = c(1, 3), mar = c(4.5, 4.5, 3, 1)) 

for (v in 1:n_vars) {
  # Plot IRF for variable v in response to shock 3
  plot(0:horizon, irf_mt[, v, 3], type = "l", col = "blue", lwd = 2.5,
       main = paste("Response of", varnames[v], "\nto MP Shock"),
       xlab = "Quarters Ahead", ylab = "Response",
       cex.main = 1.1, cex.lab = 1.0)
  
  # Add horizontal reference line at zero
  abline(h = 0, lty = 2, col = "red", lwd = 1.2) 
}

# Close the device and save the file
dev.off()

message("Success: IRF plot has been saved to '", file_name, "'.")
