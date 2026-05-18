# Global Crop Yield Prediction: Integrating Environmental, Biological, and Geographical Constraints

---

## 📊 Executive Summary
This project investigates the primary drivers of global agricultural productivity using data aggregated from the Food and Agriculture Organization (FAO). The objective was to construct a robust **Multiple Linear Regression (MLR)** model to predict crop yield (measured in hg/ha) by accounting for environmental factors, temporal trends, and geographical constraints.

## 🚀 Key Results
* **Baseline Significance:** Environmental factors (temperature, rainfall, pesticide use) were statistically significant ($p < 2.2 \times 10^{-16}$) but explained only **4.11%** of yield variance in isolation.
* **Feature Expansion:** By introducing **Crop Type** (biological) and **Country** (geographical) categorical variables, the model's explanatory power improved significantly to **83.68%**.
* **Generalization:** Rigorous **10-Fold Cross-Validation** confirmed the model's stability and predictive power on unseen data.

## 🔍 Exploratory Data Analysis (EDA)
* **Data Filtering:** The dataset was filtered to remove rare categorical instances (countries and crops with fewer than 5 records) to ensure statistical stability.
* **Yield Distribution:** Density plots revealed a right-skewed distribution, typical of global data where a few highly optimized regions produce massive yields compared to the median.
* **Temperature Interaction:** Smoothed **LOESS curves** mapping average temperature against yield by crop type revealed non-linear, crop-specific optimal temperature zones.
* **Biological Mediation:** Findings confirmed that biological differences (crop species) mediate the effects of climate.

## 🛠️ Methodology

### 1. Feature Selection
Automated feature selection was performed using the **Akaike Information Criterion (AIC)**. Backward elimination, forward selection, and stepwise approaches all converged on retaining four baseline variables:
1. Average Rainfall
2. Pesticide Use
3. Average Temperature
4. Year

### 2. Time Series Validation
A **Durbin-Watson test** was conducted to check for temporal autocorrelation.
* **Result:** $DW = 0.909, p < 2.2 \times 10^{-16}$
* **Interpretation:** Indicated positive autocorrelation, validating the inclusion of "Year" as a control variable for macro-trends such as soil health and farming practice evolution.

### 3. Model Robustness
To guard against overfitting, the dataset was partitioned using a stratified 80/20 train/test split.
* **Out-of-Sample $R^2$:** 77.30%
* **10-Fold Cross-Validation (Training):** 83.50%

## 📈 Performance Comparison

| Model Phase | Variables Included | Adjusted $R^2$ |
| :--- | :--- | :--- |
| **Baseline** | Rain, Temp, Pesticides, Year | 4.11% |
| **Improved** | Baseline + Crop Type + Country | **83.68%** |

## 💡 Conclusion
The transition from 4.11% to 83.68% explanatory power demonstrates the successful application of theoretical regression principles. While climate factors dictate if a crop survives, they are insufficient for predicting volume in isolation. Effective forecasting models must prioritize geopolitical boundaries and specific crop biology to achieve actionable predictive accuracy.

---
### 🛠 Technologies Used
- **Language:** R / Python
- **Models:** Multiple Linear Regression (MLR)
- **Validation:** 10-Fold Cross-Validation, Durbin-Watson Test, AIC Stepwise Selection
- **Visualization:** ggplot2 / Matplotlib (LOESS Smoothing, Density Plots)
