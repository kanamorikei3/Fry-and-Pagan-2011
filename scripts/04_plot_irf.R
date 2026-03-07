# ==========================================================
# Script: 04_plot_irf.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Calculate and visualize Impulse Response Functions (IRFs)
#              using the VMA representation and the MT representative model.
#              This script incorporates optimized matrix operations for efficiency.
# ==========================================================

# 1. Setup and Loading
library(vars)

# Load identification results and the estimated model from Script 03
if (!file.exists("data/mt_results.RData")) {
  stop("Error: 'mt_results.RData' not found. Please run Script 01-03 first.")
}
load("data/mt_results.RData") 
# Loads: best_B, best_Q, horizon, var_fit

n_vars   <- var_fit$K
varnames <- colnames(var_fit$y)

# 2. Impulse Response Function (IRF) Calculation
# Instead of manual recursion, we use the VMA (Vector Moving Average) representation.
# Phi() computes the coefficient matrices of the VMA representation of a stable VAR.
phi_array <- Phi(var_fit, nstep = horizon)

# Initialize array for structural IRFs: [horizon+1, n_vars, n_vars]
irf_mt <- array(0, dim = c(horizon + 1, n_vars, n_vars))

# For each step h, the structural IRF is calculated as: IRF_h = Phi_h %*% B
for (h in 1:(horizon + 1)) {
  # phi_array is [n_vars, n_vars, horizon+1]
  irf_mt[h, , ] <- phi_array[, , h] %*% best_B
}

# 3. Visualization and Export
# Focusing on the Monetary Policy (MP) shock identified in the 3rd column (FEDFUNDS).
mp_shock_index <- 3 

if (!dir.exists("output")) dir.create("output")
file_path <- "output/irf_mp_shock_mt.png"

# Setup high-resolution PNG device
png(file_path, width = 1200, height = 450, res = 120)

# Layout: 1 row, 3 columns (matching the number of variables)
par(mfrow = c(1, n_vars), mar = c(4.5, 4.5, 3, 1)) 

for (v in 1:n_vars) {
  # Plotting structural responses across the horizon
  plot(0:horizon, irf_mt[, v, mp_shock_index], 
       type = "l", col = "blue", lwd = 2.5,
       main = paste("Response of", varnames[v], "\nto MP Shock"),
       xlab = "Quarters Ahead", ylab = "Response (Annual %)",
       cex.main = 1.1, cex.lab = 1.0)
  
  # Add zero reference line
  abline(h = 0, lty = 2, col = "red", lwd = 1.2) 
}

dev.off()
message("Final IRF visualization successful. Plot saved to: ", file_path)