#property strict
#property version "1.00"
#property description "EA com GUI Canvas e inicialização de indicadores. Sem envio de ordens."
#include "Include/CanvasGUI/GuiApp.mqh"
#include "Include/UniRuntime.mqh"
#include "Include/Configuration/UniInputOptions.mqh"

MqlTick lastest_price; // Armazena o último tick recebido para evitar processamento duplicado  
MqlRates mrate[]; // Armazena os dados de preço do ativo

// Modos de gestao com os mesmos valores usados pela interface.
enum ENUM_UNI_MANAGEMENT_MODE
  {
   UNI_MANAGEMENT_DISABLED=0, // Desativado
   UNI_MANAGEMENT_POINTS=1,   // Pontos
   UNI_MANAGEMENT_PERCENT=2   // Porcentagem
  };

// Parametros de entrada: declarados para a futura carga da configuracao.
// Os inputs preenchem o Canvas. Aplicar ao motor valida e transfere a configuracao.
// Identidade do arquivo e limites de volume sao dados internos, nao inputs.
input group "Setup"
input string InpName="Meu setup";                              // Nome do setup
input long InpMagic=1;                                         // Magic Number: 1 a 2147483647
input ENUM_GUI_SETUP_MARKET InpMarket=GUI_SETUP_FOREX;          // Mercado: Forex ou B3
input ENUM_UNI_TIMEFRAME InpStrategyTimeframe=UNI_PERIOD_CURRENT;                   // Período da estratégia
input ENUM_GUI_SETUP_DIRECTION InpDirection=GUI_SETUP_BUY_SELL; // Direcao permitida das operacoes
input ENUM_GUI_SETUP_TRADE_MODE InpTradeMode=GUI_SETUP_DAY_TRADE; // Modalidade: operações no mesmo dia ou em vários dias
input double InpLot=0.01;                                      // Volume por operacao; respeitar limites e passo do ativo

// Horarios em minutos desde 00:00 no servidor, de 0 a 1435, em passos de 5.
// Exemplo: 09:30 = 570. Inicio e fim devem ser diferentes.
input group "Horarios"
input int InpEntryStart=0;         // Inicio das entradas: 0 = 00:00
input int InpEntryEnd=1435;        // Encerramento das entradas: 1435 = 23:55
// Encerramento das entradas usa InpEntryEnd. Posições seguem a modalidade.

input group "Regras de entrada e saida"
input ENUM_GUI_ORDER_MODE InpOrderMode=GUI_ORDER_MARKET;           // Tipo de ordem: a mercado ou pendente
input ENUM_GUI_CANDLE_FILTER InpCandleFilter=GUI_CANDLE_DISABLED;   // Filtro: desativado, tamanho de candles ou pavios
input ENUM_GUI_TARGET_UNIT InpTargetUnit=GUI_TARGET_POINTS;        // Unidade do stop loss e take profit
input double InpStopLoss=0.0;                                      // Stop loss na unidade selecionada; 0 desativa
input double InpTakeProfit=0.0;                                    // Take profit na unidade selecionada; 0 desativa

// Valores de gestao usam a unidade do respectivo modo.
// A base de calculo percentual sera definida na implementacao da gestao.
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

input group "Diagnostico"
input ENUM_UNI_YES_NO DebugGUI=UNI_YES; // Habilitar mensagens de diagnostico da interface

// Selecione o tipo em cada indicador; configure seus parametros no grupo do indicador.
// Apenas a Media Movel possui parametros independentes por indicador.
// RSI, ADX e futuros tipos usam um grupo compartilhado quando repetidos nos inputs.
input group "▪▪▪▪▪ Indicador 1 ▪▪▪▪▪"
input ENUM_GUI_INDICATOR_TYPE InpIndicator1Type=GUI_INDICATOR_NONE; // Tipo do Indicador 1; Não usar = desativado

input group "▪▪▪▪▪ Indicador 2 ▪▪▪▪▪"
input ENUM_GUI_INDICATOR_TYPE InpIndicator2Type=GUI_INDICATOR_NONE; // Tipo do Indicador 2; Não usar = desativado

