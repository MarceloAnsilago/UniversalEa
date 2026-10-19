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
input ENUM_TIMEFRAMES SourcePeriod=PERIOD_CURRENT;
double line0[];
int source=INVALID_HANDLE;
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
  {
   int available=BarsCalculated(source);
   if(available<=0 || rates_total<=0) return prev_calculated;
   ArraySetAsSeries(time,true);
   int count=prev_calculated==0 ? rates_total : MathMin(rates_total,rates_total-prev_calculated+1);
   ENUM_TIMEFRAMES period=SourcePeriod==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : SourcePeriod;
   // Refresh every chart bar inside the current source candle as its value changes.
   int active=iBarShift(_Symbol,(ENUM_TIMEFRAMES)_Period,iTime(_Symbol,period,0),false);
   if(active>=0) count=MathMax(count,MathMin(rates_total,active+1));
   int oldest=iBarShift(_Symbol,period,time[count-1],false);
   int needed=oldest<0 ? available : MathMin(available,oldest+1);
   double values0[],values1[],values2[];
   ArraySetAsSeries(values0,true); ArraySetAsSeries(values1,true); ArraySetAsSeries(values2,true);
   if(needed<=0 || CopyBuffer(source,0,0,needed,values0)!=needed) return prev_calculated;
   for(int i=0;i<count;i++)
     {
      int shift=i==0 ? 0 : iBarShift(_Symbol,period,time[i],false);
      line0[i]=shift>=0 && shift<needed ? values0[shift] : EMPTY_VALUE;
     }
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
   source=iMA(_Symbol,SourcePeriod,Length,0,Method,Price);
   return source==INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED;
  }
