#property strict
#resource "Indicators\\UniMaPlot.ex5"
#resource "Indicators\\UniOscillatorPlot.ex5"
#resource "Indicators\\UniSignalHistogram.ex5"
#property version "1.10"
#property description "EA com painel padrao, ordens, SL/TP e gestao de posicoes."
#include "Include/UniPanel.mqh"
#include "Include/UniRuntime.mqh"
#include "Include/Configuration/UniInputOptions.mqh"
#include "Include/UniPriceMarkers.mqh"


// Modos de gestao da configuracao.
enum ENUM_UNI_MANAGEMENT_MODE
  {
   UNI_MANAGEMENT_DISABLED=0, // Desativado
   UNI_MANAGEMENT_POINTS=1,   // Pontos
   UNI_MANAGEMENT_PERCENT=2   // Porcentagem
  };

// Parâmetros iniciais da configuração.
// Os inputs sao validados e aplicados ao motor durante a inicializacao.
// Identidade do arquivo e limites de volume sao dados internos, nao inputs.
input group "Identificação"
input string InpName="Meu setup";                              // Nome do setup
input long InpMagic=1;                                         // Magic Number: 1 a 2147483647

input group "Mercado e operação"
input ENUM_GUI_SETUP_MARKET InpMarket=GUI_SETUP_FOREX;          // Mercado: Forex ou B3
input ENUM_GUI_SETUP_TRADE_MODE InpTradeMode=GUI_SETUP_DAY_TRADE; // Modalidade: operações no mesmo dia ou em vários dias
input ENUM_UNI_TIMEFRAME InpStrategyTimeframe=UNI_PERIOD_CURRENT;                   // Período da estratégia
input double InpLot=0.01;                                      // Volume por operacao; respeitar limites e passo do ativo
input ENUM_GUI_SETUP_DIRECTION InpDirection=GUI_SETUP_BUY_SELL; // Direcao permitida das operacoes

// Horarios em minutos desde 00:00 no servidor, de 0 a 1435, em passos de 5.
// Exemplo: 09:30 = 570. Inicio e fim devem ser diferentes.
input group "Horários"
input int InpEntryStart=0;         // Início entradas (minutos): 0 = 00:00; passo 5
input int InpEntryEnd=1435;        // Encerramento entradas (minutos): 1435 = 23:55; passo 5
// Encerramento das entradas usa InpEntryEnd. Posições seguem a modalidade.

input group "Ordem"
input ENUM_GUI_ORDER_MODE InpOrderMode=GUI_ORDER_MARKET;           // Tipo de ordem: a mercado ou pendente
input ENUM_UNI_PENDING_REFERENCE InpPendingReference=UNI_PENDING_HIGH; // Pendente: posicionar em
input int InpPendingCandle=1; // Pendente: vela 1 = ultima fechada; 1 a 100000

input group "Regras de entrada e saida"
input ENUM_GUI_CANDLE_FILTER InpCandleFilter=GUI_CANDLE_DISABLED;   // Filtro: desativado, tamanho de candles ou pavios
input ENUM_GUI_TARGET_UNIT InpTargetUnit=GUI_TARGET_POINTS;        // Unidade do stop loss e take profit
input ENUM_UNI_STOP_MODE InpStopMode=UNI_STOP_DISTANCE_CANDLE; // Modo do stop loss
input double InpStopLoss=0.0;                                      // Distancia do stop; no modo fixo, 0 desativa
input ENUM_UNI_TAKE_MODE InpTakeMode=UNI_TAKE_AUTO; // Modo do take; automatico preserva presets antigos
input double InpTakeProfit=0.0;                                    // Take profit na unidade selecionada; 0 desativa
input double InpStopCandleMultiplier=1.0;                          // Stop: multiplicador do candle
input int InpStopCandle=1;                                        // Stop: candle fechado 1 a 3
input bool InpStopBody=false;                                     // Stop: usar corpo em vez de total
input double InpTakeStopMultiplier=2.0;                           // Take: multiplicador usado no modo vezes o stop

// Valores de gestao usam a unidade do respectivo modo.
// Percentuais da gestão usam o preço de abertura da posição.
input group "Breakeven"
input ENUM_UNI_MANAGEMENT_MODE InpBreakevenMode=UNI_MANAGEMENT_DISABLED; // Modo do breakeven
input double InpBreakevenTrigger=0.0; // Ativacao: maior que zero quando habilitado
input double InpBreakevenOffset=0.0;  // Protecao: menor que a ativacao; 0 = preco de entrada

