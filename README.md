# Fully-Automated-Signal-Driven-Trader-Expert-Advisor-for-MT5

> **A fully automated MetaTrader 5 Expert Advisor (EA) that executes daily trades based on machine learning (ML) or algorithmic forecast signals.**

---

## Overview

`MT5-AutoForecast-EA` is a fully automated trading bot for MetaTrader 5 that reads daily buy/sell signals from an external file (e.g., generated by a machine learning model or statistical algorithm).  
Every trading day at a specified time, the EA closes existing positions, deletes pending orders, reads the latest forecast signal, and places new pending orders (BUY or SELL) based on your risk settings and recent market data.

---

## Features

- **100% Automated Execution:** No manual intervention required.
- **Forecast-Driven:** Reads signals (BUY/SELL) from a simple text file.
- **Position Management:** Closes existing positions and deletes all pending orders before opening new ones.
- **Flexible Risk Settings:** Adjustable risk ratio and pip value for lot size calculation.
- **Dynamic Order Placement:** Pending orders (BUY/SELL) are placed at calculated price levels using recent M15 bar data.
- **Error Handling & Logging:** Prints detailed status and error messages for transparency and troubleshooting.

---

## How It Works

1. **Forecast Signal Input:**  
   - The EA expects a signal file (default: `forecast_signal.txt`) in the `MQL5/Files` directory.
   - The file should contain a single line:  
     - `1` = BUY signal  
     - `0` = SELL signal

2. **Scheduled Action:**  
   - Every new day, between 09:16 and 09:18 (terminal/server time), the EA:
     - Closes all open market positions on the current symbol.
     - Deletes all pending orders.
     - Reads the forecast signal from the file.
     - Opens a pending BUY or SELL order according to the signal and risk settings.

3. **Order Logic:**  
   - Entry, stop loss (SL), and take profit (TP) levels are calculated based on the highest and lowest prices of a specific M15 candle (default: 09:00 bar).
   - Position size is calculated automatically based on risk percentage and pip value.

---

## Installation

1. **Copy the EA Script:**
   - Place the `.mq5` file in your `MQL5/Experts` directory.

2. **Signal File:**
   - Ensure `forecast_signal.txt` is updated by your ML/algorithmic script and located in the `MQL5/Files` directory.
   - Example content:
     ```
     1
     ```
     or
     ```
     0
     ```

3. **Attach EA to Chart:**
   - Start MetaTrader 5.
   - Attach the EA to the chart of the desired trading symbol (e.g., EURUSD, GBPUSD).

4. **Configure Inputs (Optional):**
   - `SignalFile`: Name of the signal file (default: `forecast_signal.txt`)
   - `RiskRatio`: Risk per trade as a percent of account balance (default: `1.0`)
   - `OnePipUSD`: Value of 1 pip in USD for your symbol (default: `10.0`)

---

## Usage

- **Automated Mode:**  
  Once installed, the EA operates fully automatically according to the above logic.
- **Signal Generation:**  
  You are responsible for ensuring the signal file is updated (e.g., by a Python/R/Matlab script, or manually).

---

## Example Signal Workflow

1. Your ML script forecasts a "BUY" signal.
2. Script writes `1` into `MQL5/Files/forecast_signal.txt`.
3. At the scheduled time, the EA reads the file and places a pending BUY order.

---

## License

MIT License

---

## Author

- Developed by [Enes Celik]

---

