//+------------------------------------------------------------------+
//|                                  ICT_OrderBlock_FVG_Strategy.mq5 |
//|               Dynamic Risk Management & FVG-Based SL/TP         |
//|                        (Final Debugged Version)                  |
//+------------------------------------------------------------------+
#property copyright "ICT Inspired Strategy"
#property version   "3.01"
#include <Trade\Trade.mqh>

CTrade Trade;
MqlRates rates[];

// Inputs
input int      SwingPeriod = 50;        // Swing period for Order Block detection
input int      FVG_Bars = 3;            // Bars to look back for FVG
input double   RiskPercentage = 1.0;    // Risk percentage per trade (0.1-5%)
input double   RiskRewardRatio = 2.0;   // Risk:Reward ratio (1:2)
input bool     UseLiquidityPool = true; // Use liquidity pool (MSS) logic

// Global variables
double lastOrderBlockHigh = 0, lastOrderBlockLow = 0;
bool bullSignal = false, bearSignal = false;
int fvgStartIndex = -1; // Stores starting index of detected FVG

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
  ArraySetAsSeries(rates, true);
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Main tick function                                               |
//+------------------------------------------------------------------+
void OnTick() {
  if (IsNewBar()) {
    int requiredBars = MathMax(SwingPeriod * 2 + 1, FVG_Bars + 10);
    if (!LoadData(requiredBars)) return;

    DetectOrderBlock();
    DetectFVG();
    CheckLiquiditySweep();
    ExecuteTrades();
  }
}

//+------------------------------------------------------------------+
//| Load historical price data with validation                       |
//+------------------------------------------------------------------+
bool LoadData(int barsToLoad) {
  if (CopyRates(_Symbol, _Period, 0, barsToLoad, rates) < barsToLoad) {
    Print("Error: Not enough historical data loaded!");
    return false;
  }
  return true;
}

//+------------------------------------------------------------------+
//| Detect Order Blocks with bounds checking                         |
//+------------------------------------------------------------------+
void DetectOrderBlock() {
  int swingHighIndex = iHighest(_Symbol, _Period, MODE_HIGH, SwingPeriod*2+1, 1);
  int swingLowIndex = iLowest(_Symbol, _Period, MODE_LOW, SwingPeriod*2+1, 1);
  
  if (swingHighIndex != -1 && swingHighIndex < ArraySize(rates)) {
    lastOrderBlockHigh = rates[swingHighIndex].high;
  }
  if (swingLowIndex != -1 && swingLowIndex < ArraySize(rates)) {
    lastOrderBlockLow = rates[swingLowIndex].low;
  }
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps (FVG) and store start index               |
//+------------------------------------------------------------------+
void DetectFVG() {
  if (FVG_Bars >= ArraySize(rates)) return;

  // Bullish FVG: Current low > previous high (FVG_Bars bars back)
  if (rates[0].low > rates[FVG_Bars].high) {
    bullSignal = rates[0].close > lastOrderBlockHigh;
    fvgStartIndex = FVG_Bars;
  }
  
  // Bearish FVG: Current high < previous low (FVG_Bars bars back)
  if (rates[0].high < rates[FVG_Bars].low) {
    bearSignal = rates[0].close < lastOrderBlockLow;
    fvgStartIndex = FVG_Bars;
  }
}

//+------------------------------------------------------------------+
//| Check Liquidity Sweep (MSS)                                      |
//+------------------------------------------------------------------+
void CheckLiquiditySweep() {
  if (!UseLiquidityPool || ArraySize(rates) < 1) return;
  
  if (lastOrderBlockHigh == 0 || lastOrderBlockLow == 0) return;

  if (rates[0].low < lastOrderBlockLow && rates[0].close > lastOrderBlockHigh) {
    bullSignal = true;
  }
  
  if (rates[0].high > lastOrderBlockHigh && rates[0].close < lastOrderBlockLow) {
    bearSignal = true;
  }
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk percentage                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance) {
  if(slDistance <= 0) return 0.0;
  
  double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
  if(accountBalance <= 0) return 0.0;
  
  double riskAmount = accountBalance * (RiskPercentage / 100);
  double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
  double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
  
  if(tickSize <= 0) return 0.0;
  
  double pointValue = tickValue / tickSize;
  double lotSize = NormalizeDouble(riskAmount / (slDistance * pointValue), 2);
  
  // Apply broker limits
  double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
  double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
  lotSize = MathMax(MathMin(lotSize, maxLot), minLot);
  
  return lotSize;
}

//+------------------------------------------------------------------+
//| Execute trades with dynamic risk management                      |
//+------------------------------------------------------------------+
void ExecuteTrades() {
  if (PositionsTotal() > 0 || fvgStartIndex == -1) return;

  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  
  if (bullSignal) {
    double slPrice = rates[fvgStartIndex].low;
    double slDistance = ask - slPrice;
    
    if(slDistance > 0) {
      double tpPrice = ask + (slDistance * RiskRewardRatio);
      double lotSize = CalculateLotSize(slDistance);
      
      if(lotSize > 0) {
        Trade.Buy(lotSize, _Symbol, ask, slPrice, tpPrice, "Bullish FVG+OB");
      }
    }
    bullSignal = false;
    fvgStartIndex = -1;
  }
  
  if (bearSignal) {
    double slPrice = rates[fvgStartIndex].high;
    double slDistance = slPrice - bid;
    
    if(slDistance > 0) {
      double tpPrice = bid - (slDistance * RiskRewardRatio);
      double lotSize = CalculateLotSize(slDistance);
      
      if(lotSize > 0) {
        Trade.Sell(lotSize, _Symbol, bid, slPrice, tpPrice, "Bearish FVG+OB");
      }
    }
    bearSignal = false;
    fvgStartIndex = -1;
  }
}

//+------------------------------------------------------------------+
//| Check for new bar                                                |
//+------------------------------------------------------------------+
bool IsNewBar() {
  static datetime lastBar;
  datetime currentBar = iTime(_Symbol, _Period, 0);
  if (lastBar != currentBar) {
    lastBar = currentBar;
    return true;
  }
  return false;
}

