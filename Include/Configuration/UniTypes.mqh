#ifndef UNI_CONFIGURATION_TYPES_MQH
#define UNI_CONFIGURATION_TYPES_MQH

// Tipos compartilhados pelo EA e pela interface, sem dependencias graficas.
// Nomes e valores preservados para compatibilidade com os sets existentes.
enum ENUM_GUI_SETUP_MARKET
  {
   GUI_SETUP_FOREX=0, // Câmbio (Forex)
   GUI_SETUP_B3=1 // Bolsa brasileira (B3)
  };
enum ENUM_GUI_SETUP_DIRECTION
  {
   GUI_SETUP_BUY_SELL=0, // Compra e venda
   GUI_SETUP_BUY_ONLY=1, // Somente compra
   GUI_SETUP_SELL_ONLY=2 // Somente venda
  };
enum ENUM_GUI_SETUP_TRADE_MODE
  {
   GUI_SETUP_DAY_TRADE=0, // Operações no mesmo dia
   GUI_SETUP_SWING_TRADE=1 // Operações de vários dias
  };
enum ENUM_GUI_ORDER_MODE
  {
   GUI_ORDER_MARKET, // A mercado
   GUI_ORDER_PENDING // Pendente
  };
enum ENUM_GUI_CANDLE_FILTER
  {
   GUI_CANDLE_DISABLED, // Desativado
   GUI_CANDLE_BULLISH, // Vela de alta
   GUI_CANDLE_BEARISH // Vela de baixa
  };
enum ENUM_GUI_TARGET_UNIT
  {
   GUI_TARGET_POINTS, // Pontos
   GUI_TARGET_PERCENT // Porcentagem
  };
enum ENUM_GUI_INDICATOR_TYPE
  {
   GUI_INDICATOR_NONE=-1, // Não usar
   GUI_INDICATOR_MA, // Média móvel
   GUI_INDICATOR_RSI, // Índice de força relativa (RSI)
   GUI_INDICATOR_ADX // Índice direcional médio (ADX)
  };

// Formato de transporte da GUI e dos sets; a fabrica extrai apenas o tipo ativo.
struct IndicatorConfig
  {
   ENUM_GUI_INDICATOR_TYPE type;
   int maPeriod;
   ENUM_MA_METHOD maMethod;
   ENUM_APPLIED_PRICE maPrice;
   int maShift;
   int rsiPeriod;
   int adxPeriod;
   ENUM_APPLIED_PRICE rsiPrice;
   double rsiLower,rsiUpper;
   double adxMinimum; // Forca minima exigida: ADX deve ser estritamente maior.
   int maSlopeBars; // Quantidade de velas fechadas para inclinacao consecutiva (minimo 2).
  };
#endif
