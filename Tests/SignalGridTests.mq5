#property strict
#include "../Include/UniSignals.mqh"
// Fully synthetic: no handles, account changes or OrderSend.
class SignalProbe : public CUniSignals
  {
public:
   double samples[22][5];
   bool ready;
   SignalProbe() { ready=true; for(int i=0;i<22;i++) for(int j=0;j<5;j++) samples[i][j]=100; }
protected:
   virtual bool Read(MyUnEA *engine,const int source,const int bar,const double fixed_value,double &value)
     { if(!ready || bar<0 || bar>4) return false; value=source==9 ? fixed_value : samples[source][bar]; return true; }
  };
class LevelProbe : public CUniSignals
  {
public:
   bool ReadLevel(const int source,const int bar,double &value) { return CUniSignals::Read(NULL,source,bar,0,value); }
  };
int failures=0,checks=0;
void Check(bool ok,string label) { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   SignalProbe probe; GuiAppliedConfiguration config; CGuiState state;
   for(int i=0;i<4;i++) config.indicators[i]=state.indicators[i];
   config.indicators[0].type=GUI_INDICATOR_MA; config.indicators[1].type=GUI_INDICATOR_MA;
   int usages[4]={0,1,0,0}; string rows[5]={"1,0,1,10,0,6,9,0,100,0,0","1,1,-1,13,0,6,9,0,110,0,0","","",""};
   string error; int events;
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Parse entry and exit with independent buffers");
   Check(probe.LiveEntry(1) && !probe.LiveEntry(-1),"Current entry does not wait for bar close");
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==1,"Current touch enters immediately");
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==0,"Same touch does not repeat");
   probe.samples[13][0]=110;
   Check(probe.Evaluate(NULL,100,0.01,events,error) && events==8,"Exit sell closes buy on the same bar");
   Check(probe.Evaluate(NULL,101,0.01,events,error) && events==0,"Persistent live touch remains latched across bars");
   probe.ready=false;
   Check(!probe.Evaluate(NULL,102,0.01,events,error) && events==0,"Missing data cannot trade"); probe.ready=true;
   rows[0]="1,0,1,10,3,7,9,0,100,0,0"; rows[1]="";
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Closed crossing on antepenultimate bar");
   Check(!probe.LiveEntry(1),"Closed entry waits for a new bar");
   probe.samples[10][3]=101; probe.samples[10][4]=99;
   Check(probe.Evaluate(NULL,200,0.01,events,error) && events==1,"Uses bar 4 for previous crossing sample");
   Check(probe.Evaluate(NULL,200,0.01,events,error) && events==0,"Closed condition evaluated once per bar");
   Check(probe.Evaluate(NULL,201,0.01,events,error) && events==1,"Next closed bar is evaluated");
   rows[0]="1,0,1,10,0,9,9,0,100,0,0";
   Check(!probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Cross and close rejects current candle");
   rows[0]="1,1,1,10,0,6,9,0,100,0,0";
   Check(!probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Usage must match selected indicator");
   rows[0]="1,0,1,11,0,6,9,0,100,0,0";
   Check(!probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"MA has no buffer 1");
   rows[0]="1,0,1,10,1,0,9,0,50,0,0";
   rows[1]="3,0,1,10,1,0,9,0,200,0,0";
   rows[2]="2,0,1,10,1,0,9,0,200,0,0";
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Configure OR followed by AND");
   Check(probe.Evaluate(NULL,300,0.01,events,error) && events==1,"AND has precedence over OR");
   rows[1]="1,0,-1,10,1,0,9,0,50,0,0"; rows[2]="";
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Opposite entry groups are independent");
   Check(probe.Evaluate(NULL,301,0.01,events,error) && events==3,"Conflicting entries are exposed for runtime to suppress");
   for(int op=0;op<11;op++)
      Check(!UniSignalCompare(op,100,100,99,100,0,false) || op==2 || op==3 || op==4 || op==6,"Equality and first tick comparison");
   Check(UniSignalCompare(6,101,100,99,100,0,true),"Touch detects crossing between ticks");
   Check(UniSignalCompare(7,101,100,99,100,0,true),"Upward crossing");
   Check(UniSignalCompare(8,99,100,101,100,0,true),"Downward crossing");
   LevelProbe levelsProbe;
   config.indicators[0].type=GUI_INDICATOR_RSI;
   rows[0]="1,0,1,10,1,9,22,0,0,0,0"; rows[1]="";
   Check(levelsProbe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Closed RSI crossing accepts constant level");
   Check(!levelsProbe.LiveEntry(1),"Constant level does not turn closed signal into tick signal");
   double levels[12]={75.5,51,25,70,50,30,70,50,30,70,50,30};
   Check(levelsProbe.ConfigureRsiLevels(levels,config,error),"Configure decimal RSI levels");
   for(int i=0;i<3;i++) { double value; Check(levelsProbe.ReadLevel(22+i,4,value) && value==levels[i],"Read configured level independent of candle"); }
   rows[0]="1,0,1,24,0,9,10,1,0,0,0";
   Check(levelsProbe.Configure(rows,usages,"TEST",PERIOD_M1,config,error) && !levelsProbe.LiveEntry(1),"Constant A accepts closed RSI reference");
   levels[1]=80;
   Check(!levelsProbe.ConfigureRsiLevels(levels,config,error),"Reject unordered RSI levels");
   rows[0]="1,0,1,10,1,9,25,0,0,0,0";
   Check(!levelsProbe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Reject RSI level from MA slot");
   for(int i=0;i<5;i++) rows[i]="";
   for(int i=0;i<4;i++) { config.indicators[i].type=GUI_INDICATOR_MA; usages[i]=0; }
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Four MA entries allowed");
   for(int kind=1;kind<=2;kind++)
     {
      config.indicators[0].type=kind==1 ? GUI_INDICATOR_RSI : GUI_INDICATOR_ADX;
      config.indicators[1].type=config.indicators[0].type;
      usages[0]=0; usages[1]=0;
      Check(!probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Duplicate entries rejected even without signals");
      usages[1]=1;
      Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"One entry and one exit allowed");
      usages[0]=1;
      Check(!probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Duplicate exits rejected");
     }
   // Visual reads use the same condition outcomes and never consume trading events.
   config.indicators[0].type=GUI_INDICATOR_MA; config.indicators[1].type=GUI_INDICATOR_NONE;
   usages[0]=0; usages[1]=0; probe.ready=true;
   for(int i=0;i<5;i++) rows[i]="";
   rows[0]="1,0,1,10,1,0,9,0,100,0,0";
   rows[1]="1,0,-1,10,1,1,9,0,100,0,0";
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Visual rules configured");
   Check(probe.VisualState(NULL,0,0,0.01)==2,"Not evaluated is unavailable");
   probe.samples[10][1]=110;
   Check(probe.Evaluate(NULL,1000,0.01,events,error) && events==1,"Buy before visual read");
   Check(probe.VisualState(NULL,0,0,0.01)==1,"Visual buy");
   Check(probe.Evaluate(NULL,1000,0.01,events,error) && events==0,"Visual read preserves event state");
   probe.samples[10][1]=90;
   Check(probe.Evaluate(NULL,1100,0.01,events,error) && events==2,"Sell before visual read");
   Check(probe.VisualState(NULL,0,0,0.01)==-1,"Visual sell");
   probe.samples[10][1]=100;
   Check(probe.Evaluate(NULL,1200,0.01,events,error),"Neutral evaluated");
   Check(probe.VisualState(NULL,0,0,0.01)==0,"No buy and no sell is neutral");
   Check(probe.VisualState(NULL,1,0,0.01)==2,"No applicable rule has no invented signal");
   probe.samples[10][2]=110;
   Check(probe.VisualState(NULL,0,1,0.01)==1,"History applies configured candle offset");
   probe.samples[10][2]=90;
   Check(probe.VisualState(NULL,0,1,0.01)==-1,"Historical sell");
   probe.ready=false;
   Check(!probe.Evaluate(NULL,1300,0.01,events,error),"Missing data fails evaluation");
   Check(probe.VisualState(NULL,0,0,0.01)==2,"Missing data is not neutral or sell");
   probe.ready=true; rows[0]="1,0,1,10,0,7,9,0,100,0,0"; rows[1]="";
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Tick crossing configured");
   Check(probe.VisualState(NULL,0,1,0.01)==2,"Tick history remains unavailable");
   rows[0]="1,0,1,10,0,0,9,0,100,0,0";
   Check(probe.Configure(rows,usages,"TEST",PERIOD_M1,config,error),"Current simple comparison configured");
   probe.samples[10][1]=110;
   Check(probe.VisualState(NULL,0,1,0.01)==1,"Simple current comparisons reconstruct the past candle close");
   PrintFormat("[SignalGridTests] %d checks, %d failures",checks,failures);
  }
