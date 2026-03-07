# ==========================================================
# Script: 01_load_data.R
# Project: Replication of Sign Restrictions in SVAR (Fry and Pagan, 2011)
# Description: Advanced data processing using tidyverse and zoo.
#              Includes frequency conversion, annualization, and detrending.
# ==========================================================

# 1. Load Required Libraries
library(mFilter)   # For HP filter
library(tidyverse) # For modern data manipulation
library(zoo)       # For yearqtr frequency handling

# 2. Data Ingestion with Schema Enforcement
# Suppressing messages and ensuring correct naming at the start
load_fred_data <- function(file_name, new_col_name) {
  read_csv(paste0("data/", file_name), show_col_types = FALSE) %>%
    rename(DATE = 1, !!new_col_name := 2)
}

gdp_raw <- load_fred_data("GDPC1.csv", "GDPC1")
cpi_raw <- load_fred_data("CPIAUCSL.csv", "CPI")
fed_raw <- load_fred_data("FEDFUNDS.csv", "FEDFUNDS")

# 3. Frequency Conversion (Monthly Average to Quarterly)
# Monthly CPI and FEDFUNDS are averaged over each quarter.
# GDP is usually already quarterly, but as.yearqtr() ensures synchronization.
cpi_q <- cpi_raw %>%
  mutate(QTR = as.yearqtr(DATE)) %>%
  group_by(QTR) %>%
  summarise(CPI = mean(CPI, na.rm = TRUE), .groups = "drop")

fed_q <- fed_raw %>%
  mutate(QTR = as.yearqtr(DATE)) %>%
  group_by(QTR) %>%
  summarise(FEDFUNDS = mean(FEDFUNDS, na.rm = TRUE), .groups = "drop")

gdp_q <- gdp_raw %>%
  mutate(QTR = as.yearqtr(DATE))

# Inner join to ensure balanced sample across all variables
combined_data <- gdp_q %>%
  inner_join(cpi_q, by = "QTR") %>%
  inner_join(fed_q, by = "QTR") %>%
  arrange(QTR)

# 4. Variable Transformation
# Inflation is calculated as annualized log-difference: (log(P_t) - log(P_{t-1})) * 400
# GDP gap is extracted using the cyclical component of the HP filter (lambda=1600)
combined_data <- combined_data %>%
  mutate(
    CPI_infl = (log(CPI) - log(lag(CPI))) * 400,
    gdp_log  = log(GDPC1)
  ) %>%
  drop_na()

# HP Filter Application
hp_res <- hpfilter(combined_data$gdp_log, freq = 1600)
combined_data$y_gap <- as.numeric(hp_res$cycle)

# 5. Final Scaling (Demeaning)
# Applying Mean Correction (scale=FALSE) for the VAR estimation.
final_data <- combined_data %>%
  select(y_gap, CPI_infl, FEDFUNDS) %>%
  mutate(across(everything(), ~ as.numeric(scale(., scale = FALSE))))

# 6. Export and Logging
if (!dir.exists("data")) dir.create("data")
write_csv(final_data, "data/processed_data.csv")

message("Data processing complete. The final dataset has ", nrow(final_data), " observations.")