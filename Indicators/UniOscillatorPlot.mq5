#property strict
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots 3
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_color2 clrLimeGreen
#property indicator_color3 clrTomato
input string DisplayName="Uni oscillator";
input bool Rsi=true;
input int Length=14;
input ENUM_APPLIED_PRICE Price=PRICE_CLOSE;
input double Upper=70;
input double Middle=50;
input double Lower=30;
input ENUM_TIMEFRAMES SourcePeriod=PERIOD_CURRENT;
double line0[],line1[],line2[];
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
   if(!Rsi && (CopyBuffer(source,1,0,needed,values1)!=needed || CopyBuffer(source,2,0,needed,values2)!=needed)) return prev_calculated;
   for(int i=0;i<count;i++)
     {
      int shift=i==0 ? 0 : iBarShift(_Symbol,period,time[i],false);
      line0[i]=shift>=0 && shift<needed ? values0[shift] : EMPTY_VALUE;
      line1[i]=!Rsi && shift>=0 && shift<needed ? values1[shift] : EMPTY_VALUE;
      line2[i]=!Rsi && shift>=0 && shift<needed ? values2[shift] : EMPTY_VALUE;
     }
   return rates_total;
  }
void OnDeinit(const int reason) { if(source!=INVALID_HANDLE) IndicatorRelease(source); }

int OnInit()
  {
   SetIndexBuffer(0,line0,INDICATOR_DATA); ArraySetAsSeries(line0,true);
   SetIndexBuffer(1,line1,INDICATOR_DATA); ArraySetAsSeries(line1,true);
   SetIndexBuffer(2,line2,INDICATOR_DATA); ArraySetAsSeries(line2,true);
   IndicatorSetString(INDICATOR_SHORTNAME,DisplayName);
   PlotIndexSetString(0,PLOT_LABEL,Rsi ? "RSI" : "ADX");
   PlotIndexSetString(1,PLOT_LABEL,"+DI"); PlotIndexSetString(2,PLOT_LABEL,"-DI");
   if(Rsi)
     {
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE); PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
      IndicatorSetDouble(INDICATOR_MINIMUM,0); IndicatorSetDouble(INDICATOR_MAXIMUM,100);
      IndicatorSetInteger(INDICATOR_LEVELS,3);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,0,Upper);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,1,Middle);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,2,Lower);
      IndicatorSetString(INDICATOR_LEVELTEXT,0,"Superior");
      IndicatorSetString(INDICATOR_LEVELTEXT,1,"Medio");
      IndicatorSetString(INDICATOR_LEVELTEXT,2,"Inferior");
     }
   source=Rsi ? iRSI(_Symbol,SourcePeriod,Length,Price) : iADX(_Symbol,SourcePeriod,Length);
   return source==INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED;
  }
