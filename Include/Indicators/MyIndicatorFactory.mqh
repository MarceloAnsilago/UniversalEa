#ifndef UNI_MY_INDICATOR_FACTORY_MQH
#define UNI_MY_INDICATOR_FACTORY_MQH
#include "../Configuration/UniTypes.mqh"
#include "MyMA.mqh"
#include "MyRSI.mqh"
#include "MyADX.mqh"

// Adaptador entre a configuracao salva e as classes de execucao.
class MyIndicatorFactory
  {
public:
   // Cria apenas o tipo selecionado, sem acessar o terminal.
   // O chamador assume a propriedade e deve usar delete ao terminar.
   // NONE retorna NULL sem erro; tipo/parametros invalidos retornam erro.
   static MyIndicator *Create(const IndicatorConfig &config,string &error)
     {
      error="";
      switch(config.type)
        {
         case GUI_INDICATOR_NONE: return NULL;
         case GUI_INDICATOR_MA:
           {
            MyMAConfig settings;
            settings.period=config.maPeriod; settings.shift=config.maShift;
            settings.method=config.maMethod; settings.price=config.maPrice;
            MyMA *indicator=new MyMA(settings);
            if(indicator==NULL) { error="Falha ao alocar MA."; return NULL; }
            if(indicator.Validate()) return indicator;
            delete indicator; error="Parametros de MA invalidos."; return NULL;
           }
         case GUI_INDICATOR_RSI:
           {
            MyRSIConfig settings;
            settings.period=config.rsiPeriod; settings.price=config.rsiPrice;
            settings.lower=config.rsiLower; settings.upper=config.rsiUpper;
            MyRSI *indicator=new MyRSI(settings);
            if(indicator==NULL) { error="Falha ao alocar RSI."; return NULL; }
            if(indicator.Validate()) return indicator;
            delete indicator; error="Parametros de RSI invalidos."; return NULL;
           }
         case GUI_INDICATOR_ADX:
           {
            MyADXConfig settings; settings.period=config.adxPeriod; settings.minimum=config.adxMinimum;
            MyADX *indicator=new MyADX(settings);
            if(indicator==NULL) { error="Falha ao alocar ADX."; return NULL; }
            if(indicator.Validate()) return indicator;
            delete indicator; error="Parametros de ADX invalidos."; return NULL;
           }
        }
      error="Tipo de indicador desconhecido.";
      return NULL;
     }
  };
#endif
