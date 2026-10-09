#ifndef GUI_CANDLE_FILTER_MQH
#define GUI_CANDLE_FILTER_MQH

// Estrutura sem campos dinâmicos para salvar os filtros no arquivo do conjunto.
// Cada limite em zero é ignorado; um limite máximo zero não restringe o tamanho.
struct GuiCandleFilterConfig
  {
   int measure; // 0 = corpo (abertura/fechamento); 1 = total (máxima/mínima).
   double minimum,maximum;
   double upper_minimum,upper_maximum;
   double lower_minimum,lower_maximum;
  };

// Confere uma faixa sem impedir filtros com apenas mínimo ou apenas máximo.
bool GuiValidateCandleRange(const double minimum,const double maximum,const string label,string &error,const string unit="pontos")
  {
   double limit=unit=="%" ? 100.0 : 100000000.0;
   if(!MathIsValidNumber(minimum) || !MathIsValidNumber(maximum) ||
      minimum<0 || maximum<0 || minimum>limit || maximum>limit)
     { error=label+": use valores de 0 a "+DoubleToString(limit,0)+" "+unit+"."; return false; }
   if(minimum>0 && maximum>0 && minimum>maximum)
     { error=label+": o mínimo não pode superar o máximo."; return false; }
   return true;
  }

// Valida corpo/total e os limites independentes dos dois pavios.
bool GuiValidateCandleFilter(const GuiCandleFilterConfig &config,string &error,const string unit="pontos")
  {
   error="";
   if(config.measure<0 || config.measure>1)
     { error="Selecione corpo ou tamanho total do candle."; return false; }
   return GuiValidateCandleRange(config.minimum,config.maximum,"Tamanho do candle",error,unit) &&
          GuiValidateCandleRange(config.upper_minimum,config.upper_maximum,"Pavio superior",error,unit) &&
          GuiValidateCandleRange(config.lower_minimum,config.lower_maximum,"Pavio inferior",error,unit);
  }
#endif
