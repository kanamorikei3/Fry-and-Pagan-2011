# ==========================================================
# Script: 01_Data_Cleaning.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Data loading, cleaning, and preprocessing for SVAR analysis.
#              This includes HP-filtering for the Output Gap and 
#              calculating inflation rates.
# ==========================================================

# 1. Load Libraries
library(mFilter)  # For HP filter
library(vars)     # For VAR model utilities
library(readr)    # For robust CSV reading

# 2. Load Raw Data
# Data sourced from FRED (Federal Reserve Economic Data)
# Required files: GDPC1.csv, CPIAUCSL.csv, FEDFUNDS.csv
gdp_raw  <- read_csv("data/GDPC1.csv", show_col_types = FALSE)
cpi_raw  <- read_csv("data/CPIAUCSL.csv", show_col_types = FALSE)
fed_raw  <- read_csv("data/FEDFUNDS.csv", show_col_types = FALSE)

# 3. Data Integration and Transformation
# Standardize column names for merging
colnames(gdp_raw) <- c("DATE", "GDPC1")
colnames(cpi_raw) <- c("DATE", "CPI")
colnames(fed_raw) <- c("DATE", "FEDFUNDS")

# Merge datasets by DATE (Common frequency: Quarterly)
# Note: Ensure all series are converted to the same frequency if necessary.
combined_data <- merge(merge(gdp_raw, cpi_raw, by = "DATE"), fed_raw, by = "DATE")

# Calculate Inflation Rate (Quarter-on-Quarter Log-Difference, Percentage)
# Formula: pi_t = [log(CPI_t) - log(CPI_{t-1})] * 100
combined_data$CPI_infl <- c(NA, diff(log(combined_data$CPI))) * 100

# 4. Detrending (HP Filter)
# Extract the cyclical component (Output Gap) from Log Real GDP.
# lambda = 1600 is the standard setting for quarterly data.
gdp_log <- log(combined_data$GDPC1)
gdp_hp  <- hpfilter(gdp_log, freq = 1600)

# Extract the cycle component as Output Gap
combined_data$y_gap <- as.numeric(gdp_hp$cycle)

# 5. Final Dataset Preparation
# Variables: Output Gap (y_gap), Inflation (CPI_infl), Interest Rate (FEDFUNDS)
# Removing the first row (NA due to diff) to ensure a balanced sample.
final_data <- na.omit(combined_data[, c("DATE", "y_gap", "CPI_infl", "FEDFUNDS")])

# 6. Mean Correction (Demeaning)
# As per Fry and Pagan (2011), variables are centered before estimation.
# We remove the first column (DATE) for calculation.
final_data_centered <- scale(as.matrix(final_data[, -1]), scale = FALSE)

# Convert back to data frame for easier handling in subsequent scripts
final_data_final <- as.data.frame(final_data_centered)

# 7. Export Processed Data
if (!dir.exists("data")) dir.create("data")
write.csv(final_data_final, "data/processed_data.csv", row.names = FALSE)

message("Pre-processing complete. Processed data saved to 'data/processed_data.csv'.")