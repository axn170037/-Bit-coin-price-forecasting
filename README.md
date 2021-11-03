# Bit-coin-price-forecasting:
Develop a model to forecast Bit coin prices using historical bitcoin, S&P500, Gold, US/Euro Exchange prices since 2014.

# Approach:
Scrapped the daily rate of S&P500 (SP500), the London bullion market price for gold in US dollars (GOLDAMGBD228NLBM), the US/Euro exchange rate (DEXUSEU), and the West Texas Intermediate spot price of oil (DCOILWTICO) from St Louis FRED. Used naive regression and KPSS test to find correlation and stationarity of the Dataset.

Used ACF and PACF to check for Lag and correlation between the Lagged values. Used ARIMA models to predict Bit coin prices based on the lowest AIC and BIC score.
Used Periodogram charts to check for seasonality in the data.

