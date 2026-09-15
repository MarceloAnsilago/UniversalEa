#property strict
#include "../Include/MyUnEA.mqh"

int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }

// Executar em gráfico com cotação e pelo menos 60 velas disponíveis.
// Confere isolamento entre instâncias e reinicialização, sem enviar ordens.
void OnStart()
  {
   MyUnEA first,second;
   string error;
   Check(!first.doTick(error) && error!="","Rejeita tick antes da inicializacao");
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   MqlRates history[];
   MqlTick quote;
   if(minimum<=0 || step<=0 || CopyRates(_Symbol,_Period,0,60,history)!=60 ||
      !SymbolInfoTick(_Symbol,quote) || quote.time<=0)
     { Print("INCOMPLETO: preparar cotacao e historico antes de executar o teste."); return; }
   double lot=MathCeil(minimum/step-1e-8)*step;
   first.setSymbol(_Symbol); first.setPeriod(_Period); first.setLOTS(lot);
   second.setSymbol(_Symbol); second.setPeriod(_Period); second.setLOTS(lot);
   if(first.doInit(error)!=INIT_SUCCEEDED || second.doInit(error)!=INIT_SUCCEEDED)
     { Print("INCOMPLETO: inicializacao falhou: ",error); return; }
   Check(first.doTick(error) && error=="","Primeira leitura reconhece a vela");
   Check(second.doTick(error) && error=="","Instancias possuem controle independente");
   // Se o mercado mudar de vela durante o teste, nao avaliar a repeticao.
   datetime before=iTime(_Symbol,_Period,0);
   first.doTick(error);
   bool repeated=first.doTick(error);
   if(before==iTime(_Symbol,_Period,0))
      Check(!repeated && error=="","Mesma vela nao dispara novamente");
   else Print("INCOMPLETO: repetir teste de duplicidade fora da virada de vela.");
   first.doDeinit();
   Check(!first.doTick(error) && error!="","Finalizacao bloqueia ticks");
   Check(first.doInit(error)==INIT_SUCCEEDED,"Reinicializacao");
   Check(first.doTick(error) && error=="","Reinicializacao limpa a vela anterior");
   PrintFormat("MyUnEATickTests: %d falhas",failures);
  }
