#property strict
#include "../Include/Indicators/MyMA.mqh"
#include "../Include/Indicators/MyRSI.mqh"
#include "../Include/Indicators/MyADX.mqh"

// Fornece medias de varias velas fechadas; nenhum handle ou ordem e criado.
class SignalValues : public MyIndicatorValues
  {
public:
   double average;
   bool available;
   int slope,last_bar;
   SignalValues() { average=100; available=true; slope=1; last_bar=3; }
   virtual bool Get(const int buffer,const int bar,double &value)
     {
      value=EMPTY_VALUE;
      if(!available || buffer!=0 || (bar<1 || bar>last_bar)) return false;
      value=average==EMPTY_VALUE ? EMPTY_VALUE : average-(bar-1)*slope; return true;
     }
  };
int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }

void OnStart()
  {
   MyMAConfig config;
   config.slopeBars=3; config.period=20; config.shift=0; config.method=MODE_EMA; config.price=PRICE_CLOSE;
   MyMA average(config);
   SignalValues values;
   MqlRates rates[];
   ArrayResize(rates,3); ArraySetAsSeries(rates,true);
   rates[0].close=1; rates[1].close=101; rates[2].close=102;
   Check(average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Compra exige fechamento acima e inclinacao crescente");
   rates[0].close=1000;
   Check(average.CheckBuy(rates,values),"Vela atual nao altera a regra");
   rates[1].close=99; values.slope=-1;
   Check(!average.CheckBuy(rates,values) && average.CheckSell(rates,values),"Venda exige fechamento abaixo e inclinacao decrescente");
   rates[1].close=100;
   Check(!average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Igualdade e neutra");
   rates[1].close=101; values.slope=-1;
   Check(!average.CheckBuy(rates,values),"Fechamento acima sem inclinacao crescente nao compra");
   values.slope=0;
   Check(!average.CheckBuy(rates,values) && !average.CheckSell(rates,values),"Media plana e neutra");
   values.slope=1; values.last_bar=2;
   Check(!average.CheckBuy(rates,values),"Falta terceira vela impede sinal");
   config.slopeBars=2; MyMA two(config);
   Check(two.CheckBuy(rates,values) && two.RequiredValues()==3,"Duas velas configuraveis");
   config.slopeBars=5; MyMA five(config);
   Check(!five.CheckBuy(rates,values) && five.RequiredValues()==6,"Cinco velas exigem buffer maior");
   values.last_bar=5;
   Check(five.CheckBuy(rates,values),"Inclinacao avaliada nas cinco velas");
   config.slopeBars=1; MyMA invalid(config);
   Check(!invalid.Validate(),"Uma vela nao permite avaliar inclinacao");
   values.last_bar=3;
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
   MyADXConfig adx_config; adx_config.period=14; adx_config.minimum=25;
   MyADX adx(adx_config);
   Check(!rsi.CheckBuy(rates,values) && !rsi.CheckSell(rates,values),"RSI sem cruzamento nao confirma");
   Check(!adx.CheckBuy(rates,values) && !adx.CheckSell(rates,values),"ADX exige os tres buffers");
   PrintFormat("IndicatorSignalTests: %d falhas",failures);
  }
