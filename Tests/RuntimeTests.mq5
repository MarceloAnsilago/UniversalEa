#property strict
#define private public
#include "../Include/UniRuntime.mqh"
#undef private
int checks=0,failures=0;
void Check(const bool ok,const string label)
  { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   CGuiState initial; initial.Reset();
   GuiAppliedConfiguration config;
   config.setup=initial.setup; config.rules=initial.rules; config.management=initial.management;
   for(int i=0;i<4;i++) config.indicators[i]=initial.indicators[i];
   string error;
   Check(UniValidateConfiguration(config,error),"Price-only conditions allow no indicators");
   config.indicators[0].type=GUI_INDICATOR_MA;
   Check(UniValidateConfiguration(config,error),"Complete draft valid");
   config.rules.stop_multiplier=0; config.rules.stop_loss=0;
   Check(!UniValidateConfiguration(config,error),"Take multiple requires stop");
   config.rules.take_mode=1;
   Check(UniValidateConfiguration(config,error),"Fixed take can use disabled stop");
   config.rules.Reset();
   Check(UniEntryWindow(540,1020,D'2026.09.23 09:00:00') && !UniEntryWindow(540,1020,D'2026.09.23 17:00:00'),"Session boundaries");
   Check(UniEntryWindow(1320,120,D'2026.09.23 23:00:00') && UniEntryWindow(1320,120,D'2026.09.23 01:00:00') &&
         !UniEntryWindow(1320,120,D'2026.09.23 12:00:00'),"Overnight session");
   MqlRates closed[3];
   for(int i=0;i<3;i++) { ZeroMemory(closed[i]); closed[i].open=100; closed[i].close=102; closed[i].high=104; closed[i].low=99; }
   config.rules.candle_filter=GUI_CANDLE_SIZE;
   config.rules.candle_sizes[0].minimum=1; config.rules.candle_sizes[0].maximum=3;
   Check(UniCandlesMatch(config.rules,closed,1),"Body filter");
   config.rules.candle_sizes[0].measure=1;
   Check(!UniCandlesMatch(config.rules,closed,1),"Total filter measures wicks too");
   config.rules.candle_units[0]=1; config.rules.candle_percent[0].minimum=40; config.rules.candle_percent[0].maximum=40;
   Check(UniCandlesMatch(config.rules,closed,1),"Percent body filter");
   config.rules.candle_filter=GUI_CANDLE_WICKS; config.rules.candle_percent[0].upper_maximum=30;
   Check(!UniCandlesMatch(config.rules,closed,1),"Wick percent filter");
   config.rules.Reset();
   config.setup.lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   config.rules.stop_multiplier=1.5; config.rules.stop_bar=3; config.rules.take_mode=1; config.rules.take_profit=125;
   config.rules.pending_reference=0; config.rules.pending_bar=7;
   CUniRuntime runtime;
   Check(!runtime.Active() && !runtime.HasConfiguration() && runtime.PollSignal(error)==0 && error=="","Runtime begins paused");
   Check(!runtime.Activate(error),"No activation before apply");
   Check(runtime.Apply(_Symbol,config,error) && runtime.Revision()==1 && !runtime.Active(),"Apply initializes engine and remains paused");
   GuiAppliedConfiguration snapshot;
   Check(runtime.CopyConfiguration(snapshot) && snapshot.rules.stop_bar==3 && snapshot.rules.take_mode==1 &&
         snapshot.rules.take_profit==125 && snapshot.rules.pending_bar==7,"Full rules reach runtime");
   Check(runtime.m_engine.m_magic==config.setup.magic && runtime.m_engine.m_lot==config.setup.lot &&
         runtime.m_engine.m_indicators[0]!=NULL,"Engine receives setup and indicators");
   config.rules.take_profit=999;
   runtime.CopyConfiguration(snapshot);
   Check(snapshot.rules.take_profit==125,"Editing draft does not mutate applied configuration");
   runtime.m_active=true; config.setup.magic=0;
   Check(!runtime.Apply(_Symbol,config,error) && runtime.Active() && runtime.Revision()==1,"Failed apply preserves active engine");
   config.setup.magic=1;
   runtime.Pause();
   Check(!runtime.Active() && runtime.PollSignal(error)==0 && runtime.HasConfiguration(),"Pause preserves configuration");
   Check(runtime.Apply(_Symbol,config,error) && runtime.Revision()==2 && !runtime.Active(),"Reapply leaves runtime paused");
   runtime.m_active=true; config.indicators[0].maPeriod=0;
   Check(!runtime.Apply(_Symbol,config,error) && runtime.Active() && runtime.Revision()==2,"Invalid indicator cannot replace engine");
   runtime.Pause();
   config.indicators[0].maPeriod=20;
   if(runtime.Activate(error))
     {
      Check(runtime.Active() && runtime.m_resume_bar>0,"Activation starts at next bar");
      runtime.Pause(); Check(!runtime.Active(),"Activated runtime can pause");
     }
   else Check(!runtime.Active() && error!="","Missing history leaves runtime paused with reason");
   runtime.Shutdown();
   Check(!runtime.Active() && !runtime.HasConfiguration(),"Shutdown releases runtime");
   PrintFormat("[RuntimeTests] %d checks, %d failures",checks,failures);
  }
