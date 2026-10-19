#property strict
#define private public
#include "../Include/UniSignals.mqh"
#include "../Include/Configuration/GuiSetFile.mqh"
#include "../Include/Configuration/UniInputOptions.mqh"
#undef private
// Synthetic buffers and clocks: these tests never send orders.
class MtfProbe : public CUniSignals
  {
public:
   datetime stamps[4];
   ENUM_TIMEFRAMES seen[22];
   int bars[22];
   bool ready;
   MtfProbe() { ready=true; for(int i=0;i<4;i++) stamps[i]=900; }
protected:
   virtual datetime SourceClock(MyUnEA *engine,const int source,const int rule,const datetime fallback)
     { int slot=Slot(source); return Constant(source) ? 0 : slot>=0 ? stamps[slot] : fallback; }
   virtual bool Read(MyUnEA *engine,const int source,const int bar,const double fixed_value,double &value)
     {
      if(!ready) return false;
      if(source<22) { seen[source]=m_read_period; bars[source]=bar; }
      value=source==9 ? fixed_value : source==0 ? 110 : source==10 ? 100 : 60;
      return true;
     }
  };
int checks=0,failures=0;
void Check(const bool condition,const string label)
  { checks++; if(!condition) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   CGuiState state; state.Reset(); GuiAppliedConfiguration config;
   config.setup=state.setup; config.rules=state.rules; config.management=state.management;
   for(int i=0;i<4;i++) { config.indicators[i]=state.indicators[i]; config.indicator_timeframes[i]=PERIOD_CURRENT; }
   config.indicators[0].type=GUI_INDICATOR_MA; config.indicator_timeframes[0]=PERIOD_M15;
   config.indicators[1].type=GUI_INDICATOR_RSI; config.indicator_timeframes[1]=PERIOD_M5;
   config.indicators[2].type=GUI_INDICATOR_ADX; config.indicator_timeframes[2]=PERIOD_H1;
   int usages[4]={0,0,1,0}; string error; int events;
   string rows[5]={"1,0,1,10,1,0,9,0,90,0,0","2,0,1,13,1,0,9,0,50,0,0","1,1,-1,16,1,0,9,0,50,0,0","",""};
   MtfProbe probe;
   Check(probe.Configure(rows,usages,"TEST",PERIOD_H4,config,error),"Configure three independent timeframes");
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==9,"Entry and exit groups evaluate initially");
   Check(probe.seen[10]==PERIOD_M15 && probe.seen[13]==PERIOD_M5 && probe.seen[16]==PERIOD_H1,"Each operand uses its slot period");
   Check(probe.bars[10]==1 && probe.bars[13]==1,"Anterior is candle 1 of each source");
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==0,"No repeated closed signals on the same source candles");
   probe.stamps[1]=1200;
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==1,"M5 can trigger before the H4 chart opens a new bar");
   Check(probe.ClosedEntryAfter(1,NULL,1000,100),"Activation gate follows the new M5 boundary");
   Check(!probe.ClosedEntryAfter(1,NULL,1200,100),"Activation gate does not consume the already open M5 candle");
   probe.stamps[2]=4500;
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==8,"H1 exit updates independently from entry periods");
   probe.stamps[1]=1500; probe.ready=false;
   Check(!probe.Evaluate(NULL,100,0.01,events,error),"Unavailable data prevents evaluation");
   probe.ready=true;
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==1,"Failed snapshots do not consume M5 boundaries");
   rows[0]="1,0,1,0,1,0,10,1,0,0,0"; rows[1]=""; rows[2]="";
   Check(probe.Configure(rows,usages,"TEST",PERIOD_H4,config,error),"Configure price versus M15 MA");
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==1 && probe.seen[0]==PERIOD_M15,"Price candle inherits the referenced indicator period");
   MyUnEA engine;
   Check(engine.Configure(_Symbol,config,error) && engine.IndicatorPeriod(0)==PERIOD_M15 && engine.IndicatorPeriod(1)==PERIOD_M5 && engine.IndicatorPeriod(2)==PERIOD_H1,"Engine retains each handle period");
   for(int i=0;i<=21;i++) Check(GuiSetupTimeframeIndex(UniSlotTimeframe((ENUM_UNI_SLOT_TIMEFRAME)i))>=0,"Optimization index maps to a valid timeframe");
   Check(UniSlotTimeframe(UNI_SLOT_M15)==PERIOD_M15 && UniSlotTimeframe(UNI_SLOT_H1)==PERIOD_H1,"Sparse terminal values map from contiguous optimization indices");
   state.setup.name="MTF test"; state.setup.magic=123456; state.setup.set_id=GuiNewSetId(state.setup.magic);
   state.indicator_timeframes[0]=PERIOD_M15; state.indicator_timeframes[1]=PERIOD_M5; state.indicator_timeframes[2]=PERIOD_H1;
   GuiSetRecord record; CGuiState loaded;
   Check(GuiEncodeSet(state,record,error) && record.version==12 && GuiDecodeSet(record,loaded,error),"New binary preset version round-trips");
   Check(loaded.indicator_timeframes[0]==PERIOD_M15 && loaded.indicator_timeframes[1]==PERIOD_M5 && loaded.indicator_timeframes[2]==PERIOD_H1,"Binary preset preserves independent periods");
   record.version=11; record.timeframe=PERIOD_H4;
   Check(GuiDecodeSet(record,loaded,error) && loaded.indicator_timeframes[0]==PERIOD_H4 && loaded.indicator_timeframes[2]==PERIOD_H4,"Legacy binary presets inherit the old global period");
   PrintFormat("[MultiTimeframeTests] %d checks, %d failures",checks,failures);
  }