input group "▪▪▪▪▪ Indicador 3 ▪▪▪▪▪"
input ENUM_GUI_INDICATOR_TYPE InpIndicator3Type=GUI_INDICATOR_NONE; // Tipo do Indicador 3; Não usar = desativado

input group "▪▪▪▪▪ Indicador 4 ▪▪▪▪▪"
input ENUM_GUI_INDICATOR_TYPE InpIndicator4Type=GUI_INDICATOR_NONE; // Tipo do Indicador 4; Não usar = desativado

input group "Média Móvel — Parâmetros por indicador"
// Use os campos do indicador que selecionou Media Movel; os demais ficam inativos na futura carga.
// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa1="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 1 ▪▪▪
input int InpIndicator1MaPeriod=20; // Indicador 1 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator1MaMethod=UNI_MA_EMA; // Indicador 1 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator1MaPrice=UNI_PRICE_CLOSE; // Indicador 1 │ Preço aplicado
input int InpIndicator1MaShift=0; // Indicador 1 │ Deslocamento em barras: -100000 a 100000
input int InpIndicator1MaSlopeBars=3; // Indicador 1 │ Inclinação: 2 a 100000 velas fechadas

// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa2="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 2 ▪▪▪
input int InpIndicator2MaPeriod=20; // Indicador 2 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator2MaMethod=UNI_MA_EMA; // Indicador 2 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator2MaPrice=UNI_PRICE_CLOSE; // Indicador 2 │ Preço aplicado
input int InpIndicator2MaShift=0; // Indicador 2 │ Deslocamento em barras: -100000 a 100000
input int InpIndicator2MaSlopeBars=3; // Indicador 2 │ Inclinação: 2 a 100000 velas fechadas

// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa3="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 3 ▪▪▪
input int InpIndicator3MaPeriod=20; // Indicador 3 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator3MaMethod=UNI_MA_EMA; // Indicador 3 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator3MaPrice=UNI_PRICE_CLOSE; // Indicador 3 │ Preço aplicado
input int InpIndicator3MaShift=0; // Indicador 3 │ Deslocamento em barras: -100000 a 100000
input int InpIndicator3MaSlopeBars=3; // Indicador 3 │ Inclinação: 2 a 100000 velas fechadas

// Linha apenas visual; nao participa da configuracao nem da otimizacao.
sinput string InpSeparatorMa4="▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪"; // ▪▪▪ Indicador 4 ▪▪▪
input int InpIndicator4MaPeriod=20; // Indicador 4 │ Período: 1 a 100000
input ENUM_UNI_MA_METHOD InpIndicator4MaMethod=UNI_MA_EMA; // Indicador 4 │ Método de cálculo
input ENUM_UNI_APPLIED_PRICE InpIndicator4MaPrice=UNI_PRICE_CLOSE; // Indicador 4 │ Preço aplicado
input int InpIndicator4MaShift=0; // Indicador 4 │ Deslocamento em barras: -100000 a 100000
input int InpIndicator4MaSlopeBars=3; // Indicador 4 │ Inclinação: 2 a 100000 velas fechadas

input group "RSI — Parâmetros compartilhados"
// Todas as selecoes de RSI nos inputs usam estes mesmos parametros.
input int InpRsiPeriod=14; // Período: 1 a 100000
input ENUM_UNI_APPLIED_PRICE InpRsiPrice=UNI_PRICE_CLOSE; // Preço aplicado
input double InpRsiLower=30.0; // Sobrevenda: compra ao cruzar para cima (padrão 30)
input double InpRsiUpper=70.0; // Sobrecompra: venda ao cruzar para baixo (padrão 70)

input group "ADX — Parâmetros compartilhados"
// Todas as selecoes de ADX nos inputs usam este mesmo periodo.
input int InpAdxPeriod=14; // Período: 1 a 100000
input double InpAdxMinimum=25.0; // ADX mínimo (0 a 100): exige valor acima; otimizável

