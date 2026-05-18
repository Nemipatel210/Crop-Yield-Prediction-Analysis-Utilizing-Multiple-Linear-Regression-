# 0. Setup and Data Preparation

library(tidyverse)  
library(car)        
library(lmtest)    
library(caret)      
library(MASS)     

df <- read.csv("yield_df.csv")

# Clean indexing column if it carried over from Pandas
if("Unnamed..0" %in% colnames(df)) {
  df <- df %>% dplyr::select(-Unnamed..0)
}

# Rename target for cleaner code syntax
df <- df %>% rename(Yield = hg.ha_yield)

# CRITICAL DATA CLEANING: Remove rare categories to ensure stable train/test splits
df_clean <- df %>%
  group_by(Area) %>%
  filter(n() >= 5) %>%   # Keep only countries with 5+ records
  ungroup() %>%
  group_by(Item) %>%
  filter(n() >= 5) %>%   # Keep only crops with 5+ records
  ungroup()

# Convert categorical variables to factors and drop empty levels
df_clean$Area <- droplevels(as.factor(df_clean$Area))
df_clean$Item <- droplevels(as.factor(df_clean$Item))


# 1. Advanced Exploratory Data Analysis (EDA)

# A. Target Variable Skewness
p1 <- ggplot(df_clean, aes(x = Yield)) +
  geom_histogram(aes(y = ..density..), bins = 50, fill = "steelblue", color = "black", alpha = 0.7) +
  geom_density(color = "darkred", size = 1.2) +
  scale_x_continuous(labels = scales::comma) +
  labs(title = "Distribution of Global Crop Yields", x = "Yield (hg/ha)", y = "Density") +
  theme_minimal()
print(p1)

# B. Interaction Effects (Temperature vs. Crop Type)
top_crops <- df_clean %>% count(Item, sort = TRUE) %>% head(6) %>% pull(Item)
p2 <- df_clean %>% filter(Item %in% top_crops) %>%
  ggplot(aes(x = avg_temp, y = Yield, color = Item)) +
  geom_point(alpha = 0.1) + 
  geom_smooth(method = "loess", color = "black", se = FALSE, size = 1) + 
  facet_wrap(~ Item, scales = "free_y") + 
  labs(title = "Temperature Effects on Yield by Crop Type", x = "Average Temp (°C)", y = "Yield") +
  theme_bw() + theme(legend.position = "none")
print(p2)

# 2. MLR Modeling & Hypothesis Testing

cat(" HYPOTHESIS TESTING (BASELINE MLR MODEL)\n")

# HYPOTHESIS TESTING:
# H0: Beta_i = 0 (The environmental variable has no effect on Yield)
# HA: Beta_i != 0 (The environmental variable significantly affects Yield)

baseline_model <- lm(Yield ~ average_rain_fall_mm_per_year + pesticides_tonnes + avg_temp + Year, data = df_clean)

# Look at the Pr(>|t|) column in this summary to reject the Null Hypothesis
print(summary(baseline_model))

library(lmtest)
print(dwtest(baseline_model))

# 3. Feature Selection (Forward, Backward, Stepwise)
cat(" FEATURE SELECTION (Using Akaike Information Criterion)\n")

# Define a null model (intercept only) to serve as the starting point for Forward selection
null_model <- lm(Yield ~ 1, data = df_clean)

cat("\n--- Backward Elimination ---\n")
backward_model <- stepAIC(baseline_model, direction = "backward", trace = FALSE)
print(summary(backward_model)$coefficients)

cat("\n--- Forward Selection ---\n")
forward_model <- stepAIC(null_model, 
                         scope = list(lower = null_model, upper = baseline_model), 
                         direction = "forward", trace = FALSE)
print(summary(forward_model)$coefficients)

cat("\n--- Stepwise Regression ---\n")
stepwise_model <- stepAIC(null_model, 
                          scope = list(lower = null_model, upper = baseline_model), 
                          direction = "both", trace = FALSE)
print(summary(stepwise_model)$coefficients)

# 4. Out-of-Sample Regression Evaluation & Visualization
cat(" FINAL MODEL EVALUATION (IMPROVED OOS PIPELINE)\n")

set.seed(42)
train_indices <- createDataPartition(df_clean$Yield, p = 0.8, list = FALSE)
train_data <- df_clean[train_indices, ]
test_data <- df_clean[-train_indices, ]
predictive_model <- lm(Yield ~ average_rain_fall_mm_per_year + pesticides_tonnes + 
                         avg_temp + Year + Item + Area, data = train_data)
train_r_squared <- summary(predictive_model)$r.squared

predictions <- predict(predictive_model, newdata = test_data)
actuals <- test_data$Yield

rmse <- sqrt(mean((predictions - actuals)^2))
mae <- mean(abs(predictions - actuals))
r_squared_oos <- 1 - (sum((actuals - predictions)^2) / sum((actuals - mean(actuals))^2))

cat("--- Model Fit Comparison ---\n")
cat(sprintf("Training R-squared:      %.4f (%.2f%%)\n", train_r_squared, train_r_squared*100))
cat(sprintf("Out-of-Sample R-squared: %.4f (%.2f%%)\n", r_squared_oos, r_squared_oos*100))

cat("\n--- Out-of-Sample Error Metrics ---\n")
cat(sprintf("Test RMSE: %.2f\n", rmse))
cat(sprintf("Test MAE:  %.2f\n", mae))

# Create a dataframe for plotting
results_df <- data.frame(Actual = actuals, Predicted = predictions)

# Generate the Regression Performance Plot
p3 <- ggplot(results_df, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.3, color = "#2c7bb6") +  # Scatter plot of predictions
  geom_smooth(method = "lm", color = "darkblue", size = 1.2, se = FALSE) + # Actual model trend line
  scale_x_continuous(labels = scales::comma) +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Model Performance: Actual vs. Predicted Yield",
       x = "Actual Yield (hg/ha) [Test Set]",
       y = "Predicted Yield (hg/ha)") +
  theme_bw() +
  theme(plot.title = element_text(face = "bold", size = 16))

# Display the final plot
print(p3)


# 5. K-Fold Cross-Validation (Model Robustness Check)

cat(" 10-FOLD CROSS-VALIDATION\n")

set.seed(42)

# Define training control for 10-fold CV
train_control <- trainControl(method = "cv", number = 10)

# Train the model using K-Fold CV strictly on the training data
# This prevents data leakage while proving internal consistency
cv_model <- train(Yield ~ average_rain_fall_mm_per_year + pesticides_tonnes + 
                    avg_temp + Year + Item + Area, 
                  data = train_data, 
                  method = "lm", 
                  trControl = train_control)

# Print the Cross-Validation Summary
cat("--- Cross-Validation Results across 10 Folds ---\n")
cat(sprintf("Average CV RMSE: %.2f\n", cv_model$results$RMSE))
cat(sprintf("Average CV MAE:  %.2f\n", cv_model$results$MAE))
cat(sprintf("Average CV R-squared: %.4f (%.2f%%)\n", cv_model$results$Rsquared, cv_model$results$Rsquared*100))

