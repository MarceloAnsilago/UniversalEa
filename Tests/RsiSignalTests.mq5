#property strict
#include "../Include/Indicators/MyRSI.mqh"

// Valores simulados das velas fechadas; nao cria handles nem negocia.
class RsiValues : public MyIndicatorValues
  {
public:
   double previous,current;
   bool available;
   RsiValues() { previous=50; current=50; available=true; }
   virtual bool Get(const int buffer,const int bar,double &value)
     {
      value=EMPTY_VALUE;
      if(!available || buffer!=0 || (bar!=1 && bar!=2)) return false;
      value=(bar==1 ? current : previous); return true;
     }
  };
int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   MyRSIConfig config;
   config.period=14; config.price=PRICE_CLOSE; config.lower=30; config.upper=70;
   MyRSI rsi(config);
   RsiValues values;
   MqlRates rates[]; ArrayResize(rates,3); ArraySetAsSeries(rates,true);
   values.previous=28; values.current=35;
   Check(rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Saida da sobrevenda compra");
   values.previous=75; values.current=65;
   Check(rsi.CheckSell(rates,values) && !rsi.CheckBuy(rates,values),"Saida da sobrecompra vende");
   values.previous=45; values.current=50;
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Faixa neutra sem cruzamento");
   values.previous=35; values.current=28;
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Entrar em sobrevenda nao compra");
   values.previous=65; values.current=75;
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Entrar em sobrecompra nao vende");
   values.previous=29; values.current=30;
   Check(!rsi.CheckBuy(rates,values),"Tocar 30 nao confirma");
   values.previous=30; values.current=31;
   Check(rsi.CheckBuy(rates,values),"Sair de 30 para cima confirma");
   values.previous=71; values.current=70;
   Check(!rsi.CheckSell(rates,values),"Tocar 70 nao confirma");
   values.previous=70; values.current=69;
   Check(rsi.CheckSell(rates,values),"Sair de 70 para baixo confirma");
   config.lower=20; config.upper=80;
   MyRSI custom(config);
   values.previous=25; values.current=35;
   Check(!custom.CheckBuy(rates,values),"Respeita nivel inferior personalizado");
   values.previous=19; values.current=21;
   Check(custom.CheckBuy(rates,values),"Cruza nivel inferior personalizado");
   values.previous=81; values.current=79;
   Check(custom.CheckSell(rates,values),"Cruza nivel superior personalizado");
   values.current=EMPTY_VALUE;
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Valor vazio rejeitado");
   values.current=101;
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Valor fora da escala rejeitado");
   values.available=false;
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Dado ausente rejeitado");
   ArrayResize(rates,2);
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"Exige duas velas fechadas");
   PrintFormat("RsiSignalTests: %d falhas",failures);
  }
