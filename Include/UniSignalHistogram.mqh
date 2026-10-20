#ifndef UNI_SIGNAL_HISTOGRAM_MQH
#define UNI_SIGNAL_HISTOGRAM_MQH
#include "UniHistogramEvaluation.mqh"
// The renderer owns its buffers and evaluates the shared read-only conditions.
// No per-tick file channel, timer, publication throttle or final-frame handshake.
class CUniSignalHistogram
  {
private:
   long m_chart;
   int m_handles[4];
   string m_names[4];
public:
   CUniSignalHistogram() { m_chart=0; for(int i=0;i<4;i++) { m_handles[i]=INVALID_HANDLE; m_names[i]=""; } }
   ~CUniSignalHistogram() { Clear(); }
   void Clear(const bool preserve_display=false)
     {
      for(int i=3;i>=0;i--)
        {
         if(!preserve_display && m_names[i]!="")
           {
            int window=ChartWindowFind(m_chart,m_names[i]);
            if(window>0) ChartIndicatorDelete(m_chart,window,m_names[i]);
           }
         if(!preserve_display && m_handles[i]!=INVALID_HANDLE) IndicatorRelease(m_handles[i]);
         m_handles[i]=INVALID_HANDLE; m_names[i]="";
        }
     }
   bool Attach(const long chart,GuiAppliedConfiguration &config,CUniSignals &signals,const bool enabled,const int bars,string &error,
               const string plot_path="::Indicators\\UniSignalHistogram.ex5")
     {
      Clear(); m_chart=chart; error="";
      if(!enabled || (MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE))) return true;
      if(bars<1 || bars>5000) { error="Histogramas: use entre 1 e 5000 candles."; return false; }
      string configuration=UniHistogramConfiguration(config,signals); string parts[];
      if(StringSplit(configuration,'|',parts)!=6+UNI_SIGNAL_COUNT) { error="Configuracao visual invalida."; return false; }
      for(int i=0;i<4;i++)
        {
         if(config.indicators[i].type==GUI_INDICATOR_NONE) continue;
         string type=config.indicators[i].type==GUI_INDICATOR_MA ? "Media Movel" : config.indicators[i].type==GUI_INDICATOR_RSI ? "RSI" : "ADX";
         ENUM_TIMEFRAMES period=config.indicator_timeframes[i]==PERIOD_CURRENT ? ChartPeriod(chart) : config.indicator_timeframes[i];
         m_names[i]=StringFormat("UNI S %I64u | %d %s %s",GetMicrosecondCount(),i+1,type,EnumToString(period));
         m_handles[i]=iCustom(_Symbol,ChartPeriod(chart),plot_path,m_names[i],bars,i,(ENUM_TIMEFRAMES)StringToInteger(parts[1]),
                               parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8],parts[9],parts[10],parts[11],parts[12],parts[13],parts[14],parts[15]);
         if(m_handles[i]==INVALID_HANDLE || !ChartIndicatorAdd(chart,(int)ChartGetInteger(chart,CHART_WINDOWS_TOTAL),m_handles[i]))
           { error=StringFormat("Falha no histograma %d: %d",i+1,GetLastError()); Clear(); return false; }
        }
      return true;
     }
  };
#endif
