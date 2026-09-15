#property strict
#include "../Include/Indicators/MyMA.mqh"
#include "../Include/Indicators/MyRSI.mqh"
#include "../Include/Indicators/MyADX.mqh"

// Fornece apenas a media da vela fechada; nenhum handle ou ordem e criado.
class SignalValues : public MyIndicatorValues
  {
public:
   double average;
   bool available;
   SignalValues() { average=100; available=true; }
   virtual bool Get(const int buffer,const int bar,double &value)
     {
      value=EMPTY_VALUE;
      if(!available || buffer!=0 || bar!=1) return false;
      value=average; return true;
     }
  };
int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }

void OnStart()
  {
   MyMAConfig config;
   config.period=20; config.shift=0; config.method=MODE_EMA; config.price=PRICE_CLOSE;
   MyMA average(config);
   SignalValues values;
   MqlRates rates[];
   ArrayResize(rates,3); ArraySetAsSeries(rates,true);
   rates[0].close=1; rates[1].close=101; rates[2].close=102;
   Check(average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Fechamento acima compra, sem exigir cruzamento");
   rates[0].close=1000;
   Check(average.CheckBuy(rates,values),"Vela atual nao altera a regra");
   rates[1].close=99;
   Check(!average.CheckBuy(rates,values) && average.CheckSell(rates,values),"Fechamento abaixo vende");
   rates[1].close=100;
   Check(!average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Igualdade e neutra");
   values.available=false; rates[1].close=101;
   Check(!average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Dado ausente nao confirma");
   values.available=true; values.average=EMPTY_VALUE;
   Check(!average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Media vazia nao confirma");
   values.average=100; rates[1].close=EMPTY_VALUE;
   Check(!average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Fechamento vazio nao confirma");
   ArrayResize(rates,1);
   Check(!average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Sem vela fechada nao confirma");
   ArrayResize(rates,3); rates[1].close=101;
   MyRSIConfig rsi_config;
   rsi_config.period=14; rsi_config.price=PRICE_CLOSE; rsi_config.lower=30; rsi_config.upper=70;
   MyRSI rsi(rsi_config);
   MyADXConfig adx_config; adx_config.period=14;
   MyADX adx(adx_config);
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"RSI aguarda regra especifica");
   Check(!adx.CheckBuy(rates,values) && !adx.CheckSell(rates,values),"ADX aguarda regra especifica");
   PrintFormat("IndicatorSignalTests: %d falhas",failures);
  }
