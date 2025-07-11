#include <Trade\Trade.mqh>
CTrade trade;

input string SignalFile = "forecast_signal.txt";  // Must be placed in MQL5/Files directory
input double RiskRatio = 1.0;                     // Risk percentage (e.g., 1%)
input double OnePipUSD = 10.0;                    // Value of one pip in USD

datetime lastTradeDate = 0;

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   datetime currentTime = TimeCurrent();
   MqlDateTime now;
   TimeToStruct(currentTime, now);

   MqlDateTime lastTradeDt;
   TimeToStruct(lastTradeDate, lastTradeDt);
   bool isNewDay = (now.day != lastTradeDt.day || now.mon != lastTradeDt.mon || now.year != lastTradeDt.year);

   if (isNewDay && now.hour == 09 && now.min >= 16 && now.min <= 18)
   {
      // 1) Close all open market positions
      closeOpenPosition();

      // 2) Delete all pending orders (MQL5 compatible)
      deletePendingOrders();

      // 3) Read forecast signal
      string signal;
      int fileHandle = FileOpen(SignalFile, FILE_READ | FILE_TXT | FILE_ANSI);
      if(fileHandle == INVALID_HANDLE)
      {
         Print("Failed to open ", SignalFile);
         return;
      }

      signal = FileReadString(fileHandle);
      FileClose(fileHandle);

      // Trim any whitespace or newlines just in case
      StringTrimLeft(signal);
      StringTrimRight(signal);

      // Now the first character should be '0' or '1' (ASCII code 48 or 49)
      PrintFormat("Signal read: [%s] | Char codes: [%d %d %d]",
                  signal,
                  StringGetCharacter(signal,0),
                  StringGetCharacter(signal,1),
                  StringGetCharacter(signal,2));

      int signalInt = StringToInteger(signal);
      if(signalInt == 1)
      {
         Print("Signal is 1 → Opening BUY order");
         openBuyOrder();
      }
      else if(signalInt == 0)
      {
         Print("Signal is 0 → Opening SELL order");
         openSellOrder();
      }
      else
      {
         Print("Invalid signal: [", signal, "]");
      }

      lastTradeDate = currentTime;
   }
}

// ---------- Close open market position ----------
void closeOpenPosition()
{
   if(PositionSelect(_Symbol))
   {
      double volume = PositionGetDouble(POSITION_VOLUME);
      ulong ticket = PositionGetInteger(POSITION_TICKET);
      int type = PositionGetInteger(POSITION_TYPE);

      double price = (type == POSITION_TYPE_BUY)
                     ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                     : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      MqlTradeRequest req = {};
      MqlTradeResult res = {};
      req.action = TRADE_ACTION_DEAL;
      req.position = ticket;
      req.symbol = _Symbol;
      req.volume = volume;
      req.price = price;
      req.type = (type == POSITION_TYPE_BUY)
                 ? ORDER_TYPE_SELL
                 : ORDER_TYPE_BUY;

      if(!OrderSend(req, res))
         Print("Failed to close position! Error: ", GetLastError());
      else
         Print("Position closed. Ticket: ", ticket);
   }
}

// ---------- Delete all pending orders (MQL5 version) ----------
void deletePendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderGetTicket(i))
      {
         ulong ticket = OrderGetTicket(i);
         int type = (int)OrderGetInteger(ORDER_TYPE);

         if(type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT ||
            type == ORDER_TYPE_BUY_STOP  || type == ORDER_TYPE_SELL_STOP)
         {
            MqlTradeRequest req = {};
            MqlTradeResult res = {};
            req.action = TRADE_ACTION_REMOVE;
            req.order  = ticket;
            req.symbol = _Symbol;

            if(!OrderSend(req, res))
               Print("Failed to delete pending order! Ticket: ", ticket, " Error: ", GetLastError());
            else
               Print("Pending order deleted. Ticket: ", ticket);
         }
      }
   }
}

// ---------- Open a BUY order ----------
void openBuyOrder()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double highest = getHighestPrice();
    double lowest = getLowestPrice();

    double entry = highest + 0.00010;
    double sl = lowest - 0.00010;
    double pipRange = (highest - lowest + 0.00020) * 10000;
    double tp = ((entry - sl) * 2.5) + entry;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    MqlTradeRequest req = {};
    MqlTradeResult res = {};
    req.action = TRADE_ACTION_PENDING;
    req.symbol = _Symbol;
    req.price = entry;
    req.volume = NormalizeDouble(balance * (RiskRatio / 100) / (OnePipUSD * pipRange), 2);
    req.sl = sl;
    req.tp = tp;
    req.type = (entry > ask) ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_BUY_LIMIT;

    if(!OrderSend(req, res))
        Print("Failed to open BUY order! Error: ", GetLastError());
    else
        Print("BUY order placed. Order ID: ", res.order);
}

// ---------- Open a SELL order ----------
void openSellOrder()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double highest = getHighestPrice();
    double lowest = getLowestPrice();

    double entry = lowest - 0.00010;
    double sl = highest + 0.00010;
    double pipRange = (highest - lowest + 0.00020) * 10000;
    double tp = entry - ((sl - entry) * 2.5);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    MqlTradeRequest req = {};
    MqlTradeResult res = {};
    req.action = TRADE_ACTION_PENDING;
    req.symbol = _Symbol;
    req.price = entry;
    req.volume = NormalizeDouble(balance * (RiskRatio / 100) / (OnePipUSD * pipRange), 2);
    req.sl = sl;
    req.tp = tp;
    req.type = (entry < bid) ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_SELL_LIMIT;

    if(!OrderSend(req, res))
        Print("Failed to open SELL order! Error: ", GetLastError());
    else
        Print("SELL order placed. Order ID: ", res.order);
}

// ---------- Get the highest price from the 19:45 M15 bar ----------
double getHighestPrice()
{
    datetime t = StringToTime("09:00");
    int bar = iBarShift(_Symbol, PERIOD_M15, t, false);
    return iHigh(_Symbol, PERIOD_M15, bar);
}

// ---------- Get the lowest price from the 19:45 M15 bar ----------
double getLowestPrice()
{
    datetime t = StringToTime("09:00");
    int bar = iBarShift(_Symbol, PERIOD_M15, t, false);
    return iLow(_Symbol, PERIOD_M15, bar);
}
