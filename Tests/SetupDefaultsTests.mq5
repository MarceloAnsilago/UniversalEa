#property strict
#define OnInit UniTestInit
#define OnDeinit UniTestDeinit
#define OnTick UniTestTick
#define OnTimer UniTestTimer
// Scripts do not support timers: simulate registration to test EA lifecycle.
bool test_timer_failure=false;
bool TestEventSetTimer(const int seconds) { return !test_timer_failure && seconds==1; }
void TestEventKillTimer() {}
#define EventSetTimer TestEventSetTimer
#define EventKillTimer TestEventKillTimer
#include "../UniEA.mq5"
#undef EventSetTimer
#undef EventKillTimer
#undef OnInit
#undef OnDeinit
#undef OnTick
#undef OnTimer
int setup_checks=0,setup_failures=0;
void SetupCheck(const bool ok,const string label)
  { setup_checks++; if(!ok) { setup_failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   CGuiState initial; BuildInitialConfiguration(initial);
   SetupCheck(initial.setup.timeframe==PERIOD_CURRENT,"Current timeframe preserved");
   SetupCheck(initial.setup.magic==InpMagic && initial.setup.lot==InpLot,"Identity and volume reach configuration");
   SetupCheck(!InpAutoStart && !InpTesterAutoStart,"Entries disabled by default");
   ObjectCreate(ChartID(),"UnrelatedTestObject",OBJ_LABEL,0,0,0);
   int objects_before=ObjectsTotal(ChartID());
   SetupCheck(UniTestInit()==INIT_SUCCEEDED,"Default placeholder initializes without indicators");
   SetupCheck(!runtime.Active() && !runtime.HasConfiguration(),"Placeholder does not activate engine");
   SetupCheck(ObjectsTotal(ChartID())==objects_before+1,"Panel creates one Canvas object");
   SetupCheck(panel.Create(ChartID(),"Teste",initial),"Panel recreation succeeds");
   SetupCheck(ObjectsTotal(ChartID())==objects_before+1,"Recreation leaves no orphan objects");
   UniTestDeinit(REASON_REMOVE);
   SetupCheck(ObjectsTotal(ChartID())==objects_before && ObjectFind(ChartID(),"UnrelatedTestObject")>=0,"Deinit removes only owned objects");
   test_timer_failure=true;
   SetupCheck(UniTestInit()==INIT_FAILED,"Timer failure rejects initialization");
   SetupCheck(ObjectsTotal(ChartID())==objects_before && !runtime.HasConfiguration(),"Timer failure cleans panel and engine");
   test_timer_failure=false;
   ObjectDelete(ChartID(),"UnrelatedTestObject");
   SetupCheck(!runtime.Active() && !runtime.HasConfiguration(),"Deinit releases runtime");
   PrintFormat("[SetupDefaultsTests] %d checks, %d failures",setup_checks,setup_failures);
  }
