#property strict
#include "../Include/MyUnEA.mqh"

int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }

// Executar em um grafico com especificacoes de volume disponiveis.
// Nao cria ordens; usa slots vazios para testar o ciclo de vida do setup.
void OnStart()
  {
   MyUnEA ea;
   string error;
   Check(!ea.IsInitialized(),"Construtor nao inicializa recursos");
   Check(ea.doInit(error)==INIT_FAILED && error!="","Ativo ausente informa falha");
   ea.setSymbol(_Symbol);
   ea.setPeriod(PERIOD_CURRENT);
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(minimum<=0 || step<=0) { Print("Teste interrompido: volume indisponivel."); return; }
   ea.setLOTS(MathCeil(minimum/step-1e-8)*step);
   Check(ea.doInit(error)==INIT_SUCCEEDED && ea.IsInitialized(),"Inicializa setup sem indicadores");
   ea.doDeinit(); ea.doDeinit();
   Check(!ea.IsInitialized(),"Finalizacao repetida");
   Check(ea.doInit(error)==INIT_SUCCEEDED,"Reinicializa preservando configuracao");
   ea.setMagic(0);
   Check(!ea.IsInitialized(),"Alteracao invalida estado inicializado");
   Check(ea.doInit(error)==INIT_PARAMETERS_INCORRECT,"Magic invalido");
   ea.setMagic(1);
   ea.setSchedule(600,600,false,1435);
   Check(ea.doInit(error)==INIT_PARAMETERS_INCORRECT,"Janela de duracao zero rejeitada");
   ea.setSchedule(1320,120,true,180);
   Check(ea.doInit(error)==INIT_SUCCEEDED,"Janela noturna aceita");
   ea.setSchedule(1320,120,true,60);
   Check(ea.doInit(error)==INIT_SUCCEEDED,"Horário legado não restringe entradas");
   ea.setSchedule(0,1435,false,1435);
   ea.setBreakeven(1,10,10);
   Check(ea.doInit(error)==INIT_PARAMETERS_INCORRECT,"Breakeven invalido");
   ea.setBreakeven(0,0,0);
   ea.setLOTS(0);
   Check(ea.doInit(error)==INIT_PARAMETERS_INCORRECT,"Volume zero rejeitado");
   PrintFormat("MyUnEAInitTests: %d falhas",failures);
  }
