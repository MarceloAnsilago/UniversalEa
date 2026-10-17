#property strict
#include "../Include/UniSignalHistogram.mqh"
class HistogramProbe : public CUniSignals
  {
protected:
   virtual bool Read(MyUnEA *engine,const int source,const int bar,const double fixed_value,double &value)
     { value=source==9 ? fixed_value : source==10 ? 110 : source==13 ? 90 : 100; return true; }
  };
int failures=0,checks=0;
void Check(bool ok,string label) { checks++; if(!ok) { failures++; Print("FAIL: ",label," error=",GetLastError()); } }
void OnStart()
  {
   int initial=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
   CGuiState defaults; GuiAppliedConfiguration config;
   config.setup=defaults.setup; config.setup.timeframe=(ENUM_TIMEFRAMES)_Period;
   for(int i=0;i<4;i++) { config.indicators[i]=defaults.indicators[i]; config.indicators[i].type=i<3 ? GUI_INDICATOR_MA : GUI_INDICATOR_NONE; }
   CUniSignalHistogram panel; HistogramProbe signals; string error; int events;
   int usages[4]={0,0,0,0};
   string rows[5]={"1,0,1,10,1,0,9,0,100,0,0","1,0,-1,13,1,1,9,0,100,0,0","3,0,1,16,1,0,9,0,100,0,0","",""};
   Check(signals.Configure(rows,usages,_Symbol,(ENUM_TIMEFRAMES)_Period,config,error),"Configure shared rules");
   Check(signals.Evaluate(NULL,iTime(_Symbol,_Period,0),_Point,events,error),"Evaluate shared rules");
   Check(panel.Attach(0,config,false,20,error,"UniSignalHistogram"),"Disabled attach");
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial,"Disabled creates no windows");
   Check(panel.Attach(0,config,true,20,error,"UniSignalHistogram"),"Three enabled indicators attach");
   panel.Refresh(NULL,signals,_Symbol,(ENUM_TIMEFRAMES)_Period); ChartRedraw(); Sleep(2200);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial+3,"Three independent windows");
   for(int i=0;i<3;i++)
     {
      string name=ChartIndicatorName(0,initial+i,0); int handle=ChartIndicatorGet(0,initial+i,name);
      double height[],palette[];
      Check(handle!=INVALID_HANDLE && CopyBuffer(handle,0,0,1,height)==1 && height[0]==1,"Fixed height for slot "+IntegerToString(i));
      Check(CopyBuffer(handle,1,0,1,palette)==1 && palette[0]==i,"Buy sell neutral colors for slot "+IntegerToString(i));
      if(handle!=INVALID_HANDLE) IndicatorRelease(handle);
     }
   panel.Clear(); ChartRedraw(); Sleep(250);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial,"Clear removes owned windows");
   config.indicators[1].type=GUI_INDICATOR_NONE; config.indicators[2].type=GUI_INDICATOR_NONE;
   Check(panel.Attach(0,config,true,20,error,"UniSignalHistogram"),"One enabled indicator attaches");
   ChartRedraw(); Sleep(300);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial+1,"One enabled indicator has one window");
   panel.Clear();
   PrintFormat("[HistogramPanelTests] %d checks, %d failures",checks,failures);
  }
