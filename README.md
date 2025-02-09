# ICT Order Block & FVG Strategy

> **Important:** This strategy is provided for educational and research purposes only. **The author is a developer, not a financial analyst.** **Do not** use this strategy on a live account without thorough testing and validation. If you share or modify this code, please give proper credit to [Tzigger](https://github.com/Tzigger) as the original creator.

---

## Overview

The **ICT Order Block & FVG Strategy** is an Expert Advisor (EA) for MetaTrader 5 that implements concepts inspired by ICT (Inner Circle Trader) methodologies. It combines the detection of **Order Blocks**, **Fair Value Gaps (FVGs)**, and **Liquidity Pool Sweeps (MSS)** to generate trading signals with dynamic risk management. This final, debugged version is intended for those who want to study and experiment with ICT-inspired trading logic.

---

## Strategy Theory & Concepts

### Order Blocks
- **Definition:** Order blocks are areas on the chart where institutional orders have accumulated. These levels can act as support or resistance.
- **Detection:** The strategy identifies order blocks by scanning for swing highs and swing lows over a specified period (the `SwingPeriod` input). The highest swing high and lowest swing low define the potential order block levels.

### Fair Value Gaps (FVGs)
- **Definition:** Fair Value Gaps are gaps in the price action where the market has moved quickly, leaving an imbalance. These areas often represent a temporary mispricing that can be exploited.
- **Detection:** The EA checks for a bullish FVG when the current bar's low is higher than the high of a previous bar (set by `FVG_Bars`), and for a bearish FVG when the current bar's high is lower than the low of a previous bar.

### Liquidity Pool Sweeps (MSS)
- **Definition:** Liquidity Pool Sweeps involve triggering stop-loss orders and liquidity clusters that exist around order block areas. They can often lead to a reversal or a strong follow-through move.
- **Logic:** When the current price action penetrates the identified order block boundaries, it may indicate that liquidity is being swept, prompting a potential trade setup.

### Dynamic Risk Management
- **Risk Calculation:** The position size is calculated dynamically based on the distance from the entry to the stop loss, using a predefined risk percentage (`RiskPercentage`).
- **Risk/Reward Ratio:** The take-profit is set using a multiplier (`RiskRewardRatio`) of the stop-loss distance.
- **Lot Sizing:** The EA adjusts the trade size according to account balance and broker constraints (minimum/maximum lot sizes).

---

## How the Strategy Works

1. **Data Loading:**  
   On every new bar, the EA loads the latest historical price data to ensure that there is enough data for analysis.

2. **Order Block Detection:**  
   - The EA finds the most recent swing high and swing low over a defined period.
   - These swing levels form the basis of the order block boundaries.

3. **FVG Detection:**  
   - Checks for the presence of a bullish or bearish Fair Value Gap by comparing the current bar with a previous bar.
   - Sets a signal (`bullSignal` or `bearSignal`) if the gap meets the criteria.

4. **Liquidity Pool Sweep Check:**  
   - Optionally (based on the `UseLiquidityPool` flag), the EA further validates signals by detecting liquidity sweeps around the order block levels.

5. **Trade Execution:**  
   - If there is a valid signal (and no open positions), the EA calculates the stop-loss based on the detected FVG and order block levels.
   - The EA dynamically calculates the appropriate lot size considering the risk percentage.
   - A market order is executed with a take-profit set at a multiple of the stop-loss distance.

6. **Risk Management:**  
   - The stop-loss and take-profit levels are determined dynamically to ensure that the risk/reward ratio is maintained according to the specified inputs.

---

## Installation & Usage

1. **Installation:**
   - Copy the `ICT_OrderBlock_FVG_Strategy.mq5` file into your MetaTrader 5 `Experts` folder.
   - Restart MetaTrader 5 or refresh the Navigator panel.
   - Compile the EA using the MetaEditor to ensure there are no compilation errors.

2. **Usage:**
   - Attach the EA to a chart.
   - Configure the input parameters:
     - **SwingPeriod:** Number of bars used to determine the swing highs/lows.
     - **FVG_Bars:** Number of bars back to check for Fair Value Gaps.
     - **RiskPercentage:** Percentage of account balance risked per trade.
     - **RiskRewardRatio:** Multiplier for calculating the take-profit level relative to the stop-loss distance.
     - **UseLiquidityPool:** Enable or disable liquidity pool (MSS) logic.
   - **Test Thoroughly:** Run the EA in a demo environment or use the strategy tester to validate performance before considering any live deployment.

---

## Disclaimer

- **No Financial Advice:** This EA is not financial advice. Trading involves significant risk, and you should only trade with money you can afford to lose.
- **Developer, Not Analyst:** The strategy was developed by a programmer with an interest in ICT concepts. It does not come from a certified financial analyst.
- **Do Your Own Research:** Always backtest and paper trade before using any automated strategy on a live account.
- **Credit:** If you distribute or modify this code, please credit Tzigger as the original creator of the underlying strategy concepts.

---

## Contributing & Credits

- **Original Concept & Credits:** The strategy is inspired by ICT (Inner Circle Trader) methodologies and was originally created by [Tzigger](https://github.com/Tzigger).  
- **Contributions:** Feel free to fork, experiment, and improve upon this EA, but please maintain the credit to the original author.
- **Issues & Feedback:** For any issues or suggestions, please open an issue on the GitHub repository.

---

## License

This project is provided under a permissive license. Please ensure that any redistributed versions of this project retain the credit to Tzigger and include this disclaimer.

---

*Happy coding and safe trading!*
