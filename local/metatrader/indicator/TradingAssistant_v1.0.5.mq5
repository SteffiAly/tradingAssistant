//+------------------------------------------------------------------+
//| TradingAssistant v1.0.5                                          |
//| Removed Telegram function & Testmode                             |
//| Live Spread & ATR Monitoring                                     |
//|                                                                  |
//| © 2025 SteffiAly                                                 |
//| GitHub: https://github.com/SteffiAly/tradingAssistant            |
//+------------------------------------------------------------------+

#property indicator_chart_window
#property strict

// Version info
string version = "TradingAssistant v1.0.4";

// Input parameters
input double SL_Factor = 1.8;
input double TP_Factor = 2.0;
input double Max_Spread_ATR_Percent = 50.0;

// Global handles
int handleATR14;
int handleATR100;

// Buffers
double atr14Buffer[];
double atr100Buffer[];

//+------------------------------------------------------------------+
int OnInit()
  {
   // Create ATR handles
   handleATR14  = iATR(NULL, 0, 14);
   handleATR100 = iATR(NULL, 0, 100);
        
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(rates_total < 100) return(0);

   // Copy ATR values
   CopyBuffer(handleATR14, 0, 0, 1, atr14Buffer);
   CopyBuffer(handleATR100, 0, 0, 1, atr100Buffer);

   double atr14 = atr14Buffer[0];
   double atr100 = atr100Buffer[0];

   // Calculate spread
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = NormalizeDouble(ask - bid, _Digits);

   // Spread/ATR ratio
   double spread_atr_percent = (spread / atr14) * 100;

   // CRV calculation
   double SL = (atr14 * SL_Factor) + spread;
   double TP = atr14 * TP_Factor;
   double crv = TP / SL;

   // Check trading conditions
   bool good_conditions = (spread_atr_percent <= Max_Spread_ATR_Percent) && (crv >= 1.0) && (MathAbs(atr14 - atr100) <= (atr100 * 0.2));

   // Chart overlay
   string status = good_conditions ? "👍 Good Conditions" : "👎 Unfavorable";
   string info = StringFormat("%s\nSpread: %.2f\nATR(14): %.2f | ATR(100): %.2f\nSpread/ATR: %.1f%%\nCRV: 1:%.2f\n%s",
                              version, spread, atr14, atr100, spread_atr_percent, crv, status);
   Comment(info);

   return(rates_total);
  }
//+------------------------------------------------------------------+