input group "Trailing stop"
input ENUM_UNI_MANAGEMENT_MODE InpTrailingMode=UNI_MANAGEMENT_DISABLED; // Modo do trailing stop
input double InpTrailingTrigger=0.0;  // Ativacao: maior que zero quando habilitado
input double InpTrailingDistance=0.0; // Distancia do preco: maior que zero quando habilitado
input double InpTrailingStep=0.0;     // Passo de ajuste: maior que zero quando habilitado

input group "Stop movel"
input ENUM_UNI_MANAGEMENT_MODE InpMovingStopMode=UNI_MANAGEMENT_DISABLED; // Modo do stop movel
input double InpMovingStopTrigger=0.0;  // Ativacao: maior que zero quando habilitado
input double InpMovingStopDistance=0.0; // Distancia do preco: maior que zero quando habilitado
input double InpMovingStopStep=0.0;     // Passo de ajuste: maior que zero quando habilitado

input group "Execucao"
input bool InpAutoStart=false; // Ativar novas entradas fora do testador; false mantem gestao e pausa entradas
input bool InpTesterAutoStart=false; // Aplicar inputs e ativar automaticamente SOMENTE no testador

// Slots selecionam tipo e finalidade; parametros ficam nos grupos abaixo.
input group "Slot 1"
input ENUM_GUI_INDICATOR_TYPE InpIndicator1Type=GUI_INDICATOR_NONE; // Indicador do slot 1
input ENUM_UNI_YES_NO InpIndicator1Exit=UNI_NO; // Finalidade: Nao = entrada; Sim = saida

input group "Slot 2"
input ENUM_GUI_INDICATOR_TYPE InpIndicator2Type=GUI_INDICATOR_NONE; // Indicador do slot 2
input ENUM_UNI_YES_NO InpIndicator2Exit=UNI_NO; // Finalidade: Nao = entrada; Sim = saida

input group "Slot 3"
input ENUM_GUI_INDICATOR_TYPE InpIndicator3Type=GUI_INDICATOR_NONE; // Indicador do slot 3
input ENUM_UNI_YES_NO InpIndicator3Exit=UNI_NO; // Finalidade: Nao = entrada; Sim = saida

input group "Slot 4"
input ENUM_GUI_INDICATOR_TYPE InpIndicator4Type=GUI_INDICATOR_NONE; // Indicador do slot 4
input ENUM_UNI_YES_NO InpIndicator4Exit=UNI_NO; // Finalidade: Nao = entrada; Sim = saida

input group "RSI"
// Separadores visuais; nao participam da otimizacao.
sinput string InpSeparatorRsiEntry="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Entrada ▪▪▪
input int InpRsiEntryPeriod=14; // Periodo
input ENUM_UNI_APPLIED_PRICE InpRsiEntryPrice=UNI_PRICE_CLOSE; // Preco aplicado
input double InpRsiEntryUpper=70; // Nivel superior
input double InpRsiEntryMiddle=50; // Nivel medio
input double InpRsiEntryLower=30; // Nivel inferior

sinput string InpSeparatorRsiExit="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Saída ▪▪▪
input int InpRsiExitPeriod=14; // Periodo
input ENUM_UNI_APPLIED_PRICE InpRsiExitPrice=UNI_PRICE_CLOSE; // Preco aplicado
input double InpRsiExitUpper=70; // Nivel superior
input double InpRsiExitMiddle=50; // Nivel medio
input double InpRsiExitLower=30; // Nivel inferior

input group "ADX"
// Separadores visuais; nao participam da otimizacao.
sinput string InpSeparatorAdxEntry="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Entrada ▪▪▪
input int InpAdxEntryPeriod=14; // Periodo

sinput string InpSeparatorAdxExit="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Saída ▪▪▪
input int InpAdxExitPeriod=14; // Periodo

input group "Média Móvel — Parâmetros por indicador"
// Use os campos do indicador que selecionou Media Movel; os demais ficam inativos.
// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa1="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 1 ▪▪▪
input int InpIndicator1MaPeriod=20; // Indicador 1 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator1MaMethod=UNI_MA_EMA; // Indicador 1 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator1MaPrice=UNI_PRICE_CLOSE; // Indicador 1 │ Preço aplicado
input int InpIndicator1MaShift=0; // Indicador 1 │ Deslocamento em barras: -100000 a 100000

// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa2="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 2 ▪▪▪
input int InpIndicator2MaPeriod=20; // Indicador 2 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator2MaMethod=UNI_MA_EMA; // Indicador 2 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator2MaPrice=UNI_PRICE_CLOSE; // Indicador 2 │ Preço aplicado
input int InpIndicator2MaShift=0; // Indicador 2 │ Deslocamento em barras: -100000 a 100000

// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa3="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 3 ▪▪▪
input int InpIndicator3MaPeriod=20; // Indicador 3 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator3MaMethod=UNI_MA_EMA; // Indicador 3 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator3MaPrice=UNI_PRICE_CLOSE; // Indicador 3 │ Preço aplicado
input int InpIndicator3MaShift=0; // Indicador 3 │ Deslocamento em barras: -100000 a 100000

// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa4="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 4 ▪▪▪
input int InpIndicator4MaPeriod=20; // Indicador 4 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator4MaMethod=UNI_MA_EMA; // Indicador 4 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator4MaPrice=UNI_PRICE_CLOSE; // Indicador 4 │ Preço aplicado
input int InpIndicator4MaShift=0; // Indicador 4 │ Deslocamento em barras: -100000 a 100000

input group "Sinal - condicoes do GeraSet"
// Payload v1: operador,finalidade,lado,A,candleA,comparacao,DE,candleDE,fixo,distancia,unidade.
input string InpSignal1=""; // Condicao 1: configurada na grade do GeraSet
input string InpSignal2=""; // Condicao 2: configurada na grade do GeraSet
input string InpSignal3=""; // Condicao 3: configurada na grade do GeraSet
input string InpSignal4=""; // Condicao 4: configurada na grade do GeraSet
input string InpSignal5=""; // Condicao 5: configurada na grade do GeraSet

input group "Visualizacao no MetaTrader 5"
sinput bool InpExibirPainel=true; // Mostrar painel do UNI
sinput bool InpExibirHistogramas=true; // Uma faixa por indicador habilitado
sinput int InpHistogramasBarras=300; // Historico visual: 1 a 5000 candles

input group "Marcadores de preco"
sinput bool InpShowPriceMarkers=true; // Mostrar etiquetas de entrada, stop e take
sinput bool InpMarkerShowProfit=true; // Mostrar resultado bruto atual na entrada e estimativas nos niveis
sinput color InpMarkerEntryColor=C'37,99,235'; // Cor da entrada
sinput color InpMarkerStopColor=C'220,55,65'; // Cor do stop atual
sinput color InpMarkerTakeColor=C'0,145,110'; // Cor do take profit
sinput color InpMarkerPendingColor=C'180,110,10'; // Cor da entrada pendente
sinput color InpMarkerBreakevenColor=C'147,51,234'; // Cor do nivel de ativacao do breakeven
sinput color InpMarkerTextColor=clrWhite; // Cor do texto das etiquetas
sinput color InpMarkerProfitColor=C'0,145,110'; // Cor do bloco de lucro estimado
sinput color InpMarkerLossColor=C'220,55,65'; // Cor do bloco de prejuizo estimado
sinput int InpMarkerFontSize=13; // Tamanho da fonte: 10 a 20

CUniPanel panel;
CUniTradeMarkers price_markers;
CUniRuntime runtime;


