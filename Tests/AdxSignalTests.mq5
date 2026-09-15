#property strict
#include "../Include/Indicators/MyADX.mqh"
class AdxValues : public MyIndicatorValues
  {
public:
   double adx,plus,minus;
   bool available;
   AdxValues() { adx=30; plus=35; minus=15; available=true; }
   virtual bool Get(const int buffer,const int bar,double &value)
     {
      value=EMPTY_VALUE;
      if(!available || bar!=1 || buffer<0 || buffer>2) return false;
      value=buffer==0 ? adx : (buffer==1 ? plus : minus); return true;
     }
  };
int failures=0;
void Check(const bool ok,const string label)
  { if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   MyADXConfig config; config.period=14; config.minimum=25;
   MyADX indicator(config); AdxValues values;
   MqlRates rates[]; ArrayResize(rates,3);
   Check(indicator.CheckBuy(rates,values) && !indicator.CheckSell(rates,values),"Compra forte");
   values.plus=15; values.minus=35;
   Check(indicator.CheckSell(rates,values) && !indicator.CheckBuy(rates,values),"Venda forte");
   values.adx=25;
   Check(!indicator.CheckBuy(rates,values) && !indicator.CheckSell(rates,values),"Igual ao minimo nao sinaliza");
   values.adx=19;
   Check(!indicator.CheckBuy(rates,values) && !indicator.CheckSell(rates,values),"Mercado sem forca");
   config.minimum=20; MyADX optimized(config); values.adx=22;
   Check(optimized.CheckSell(rates,values) && !indicator.CheckSell(rates,values),"Limiar configuravel 20 vs 25");
   values.adx=30; values.plus=values.minus;
   Check(!indicator.CheckBuy(rates,values) && !indicator.CheckSell(rates,values),"DI iguais sao neutros");
   values.plus=EMPTY_VALUE;
   Check(!indicator.CheckBuy(rates,values) && !indicator.CheckSell(rates,values),"Buffer vazio rejeitado");
   values.available=false;
   Check(!indicator.CheckBuy(rates,values) && !indicator.CheckSell(rates,values),"Buffer ausente rejeitado");
   config.minimum=101; MyADX invalid(config);
   Check(!invalid.Validate(),"Limiar fora da escala rejeitado");
   PrintFormat("AdxSignalTests: %d falhas",failures);
  }
