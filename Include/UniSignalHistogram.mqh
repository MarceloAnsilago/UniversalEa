#ifndef UNI_SIGNAL_HISTOGRAM_MQH
#define UNI_SIGNAL_HISTOGRAM_MQH
#include "UniSignals.mqh"
// EA-owned bounded binary snapshots: shared with the display, never with order logic.
class CUniSignalHistogram
  {
private:
   long m_chart;
   int m_handles[4],m_last[4],m_files[4],m_bars,m_cursor;
   long m_revision;
   string m_paths[4];
   string m_names[4];
   datetime m_time;
   bool m_initial;
public:
   CUniSignalHistogram() { m_chart=0; m_cursor=0; m_revision=0; m_time=0; m_initial=true; m_bars=300; for(int i=0;i<4;i++) { m_handles[i]=INVALID_HANDLE; m_files[i]=INVALID_HANDLE; m_paths[i]=""; m_names[i]=""; m_last[i]=99; } }
   ~CUniSignalHistogram() { Clear(); }
   void Clear()
     {
      for(int i=3;i>=0;i--)
        {
         if(m_names[i]!="")
            for(int w=(int)ChartGetInteger(m_chart,CHART_WINDOWS_TOTAL)-1;w>0;w--)
               if(ChartWindowFind(m_chart,m_names[i])==w) ChartIndicatorDelete(m_chart,w,m_names[i]);
         if(m_handles[i]!=INVALID_HANDLE) IndicatorRelease(m_handles[i]);
         if(m_files[i]!=INVALID_HANDLE) FileClose(m_files[i]);
         if(m_paths[i]!="") FileDelete(m_paths[i]);
         m_files[i]=INVALID_HANDLE; m_paths[i]="";
         m_handles[i]=INVALID_HANDLE; m_names[i]=""; m_last[i]=99;
        }
      m_time=0; m_initial=true; m_cursor=0; m_revision=0;
     }
   bool Attach(const long chart,GuiAppliedConfiguration &config,const bool enabled,const int bars,string &error,const string plot_path="::Indicators\\UniSignalHistogram.ex5")
     {
      Clear(); m_chart=chart; m_bars=bars; error="";
      if(!enabled || (MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE))) return true;
      if(bars<1 || bars>5000) { error="Histogramas: use entre 1 e 5000 candles."; return false; }
      ENUM_TIMEFRAMES period=config.setup.timeframe==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : config.setup.timeframe;
      if(ChartPeriod(chart)!=period) { error="Histogramas: use o periodo da estrategia no grafico."; return false; }
      for(int i=0;i<4;i++)
        {
         if(config.indicators[i].type==GUI_INDICATOR_NONE) continue;
         string type=config.indicators[i].type==GUI_INDICATOR_MA ? "Media Movel" : config.indicators[i].type==GUI_INDICATOR_RSI ? "RSI" : "ADX";
         m_names[i]=StringFormat("UNI S %I64u | %d %s",GetMicrosecondCount(),i+1,type);
         m_paths[i]=StringFormat("UNI_Hist_%I64d_%I64u_%d.bin",chart,GetMicrosecondCount(),i);
         m_files[i]=FileOpen(m_paths[i],FILE_BIN|FILE_READ|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE);
         if(m_files[i]==INVALID_HANDLE) { error="Falha no canal visual de sinais."; Clear(); return false; }
         FileWriteLong(m_files[i],0); FileFlush(m_files[i]);
         m_handles[i]=iCustom(_Symbol,period,plot_path,m_names[i],bars,m_paths[i]);
         if(m_handles[i]==INVALID_HANDLE || !ChartIndicatorAdd(chart,(int)ChartGetInteger(chart,CHART_WINDOWS_TOTAL),m_handles[i]))
           { error=StringFormat("Falha no histograma %d: %d",i+1,GetLastError()); Clear(); return false; }
        }
      return true;
     }
   void Refresh(MyUnEA *engine,CUniSignals &signals,const string symbol,const ENUM_TIMEFRAMES period)
     {
      bool any=false; for(int i=0;i<4;i++) if(m_handles[i]!=INVALID_HANDLE) any=true;
      if(!any) return;
      datetime now=iTime(symbol,period,0); if(now==0) return;
      bool history=m_initial;
      if(!m_initial && now!=m_time) m_cursor=(m_cursor+m_bars-1)%m_bars;
      m_revision++;
      for(int slot=0;slot<4;slot++)
        {
         if(m_handles[slot]==INVALID_HANDLE) continue;

         int current=signals.VisualState(engine,slot,0,SymbolInfoDouble(symbol,SYMBOL_POINT));
         if(history)
            for(int b=MathMin(m_bars-1,Bars(symbol,period)-1);b>0;b--)
              {
               int state=signals.VisualState(engine,slot,b,SymbolInfoDouble(symbol,SYMBOL_POINT));
               FileSeek(m_files[slot],8+b*12,SEEK_SET);
               FileWriteLong(m_files[slot],(long)iTime(symbol,period,b)); FileWriteInteger(m_files[slot],state);
              }
         if(history || current!=m_last[slot] || now!=m_time)
           {
            FileSeek(m_files[slot],8+m_cursor*12,SEEK_SET);
            FileWriteLong(m_files[slot],(long)now); FileWriteInteger(m_files[slot],current);
            FileSeek(m_files[slot],0,SEEK_SET); FileWriteLong(m_files[slot],m_revision); FileFlush(m_files[slot]);
            m_last[slot]=current;
           }
        }
      m_time=now; m_initial=false;
     }
  };
#endif
