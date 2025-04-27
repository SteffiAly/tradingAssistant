//+------------------------------------------------------------------+
//| TradingAssistant_EA v1.0.0                                       |
//| Telegram Alerts, Cooldown, Overlay Monitoring                    |
//| © 2025 SteffiAly                                                 |
//| GitHub: https://github.com/SteffiAly/tradingAssistant            |
//+------------------------------------------------------------------+
#property strict

// Inputs
input double   SL_Factor              = 1.0;
input double   TP_Factor              = 2.0;
input double   Max_Spread_ATR_Percent = 50.0;
input int      Cooldown_Minutes       = 10;
input bool     TestMode               = false;
input string   TelegramBotToken      = "YOUR_TOKEN_HERE";
input string   TelegramChatID        = "YOUR_CHAT_ID_HERE";

// Globals
datetime lastMessageTime = 0;
string lastMessageText = "Keine";

//--- Indicator handles
int handleATR14;
int handleATR100;

//+------------------------------------------------------------------+
int OnInit()
  {
   handleATR14  = iATR(_Symbol, _Period, 14);
   handleATR100 = iATR(_Symbol, _Period, 100);

   if(TestMode)
     {
      string testMsg = "🤖 TradingAssistant_EA v1.0.0 gestartet!\nSymbol: " + _Symbol + "\nTestMode aktiv.";
      SendTelegram(testMsg);
      lastMessageTime = TimeCurrent();
      lastMessageText = TimeToString(lastMessageTime, TIME_DATE|TIME_SECONDS);
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   double spreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   double atr14[], atr100[];
   if(CopyBuffer(handleATR14, 0, 0, 1, atr14) < 0) return;
   if(CopyBuffer(handleATR100, 0, 0, 1, atr100) < 0) return;

   double spreadATRPercent = (spreadPoints / atr14[0]) * 100.0;
   double sl = atr14[0] * SL_Factor + spreadPoints;
   double tp = atr14[0] * TP_Factor;
   double crv = tp / sl;

   bool goodConditions = 
      (spreadATRPercent <= Max_Spread_ATR_Percent) &&
      (crv >= 1.0) &&
      (MathAbs(atr14[0] - atr100[0]) <= atr100[0] * 0.2);

   if(goodConditions && CooldownExpired())
     {
      string alertMsg = StringFormat(
         "📊 TradingAssistant Alert!\nSymbol: %s\nSpread: %.1f | ATR: %.2f | CRV: 1:%.2f\nZeit: %s",
         _Symbol, spreadPoints, atr14[0], crv, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)
      );
      SendTelegram(alertMsg);
      lastMessageTime = TimeCurrent();
      lastMessageText = TimeToString(lastMessageTime, TIME_DATE|TIME_SECONDS);
     }

   DrawOverlay(spreadPoints, atr14[0], atr100[0], spreadATRPercent, crv, goodConditions);
  }

//+------------------------------------------------------------------+
bool CooldownExpired()
  {
   return (TimeCurrent() - lastMessageTime) >= (Cooldown_Minutes * 60);
  }

//+------------------------------------------------------------------+
void SendTelegram(string text)
  {
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
   string data = "chat_id=" + TelegramChatID + "&text=" + text;
   char postData[];
   StringToCharArray(data, postData);
   char result[];
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";

   ResetLastError();
   int res = WebRequest("POST", url, headers, 5000, postData, result, headers);

   if(res == -1)
      Print("❌ Telegram WebRequest failed. Error: ", GetLastError());
   else
      Print("✅ Telegram Alert sent.");
  }

//+------------------------------------------------------------------+
void DrawOverlay(double spread, double atr14, double atr100, double spreadATR, double crv, bool good)
  {
   string status = good ? "🟢 Good Conditions" : "🔴 Unfavorable";
   string overlayText = StringFormat(
      "TradingAssistant_EA v1.0.0\nSpread: %.1f\nATR(14): %.2f | ATR(100): %.2f\nSpread/ATR: %.1f %%\nCRV: 1:%.2f\n%s\nLetzte Nachricht: %s",
      spread, atr14, atr100, spreadATR, crv, status, lastMessageText
   );

   Comment(overlayText);
  }
