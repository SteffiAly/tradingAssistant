//+------------------------------------------------------------------+
//| TradingAssistant v1.0                                            |
//| Live Spread & ATR Monitoring + Telegram Alerts                   |
//| https://github.com/SteffiAly/tradingAssistant                    |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property strict

// Version info
string version = "TradingAssistant v1.0";

// Input parameters
input double SL_Factor = 1.8;
input double TP_Factor = 2.0;
input double Max_Spread_ATR_Percent = 50.0;    // Threshold for good conditions (%)
input string TelegramBotToken = "YOUR_BOT_TOKEN";
input string TelegramChatID   = "YOUR_CHAT_ID";

// Internal variables
double atr14, atr100, spread;
bool alert_sent = false;

//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   // Calculate current spread
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   spread = NormalizeDouble(ask - bid, _Digits);

   // Get ATR values
   atr14 = iATR(NULL, 0, 14, 0);
   atr100 = iATR(NULL, 0, 100, 0);

   // Calculate Spread/ATR ratio in percent
   double spread_atr_percent = (spread / atr14) * 100;

   // Calculate CRV (Risk-Reward Ratio)
   double SL = (atr14 * SL_Factor) + spread;
   double TP = atr14 * TP_Factor;
   double crv = TP / SL;

   // Check if trading conditions are good
   bool good_conditions = (spread_atr_percent <= Max_Spread_ATR_Percent) && (crv >= 1.0) && (MathAbs(atr14 - atr100) <= (atr100 * 0.2));

   // Display info on chart
   string status = good_conditions ? "🟢 Good Conditions" : "🔴 Unfavorable";
   string info = StringFormat("%s\nSpread: %.2f\nATR(14): %.2f | ATR(100): %.2f\nSpread/ATR: %.1f%%\nCRV: 1:%.2f\n%s",
                              version, spread, atr14, atr100, spread_atr_percent, crv, status);
   Comment(info);

   // Send Telegram alert once when conditions are good
   if(good_conditions && !alert_sent)
     {
      string message = StringFormat("✅ Good trading conditions on %s\nSpread: %.2f | ATR: %.2f | CRV: 1:%.2f", 
                                      _Symbol, spread, atr14, crv);
      SendTelegram(message);
      alert_sent = true;
     }

   // Reset alert flag if conditions no longer met
   if(!good_conditions) alert_sent = false;

   return(rates_total);
  }
//+------------------------------------------------------------------+

// Function to send Telegram message
void SendTelegram(string text)
  {
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage?chat_id=" + TelegramChatID + "&text=" + text;
   char result[];
   int timeout = 5000;
   ResetLastError();
   int res = WebRequest("GET", url, "", NULL, 0, result, timeout);
  }
//+------------------------------------------------------------------+
