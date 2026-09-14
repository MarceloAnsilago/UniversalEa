#property strict
#property version "1.00"
#property description "Experimento de GUI Canvas. Sem trading ou indicadores reais."
#include "Include/CanvasGUI/GuiApp.mqh"
#include "Include/MyUnEA.mqh"
#include "Include/Configuration/UniInputOptions.mqh"

// Modos de gestao com os mesmos valores usados pela interface.
enum ENUM_UNI_MANAGEMENT_MODE
  {
   UNI_MANAGEMENT_DISABLED=0, // Desativado
   UNI_MANAGEMENT_POINTS=1,   // Pontos
   UNI_MANAGEMENT_PERCENT=2   // Porcentagem
  };

// Parametros de entrada: declarados para a futura carga da configuracao.
// Os indicadores sao transferidos para MyUnEA; os demais grupos e a GUI aguardam integracao.
// Identidade do arquivo e limites de volume sao dados internos, nao inputs.
input group "Setup"
input string InpName="Meu setup";                              // Nome do setup
input long InpMagic=1;                                         // Magic Number: 1 a 2147483647
input ENUM_GUI_SETUP_MARKET InpMarket=GUI_SETUP_FOREX;          // Mercado: Forex ou B3
input ENUM_UNI_TIMEFRAME InpTimeframe=UNI_PERIOD_M1;                   // Período da estratégia
input ENUM_GUI_SETUP_DIRECTION InpDirection=GUI_SETUP_BUY_SELL; // Direcao permitida das operacoes
input ENUM_GUI_SETUP_TRADE_MODE InpTradeMode=GUI_SETUP_DAY_TRADE; // Modalidade: operações no mesmo dia ou em vários dias
input double InpLot=0.01;                                      // Volume por operacao; respeitar limites e passo do ativo

// Horarios em minutos desde 00:00 no servidor, de 0 a 1435, em passos de 5.
// Exemplo: 09:30 = 570. Inicio e fim devem ser diferentes.
input group "Horarios"
input int InpEntryStart=0;         // Inicio das entradas: 0 = 00:00
input int InpEntryEnd=1435;        // Fim das entradas: 1435 = 23:55
input ENUM_UNI_YES_NO InpCloseEnabled=UNI_NO; // Habilitar encerramento por horario
input int InpCloseTime=1435;       // Encerramento: minutos desde 00:00; usado quando habilitado

input group "Regras de entrada e saida"
input ENUM_GUI_ORDER_MODE InpOrderMode=GUI_ORDER_MARKET;           // Tipo de ordem: a mercado ou pendente
input ENUM_GUI_CANDLE_FILTER InpCandleFilter=GUI_CANDLE_DISABLED;   // Filtro: desativado, candle de alta ou de baixa
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

input group "RSI — Parâmetros compartilhados"
// Todas as selecoes de RSI nos inputs usam estes mesmos parametros.
input int InpRsiPeriod=14; // Período: 1 a 100000
input ENUM_UNI_APPLIED_PRICE InpRsiPrice=UNI_PRICE_CLOSE; // Preço aplicado
input double InpRsiLower=30.0; // Nível inferior: 0 a 100, menor que o superior
input double InpRsiUpper=70.0; // Nível superior: 0 a 100, maior que o inferior

input group "ADX — Parâmetros compartilhados"
// Todas as selecoes de ADX nos inputs usam este mesmo periodo.
input int InpAdxPeriod=14; // Período: 1 a 100000

CGuiApp gui;
// Instancia da classe responsavel pela logica do Expert Advisor.
MyUnEA ea;
// Monta a configuracao de cada indicador a partir dos inputs.
// MA usa os parametros da sua posicao; os demais tipos usam o grupo unico.
bool ConfigureInputIndicators()
  {
   ENUM_GUI_INDICATOR_TYPE types[]={InpIndicator1Type,InpIndicator2Type,InpIndicator3Type,InpIndicator4Type};
   int periods[]={InpIndicator1MaPeriod,InpIndicator2MaPeriod,InpIndicator3MaPeriod,InpIndicator4MaPeriod};
   int shifts[]={InpIndicator1MaShift,InpIndicator2MaShift,InpIndicator3MaShift,InpIndicator4MaShift};
   ENUM_UNI_MA_METHOD methods[]={InpIndicator1MaMethod,InpIndicator2MaMethod,InpIndicator3MaMethod,InpIndicator4MaMethod};
   ENUM_UNI_APPLIED_PRICE prices[]={InpIndicator1MaPrice,InpIndicator2MaPrice,InpIndicator3MaPrice,InpIndicator4MaPrice};
   for(int i=0;i<4;i++)
     {
      IndicatorConfig config;
      config.type=types[i];
      config.maPeriod=periods[i]; config.maShift=shifts[i];
      config.maMethod=(ENUM_MA_METHOD)methods[i];
      config.maPrice=(ENUM_APPLIED_PRICE)prices[i];
      config.rsiPeriod=InpRsiPeriod; config.rsiPrice=(ENUM_APPLIED_PRICE)InpRsiPrice;
      config.rsiLower=InpRsiLower; config.rsiUpper=InpRsiUpper;
      config.adxPeriod=InpAdxPeriod;
      string error;
      if(!ea.ConfigureIndicator(i,config,error))
        { PrintFormat("Indicador %d: %s",i+1,error); return false; }
     }
   return true;
  }
int OnInit() {
 if(!ConfigureInputIndicators()) return INIT_PARAMETERS_INCORRECT;
 return gui.Create(ChartID(),DebugGUI==UNI_YES) ? INIT_SUCCEEDED : INIT_FAILED;
 
  }
void OnDeinit(const int reason) {

 gui.Destroy();
 
  }
void OnTick() {


}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  { gui.Event(id,lparam,dparam,sparam); }
