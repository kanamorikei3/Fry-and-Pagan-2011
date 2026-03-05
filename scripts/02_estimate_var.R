# ==========================================================
# Script: 02_estimate_var.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Estimate the reduced-form VAR model and evaluate its stability.
#              The resulting variance-covariance matrix (Omega) will be used
#              for structural identification in the next step.
# ==========================================================

# 1. Load Libraries
library(vars)

# 2. Load Processed Data
# The data is expected to be demeaned (mean-corrected) in the previous script.
data_path <- "data/processed_data.csv"
if (!file.exists(data_path)) {
  stop("Error: 'data/processed_data.csv' not found. Please run 01_Data_Cleaning.R first.")
}
df <- read.csv(data_path)

# 3. Lag Selection
# Evaluating the optimal lag length (p) using Information Criteria.
# We consider up to 8 lags for quarterly frequency.
# 'type = none' is used because the data is already centered.
select_res <- VARselect(df, lag.max = 8, type = "none")
print("Information Criteria for Lag Selection:")
print(select_res$selection)

# 4. Model Estimation
# Selecting the lag length (p) suggested by the AIC (Akaike Information Criterion).
p_opt <- as.integer(select_res$selection["AIC(n)"])
var_fit <- VAR(df, p = p_opt, type = "none")

# 5. Model Stability and Diagnostics
# A VAR model is stable if all characteristic roots are within the unit circle.
cat("\nChecking Model Stability (Roots of the characteristic polynomial):\n")
roots_val <- roots(var_fit)
print(roots_val)

if (any(roots_val >= 1)) {
  warning("Warning: The estimated VAR system is unstable (at least one root >= 1).")
}

# 6. Extraction of Variance-Covariance Matrix (Omega)
# This matrix Omega represents the 'raw' correlations between reduced-form errors.
# We will decompose this into structural shocks in the next script.
e_hat <- residuals(var_fit)
omega <- cov(e_hat)

cat("\nReduced-form Variance-Covariance Matrix (Omega):\n")
print(omega)

# Save the estimated VAR object for use in IRF plotting
saveRDS(var_fit, file = "data/var_model_fit.rds")