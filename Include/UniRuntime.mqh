#ifndef UNI_RUNTIME_MQH
#define UNI_RUNTIME_MQH
#include "MyUnEA.mqh"

// Controla somente análise. Não possui funções de negociação.
class CUniRuntime
  {
private:
   MyUnEA *m_engine;
   GuiAppliedConfiguration m_applied;
   string m_symbol;
   ENUM_TIMEFRAMES m_period;
   bool m_active;
   int m_revision;
   datetime m_resume_bar,m_evaluated_bar;
public:
   CUniRuntime() { m_engine=NULL; m_active=false; m_revision=0; m_resume_bar=0; m_evaluated_bar=0; }
   ~CUniRuntime() { Shutdown(); }
   void Shutdown() { if(m_engine!=NULL) delete m_engine; m_engine=NULL; m_active=false; }
   bool HasConfiguration() { return m_engine!=NULL; }
   bool Active() { return m_active; }
   int Revision() { return m_revision; }
   string AppliedName() { return m_engine==NULL ? "" : m_applied.setup.name; }
   bool CopyConfiguration(GuiAppliedConfiguration &value)
     { if(m_engine==NULL) return false; value=m_applied; return true; }
   bool Apply(const string symbol,GuiAppliedConfiguration &draft,string &error)
     {
      GuiAppliedConfiguration candidate; candidate=draft;
      if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN,candidate.setup.volume_min) ||
         !SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,candidate.setup.volume_max) ||
         !SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP,candidate.setup.volume_step))
        { error="Não foi possível consultar os limites de volume do ativo."; return false; }
      MyUnEA *next=new MyUnEA;
      if(next==NULL) { error="Sem memória para preparar a configuração."; return false; }
      if(!next.ConfigureCanvas(symbol,candidate,error) || next.doInit(error)!=INIT_SUCCEEDED)
        { delete next; return false; }
      // Troca atômica: erros acima preservam a configuração e o estado anteriores.
      if(m_engine!=NULL) delete m_engine;
      m_engine=next; m_applied=candidate; m_symbol=symbol;
      m_period=candidate.setup.timeframe==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : candidate.setup.timeframe;
      m_active=false; m_resume_bar=0; m_evaluated_bar=0; m_revision++; error=""; return true;
     }
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
   int PollSignal(string &error)
     {
      error="";
      if(!m_active || m_engine==NULL) return 0;
      m_engine.doTick(error);
      if(error!="") return 0;
      // Ativar ou retomar não reaproveita o sinal da vela que já estava aberta.
      datetime bar=m_engine.SignalBarTime();
      if(bar<=m_resume_bar || bar<=m_evaluated_bar) return 0;
      if(!UniEntryWindow(m_applied.setup.entry_start,m_applied.setup.entry_end,m_engine.QuoteTime()))
        { m_evaluated_bar=bar; return 0; }
      if(m_applied.rules.candle_filter!=GUI_CANDLE_DISABLED)
        {
         MqlRates closed[]; ArraySetAsSeries(closed,true);
         datetime now[];
         if(CopyRates(m_symbol,m_period,1,3,closed)!=3 || CopyTime(m_symbol,m_period,0,1,now)!=1 ||
            now[0]!=m_engine.SignalBarTime()) { error="Aguardando candles do filtro."; return 0; }
         if(!UniCanvasCandlesMatch(m_applied.rules,closed,SymbolInfoDouble(m_symbol,SYMBOL_POINT)))
           { m_evaluated_bar=bar; return 0; }
        }
      m_evaluated_bar=bar;
      if(m_engine.checkBuy()) return 1;
      if(m_engine.checkSell()) return -1;
      return 0;
     }
  };
#endif
