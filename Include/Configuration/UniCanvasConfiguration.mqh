#ifndef UNI_CANVAS_CONFIGURATION_MQH
#define UNI_CANVAS_CONFIGURATION_MQH
#include "../CanvasGUI/GuiState.mqh"
#include "../Indicators/MyIndicatorFactory.mqh"

// Validação compartilhada pelo painel e pela aplicação no motor.
bool UniValidateCanvasConfiguration(GuiAppliedConfiguration &config,string &error)
  {
   if(!config.setup.Validate(error) || !config.rules.Validate(error) || !config.management.Validate(error)) return false;
   int active=0; bool rsi=false,adx=false;
   for(int i=0;i<4;i++)
     {
      IndicatorConfig c=config.indicators[i];
      if((c.type==GUI_INDICATOR_RSI && rsi) || (c.type==GUI_INDICATOR_ADX && adx))
        { error="RSI e ADX não podem aparecer em mais de um indicador."; return false; }
      if(c.type==GUI_INDICATOR_RSI) rsi=true;
      if(c.type==GUI_INDICATOR_ADX) adx=true;
      MyIndicator *probe=MyIndicatorFactory::Create(c,error);
      if(error!="") return false;
      if(probe!=NULL) { active++; delete probe; }
     }
   if(active==0) { error="Selecione pelo menos um indicador antes de aplicar ao motor."; return false; }
   if(config.rules.take_mode==0 && config.rules.take_multiplier>0 &&
      config.rules.stop_loss==0 && config.rules.stop_multiplier==0)
     { error="Take Profit em vezes o stop exige um Stop Loss maior que zero."; return false; }
   error=""; return true;
  }

// Janela no horário do servidor, com fim exclusivo e suporte à meia-noite.
bool UniEntryWindow(const int start,const int end,const datetime server_time)
  {
   MqlDateTime parts;
   if(server_time<=0 || !TimeToStruct(server_time,parts)) return false;
   int minute=parts.hour*60+parts.min;
   return start<end ? minute>=start && minute<end : minute>=start || minute<end;
  }

bool UniCandleRangeMatches(const double value,const double minimum,const double maximum)
  { return (minimum==0 || value>=minimum) && (maximum==0 || value<=maximum); }

bool UniCanvasCandlesMatch(CGuiRulesState &rules,const MqlRates &closed[],const double point)
  {
   if(rules.candle_filter==GUI_CANDLE_DISABLED) return true;
   if(ArraySize(closed)<3 || point<=0) return false;
   for(int i=0;i<3;i++)
     {
      MqlRates bar=closed[i];
      if(!MathIsValidNumber(bar.high) || !MathIsValidNumber(bar.low) || !MathIsValidNumber(bar.open) ||
         !MathIsValidNumber(bar.close) || bar.high<bar.low || bar.high<MathMax(bar.open,bar.close) ||
         bar.low>MathMin(bar.open,bar.close)) return false;
      GuiCandleFilterConfig c;
      bool percent=rules.candle_units[i]==1;
      if(percent) c=rules.candle_percent[i]; else c=rules.candle_sizes[i];
      double total=bar.high-bar.low;
      double scale=percent ? (total>0 ? 100.0/total : 0.0) : 1.0/point;
      if(rules.candle_filter==GUI_CANDLE_SIZE)
        {
         double size=(c.measure==0 ? MathAbs(bar.close-bar.open) : total)*scale;
         if(!UniCandleRangeMatches(size,c.minimum,c.maximum)) return false;
        }
      else
        {
         double upper=(bar.high-MathMax(bar.open,bar.close))*scale;
         double lower=(MathMin(bar.open,bar.close)-bar.low)*scale;
         if(!UniCandleRangeMatches(upper,c.upper_minimum,c.upper_maximum) ||
            !UniCandleRangeMatches(lower,c.lower_minimum,c.lower_maximum)) return false;
        }
     }
   return true;
  }
#endif
