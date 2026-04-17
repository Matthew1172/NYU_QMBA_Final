# ============================
# 0. LOAD PACKAGES + DATA
# ============================

library(readxl)
library(dplyr)

data <- read_excel("~/Desktop/MASY1-GC 1015/Revised Project Customer Dataset 1.xlsx")

# Quick check
head(data)
str(data)

# ============================
# 1. VALIDATION CHECKS (ORIGINAL DATA)
# ============================

# Missing values
colSums(is.na(data))

# Data types
str(data)

# Car Value < 1000
sum(data$`Car Value` < 1000, na.rm = TRUE)

# Education Years >= Age (invalid)
sum(data$`Education Years` >= data$Age, na.rm = TRUE)

# Employment Years >= Age - 14 (invalid)
sum(data$`Employment Years` >= (data$Age - 14), na.rm = TRUE)

# Negative values
sum(data$`Employment Years` < 0, na.rm = TRUE)
sum(data$`Education Years` < 0, na.rm = TRUE)
sum(data$`Household Income` <= 0, na.rm = TRUE)

# Cumulative vs Monthly issues
sum(data$`Cumulative Spend ProductA` <= data$`Monthly Spend ProductA`, na.rm = TRUE)
sum(data$`Cumulative Spend ProductB` <= data$`Monthly Spend ProductB`, na.rm = TRUE)
sum(data$`Cumulative Spend ProductC` <= data$`Monthly Spend ProductC`, na.rm = TRUE)

# Duplicates
sum(duplicated(data$CustomerID))

# ============================
# 2. STRICT CLEANING DATASET
# ============================

clean_data_strict <- data %>%
  
  # Fix column name
  rename(`Number Pets` = `umber Pets`) %>%
  
  # Remove ALL missing values
  na.omit() %>%
  
  # Trim spaces
  mutate(across(where(is.character), trimws)) %>%
  
  # Convert Yes/No → 1/0
  mutate(
    `Streaming Svcs` = ifelse(`Streaming Svcs` == "Yes", 1, 0),
    `Wireless Internet` = ifelse(`Wireless Internet` == "Yes", 1, 0),
    `News Subscriber` = ifelse(`News Subscriber` == "Yes", 1, 0),
    `Active Lifestyle` = ifelse(`Active Lifestyle` == "Yes", 1, 0),
    Retired = ifelse(Retired == "Yes", 1, 0)
  ) %>%
  
  # STRICT RULES
  filter(
    `Car Value` >= 1000,
    Age >= 18 & Age <= 80,
    `Education Years` > 0 & `Education Years` < Age,
    `Employment Years` >= 0 & `Employment Years` < (Age - 14),
    `Household Income` > 0
  ) %>%
  
  # STRICT cumulative checks
  filter(
    `Cumulative Spend ProductA` > `Monthly Spend ProductA`,
    `Cumulative Spend ProductB` > `Monthly Spend ProductB`,
    `Cumulative Spend ProductC` > `Monthly Spend ProductC`
  ) %>%
  
  # Remove duplicates
  distinct(CustomerID, .keep_all = TRUE)

# ============================
# 3. CHECK FINAL CLEAN DATA
# ============================

# Row count
nrow(clean_data_strict)

# Structure
str(clean_data_strict)

# Summary stats
summary(clean_data_strict)
