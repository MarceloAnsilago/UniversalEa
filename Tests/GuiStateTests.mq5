#property strict
#property script_show_inputs
#include "../Include/CanvasGUI/GuiState.mqh"
int failures=0,checks=0;
void Check(const bool condition,const string label)
  { checks++; if(!condition) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   CGuiState state; state.Reset(); string error;
   for(int i=0;i<4;i++) Check(state.indicators[i].type==GUI_INDICATOR_NONE && state.Choice(i,GUI_TYPE)==0,"Não usar padrão");
   state.Choose(0,GUI_TYPE,GUI_INDICATOR_MA+1);
   state.Choose(1,GUI_TYPE,GUI_INDICATOR_RSI+1);
   Check(state.indicators[0].type==GUI_INDICATOR_MA && state.indicators[0].maPeriod==20 && state.indicators[0].maMethod==MODE_EMA,"MA inicial");
   Check(state.indicators[1].type==GUI_INDICATOR_RSI && state.indicators[1].rsiPeriod==14 && state.indicators[1].rsiLower==30 && state.indicators[1].rsiUpper==70,"RSI inicial");
   Check(state.Commit(0,GUI_PERIOD,"55",error),"Editar MA");
   state.Choose(0,GUI_TYPE,GUI_INDICATOR_RSI+1);
   Check(state.Commit(0,GUI_PERIOD,"9",error),"Editar RSI");
   state.Choose(0,GUI_TYPE,GUI_INDICATOR_MA+1);
   Check(state.indicators[0].maPeriod==55 && state.indicators[0].rsiPeriod==9,"Preservar parâmetros ao alternar tipo");
   Check(state.indicators[1].rsiPeriod==14,"Independência dos cards");
   Check(!state.Commit(0,GUI_PERIOD,"0",error) && state.indicators[0].maPeriod==55,"Rejeitar zero sem alterar estado");
   Check(!state.Commit(0,GUI_PERIOD,"2.5",error),"Rejeitar período fracionário");
   Check(!state.Commit(0,GUI_PERIOD,"100001",error),"Limite superior de período");
   Check(!state.Commit(0,GUI_PERIOD,"12x",error),"Rejeitar lixo após número");
   Check(!state.Commit(0,GUI_PERIOD,"",error),"Rejeitar campo vazio");
   Check(state.Commit(0,GUI_SHIFT,"-12",error) && state.indicators[0].maShift==-12,"Shift negativo");
   Check(!state.Commit(0,GUI_SHIFT,"-100001",error),"Limite de shift");
   Check(state.Commit(1,GUI_LOWER,"25,75",error) && state.indicators[1].rsiLower==25.75,"Vírgula decimal");
   Check(!state.Commit(1,GUI_LOWER,"25.755",error),"Precisão visível corresponde ao estado");
   Check(!state.Commit(1,GUI_LOWER,"70",error) && state.indicators[1].rsiLower==25.75,"Rejeitar níveis iguais");
   Check(!state.Commit(1,GUI_UPPER,"20",error) && state.indicators[1].rsiUpper==70,"Rejeitar níveis invertidos");
   Check(!state.Commit(1,GUI_UPPER,"101",error),"Limite RSI");
   Check(state.Commit(1,GUI_LOWER,"0",error) && state.Commit(1,GUI_UPPER,"100",error),"Extremos RSI");
   for(int p=0;p<7;p++)
     {
      state.Choose(0,GUI_PRICE,p); state.Choose(1,GUI_PRICE,p);
      Check(state.Choice(0,GUI_PRICE)==p && state.Choice(1,GUI_PRICE)==p,"Mapeamento preço "+IntegerToString(p));
     }
   for(int m=0;m<4;m++)
     { state.Choose(0,GUI_METHOD,m); Check(state.Choice(0,GUI_METHOD)==m,"Mapeamento método "+IntegerToString(m)); }
   Check(!state.has_applied,"Lista inicialmente vazia");
   state.Apply();
   Check(state.has_applied && state.applied[0].maPeriod==55 && state.applied[1].rsiPeriod==14,"Aplicar captura ambos os indicadores");
   state.Commit(0,GUI_PERIOD,"60",error);
   Check(state.applied[0].maPeriod==55,"Edição não altera última aplicação");
   state.Apply();
   Check(state.applied[0].maPeriod==60,"Reaplicar atualiza a lista");
   Check(ArraySize(state.applications)==2,"Cada aplicação acrescenta uma coluna");
   Check(state.applications[0].indicators[0].maPeriod==55 && state.applications[1].indicators[0].maPeriod==60,"Preservar aplicação anterior ao reaplicar");
   state.Choose(0,GUI_TYPE,GUI_INDICATOR_RSI+1);
   Check(state.applications[0].indicators[0].type==GUI_INDICATOR_MA && state.applications[1].indicators[0].type==GUI_INDICATOR_MA,"Troca de tipo não altera histórico");
   state.Reset();
   Check(!state.has_applied && ArraySize(state.applications)==0,"Reinicialização limpa histórico");
   for(int slot=0;slot<4;slot++)
     {
      state.Choose(slot,GUI_TYPE,GUI_INDICATOR_MA+1);
      Check(state.Commit(slot,GUI_PERIOD,IntegerToString(20+slot),error),"Editar MA slot "+IntegerToString(slot+1));
      state.Choose(slot,GUI_TYPE,GUI_INDICATOR_RSI+1);
      Check(state.Commit(slot,GUI_PERIOD,IntegerToString(10+slot),error),"Editar RSI slot "+IntegerToString(slot+1));
      state.Choose(slot,GUI_TYPE,GUI_INDICATOR_MA+1);
      Check(state.indicators[slot].maPeriod==20+slot && state.indicators[slot].rsiPeriod==10+slot,"Preservar tipos slot "+IntegerToString(slot+1));
     }
   Check(state.Apply(),"Salvar quatro slots");
   state.Commit(3,GUI_PERIOD,"99",error);
   Check(state.indicators[0].maPeriod==20 && state.indicators[2].maPeriod==22,"Slot 4 independente dos demais");
   Check(state.applications[0].indicators[3].maPeriod==23,"Snapshot do slot 4 imutável");
   Check(state.Apply() && state.applications[1].indicators[3].maPeriod==99,"Reaplicar captura slot 4");
   state.Reset();
   Check(!state.has_applied && state.indicators[3].rsiPeriod==14,"Reset inclui slot 4");
   state.Choose(3,GUI_TYPE,GUI_INDICATOR_MA+1);
   state.Commit(3,GUI_PERIOD,"77",error);
   state.Choose(3,GUI_TYPE,0);
   Check(state.indicators[3].type==GUI_INDICATOR_NONE,"Desabilitar slot 4");
   Check(state.Apply() && state.applications[0].indicators[3].type==GUI_INDICATOR_NONE,"Salvar slot desabilitado");
   state.Choose(3,GUI_TYPE,GUI_INDICATOR_MA+1);
   Check(state.indicators[3].maPeriod==77,"Reativar preserva parâmetros");
   Check(state.applications[0].indicators[3].type==GUI_INDICATOR_NONE,"Reativar não altera histórico");
   state.setup.name="Setup B3"; state.setup.magic=1234;
   state.setup.market=GUI_SETUP_B3; state.setup.timeframe=PERIOD_M5;
   state.setup.direction=GUI_SETUP_BUY_ONLY;
   state.setup.trade_mode=GUI_SETUP_SWING_TRADE;
   state.setup.lot=0.25;
   state.setup.entry_start=540; state.setup.entry_end=1020;
   state.setup.close_enabled=true; state.setup.close_time=1050;
   Check(state.Apply(),"Salvar inclui configuração inicial");
   int saved=ArraySize(state.applications)-1;
   state.setup.name="Outro setup"; state.setup.magic=4321; state.setup.direction=GUI_SETUP_SELL_ONLY;
   state.setup.entry_start=600; state.setup.entry_end=1080; state.setup.close_enabled=false;
   state.setup.trade_mode=GUI_SETUP_DAY_TRADE;
   state.setup.lot=0.10;
   Check(state.applications[saved].setup.name=="Setup B3" && state.applications[saved].setup.magic==1234,"Histórico preserva identificação");
   Check(state.applications[saved].setup.market==GUI_SETUP_B3 && state.applications[saved].setup.timeframe==PERIOD_M5 && state.applications[saved].setup.direction==GUI_SETUP_BUY_ONLY,"Histórico preserva mercado, timeframe e direção");
   Check(state.applications[saved].setup.entry_start==540 && state.applications[saved].setup.entry_end==1020 && state.applications[saved].setup.close_enabled && state.applications[saved].setup.close_time==1050,"Histórico preserva os horários e encerramento");
   Check(state.applications[saved].setup.trade_mode==GUI_SETUP_SWING_TRADE,"Histórico preserva modalidade após mudar setup");
   Check(state.applications[saved].setup.lot==0.25,"Histórico preserva lote após mudar setup");
   PrintFormat("[GuiStateTests] %d verificações, %d falhas",checks,failures);
  }
