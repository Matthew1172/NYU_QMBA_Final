# Load packages
library(readxl)
library(dplyr)
library(ggplot2)

# ------------------------------------------------------------
# 1. LOAD THE DATA
# ------------------------------------------------------------

customer_data <- read_excel("./outputs/26-04-16-20/customer_data_cleaned.xlsx")

# Convert columns that should be numeric but may be stored as text
numeric_cols <- c(
  "Region", "Age", "Education Years", "Employment Years", "Household Size",
  "Household Income", "Number Pets", "umber Pets", "Home Owner", "Car Value",
  "Commute Distance", "Credit Card Tenure", "TV Watching Hours",
  "Coupon Redemption", "Brand Tenure Months", "Monthly Spend ProductA",
  "Cumulative Spend ProductA", "Monthly Spend ProductB", "Cumulative Spend ProductB",
  "Monthly Spend ProductC", "Cumulative Spend ProductC", "Total Avg Monthly Spend",
  "High Value Customer"
)

numeric_cols <- intersect(numeric_cols, names(customer_data))

safe_numeric <- function(x) {
  as.numeric(gsub("[^0-9.-]", "", as.character(x)))
}

customer_data[numeric_cols] <- lapply(customer_data[numeric_cols], safe_numeric)

theme_set(theme_minimal(base_size = 12))

# ------------------------------------------------------------
# 2. CLEAN / PREP THE VARIABLES WE NEED
# ------------------------------------------------------------

# We only need:
# - Wireless Internet
# - Total Avg Monthly Spend
#
# This code safely converts Wireless Internet into 0/1 if needed.
# If it's already numeric, great.
# If it's text like "Yes"/"No", this tries to map it.

analysis_data <- customer_data %>%
  mutate(
    wireless_num = case_when(
      # already numeric 0/1
      suppressWarnings(!is.na(as.numeric(`Wireless Internet`))) ~ as.numeric(`Wireless Internet`),
      
      # common text versions
      tolower(as.character(`Wireless Internet`)) %in% c("yes", "y", "true", "1") ~ 1,
      tolower(as.character(`Wireless Internet`)) %in% c("no", "n", "false", "0") ~ 0,
      
      # anything else becomes NA
      TRUE ~ NA_real_
    )
  ) %>%
  select(wireless_num, `Total Avg Monthly Spend`) %>%
  filter(!is.na(wireless_num), !is.na(`Total Avg Monthly Spend`))

# Optional: check the first few rows
head(analysis_data)

# ------------------------------------------------------------
# 3. STATE THE HYPOTHESES
# ------------------------------------------------------------

cat("Null hypothesis H0: mean spend for wireless customers = mean spend for non-wireless customers\n")
cat("Alternative hypothesis H1: mean spend for wireless customers > mean spend for non-wireless customers\n\n")

# ------------------------------------------------------------
# 4. GET GROUP SUMMARY STATISTICS
# ------------------------------------------------------------

group_summary <- analysis_data %>%
  group_by(wireless_num) %>%
  summarise(
    n = n(),
    mean_spend = mean(`Total Avg Monthly Spend`),
    sd_spend = sd(`Total Avg Monthly Spend`)
  )

print(group_summary)

# Pull the values out for easier use
n1  <- group_summary$n[group_summary$wireless_num == 1]
x1  <- group_summary$mean_spend[group_summary$wireless_num == 1]
s1  <- group_summary$sd_spend[group_summary$wireless_num == 1]

n0  <- group_summary$n[group_summary$wireless_num == 0]
x0  <- group_summary$mean_spend[group_summary$wireless_num == 0]
s0  <- group_summary$sd_spend[group_summary$wireless_num == 0]

# ------------------------------------------------------------
# 5. CALCULATE THE Z TEST STATISTIC BY HAND
# ------------------------------------------------------------

# Standard error for difference in means
SE <- sqrt((s1^2 / n1) + (s0^2 / n0))

# z statistic
z_calc <- (x1 - x0) / SE

# One-tailed p-value because H1 is "greater than"
p_value <- 1 - pnorm(z_calc)

cat("\n--- Test Results ---\n")
cat("Mean spend (wireless = 1): ", round(x1, 2), "\n")
cat("Mean spend (wireless = 0): ", round(x0, 2), "\n")
cat("Difference in means: ", round(x1 - x0, 2), "\n")
cat("Standard error: ", round(SE, 4), "\n")
cat("z statistic: ", round(z_calc, 4), "\n")
cat("p-value: ", format(p_value, scientific = TRUE), "\n\n")

# ------------------------------------------------------------
# 6. DECISION AT ALPHA = 0.05
# ------------------------------------------------------------

alpha <- 0.05

if (p_value < alpha) {
  cat("Decision: Reject H0\n")
  cat("Conclusion: There is strong evidence that customers with wireless internet\n")
  cat("have a HIGHER average monthly spend than customers without wireless internet.\n")
} else {
  cat("Decision: Fail to reject H0\n")
  cat("Conclusion: There is not enough evidence that wireless customers spend more.\n")
}

# ------------------------------------------------------------
# 7. COMPARE WITH BUILT-IN t.test() AS A SANITY CHECK
# ------------------------------------------------------------

# Even though we manually used a z-style large-sample test,
# it's smart to compare with Welch's two-sample t-test.
# For a sample this large, the conclusion should be basically the same.

tt <- t.test(
  `Total Avg Monthly Spend` ~ wireless_num,
  data = analysis_data,
  alternative = "greater"
)

cat("\n--- Welch Two-Sample t-test (sanity check) ---\n")
print(tt)

# ------------------------------------------------------------
# 8. DRAW THE STANDARD NORMAL CURVE AND SHADE THE RIGHT TAIL
# ------------------------------------------------------------

# Create x-values for the standard normal curve
x_vals <- seq(-4, max(4, z_calc + 1), length.out = 2000)

# Standard normal density values
curve_data <- data.frame(
  x = x_vals,
  y = dnorm(x_vals)
)

# Data for the shaded p-value region (right tail beyond z_calc)
shade_data <- curve_data %>%
  filter(x >= z_calc)

# Plot
ggplot(curve_data, aes(x = x, y = y)) +
  geom_line(linewidth = 1) +
  geom_area(data = shade_data, aes(x = x, y = y), alpha = 0.35) +
  geom_vline(xintercept = z_calc, linetype = "dashed", linewidth = 1) +
  annotate(
    "text",
    x = min(z_calc, 3.5),
    y = 0.38,
    label = paste0("z = ", round(z_calc, 2)),
    hjust = ifelse(z_calc > 3.5, 1, 0)
  ) +
  labs(
    title = "Standard Normal Curve with Right-Tail p-value",
    subtitle = paste0(
      "H0: mu_wireless = mu_nonwireless   vs   H1: mu_wireless > mu_nonwireless\n",
      "p-value = ", format(p_value, scientific = TRUE)
    ),
    x = "z",
    y = "Density"
  )

# ------------------------------------------------------------
# 9. OPTIONAL: A MORE TEXTBOOK-LIKE WRITEUP
# ------------------------------------------------------------

cat("\n--- Textbook-style writeup ---\n")
cat(
  paste0(
    "For our test statistic z_calc = ", round(z_calc, 3),
    ", the p-value is ", format(p_value, scientific = TRUE), ".\n",
    "Because the p-value is less than alpha = 0.05, we reject H0.\n",
    "There is strong statistical evidence that customers with wireless internet\n",
    "have a higher average monthly spend than customers without wireless internet.\n"
  )
)