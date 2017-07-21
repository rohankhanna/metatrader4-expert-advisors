extern int     Step           = 200;
extern double  ProfitClose    = 1.0,
               lot            = 0.01;
extern int     slippage       = 3,     //The maximum permissible deviation of the price for market orders (orders to buy or sell).
               magic          = 0,     //The magic number order. Can be used as a user-defined identifier.
               nBuy = 0,
               numberOfStepsToIgnore = 0, // set as 0 for vanilla martingale
               nSell = 0;
       int f = 0;
       double lastBuy,lastSell;
//-------------------------------------------------------------------- 
int init() 
{ 
   lastBuy = Ask;
   lastSell = Bid;
   Comment("Start EA ",TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS));
} 
//-------------------------------------------------------------------- 
int start() 
{
    if(Bid < lastBuy - (Step*Point) ){
        nBuy++;
        if(nBuy - numberOfStepsToIgnore > 0)
            buy(twoRaisedTo(nBuy-numberOfStepsToIgnore)*0.01);
        lastBuy = Ask;
    }
    if(Ask > lastSell + (Step*Point) ){
        nSell++;
        if(nSell - numberOfStepsToIgnore > 0)
            sell(twoRaisedTo(nSell-numberOfStepsToIgnore)*0.01);
        lastSell = Bid;
    }
    if(Ask < lastSell - (Step*Point) ){
        nSell = 0;
        CloseAllOrders(OP_SELL);
        lastSell = Bid;
    }
    if(Bid > lastBuy + (Step*Point) ){
        nBuy = 0;
        CloseAllOrders(OP_BUY);
        lastBuy = Ask;
    }
    return(0); 
}
int twoRaisedTo(int n){
    int v = 1;
    for(int i = 1; i <= n ; i++){
        v = v*2;
    }
    return v;
}

int buy(double quantity){ //in multiples of 0.01
    if(OrderSend(Symbol(),OP_BUY,quantity,NormalizeDouble(Ask,Digits),slippage,0,0,"",magic,0,Blue)!=-1) return;
}
int sell(double quantity){ //in multiples of 0.01
    if(OrderSend(Symbol(),OP_SELL,quantity,NormalizeDouble(Bid,Digits),slippage,0,0,"",magic,0,Red)!=-1) return;
}
//----------------------------------------------------------------- 
bool CloseAllOrders(int tip)
{
   bool error=true;
   int err,nn,OT,OMN;
   while(true)
   {
      for (int j = OrdersTotal()-1; j >= 0; j--)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            OMN = OrderMagicNumber();
            if (OrderSymbol() == Symbol() && OMN == magic)
            {
               OT = OrderType();
               if (OT != tip) continue;
               if (OT==OP_BUY) 
               {
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,Digits),slippage,Blue);
                  if (error) Comment("Close order N ",OrderTicket(),"  Profit ",OrderProfit(),
                                     "     ",TimeToStr(TimeCurrent(),TIME_SECONDS));
               }
               if (OT==OP_SELL) 
               {
                  error=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits),slippage,Red);
                  if (error) Comment("Close order N ",OrderTicket(),"  Profit ",OrderProfit(),
                                     "     ",TimeToStr(TimeCurrent(),TIME_SECONDS));
               }
               if (!error) 
               {
                  err = GetLastError();
                  if (err<2) continue;
                  if (err==129) 
                  {  Comment("Wrong price ",TimeToStr(TimeCurrent(),TIME_SECONDS));
                     RefreshRates();
                     continue;
                  }
                  if (err==146) 
                  {
                     if (IsTradeContextBusy()) Sleep(2000);
                     continue;
                  }
                  Comment("Error ",err," close order N ",OrderTicket(),
                          "     ",TimeToStr(TimeCurrent(),TIME_SECONDS));
               }
            }
         }
      }
      int n=0;
      for (j = 0; j < OrdersTotal(); j++)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            OMN = OrderMagicNumber();
            if (OrderSymbol() == Symbol() && OMN == magic)
            {
               OT = OrderType();
               if (OT != tip) continue;
               if (OT==OP_BUY || OT==OP_SELL) n++;
            }
         }  
      }
      if (n==0) break;
      nn++;
      if (nn>10) {Alert(Symbol()," Failed to close all trades, there are still ",n);return(0);}
      Sleep(1000);
      RefreshRates();
   }
   return(1);
}
//--------------------------------------------------------------------
bool DeleteAll(int tip)
{
   bool error;
   int err,n,OMN,OT;
   while(true)
   {
      error=true;
      for (int j = OrdersTotal()-1; j >= 0; j--)
      {
         if (OrderSelect(j, SELECT_BY_POS))
         {
            OMN = OrderMagicNumber();
            if (OrderSymbol() == Symbol() && OMN == magic)
            {
               OT = OrderType();
               if (OT>1 && (tip==0 || OT==tip)) error=OrderDelete(OrderTicket());
            }
         }
      }
      if (error) break;
      n++;
      if (n>10) break;
      Sleep(1000);
   }
   return(1);
}
//--------------------------------------------------------------------