CGuiApp gui;
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
   // Distancia de take fornecida nos inputs seleciona o modo fixo.
   if(InpTakeProfit>0) config.rules.take_mode=1;
   config.management.Choose(0,(int)InpBreakevenMode);
   config.management.Choose(1,(int)InpTrailingMode);
   config.management.Choose(2,(int)InpMovingStopMode);
   config.management.values[0]=InpBreakevenTrigger; config.management.values[1]=InpBreakevenOffset;
   config.management.values[2]=InpTrailingTrigger; config.management.values[3]=InpTrailingDistance; config.management.values[4]=InpTrailingStep;
   config.management.values[5]=InpMovingStopTrigger; config.management.values[6]=InpMovingStopDistance; config.management.values[7]=InpMovingStopStep;
   ENUM_GUI_INDICATOR_TYPE types[]={InpIndicator1Type,InpIndicator2Type,InpIndicator3Type,InpIndicator4Type};
   int periods[]={InpIndicator1MaPeriod,InpIndicator2MaPeriod,InpIndicator3MaPeriod,InpIndicator4MaPeriod};
   int slopes[]={InpIndicator1MaSlopeBars,InpIndicator2MaSlopeBars,InpIndicator3MaSlopeBars,InpIndicator4MaSlopeBars};
   int shifts[]={InpIndicator1MaShift,InpIndicator2MaShift,InpIndicator3MaShift,InpIndicator4MaShift};
   ENUM_UNI_MA_METHOD methods[]={InpIndicator1MaMethod,InpIndicator2MaMethod,InpIndicator3MaMethod,InpIndicator4MaMethod};
   ENUM_UNI_APPLIED_PRICE prices[]={InpIndicator1MaPrice,InpIndicator2MaPrice,InpIndicator3MaPrice,InpIndicator4MaPrice};
   for(int i=0;i<4;i++)
     {
      config.indicators[i].type=types[i];
      config.indicators[i].maSlopeBars=slopes[i]; config.indicators[i].maPeriod=periods[i];
      config.indicators[i].maShift=shifts[i]; config.indicators[i].maMethod=(ENUM_MA_METHOD)methods[i];
      config.indicators[i].maPrice=(ENUM_APPLIED_PRICE)prices[i];
      config.indicators[i].rsiPeriod=InpRsiPeriod; config.indicators[i].rsiPrice=(ENUM_APPLIED_PRICE)InpRsiPrice;
      config.indicators[i].rsiLower=InpRsiLower; config.indicators[i].rsiUpper=InpRsiUpper;
      config.indicators[i].adxPeriod=InpAdxPeriod; config.indicators[i].adxMinimum=InpAdxMinimum;
     }
  }

int OnInit()
  {
   if(!gui.Create(ChartID(),DebugGUI==UNI_YES)) return INIT_FAILED;
   CGuiState initial; BuildInitialConfiguration(initial); gui.LoadInitialConfiguration(initial);
   gui.ExecutionResult(false,false,0,"","Aplique a configuracao na etapa Revisao.");
   return INIT_SUCCEEDED;
  }
void OnDeinit(const int reason) { runtime.Shutdown(); gui.Destroy(); }

void OnTick()
  {
   string error;
   int signal=runtime.PollSignal(error);
   static string previous_error="";
   if(error!=previous_error)
     {
      previous_error=error;
      if(error!="") Print("Analise: ",error);
     }
   if(signal==1) Print("Sinal de compra / ",runtime.AppliedName()," / configuracao ",runtime.Revision());
   if(signal==-1) Print("Sinal de venda / ",runtime.AppliedName()," / configuracao ",runtime.Revision());
  }
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   gui.Event(id,lparam,dparam,sparam);
   int action=gui.TakeExecutionRequest();
   if(action==0) return;
   string error,message; bool ok=true;
   if(action==1)
     {
      GuiAppliedConfiguration config;
      ok=gui.CaptureConfiguration(config,error) && runtime.Apply(_Symbol,config,error);
      message="Configuracao aplicada. Analise pausada.";
     }
   else if(action==2) { ok=runtime.Activate(error); message="Analise ativa a partir da proxima vela. Sem ordens."; }
   else { runtime.Pause(); message="Analise pausada."; }
   gui.ExecutionResult(runtime.HasConfiguration(),runtime.Active(),runtime.Revision(),runtime.AppliedName(),ok ? message : error,!ok);
  }
