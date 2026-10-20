#ifndef UNI_HISTOGRAM_EVALUATION_MQH
#define UNI_HISTOGRAM_EVALUATION_MQH
#include "UniSignals.mqh"
string UniHistogramConfiguration(GuiAppliedConfiguration &config,CUniSignals &signals)
  {
   string rows[]; int usages[]; double levels[]; ENUM_TIMEFRAMES clock;
   signals.CopyVisualConfiguration(rows,usages,levels,clock);
   string result="v1|"+IntegerToString((int)clock);
   for(int i=0;i<4;i++)
     {
      IndicatorConfig c=config.indicators[i];
      result+="|"+StringFormat("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g",
               (int)c.type,(int)config.indicator_timeframes[i],c.maPeriod,(int)c.maMethod,(int)c.maPrice,c.maShift,
               c.rsiPeriod,(int)c.rsiPrice,c.adxPeriod,usages[i],levels[i*3],levels[i*3+1],levels[i*3+2]);
     }
   for(int i=0;i<UNI_SIGNAL_COUNT;i++) result+="|"+rows[i];
   return result;
  }
// Read-only adapter. Native data handles, operators, sides, MTF offsets and E/Ou
// are evaluated by the same CUniSignals implementation used by the trading EA.
class CUniHistogramEvaluation : public CUniSignals
  {
private:
   MyIndicator *m_data[4];
   ENUM_TIMEFRAMES m_periods[4],m_cache_period[22];
   datetime m_cache_clock[22];
   double m_cache[22][5];
   bool m_cached[22][5];
protected:
   virtual bool Read(MyUnEA *engine,const int source,const int bar,const double fixed_value,double &value)
     {
      if(source==9 || source>=22) return CUniSignals::Read(NULL,source,bar,fixed_value,value);
      ENUM_TIMEFRAMES period=source>=10 ? m_periods[(source-10)/3] : ReadPeriod();
      datetime clock=iTime(_Symbol,period,0);
      if(m_cache_clock[source]!=clock || m_cache_period[source]!=period)
        { for(int b=0;b<5;b++) m_cached[source][b]=false; m_cache_clock[source]=clock; m_cache_period[source]=period; }
      bool cache=bar>0 && bar<5 && clock>0;
      if(cache && m_cached[source][bar]) { value=m_cache[source][bar]; return true; }
      if(source>=10)
        {
         int slot=(source-10)/3; double data[];
         if(m_data[slot]==NULL || !m_data[slot].Update((source-10)%3,bar,1,data)) return false;
         value=data[0]; if(value==EMPTY_VALUE || !MathIsValidNumber(value)) return false;
        }
      else if(!CUniSignals::Read(NULL,source,bar,fixed_value,value)) return false;
      if(cache) { m_cache[source][bar]=value; m_cached[source][bar]=true; }
      return true;
     }
public:
   ENUM_TIMEFRAMES clock_period;
   // A native indicator may finish updating after its series clock advances.
   // Share reads within one calculation only; never freeze that first read for an hour.
   void BeginCalculation()
     { for(int i=0;i<22;i++) for(int b=0;b<5;b++) m_cached[i][b]=false; }
   CUniHistogramEvaluation()
     {
      clock_period=PERIOD_CURRENT;
      for(int i=0;i<4;i++) m_data[i]=NULL;
      for(int i=0;i<22;i++) { m_cache_clock[i]=0; m_cache_period[i]=PERIOD_CURRENT; for(int b=0;b<5;b++) m_cached[i][b]=false; }
     }
   ~CUniHistogramEvaluation() { Release(); }
   void Release() { for(int i=0;i<4;i++) if(m_data[i]!=NULL) { delete m_data[i]; m_data[i]=NULL; } }
   bool Initialize(const string text,string &error)
     {
      string parts[]; if(StringSplit(text,'|',parts)!=6+UNI_SIGNAL_COUNT || parts[0]!="v1") { error="Configuracao visual invalida."; return false; }
      clock_period=(ENUM_TIMEFRAMES)StringToInteger(parts[1]);
      if(clock_period==PERIOD_CURRENT) clock_period=(ENUM_TIMEFRAMES)_Period;
      GuiAppliedConfiguration config; int usages[4]; double levels[12]; string payload[UNI_SIGNAL_COUNT];
      for(int i=0;i<4;i++)
        {
         string fields[]; if(StringSplit(parts[2+i],',',fields)!=13) { error="Slot visual invalido."; return false; }
         config.indicators[i].type=(ENUM_GUI_INDICATOR_TYPE)StringToInteger(fields[0]);
         config.indicator_timeframes[i]=(ENUM_TIMEFRAMES)StringToInteger(fields[1]);
         config.indicators[i].maPeriod=(int)StringToInteger(fields[2]); config.indicators[i].maMethod=(ENUM_MA_METHOD)StringToInteger(fields[3]);
         config.indicators[i].maPrice=(ENUM_APPLIED_PRICE)StringToInteger(fields[4]); config.indicators[i].maShift=(int)StringToInteger(fields[5]);
         config.indicators[i].rsiPeriod=(int)StringToInteger(fields[6]); config.indicators[i].rsiPrice=(ENUM_APPLIED_PRICE)StringToInteger(fields[7]);
         config.indicators[i].adxPeriod=(int)StringToInteger(fields[8]); usages[i]=(int)StringToInteger(fields[9]);
         for(int n=0;n<3;n++) levels[i*3+n]=StringToDouble(fields[10+n]);
         // Defaults needed by the existing factory's parameter validation.
         config.indicators[i].maSlopeBars=1; config.indicators[i].rsiLower=levels[i*3+2]; config.indicators[i].rsiUpper=levels[i*3]; config.indicators[i].adxMinimum=0;
         m_periods[i]=config.indicator_timeframes[i]==PERIOD_CURRENT ? clock_period : config.indicator_timeframes[i];
         m_data[i]=MyIndicatorFactory::Create(config.indicators[i],error);
         if(error!="" || (m_data[i]!=NULL && !m_data[i].Initialize(_Symbol,m_periods[i]))) { Release(); return false; }
        }
      for(int i=0;i<UNI_SIGNAL_COUNT;i++) payload[i]=parts[6+i];
      return Configure(payload,usages,_Symbol,clock_period,config,error) && ConfigureRsiLevels(levels,config,error);
     }
  };
#endif
