#ifndef UNI_CONFIGURATION_TYPES_MQH
#define UNI_CONFIGURATION_TYPES_MQH

// Tipos compartilhados pelo EA e pela interface, sem dependencias graficas.
// Nomes e valores preservados para compatibilidade com os sets existentes.
enum ENUM_GUI_SETUP_MARKET { GUI_SETUP_FOREX=0, GUI_SETUP_B3=1 };
enum ENUM_GUI_SETUP_DIRECTION { GUI_SETUP_BUY_SELL=0, GUI_SETUP_BUY_ONLY=1, GUI_SETUP_SELL_ONLY=2 };
enum ENUM_GUI_SETUP_TRADE_MODE { GUI_SETUP_DAY_TRADE=0, GUI_SETUP_SWING_TRADE=1 };
enum ENUM_GUI_ORDER_MODE { GUI_ORDER_MARKET,GUI_ORDER_PENDING };
enum ENUM_GUI_CANDLE_FILTER { GUI_CANDLE_DISABLED,GUI_CANDLE_BULLISH,GUI_CANDLE_BEARISH };
enum ENUM_GUI_TARGET_UNIT { GUI_TARGET_POINTS,GUI_TARGET_PERCENT };
enum ENUM_GUI_INDICATOR_TYPE { GUI_INDICATOR_NONE=-1, GUI_INDICATOR_MA, GUI_INDICATOR_RSI, GUI_INDICATOR_ADX };

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
  };
#endif
