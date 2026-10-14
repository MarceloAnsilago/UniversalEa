#ifndef UNI_RUNTIME_MQH
#define UNI_RUNTIME_MQH
#include "MyUnEA.mqh"
#include "UniOrders.mqh"
#include "UniSignals.mqh"
#include "UniChartIndicators.mqh"

// Análise separada de execução para permitir testes de sinais sem negociar.
class CUniRuntime
  {
private:
   MyUnEA *m_engine;
   CUniOrders m_orders;
   GuiAppliedConfiguration m_applied;
   string m_symbol;
   ENUM_TIMEFRAMES m_period;
   bool m_active;
   int m_revision;
   datetime m_resume_bar,m_evaluated_bar;
   CUniSignals m_signals;
   CUniChartIndicators m_chart_indicators;
   int m_pending_exits;
public:
   CUniRuntime() { m_engine=NULL; m_active=false; m_revision=0; m_resume_bar=0; m_evaluated_bar=0; m_pending_exits=0; }
   ~CUniRuntime() { Shutdown(); }
   void Shutdown() { m_chart_indicators.Clear(); if(m_engine!=NULL) delete m_engine; m_engine=NULL; m_active=false; }
   bool HasConfiguration() { return m_engine!=NULL; }
   bool Active() { return m_active; }
   int Revision() { return m_revision; }
   string AppliedName() { return m_engine==NULL ? "" : m_applied.setup.name; }
   bool CopyConfiguration(GuiAppliedConfiguration &value)
     { if(m_engine==NULL) return false; value=m_applied; return true; }
   bool Apply(const string symbol,GuiAppliedConfiguration &draft,string &error)
     {
      if(m_engine!=NULL && m_orders.Busy())
        { error="Encerre posições e pendentes da configuração atual antes de reaplicar."; return false; }
      GuiAppliedConfiguration candidate; candidate=draft;
      if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN,candidate.setup.volume_min) ||
         !SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,candidate.setup.volume_max) ||
         !SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP,candidate.setup.volume_step))
        { error="Não foi possível consultar os limites de volume do ativo."; return false; }
      MyUnEA *next=new MyUnEA;
      if(next==NULL) { error="Sem memória para preparar a configuração."; return false; }
      if(!next.Configure(symbol,candidate,error) || next.doInit(error)!=INIT_SUCCEEDED)
        { delete next; return false; }
      // Troca atômica: erros acima preservam a configuração e o estado anteriores.
      if(m_engine!=NULL) delete m_engine;
      m_engine=next; m_applied=candidate; m_symbol=symbol;
      m_period=candidate.setup.timeframe==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : candidate.setup.timeframe;
      m_orders.Configure(symbol,candidate,m_period);
      m_active=false; m_resume_bar=0; m_evaluated_bar=0; m_pending_exits=0; m_signals.Reset(); m_revision++; error=""; return true;
     }
   bool ShowIndicators(const long chart,const int &usages[],const double &levels[],string &error)
     { return m_chart_indicators.Attach(chart,m_applied,usages,levels,error); }
   bool ConfigureRsiLevels(const double &levels[],string &error)
     { return m_signals.ConfigureRsiLevels(levels,m_applied,error); }
   bool ConfigureSignals(const string &payload[],const int &usages[],string &error)
     { return m_signals.Configure(payload,usages,m_symbol,m_period,m_applied,error); }
   bool Activate(string &error)
     {
      if(m_engine==NULL) { error="Aplique a configuração antes de ativar a análise."; return false; }
      if(m_active) { error=""; return true; }
      datetime times[];
      if(CopyTime(m_symbol,m_period,0,1,times)!=1 || times[0]<=0)
        { error="Aguardando histórico para ativar a análise."; return false; }
      m_resume_bar=times[0]; m_active=true; error=""; return true;
     }
   void Pause() { m_active=false; }
   void Service(string &error)
     { error=""; if(m_engine!=NULL && m_pending_exits==0) m_orders.Service(m_active,error); }
   int Process(string &error)
     {
      error=""; if(m_engine==NULL) return 0;
      m_engine.doTick(error);
      int events=0;
      if(error=="" && !m_signals.Evaluate(m_engine,m_engine.SignalBarTime(),SymbolInfoDouble(m_symbol,SYMBOL_POINT),events,error)) events=0;
      m_pending_exits|=events&12;
      // Keep retrying a failed/partial exit, including while entries are paused.
      if(m_pending_exits!=0)
        {
         for(int i=2;i<4;i++) if((m_pending_exits&(1<<i))!=0)
           {
            bool done=false; string issue;
            if(!m_orders.ExitSignal(i==2 ? 1 : -1,done,issue)) error=issue;
            if(done) m_pending_exits&=~(1<<i);
           }
         return 0; // No closing and reopening in the same tick.
        }
      string maintenance; Service(maintenance);
      if(maintenance!="") { error=maintenance; return 0; }
      if(error!="" || !m_active) return 0;
      int signal=(events&3)==1 ? 1 : (events&3)==2 ? -1 : 0;
      if(!m_signals.LiveEntry(signal) && m_engine.SignalBarTime()<=m_resume_bar) return 0;
      if(signal==0 || !UniEntryWindow(m_applied.setup.entry_start,m_applied.setup.entry_end,m_engine.QuoteTime())) return 0;
      if(m_applied.rules.candle_filter!=GUI_CANDLE_DISABLED)
        {
         MqlRates closed[]; ArraySetAsSeries(closed,true);
         if(CopyRates(m_symbol,m_period,1,3,closed)!=3 || !UniCandlesMatch(m_applied.rules,closed,SymbolInfoDouble(m_symbol,SYMBOL_POINT))) return 0;
        }
      if(!m_orders.Enter(signal,m_engine.SignalBarTime(),error)) return 0;
      return signal;
     }
   int PollSignal(string &error)
     {
      error="";
      if(!m_active || m_engine==NULL) return 0;
      m_engine.doTick(error);
      if(error!="") return 0;
      int events=0;
      if(!m_signals.Evaluate(m_engine,m_engine.SignalBarTime(),SymbolInfoDouble(m_symbol,SYMBOL_POINT),events,error)) return 0;
      int signal=(events&3)==1 ? 1 : (events&3)==2 ? -1 : 0;
      if((!m_signals.LiveEntry(signal) && m_engine.SignalBarTime()<=m_resume_bar) ||
         !UniEntryWindow(m_applied.setup.entry_start,m_applied.setup.entry_end,m_engine.QuoteTime())) return 0;
      return signal;
     }
  };
#endif
