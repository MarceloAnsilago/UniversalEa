#property strict
#include "../Include/UniOrderMath.mqh"
int checks=0,failures=0;
void Check(const bool ok,const string label)
  { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
bool Near(const double a,const double b) { return MathAbs(a-b)<1e-7; }
void OnStart()
  {
   CGuiRulesState rules; MqlRates candle; ZeroMemory(candle);
   candle.time=D'2026.09.25 09:00'; candle.open=98; candle.close=102; candle.high=104; candle.low=96;
   string error; double sl,tp;
   rules.stop_loss=2; rules.stop_multiplier=1; rules.take_multiplier=2;
   Check(UniOrderTargets(rules,1,100,candle,1,0.5,2,sl,tp,error) && Near(sl,90) && Near(tp,120),"Buy: fixed plus candle stop, take multiple");
   Check(UniOrderTargets(rules,-1,100,candle,1,0.5,2,sl,tp,error) && Near(sl,110) && Near(tp,80),"Sell: symmetric targets");
   rules.stop_measure=1;
   Check(UniOrderTargets(rules,1,100,candle,1,0.5,2,sl,tp,error) && Near(sl,94) && Near(tp,112),"Body stop");
   rules.take_mode=1; rules.take_profit=3;
   Check(UniOrderTargets(rules,1,100,candle,1,0.5,2,sl,tp,error) && Near(tp,103),"Fixed take excludes multiple");
   rules.target_unit=GUI_TARGET_PERCENT; rules.stop_multiplier=0; rules.stop_loss=1; rules.take_profit=2;
   Check(UniOrderTargets(rules,1,200,candle,0.01,0.01,2,sl,tp,error) && Near(sl,198) && Near(tp,204),"Percent uses entry");
   rules.stop_loss=0; rules.take_profit=0;
   Check(UniOrderTargets(rules,1,100,candle,1,0.5,2,sl,tp,error) && sl==0 && tp==0,"Disabled targets");
   rules.take_mode=0; rules.take_multiplier=2;
   Check(!UniOrderTargets(rules,1,100,candle,1,0.5,2,sl,tp,error),"Reject take multiple without stop");
   rules.stop_multiplier=1; candle.open=100; candle.close=100;
   Check(!UniOrderTargets(rules,1,100,candle,1,0.5,2,sl,tp,error),"Reject configured zero body stop");
   rules.stop_measure=0; candle.low=105;
   Check(!UniOrderTargets(rules,1,100,candle,1,0.5,2,sl,tp,error),"Reject malformed candle");
   Check(Near(UniPriceGrid(100.24,0.5,2,-1),100) && Near(UniPriceGrid(100.24,0.5,2,1),100.5),"Tick rounding directional");
   MqlTick quote; ZeroMemory(quote); quote.bid=100; quote.ask=101;
   Check(UniPendingType(1,102,quote)==ORDER_TYPE_BUY_STOP,"Buy stop above ask");
   Check(UniPendingType(1,99,quote)==ORDER_TYPE_BUY_LIMIT,"Buy limit below ask");
   Check(UniPendingType(-1,99,quote)==ORDER_TYPE_SELL_STOP,"Sell stop below bid");
   Check(UniPendingType(-1,102,quote)==ORDER_TYPE_SELL_LIMIT,"Sell limit above bid");
   Check(UniEntryDeadline(D'2026.09.25 10:00',540,1080)==D'2026.09.25 18:00',"Day deadline");
   Check(UniEntryDeadline(D'2026.09.25 23:00',1320,120)==D'2026.09.26 02:00',"Overnight deadline before midnight");
   Check(UniEntryDeadline(D'2026.09.26 01:00',1320,120)==D'2026.09.26 02:00',"Overnight deadline after midnight");
   Check(!UniEntryWindow(540,1080,D'2026.09.25 18:00'),"End exclusive");
   Check(UniEntryWindow(1320,120,D'2026.09.26 01:59'),"Overnight allowed");
   CGuiManagementState management; management.Reset();
   Check(UniManagedStop(management,1,100,110,90,1,0.5,2,true)==90,"Disabled management preserves stop");
   management.mode[0]=1; management.values[0]=5; management.values[1]=1;
   Check(UniManagedStop(management,1,100,104,90,1,0.5,2,false)==90,"Before BE trigger");
   Check(UniManagedStop(management,1,100,105,90,1,0.5,2,false)==101,"Buy breakeven");
   Check(UniManagedStop(management,-1,100,95,110,1,0.5,2,false)==99,"Sell breakeven");
   Check(UniManagedStop(management,1,100,105,103,1,0.5,2,false)==103,"BE never loosens stop");
   management.mode[1]=1; management.values[2]=5; management.values[3]=2; management.values[4]=1;
   Check(UniManagedStop(management,1,100,110,90,1,0.5,2,false)==108,"Trailing tighter than BE");
   Check(UniManagedStop(management,-1,100,90,110,1,0.5,2,false)==92,"Sell trailing");
   Check(UniManagedStop(management,1,100,110.5,108,1,0.5,2,false)==108,"Trailing minimum step");
   Check(UniManagedStop(management,1,100,109,108,1,0.5,2,false)==108,"Trailing never retreats");
   management.Reset(); management.mode[2]=1; management.values[5]=5; management.values[6]=2; management.values[7]=1;
   Check(UniManagedStop(management,1,100,110,90,1,0.5,2,false)==90,"Moving stop waits for bar");
   Check(UniManagedStop(management,1,100,110,90,1,0.5,2,true)==108,"Moving stop on new bar");
   management.Reset(); management.mode[0]=2; management.values[0]=1; management.values[1]=0.5;
   Check(UniManagedStop(management,1,200,202,0,0.01,0.01,2,false)==201,"Percent BE uses opening price");
   PrintFormat("[OrderLogicTests] %d checks, %d failures",checks,failures);
  }
