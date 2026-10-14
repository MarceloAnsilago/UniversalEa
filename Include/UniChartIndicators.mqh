#ifndef UNI_CHART_INDICATORS_MQH
#define UNI_CHART_INDICATORS_MQH
#include "Configuration/UniConfiguration.mqh"
// Unique short names identify only plots owned by this EA instance.
class CUniChartIndicators
  {
private:
   long m_chart;
   string m_names[4];
   int m_handles[4];
public:
   CUniChartIndicators() { m_chart=0; for(int i=0;i<4;i++) { m_names[i]=""; m_handles[i]=INVALID_HANDLE; } }
   ~CUniChartIndicators() { Clear(); }
   void Clear()
     {
      for(int i=3;i>=0;i--)
        {
         if(m_names[i]!="")
            for(int window=(int)ChartGetInteger(m_chart,CHART_WINDOWS_TOTAL)-1;window>=0;window--)
               for(int j=ChartIndicatorsTotal(m_chart,window)-1;j>=0;j--)
                  if(ChartIndicatorName(m_chart,window,j)==m_names[i])
                    { ChartIndicatorDelete(m_chart,window,m_names[i]); break; }
         if(m_handles[i]!=INVALID_HANDLE) IndicatorRelease(m_handles[i]);
         m_handles[i]=INVALID_HANDLE; m_names[i]="";
        }
      ChartRedraw(m_chart);
     }
   bool Attach(const long chart,GuiAppliedConfiguration &config,const int &usages[],const double &levels[],string &error)
     {
      Clear(); m_chart=chart; error="";
      if(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)) return true;
      ENUM_TIMEFRAMES period=config.setup.timeframe==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : config.setup.timeframe;
      if(ChartPeriod(chart)!=period)
        { error="Para exibir os indicadores, use no grafico o mesmo periodo configurado na estrategia: "+EnumToString(period); return false; }
      color colors[4]={clrDodgerBlue,clrOrange,clrMediumPurple,clrLimeGreen};
      string prefix=StringFormat("Uni %I64d %I64u",config.setup.magic,GetMicrosecondCount());
      for(int i=0;i<4;i++)
        {
         if(config.indicators[i].type==GUI_INDICATOR_NONE) continue;
         string type=config.indicators[i].type==GUI_INDICATOR_MA ? "MA" : config.indicators[i].type==GUI_INDICATOR_RSI ? "RSI" : "ADX";
         m_names[i]=StringFormat("%s | Slot %d %s %s",prefix,i+1,type,usages[i]==1 ? "Saida" : "Entrada");
         ResetLastError();
         if(config.indicators[i].type==GUI_INDICATOR_MA)
            m_handles[i]=iCustom(_Symbol,period,"::Indicators\\UniMaPlot.ex5",m_names[i],config.indicators[i].maPeriod,
                                config.indicators[i].maShift,config.indicators[i].maMethod,config.indicators[i].maPrice,colors[i]);
         else
            m_handles[i]=iCustom(_Symbol,period,"::Indicators\\UniOscillatorPlot.ex5",m_names[i],type=="RSI",
                                type=="RSI" ? config.indicators[i].rsiPeriod : config.indicators[i].adxPeriod,
                                config.indicators[i].rsiPrice,levels[i*3],levels[i*3+1],levels[i*3+2]);
         int window=type=="MA" ? 0 : (int)ChartGetInteger(chart,CHART_WINDOWS_TOTAL);
         if(m_handles[i]==INVALID_HANDLE || !ChartIndicatorAdd(chart,window,m_handles[i]))
           { int code=GetLastError(); error=StringFormat("Falha ao exibir slot %d. Erro %d.",i+1,code); Clear(); return false; }
        }
      ChartRedraw(chart); return true;
     }
  };
#endif
