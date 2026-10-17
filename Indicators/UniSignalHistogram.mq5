#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 1
#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 clrDodgerBlue,clrRed,clrGray
#property indicator_width1 4
#property indicator_minimum 0
#property indicator_maximum 1.35
input string DisplayName="UNI sinais";
input int HistoryBars=300;
input string SnapshotFile="";
double values[],colors[];
long revision=-1;
int OnInit()
  {
   SetIndexBuffer(0,values,INDICATOR_DATA); SetIndexBuffer(1,colors,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(values,true); ArraySetAsSeries(colors,true);
   IndicatorSetString(INDICATOR_SHORTNAME,DisplayName);
   PlotIndexSetString(0,PLOT_LABEL,"Compra / Venda / Neutro");
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetInteger(INDICATOR_HEIGHT,65);
   EventSetTimer(1); return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason) { EventKillTimer(); }
bool ReadSnapshot()
  {
   if(ArraySize(values)==0 || SnapshotFile=="") return false;
   int file=FileOpen(SnapshotFile,FILE_BIN|FILE_READ|FILE_SHARE_READ|FILE_SHARE_WRITE);
   if(file==INVALID_HANDLE) return false;
   long next=FileReadLong(file);
   if(next==0 || next==revision) { FileClose(file); return false; }
   int count=(int)MathMin(HistoryBars,(FileSize(file)-8)/12);
   for(int i=0;i<count;i++)
     {
      datetime time=(datetime)FileReadLong(file); int state=FileReadInteger(file);
      int bar=iBarShift(_Symbol,_Period,time,true);
      if(bar<0 || bar>=ArraySize(values) || bar>=HistoryBars) continue;
      values[bar]=state==2 ? EMPTY_VALUE : 1.0;
      colors[bar]=state==1 ? 0 : state==-1 ? 1 : 2;
     }
   revision=next; FileClose(file); return true;
  }
void OnTimer() { if(ReadSnapshot()) ChartRedraw(); }
int OnCalculate(const int total,const int calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tv[],const long &vol[],const int &spread[])
  {
   if(calculated==0) { ArrayInitialize(values,EMPTY_VALUE); revision=-1; }
   else if(total>calculated) for(int i=0;i<MathMin(total-calculated,total);i++) values[i]=EMPTY_VALUE;
   ReadSnapshot();
   for(int i=HistoryBars;i<MathMin(total,HistoryBars+MathMax(1,total-calculated));i++) values[i]=EMPTY_VALUE;
   return total;
  }
