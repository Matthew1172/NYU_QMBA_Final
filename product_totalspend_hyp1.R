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
# 2. SET UP THE HYPOTHESIS TEST
# ------------------------------------------------------------
# We will compare Monthly Spend ProductA vs Monthly Spend ProductB
# for the SAME customers, so this is a paired mean difference setup.
#
# Define the difference:
#   diff = ProductA - ProductB
#
# Null hypothesis:
#   H0: mu_diff = 0
#
# Alternative hypothesis:
#   H1: mu_diff > 0
#
# In words:
#   The average monthly spend on Product A is greater than
#   the average monthly spend on Product B.

cat("Null hypothesis H0: mean(Product A - Product B) = 0\n")
cat("Alternative hypothesis H1: mean(Product A - Product B) > 0\n\n")

# ------------------------------------------------------------
# 3. KEEP ONLY THE COLUMNS WE NEED AND DROP MISSING VALUES
# ------------------------------------------------------------

analysis_data <- customer_data %>%
  select(`Monthly Spend ProductA`, `Monthly Spend ProductB`) %>%
  filter(!is.na(`Monthly Spend ProductA`), !is.na(`Monthly Spend ProductB`)) %>%
  mutate(
    diff = `Monthly Spend ProductA` - `Monthly Spend ProductB`
  )

# Quick check
head(analysis_data)

# ------------------------------------------------------------
# 4. CALCULATE SAMPLE STATISTICS
# ------------------------------------------------------------

n <- nrow(analysis_data)
mean_A <- mean(analysis_data$`Monthly Spend ProductA`)
mean_B <- mean(analysis_data$`Monthly Spend ProductB`)
mean_diff <- mean(analysis_data$diff)
sd_diff <- sd(analysis_data$diff)
SE <- sd_diff / sqrt(n)

cat("--- Sample Statistics ---\n")
cat("Sample size n: ", n, "\n")
cat("Mean Product A spend: ", round(mean_A, 2), "\n")
cat("Mean Product B spend: ", round(mean_B, 2), "\n")
cat("Mean difference (A - B): ", round(mean_diff, 2), "\n")
cat("SD of differences: ", round(sd_diff, 2), "\n")
cat("Standard error: ", round(SE, 4), "\n\n")

# ------------------------------------------------------------
# 5. CALCULATE THE TEST STATISTIC
# ------------------------------------------------------------
# For large n, using z is acceptable for a textbook-style normal curve example:
#
#   z = (mean_diff - 0) / (sd_diff / sqrt(n))

z_calc <- mean_diff / SE

# Right-tailed p-value because H1 is mu_diff > 0
p_value <- 1 - pnorm(z_calc)

cat("--- Hypothesis Test Results ---\n")
cat("z statistic: ", round(z_calc, 4), "\n")
cat("p-value: ", format(p_value, scientific = TRUE), "\n\n")

# ------------------------------------------------------------
# 6. MAKE A DECISION AT ALPHA = 0.05
# ------------------------------------------------------------

alpha <- 0.05

if (p_value < alpha) {
  cat("Decision: Reject H0\n")
  cat("Conclusion: There is enough evidence to conclude that\n")
  cat("average monthly spend on Product A is greater than Product B.\n\n")
} else {
  cat("Decision: Fail to reject H0\n")
  cat("Conclusion: There is not enough evidence to conclude that\n")
  cat("average monthly spend on Product A is greater than Product B.\n\n")
}

# ------------------------------------------------------------
# 7. OPTIONAL SANITY CHECK WITH A PAIRED t-TEST
# ------------------------------------------------------------
# This is statistically more standard for paired data.
# With a large sample, its conclusion should be close to the z-test.

tt <- t.test(
  analysis_data$`Monthly Spend ProductA`,
  analysis_data$`Monthly Spend ProductB`,
  paired = TRUE,
  alternative = "greater"
)

cat("--- Paired t-test Sanity Check ---\n")
print(tt)
cat("\n")

# ------------------------------------------------------------
# 8. DRAW THE STANDARD NORMAL CURVE
# ------------------------------------------------------------
# We want the plot to actually show up, so we assign it to p and print(p).
# If z_calc is outside [-4, 4], we cap the plotted line at 4 so the graph
# still looks like a textbook normal curve.

x_vals <- seq(-4, 4, length.out = 2000)

curve_data <- data.frame(
  x = x_vals,
  y = dnorm(x_vals)
)

# Cap the plotted z position so the line stays on the visible graph
z_plot <- max(min(z_calc, 4), -4)

# Shade the right-tail region for the p-value
shade_data <- curve_data %>%
  filter(x >= z_plot)

p <- ggplot(curve_data, aes(x = x, y = y)) +
  geom_line(linewidth = 1) +
  geom_area(data = shade_data, aes(x = x, y = y), alpha = 0.35) +
  geom_vline(xintercept = z_plot, linetype = "dashed", linewidth = 1) +
  annotate(
    "text",
    x = ifelse(z_plot > 3.2, 3.2, z_plot),
    y = 0.37,
    label = paste0("z = ", round(z_calc, 2)),
    hjust = ifelse(z_plot > 3.2, 1, 0)
  ) +
  labs(
    title = "Standard Normal Curve for Product A vs Product B",
    subtitle = paste0(
      "H0: mean(A - B) = 0   vs   H1: mean(A - B) > 0\n",
      "p-value = ", format(p_value, scientific = TRUE)
    ),
    x = "z",
    y = "Density"
  )

print(p)

# ------------------------------------------------------------
# 9. TEXTBOOK-STYLE WRITTEN INTERPRETATION
# ------------------------------------------------------------

cat("--- Textbook-style writeup ---\n")
cat(
  paste0(
    "For our test statistic z_calc = ", round(z_calc, 3),
    ", the p-value is ", format(p_value, scientific = TRUE), ".\n"
  )
)

if (p_value < alpha) {
  cat(
    paste0(
      "Since the p-value is less than alpha = ", alpha,
      ", we reject H0.\n",
      "There is sufficient evidence to conclude that average monthly spend on Product A\n",
      "is greater than average monthly spend on Product B.\n"
    )
  )
} else {
  cat(
    paste0(
      "Since the p-value is greater than alpha = ", alpha,
      ", we fail to reject H0.\n",
      "There is not sufficient evidence to conclude that average monthly spend on Product A\n",
      "is greater than average monthly spend on Product B.\n"
    )
  )
}

