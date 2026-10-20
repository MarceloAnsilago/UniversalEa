#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 1
#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 clrDodgerBlue,clrRed,clrGray
#property indicator_width1 4
#property indicator_minimum 0
#property indicator_maximum 1.35
#include "../Include/UniHistogramEvaluation.mqh"
input string DisplayName="UNI sinais";
input int HistoryBars=300;
input int Slot=0;
input ENUM_TIMEFRAMES EvaluationPeriod=PERIOD_CURRENT;
input string Slot1Configuration="";
input string Slot2Configuration="";
input string Slot3Configuration="";
input string Slot4Configuration="";
input string Rule1="";
input string Rule2="";
input string Rule3="";
input string Rule4="";
input string Rule5="";
double histogram_values[],colors[];
CUniHistogramEvaluation evaluation;
int OnInit()
  {
   if(Slot<0 || Slot>=4 || HistoryBars<1 || HistoryBars>5000) return INIT_PARAMETERS_INCORRECT;
   SetIndexBuffer(0,histogram_values,INDICATOR_DATA); SetIndexBuffer(1,colors,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(histogram_values,true); ArraySetAsSeries(colors,true);
   IndicatorSetString(INDICATOR_SHORTNAME,DisplayName); IndicatorSetInteger(INDICATOR_HEIGHT,65);
   PlotIndexSetString(0,PLOT_LABEL,"Compra / Venda / Neutro"); PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   string error;
   string configuration="v1|"+IntegerToString((int)EvaluationPeriod)+"|"+Slot1Configuration+"|"+Slot2Configuration+"|"+Slot3Configuration+"|"+Slot4Configuration+
                        "|"+Rule1+"|"+Rule2+"|"+Rule3+"|"+Rule4+"|"+Rule5;
   if(!evaluation.Initialize(configuration,error)) { Print("Histograma: ",error); return INIT_PARAMETERS_INCORRECT; }
   return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason) { evaluation.Release(); }
void SetState(const int bar,const int state)
  { histogram_values[bar]=state==2 ? EMPTY_VALUE : 1.0; colors[bar]=state==1 ? 0 : state==-1 ? 1 : 2; }
int OnCalculate(const int total,const int calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tv[],const long &vol[],const int &spread[])
  {
   ArraySetAsSeries(time,true);
   if(calculated==0) ArrayInitialize(histogram_values,EMPTY_VALUE);
   evaluation.BeginCalculation();
   string error; int events;
   if(!evaluation.Evaluate(NULL,iTime(_Symbol,evaluation.clock_period,0),_Point,events,error)) return calculated;
   int count=calculated==0 ? MathMin(total,HistoryBars) : MathMin(total-calculated+1,HistoryBars);
   for(int b=count-1;b>=1;b--) SetState(b,evaluation.VisualStateAt(NULL,Slot,time[b],_Point));
   SetState(0,evaluation.VisualState(NULL,Slot,0,_Point));
   for(int b=HistoryBars;b<MathMin(total,HistoryBars+MathMax(1,total-calculated));b++) histogram_values[b]=EMPTY_VALUE;
   return total;
  }