void BuildInitialConfiguration(CGuiState &config)
  {
   config.Reset();
   config.setup.name=InpName; config.setup.magic=InpMagic; config.setup.market=(int)InpMarket;
   config.setup.timeframe=(ENUM_TIMEFRAMES)InpStrategyTimeframe; config.setup.direction=(int)InpDirection;
   config.setup.trade_mode=(int)InpTradeMode; config.setup.lot=InpLot;
   config.setup.entry_start=InpEntryStart; config.setup.entry_end=InpEntryEnd;
   config.setup.close_enabled=false; config.setup.close_time=config.setup.entry_end;
   config.rules.order_mode=InpOrderMode; config.rules.candle_filter=InpCandleFilter;
   config.rules.target_unit=InpTargetUnit; config.rules.stop_loss=InpStopLoss; config.rules.take_profit=InpTakeProfit;
   config.rules.stop_multiplier=UniResolveStopMultiplier(InpStopMode,InpStopCandleMultiplier);
   config.rules.stop_bar=InpStopMode==UNI_STOP_FIXED ? 1 : InpStopCandle;
   config.rules.stop_measure=InpStopMode==UNI_STOP_FIXED ? 0 : (InpStopBody ? 1 : 0);
   config.rules.take_multiplier=InpTakeStopMultiplier;
   config.rules.pending_reference=InpPendingReference; config.rules.pending_bar=InpPendingCandle;
   // Presets antigos inferem o modo; novos presets declaram inclusive take fixo zero.
   config.rules.take_mode=UniResolveTakeMode(InpTakeMode,InpTakeProfit);
   config.management.Choose(0,(int)InpBreakevenMode);
   config.management.Choose(1,(int)InpTrailingMode);
   config.management.Choose(2,(int)InpMovingStopMode);
   config.management.values[0]=InpBreakevenTrigger; config.management.values[1]=InpBreakevenOffset;
   config.management.values[2]=InpTrailingTrigger; config.management.values[3]=InpTrailingDistance; config.management.values[4]=InpTrailingStep;
   config.management.values[5]=InpMovingStopTrigger; config.management.values[6]=InpMovingStopDistance; config.management.values[7]=InpMovingStopStep;
   ENUM_GUI_INDICATOR_TYPE types[]={InpIndicator1Type,InpIndicator2Type,InpIndicator3Type,InpIndicator4Type};
   int periods[]={InpIndicator1MaPeriod,InpIndicator2MaPeriod,InpIndicator3MaPeriod,InpIndicator4MaPeriod};
   int shifts[]={InpIndicator1MaShift,InpIndicator2MaShift,InpIndicator3MaShift,InpIndicator4MaShift};
   ENUM_UNI_MA_METHOD methods[]={InpIndicator1MaMethod,InpIndicator2MaMethod,InpIndicator3MaMethod,InpIndicator4MaMethod};
   ENUM_UNI_APPLIED_PRICE prices[]={InpIndicator1MaPrice,InpIndicator2MaPrice,InpIndicator3MaPrice,InpIndicator4MaPrice};
   ENUM_UNI_YES_NO exits[]={InpIndicator1Exit,InpIndicator2Exit,InpIndicator3Exit,InpIndicator4Exit};
   for(int i=0;i<4;i++)
     {
      config.indicators[i].type=types[i];
      config.indicators[i].maPeriod=periods[i];
      config.indicators[i].maShift=shifts[i]; config.indicators[i].maMethod=(ENUM_MA_METHOD)methods[i];
      config.indicators[i].maPrice=(ENUM_APPLIED_PRICE)prices[i];
      bool exit=exits[i]==UNI_YES;
      config.indicators[i].rsiPeriod=exit ? InpRsiExitPeriod : InpRsiEntryPeriod;
      config.indicators[i].rsiPrice=(ENUM_APPLIED_PRICE)(exit ? InpRsiExitPrice : InpRsiEntryPrice);
      config.indicators[i].rsiLower=exit ? InpRsiExitLower : InpRsiEntryLower;
      config.indicators[i].rsiUpper=exit ? InpRsiExitUpper : InpRsiEntryUpper;
      config.indicators[i].adxPeriod=exit ? InpAdxExitPeriod : InpAdxEntryPeriod;
     }
  }

