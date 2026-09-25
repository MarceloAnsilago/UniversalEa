#ifndef UNI_ORDER_MATH_MQH
#define UNI_ORDER_MATH_MQH
#include "Configuration/UniCanvasConfiguration.mqh"

double UniDistance(const double value,const bool percent,const double entry,const double point)
  { return value*(percent ? entry/100.0 : point); }

double UniPriceGrid(const double price,const double tick,const int digits,const int direction=0)
  {
   if(tick<=0 || !MathIsValidNumber(price)) return 0;
   double units=price/tick;
   return NormalizeDouble((direction<0 ? MathFloor(units+1e-8) :
                          (direction>0 ? MathCeil(units-1e-8) : MathRound(units)))*tick,digits);
  }

// Fim do ciclo de entradas que contém a abertura da operação.
datetime UniEntryDeadline(const datetime opened,const int start,const int end)
  {
   MqlDateTime date; if(!TimeToStruct(opened,date)) return 0;
   int minute=date.hour*60+date.min;
   date.hour=0; date.min=0; date.sec=0;
   datetime midnight=StructToTime(date);
   if(start>end && minute>=start) midnight+=86400;
   return midnight+end*60;
  }

bool UniOrderTargets(CGuiRulesState &rules,const int side,const double entry,const MqlRates &candle,
                     const double point,const double tick,const int digits,double &sl,double &tp,string &error)
  {
   sl=0; tp=0; error="";
   if((side!=1 && side!=-1) || entry<=0 || point<=0 || tick<=0)
     { error="Preço ou direção inválidos."; return false; }
   double size=rules.stop_measure==0 ? candle.high-candle.low : MathAbs(candle.close-candle.open);
   if(rules.stop_multiplier>0 && (candle.time<=0 || candle.high<candle.low ||
      candle.low>MathMin(candle.open,candle.close) || candle.high<MathMax(candle.open,candle.close)))
     { error="Candle do stop inválido."; return false; }
   double stop=UniDistance(rules.stop_loss,rules.target_unit==GUI_TARGET_PERCENT,entry,point)+rules.stop_multiplier*size;
   if(stop>0) sl=UniPriceGrid(entry-side*stop,tick,digits,-side);
   if((rules.stop_loss>0 || rules.stop_multiplier>0) && (stop<=0 || sl<=0 || side*(entry-sl)<=0))
     { error="Stop configurado resultou em distância inválida."; return false; }
   double take=rules.take_mode==0 ? (sl>0 ? MathAbs(entry-sl)*rules.take_multiplier : 0) :
               UniDistance(rules.take_profit,rules.target_unit==GUI_TARGET_PERCENT,entry,point);
   if(rules.take_mode==0 && rules.take_multiplier>0 && sl==0)
     { error="Take em vezes o stop exige stop válido."; return false; }
   if(take>0) tp=UniPriceGrid(entry+side*take,tick,digits,side);
   if(take>0 && (tp<=0 || side*(tp-entry)<=0)) { error="Take inválido."; return false; }
   return true;
  }

ENUM_ORDER_TYPE UniPendingType(const int side,const double price,const MqlTick &quote)
  { return side==1 ? (price>quote.ask ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_BUY_LIMIT) :
                    (price<quote.bid ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_SELL_LIMIT); }

// Calcula somente melhorias do stop. Percentuais usam o preço de abertura.
double UniManagedStop(CGuiManagementState &management,const int side,const double entry,const double price,
                      const double old_sl,const double point,const double tick,const int digits,
                      const bool moving_bar)
  {
   double best=old_sl;
   for(int group=0;group<3;group++)
     {
      int mode=management.mode[group];
      if(mode==0 || (group==2 && !moving_bar)) continue;
      int index=group==0 ? 0 : (group==1 ? 2 : 5);
      double trigger=UniDistance(management.values[index],mode==2,entry,point);
      if(side*(price-entry)+tick*1e-8<trigger) continue;
      double distance=UniDistance(management.values[index+1],mode==2,entry,point);
      double candidate=group==0 ? entry+side*distance : price-side*distance;
      candidate=UniPriceGrid(candidate,tick,digits,-side);
      double step=group==0 ? tick : MathMax(tick,UniDistance(management.values[index+2],mode==2,entry,point));
      if(candidate>0 && (best==0 || side*(candidate-best)+tick*1e-8>=step)) best=candidate;
     }
   return best;
  }
#endif
