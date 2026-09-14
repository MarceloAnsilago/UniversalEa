#property strict
#include "../Include/MyUnEA.mqh"

int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }

// Verifica criacao, parametros independentes, descarte e limites dos slots.
// Nao inicializa indicadores no terminal nem envia ordens.
void OnStart()
  {
   IndicatorConfig config;
   ZeroMemory(config);
   string error;
   config.type=GUI_INDICATOR_NONE;
   MyIndicator *indicator=MyIndicatorFactory::Create(config,error);
   Check(indicator==NULL && error=="","Slot desativado");
   config.type=(ENUM_GUI_INDICATOR_TYPE)99;
   indicator=MyIndicatorFactory::Create(config,error);
   Check(indicator==NULL && error!="","Tipo desconhecido");

   config.type=GUI_INDICATOR_MA;
   config.maPeriod=20; config.maMethod=MODE_EMA; config.maPrice=PRICE_CLOSE;
   indicator=MyIndicatorFactory::Create(config,error);
   Check(indicator!=NULL && error=="","MA ignora parametros inativos do RSI e ADX");
   if(indicator!=NULL)
     {
      double values[]; ArrayResize(values,1); values[0]=123;
      Check(!indicator.Update(0,0,1,values) && ArraySize(values)==0,"Sem handle nao fornece valores antigos");
      indicator.Release(); indicator.Release(); delete indicator;
     }
   config.maPeriod=0;
   indicator=MyIndicatorFactory::Create(config,error);
   Check(indicator==NULL && error!="","MA rejeita periodo zero");

   config.type=GUI_INDICATOR_RSI;
   config.rsiPeriod=14; config.rsiPrice=PRICE_CLOSE;
   config.rsiLower=30; config.rsiUpper=70;
   indicator=MyIndicatorFactory::Create(config,error);
   Check(indicator!=NULL && error=="","RSI ignora MA invalida");
   if(indicator!=NULL) delete indicator;
   config.rsiLower=70;
   indicator=MyIndicatorFactory::Create(config,error);
   Check(indicator==NULL && error!="","RSI rejeita niveis iguais");

   config.type=GUI_INDICATOR_ADX; config.adxPeriod=14;
   indicator=MyIndicatorFactory::Create(config,error);
   Check(indicator!=NULL && error=="","ADX ignora MA e RSI invalidos");
   if(indicator!=NULL) delete indicator;
   MyUnEA ea;
   Check(!ea.ConfigureIndicator(-1,config,error),"Slot negativo");
   Check(!ea.ConfigureIndicator(4,config,error),"Slot alem do limite");
   for(int i=0;i<4;i++) Check(ea.ConfigureIndicator(i,config,error),"Configurar ADX");
   config.type=GUI_INDICATOR_NONE;
   Check(ea.ConfigureIndicator(0,config,error),"Desativar slot ocupado");
   PrintFormat("IndicatorArchitectureTests: %d falhas",failures);
  }
