#property strict
#include "../Include/Indicators/MyMA.mqh"
#include "../Include/MyUnEA.mqh"

// Former buy/sell conditions must no longer create signals. No orders sent.
class FormerSignalValues : public MyIndicatorValues
  {
public:
   bool buy;
   virtual bool Get(const int buffer,const int bar,double &value)
     {
      if(buffer==1) value=buy ? 40 : 10;
      else if(buffer==2) value=buy ? 10 : 40;
      else value=buy ? (bar==1 ? 40 : 20) : (bar==1 ? 60 : 80);
      return true;
     }
  };
void OnStart()
  {
   MyMAConfig config;
   ZeroMemory(config);
   config.period=20; config.shift=0; config.method=MODE_EMA; config.price=PRICE_CLOSE; config.slopeBars=3;
   MyMA indicator(config);
   FormerSignalValues values;
   MqlRates rates[]; ArrayResize(rates,3);
   for(int i=0;i<3;i++) ZeroMemory(rates[i]);
   int failures=0;
   for(int direction=0;direction<2;direction++)
     {
      values.buy=direction==0;
      rates[1].close=values.buy ? 100 : 1;
      if(indicator.CheckBuy(rates,values) || indicator.CheckSell(rates,values)) failures++;
     }
   if(!indicator.Validate() || indicator.BufferCount()!=1 || indicator.RequiredValues()!=3) failures++;
   MyUnEA engine;
   if(engine.checkBuy() || engine.checkSell()) failures++;
   PrintFormat("[IndicatorSignalTests] %d failures",failures);
  }
