# ==========================================================
# Script: 02_estimate_var.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Estimate the reduced-form VAR model with data-driven lag selection.
#              The script accounts for structural changes in the extended FRED dataset.
# ==========================================================

# 1. Load Libraries
library(vars)
library(dplyr)

# 2. Load and Prepare Data
data_path <- "data/processed_data.csv"
if (!file.exists(data_path)) {
  stop("Error: 'data/processed_data.csv' not found. Run 01_Data_Cleaning.R first.")
}

# Import and convert to Time Series (ts) object for better IRF handling
df_raw <- read.csv(data_path)
# Excluding the 'QTR' column if present to keep only endogenous variables
df_numeric <- df_raw %>% select(y_gap, CPI_infl, FEDFUNDS)
df_ts <- ts(df_numeric, frequency = 4) 

# 3. Lag Selection (p)
# NOTE: Fry and Pagan (2011) used p=4 for their original sample.
# For the extended dataset (including post-2008), AIC suggests p=6.
# We adopt p=6 to better capture the long-term dynamics of modern economies.
select_res <- VARselect(df_ts, lag.max = 8, type = "none")
p_opt <- as.integer(select_res$selection["AIC(n)"])
message("Optimal lag length selected via AIC: ", p_opt)

# 4. Model Estimation
# Estimation without constant/trend as data is already centered.
var_fit <- VAR(df_ts, p = p_opt, type = "none")

# 5. Stability Diagnostics
# The VAR is stable if all eigenvalues are within the unit circle.
cat("\nChecking Model Stability (Characteristic Roots):\n")
roots_val <- roots(var_fit)
print(roots_val)

if (any(roots_val >= 1)) {
  warning("Critical: The estimated VAR system is unstable.")
} else {
  message("Success: The VAR system is stable.")
}

# 6. Extraction of Variance-Covariance Matrix (Omega)
# Extracting the degree-of-freedom adjusted covariance matrix.
omega <- summary(var_fit)$covres

cat("\nDegree-of-Freedom Adjusted Omega:\n")
print(omega)

# 7. Export Results for Identification
# Saving both the model object and the adjusted Omega for Script 03.
saveRDS(list(model = var_fit, omega = omega), file = "data/var_model_fit.rds")

message("Estimation complete. Results saved to 'data/var_model_fit.rds'.")