int OnInit()
  {
   TesterHideIndicators(true); // Display only the named slot plots explicitly attached below.
   CGuiState initial; BuildInitialConfiguration(initial);
   bool tester=(bool)MQLInfoInteger(MQL_TESTER);
   bool activate=tester ? InpTesterAutoStart : InpAutoStart;
   bool configured=InpSignal1!="" || InpSignal2!="" || InpSignal3!="" || InpSignal4!="" || InpSignal5!="";
   for(int i=0;i<4;i++)
      if(initial.indicators[i].type!=GUI_INDICATOR_NONE) configured=true;
   string error;
   if(configured || activate)
     {
      GuiAppliedConfiguration config;
      config.setup=initial.setup; config.rules=initial.rules; config.management=initial.management;
      for(int i=0;i<4;i++) config.indicators[i]=initial.indicators[i];
      if(!runtime.Apply(_Symbol,config,error))
        { Print("Configuracao: ",error); runtime.Shutdown(); return INIT_PARAMETERS_INCORRECT; }
      string signals[]={InpSignal1,InpSignal2,InpSignal3,InpSignal4,InpSignal5};
      int usages[]={(int)InpIndicator1Exit,(int)InpIndicator2Exit,(int)InpIndicator3Exit,(int)InpIndicator4Exit};
      if(!runtime.ConfigureSignals(signals,usages,error))
        { Print("Sinal: ",error); runtime.Shutdown(); return INIT_PARAMETERS_INCORRECT; }
      double levels[12];
      for(int i=0;i<4;i++)
        {
         levels[i*3]=usages[i]==1 ? InpRsiExitUpper : InpRsiEntryUpper;
         levels[i*3+1]=usages[i]==1 ? InpRsiExitMiddle : InpRsiEntryMiddle;
         levels[i*3+2]=usages[i]==1 ? InpRsiExitLower : InpRsiEntryLower;
        }
      if(!runtime.ConfigureRsiLevels(levels,error))
        { Print("RSI: ",error); runtime.Shutdown(); return INIT_PARAMETERS_INCORRECT; }
      if(!runtime.ShowIndicators(ChartID(),usages,levels,error)) Print("Indicadores no grafico: ",error);
      if(!runtime.ShowHistograms(ChartID(),InpExibirHistogramas,InpHistogramasBarras,error)) Print("Histogramas: ",error);
      if(activate && !runtime.Activate(error))
        { Print("Ativacao: ",error); runtime.Shutdown(); return INIT_FAILED; }
     }
   else if(tester && !MQLInfoInteger(MQL_VISUAL_MODE))
     { Print("Selecione ao menos um indicador para testar o motor."); return INIT_PARAMETERS_INCORRECT; }
   string status=!runtime.HasConfiguration() ? "Sem configuracao ativa" :
                 (runtime.Active() ? "Entradas habilitadas" : "Entradas pausadas; gestao habilitada");
   if(InpExibirPainel && (!tester || MQLInfoInteger(MQL_VISUAL_MODE)))
      if(!panel.Create(ChartID(),status,initial))
        { Print("Falha ao criar painel: ",GetLastError()); runtime.Shutdown(); return INIT_FAILED; }
   // Tester timers fire for every simulated second, even in Open Prices
   // mode. Process() already services orders on generated ticks; reserve
   // the timer for live maintenance between quotes.
   if(!tester && !EventSetTimer(1))
     { Print("Falha ao iniciar timer: ",GetLastError()); panel.Destroy(); runtime.Shutdown(); return INIT_FAILED; }
   if(InpExibirPainel) panel.Refresh(runtime.Active(),runtime.HasConfiguration());
   if(!tester || MQLInfoInteger(MQL_VISUAL_MODE))
     {
      price_markers.Configure(ChartID(),_Symbol,InpMagic,InpShowPriceMarkers,InpMarkerEntryColor,
                              InpMarkerStopColor,InpMarkerTakeColor,InpMarkerPendingColor,InpMarkerTextColor,InpMarkerFontSize);
      price_markers.ConfigureBreakeven(initial.management.mode[0],initial.management.values[0],InpMarkerBreakevenColor,initial.management.values[1]);
      price_markers.ShowProfit(InpMarkerShowProfit);
      price_markers.ResultColors(InpMarkerProfitColor,InpMarkerLossColor);
      price_markers.Refresh(true);
     }
   Print("UniEA: ",status,". Configuracao pelos inputs.");
   return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason)
  { EventKillTimer(); price_markers.Destroy(); runtime.Shutdown(); panel.Destroy(); }

void ReportExecutionError(const string error)
  {
   static string previous="";
   if(error==previous) return;
   previous=error;
   if(error!="") Print("Execucao: ",error);
  }
void OnTimer()
  { string error; runtime.Service(error); ReportExecutionError(error); if(InpExibirPainel) panel.Refresh(runtime.Active(),runtime.HasConfiguration(),error); price_markers.Refresh(); }

void OnTick()
  {
   string error;
   int signal=runtime.Process(error);
   ReportExecutionError(error);
   if(InpExibirPainel) panel.Refresh(runtime.Active(),runtime.HasConfiguration(),error);
   price_markers.Refresh();
   if(signal==1) Print("Sinal de compra / ",runtime.AppliedName()," / configuracao ",runtime.Revision());
   if(signal==-1) Print("Sinal de venda / ",runtime.AppliedName()," / configuracao ",runtime.Revision());
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(InpExibirPainel) panel.OnChartEvent(id,lparam,dparam,sparam);
   if(id==CHARTEVENT_CHART_CHANGE) price_markers.Refresh(true);
  }

void OnTradeTransaction(const MqlTradeTransaction &transaction,const MqlTradeRequest &request,const MqlTradeResult &result)
  { price_markers.Refresh(true); }
