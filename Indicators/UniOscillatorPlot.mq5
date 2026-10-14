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
double line0[],line1[],line2[];
int source=INVALID_HANDLE;
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[])
  {
   int available=BarsCalculated(source);
   if(available<rates_total) return prev_calculated;
   int count=MathMin(rates_total,available);
   if(prev_calculated>0) count=MathMin(count,rates_total-prev_calculated+1);
   if(count<=0) return prev_calculated;
   if(prev_calculated==0) { ArrayInitialize(line0,EMPTY_VALUE); ArrayInitialize(line1,EMPTY_VALUE); ArrayInitialize(line2,EMPTY_VALUE); }
   if(CopyBuffer(source,0,0,count,line0)!=count) return prev_calculated;
   if(!Rsi && (CopyBuffer(source,1,0,count,line1)!=count || CopyBuffer(source,2,0,count,line2)!=count)) return prev_calculated;
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
   source=Rsi ? iRSI(_Symbol,_Period,Length,Price) : iADX(_Symbol,_Period,Length);
   return source==INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED;
  }
