#property strict
#property version "1.00"
#property description "Experimento de GUI Canvas. Sem trading ou indicadores reais."
#include "Include/CanvasGUI/GuiApp.mqh"
#include "Include/MyUnEA.mqh"

// Modos de gestao com os mesmos valores usados pela interface.
enum ENUM_UNI_MANAGEMENT_MODE
  {
   UNI_MANAGEMENT_DISABLED=0, // Desativado
   UNI_MANAGEMENT_POINTS=1,   // Pontos
   UNI_MANAGEMENT_PERCENT=2   // Porcentagem
  };

// Parametros de entrada: declarados para a futura carga da configuracao.
// A transferencia destes valores para MyUnEA e para a GUI sera implementada depois.
// Identidade do arquivo e limites de volume sao dados internos, nao inputs.
input group "Setup"
input string InpName="Meu setup";                              // Nome do setup
input long InpMagic=1;                                         // Magic Number: 1 a 2147483647
input ENUM_GUI_SETUP_MARKET InpMarket=GUI_SETUP_FOREX;          // Mercado: Forex ou B3
input ENUM_TIMEFRAMES InpTimeframe=PERIOD_M1;                   // Timeframe da estrategia
input ENUM_GUI_SETUP_DIRECTION InpDirection=GUI_SETUP_BUY_SELL; // Direcao permitida das operacoes
input ENUM_GUI_SETUP_TRADE_MODE InpTradeMode=GUI_SETUP_DAY_TRADE; // Modalidade: day trade ou swing trade
input double InpLot=0.01;                                      // Volume por operacao; respeitar limites e passo do ativo

// Horarios em minutos desde 00:00 no servidor, de 0 a 1435, em passos de 5.
// Exemplo: 09:30 = 570. Inicio e fim devem ser diferentes.
input group "Horarios"
input int InpEntryStart=0;         // Inicio das entradas: 0 = 00:00
input int InpEntryEnd=1435;        // Fim das entradas: 1435 = 23:55
input bool InpCloseEnabled=false; // Habilitar encerramento por horario
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

// Cada slot preserva parametros independentes para MA, RSI e ADX.
// Somente os parametros do tipo selecionado serao usados.
// Periodos: 1 a 100000. Niveis RSI: 0 a 100, inferior menor que superior.
input group "Indicador 1"
input ENUM_GUI_INDICATOR_TYPE InpIndicator1Type=GUI_INDICATOR_NONE; // Tipo do indicador 1; NONE = nao usar
input int InpIndicator1MaPeriod=20;                     // Media movel: periodo
input ENUM_MA_METHOD InpIndicator1MaMethod=MODE_EMA;   // Media movel: metodo de calculo
input ENUM_APPLIED_PRICE InpIndicator1MaPrice=PRICE_CLOSE; // Media movel: preco aplicado
input int InpIndicator1MaShift=0;                       // Media movel: deslocamento em barras (-100000 a 100000)
input int InpIndicator1RsiPeriod=14;                    // RSI: periodo
input ENUM_APPLIED_PRICE InpIndicator1RsiPrice=PRICE_CLOSE; // RSI: preco aplicado
input double InpIndicator1RsiLower=30.0;                // RSI: nivel inferior
input double InpIndicator1RsiUpper=70.0;                // RSI: nivel superior
input int InpIndicator1AdxPeriod=14;                    // ADX: periodo

input group "Indicador 2"
input ENUM_GUI_INDICATOR_TYPE InpIndicator2Type=GUI_INDICATOR_NONE; // Tipo do indicador 2; NONE = nao usar
input int InpIndicator2MaPeriod=20;                     // Media movel: periodo
input ENUM_MA_METHOD InpIndicator2MaMethod=MODE_EMA;   // Media movel: metodo de calculo
input ENUM_APPLIED_PRICE InpIndicator2MaPrice=PRICE_CLOSE; // Media movel: preco aplicado
input int InpIndicator2MaShift=0;                       // Media movel: deslocamento em barras (-100000 a 100000)
input int InpIndicator2RsiPeriod=14;                    // RSI: periodo
input ENUM_APPLIED_PRICE InpIndicator2RsiPrice=PRICE_CLOSE; // RSI: preco aplicado
input double InpIndicator2RsiLower=30.0;                // RSI: nivel inferior
input double InpIndicator2RsiUpper=70.0;                // RSI: nivel superior
input int InpIndicator2AdxPeriod=14;                    // ADX: periodo

input group "Indicador 3"
input ENUM_GUI_INDICATOR_TYPE InpIndicator3Type=GUI_INDICATOR_NONE; // Tipo do indicador 3; NONE = nao usar
input int InpIndicator3MaPeriod=20;                     // Media movel: periodo
input ENUM_MA_METHOD InpIndicator3MaMethod=MODE_EMA;   // Media movel: metodo de calculo
input ENUM_APPLIED_PRICE InpIndicator3MaPrice=PRICE_CLOSE; // Media movel: preco aplicado
input int InpIndicator3MaShift=0;                       // Media movel: deslocamento em barras (-100000 a 100000)
input int InpIndicator3RsiPeriod=14;                    // RSI: periodo
input ENUM_APPLIED_PRICE InpIndicator3RsiPrice=PRICE_CLOSE; // RSI: preco aplicado
input double InpIndicator3RsiLower=30.0;                // RSI: nivel inferior
input double InpIndicator3RsiUpper=70.0;                // RSI: nivel superior
input int InpIndicator3AdxPeriod=14;                    // ADX: periodo

input group "Indicador 4"
input ENUM_GUI_INDICATOR_TYPE InpIndicator4Type=GUI_INDICATOR_NONE; // Tipo do indicador 4; NONE = nao usar
input int InpIndicator4MaPeriod=20;                     // Media movel: periodo
input ENUM_MA_METHOD InpIndicator4MaMethod=MODE_EMA;   // Media movel: metodo de calculo
input ENUM_APPLIED_PRICE InpIndicator4MaPrice=PRICE_CLOSE; // Media movel: preco aplicado
input int InpIndicator4MaShift=0;                       // Media movel: deslocamento em barras (-100000 a 100000)
input int InpIndicator4RsiPeriod=14;                    // RSI: periodo
input ENUM_APPLIED_PRICE InpIndicator4RsiPrice=PRICE_CLOSE; // RSI: preco aplicado
input double InpIndicator4RsiLower=30.0;                // RSI: nivel inferior
input double InpIndicator4RsiUpper=70.0;                // RSI: nivel superior
input int InpIndicator4AdxPeriod=14;                    // ADX: periodo

input group "Diagnostico"
input bool DebugGUI=true; // Habilitar mensagens de diagnostico da interface
CGuiApp gui;
// Instancia da classe responsavel pela logica do Expert Advisor.
MyUnEA ea;
int OnInit() {
 return gui.Create(ChartID(),DebugGUI) ? INIT_SUCCEEDED : INIT_FAILED;
 
  }
void OnDeinit(const int reason) {

 gui.Destroy();
 
  }
void OnTick() {


}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  { gui.Event(id,lparam,dparam,sparam); }
