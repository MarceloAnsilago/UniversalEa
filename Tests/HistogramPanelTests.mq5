#property strict
#include "../Include/UniSignalHistogram.mqh"
int failures=0,checks=0;
void Check(bool ok,string label) { checks++; if(!ok) { failures++; Print("FAIL: ",label," error=",GetLastError()); } }
void OnStart()
  {
   int initial=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
   CGuiState defaults; defaults.Reset(); GuiAppliedConfiguration config; config.setup=defaults.setup;
   for(int i=0;i<4;i++) { config.indicators[i]=defaults.indicators[i]; config.indicators[i].type=i<3 ? GUI_INDICATOR_MA : GUI_INDICATOR_NONE; }
   CUniSignalHistogram panel; CUniSignals signals; string error;
   int usages[4]={0,0,0,0};
   string rows[5]={"1,0,1,10,1,0,9,0,0,0,0","1,0,-1,13,1,0,9,0,0,0,0","3,0,1,16,1,1,9,0,0,0,0","",""};
   Check(signals.Configure(rows,usages,_Symbol,(ENUM_TIMEFRAMES)_Period,config,error),"Configure shared rules");
   string packed=UniHistogramConfiguration(config,signals); CUniHistogramEvaluation evaluation;
   Check(evaluation.Initialize(packed,error),"Visual configuration round trip including empty rows");
   Check(panel.Attach(0,config,signals,false,20,error,"UniSignalHistogram"),"Disabled attach");
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial,"Disabled creates no windows");
   Check(panel.Attach(0,config,signals,true,20,error,"UniSignalHistogram"),"Three enabled indicators attach");
   ChartRedraw(); Sleep(1500);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial+3,"Three independent windows");
   string names[3];
   for(int i=0;i<3;i++)
     {
      names[i]=ChartIndicatorName(0,initial+i,0); int handle=ChartIndicatorGet(0,initial+i,names[i]);
      double heights[],palette[];
      Check(handle!=INVALID_HANDLE && CopyBuffer(handle,0,0,20,heights)==20 && heights[19]==1,"Fixed current height for slot "+IntegerToString(i));
      Check(CopyBuffer(handle,1,0,20,palette)==20 && palette[19]==i,"Buy sell neutral colors for slot "+IntegerToString(i));
      bool history=true; for(int b=0;b<ArraySize(heights);b++) if(heights[b]!=1) history=false;
      Check(history,"All retained candles populated for slot "+IntegerToString(i));
      if(handle!=INVALID_HANDLE) IndicatorRelease(handle);
     }
   int events; datetime bar=iTime(_Symbol,_Period,0); ulong start=GetMicrosecondCount();
   for(int tick=0;tick<5000;tick++) { evaluation.BeginCalculation(); evaluation.Evaluate(NULL,bar,_Point,events,error); }
   Check(error=="","5000 evaluations of shared conditions without data errors");
   PrintFormat("[HistogramPerformance] evaluations=5000 elapsed_us=%I64u",GetMicrosecondCount()-start);
   Check(evaluation.VisualState(NULL,0,0,_Point)==1 && evaluation.VisualState(NULL,1,0,_Point)==-1 && evaluation.VisualState(NULL,2,0,_Point)==0,"Shared evaluator agrees with visual buffers");
   panel.Clear(true); ChartRedraw(); Sleep(250);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial+3,"Final display survives producer cleanup without a channel");
   for(int i=2;i>=0;i--)
     {
      int w=ChartWindowFind(0,names[i]); int h=ChartIndicatorGet(0,w,names[i]); double height[];
      Check(h!=INVALID_HANDLE && CopyBuffer(h,0,0,1,height)==1 && height[0]==1,"Final buffer remains readable after producer cleanup");
      if(w>0) ChartIndicatorDelete(0,w,names[i]); if(h!=INVALID_HANDLE) IndicatorRelease(h);
     }
   ChartRedraw(); Sleep(250);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial,"Owned final windows can be removed");
   config.indicators[1].type=GUI_INDICATOR_NONE; config.indicators[2].type=GUI_INDICATOR_NONE;
   rows[1]=""; rows[2]="";
   Check(signals.Configure(rows,usages,_Symbol,(ENUM_TIMEFRAMES)_Period,config,error),"One-slot rules configured");
   Check(panel.Attach(0,config,signals,true,20,error,"UniSignalHistogram"),"One enabled indicator attaches");
   ChartRedraw(); Sleep(300);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial+1,"One enabled indicator has one window");
   panel.Clear(); ChartRedraw(); Sleep(250);
   Check((int)ChartGetInteger(0,CHART_WINDOWS_TOTAL)==initial,"Normal cleanup removes owned windows");
   PrintFormat("[HistogramPanelTests] %d checks, %d failures",checks,failures);
  }
