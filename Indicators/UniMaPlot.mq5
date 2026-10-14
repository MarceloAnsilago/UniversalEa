#property strict
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
input string DisplayName="Uni MA";
input int Length=20;
input int Shift=0;
input ENUM_MA_METHOD Method=MODE_EMA;
input ENUM_APPLIED_PRICE Price=PRICE_CLOSE;
input color LineColor=clrDodgerBlue;
double line0[];
int source=INVALID_HANDLE;
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
  {
   int available=BarsCalculated(source);
   if(available<rates_total) return prev_calculated;
   int count=MathMin(rates_total,available);
   if(prev_calculated>0) count=MathMin(count,rates_total-prev_calculated+1);
   if(count<=0) return prev_calculated;
   if(prev_calculated==0) { ArrayInitialize(line0,EMPTY_VALUE); }
   if(CopyBuffer(source,0,0,count,line0)!=count) return prev_calculated;
   
   return rates_total;
  }
void OnDeinit(const int reason) { if(source!=INVALID_HANDLE) IndicatorRelease(source); }

int OnInit()
  {
   SetIndexBuffer(0,line0,INDICATOR_DATA); ArraySetAsSeries(line0,true);
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,LineColor);
   PlotIndexSetString(0,PLOT_LABEL,DisplayName);
   IndicatorSetString(INDICATOR_SHORTNAME,DisplayName);
   source=iMA(_Symbol,_Period,Length,0,Method,Price);
   return source==INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED;
  }
