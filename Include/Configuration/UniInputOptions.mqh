#ifndef UNI_INPUT_OPTIONS_MQH
#define UNI_INPUT_OPTIONS_MQH

// Opcoes de apresentacao em portugues. Os valores numericos correspondem
// aos enums nativos; converter explicitamente ao carregar a configuracao.
enum ENUM_UNI_TAKE_MODE
  {
   UNI_TAKE_AUTO=-1, // Automatico (presets antigos)
   UNI_TAKE_STOP=0,  // Vezes o stop
   UNI_TAKE_FIXED=1  // Distancia fixa; zero desativa
  };

int UniResolveTakeMode(const ENUM_UNI_TAKE_MODE mode,const double distance)
  { return mode==UNI_TAKE_AUTO ? (distance>0 ? 1 : 0) : (int)mode; }

enum ENUM_UNI_STOP_MODE
  {
   UNI_STOP_DISTANCE_CANDLE=0, // Distancia + candle
   UNI_STOP_FIXED=1           // Distancia fixa; zero desativa
  };

double UniResolveStopMultiplier(const ENUM_UNI_STOP_MODE mode,const double multiplier)
  { return mode==UNI_STOP_FIXED ? 0 : (mode==UNI_STOP_DISTANCE_CANDLE ? multiplier : -1); }

enum ENUM_UNI_PENDING_REFERENCE
  {
   UNI_PENDING_HIGH=0,  // Maxima
   UNI_PENDING_LOW=1,   // Minima
   UNI_PENDING_OPEN=2,  // Abertura
   UNI_PENDING_CLOSE=3  // Fechamento
  };

enum ENUM_UNI_MA_METHOD
  {
   UNI_MA_SMA=0,  // Simples
   UNI_MA_EMA=1,  // Exponencial
   UNI_MA_SMMA=2, // Suavizada
   UNI_MA_LWMA=3  // Ponderada linear
  };

enum ENUM_UNI_APPLIED_PRICE
  {
   UNI_PRICE_CLOSE=1,    // Preço de fechamento
   UNI_PRICE_OPEN=2,     // Preço de abertura
   UNI_PRICE_HIGH=3,     // Preço máximo
   UNI_PRICE_LOW=4,      // Preço mínimo
   UNI_PRICE_MEDIAN=5,   // Preço mediano (máxima + mínima) / 2
   UNI_PRICE_TYPICAL=6,  // Preço típico (máxima + mínima + fechamento) / 3
   UNI_PRICE_WEIGHTED=7  // Preço ponderado (máxima + mínima + 2 x fechamento) / 4
  };

enum ENUM_UNI_YES_NO
  {
   UNI_NO=0, // Não
   UNI_YES=1 // Sim
  };

enum ENUM_UNI_SLOT_TIMEFRAME
  {
   UNI_SLOT_CURRENT=0, // Tempo corrente
   UNI_SLOT_M1=1, // M1
   UNI_SLOT_M2=2, // M2
   UNI_SLOT_M3=3, // M3
   UNI_SLOT_M4=4, // M4
   UNI_SLOT_M5=5, // M5
   UNI_SLOT_M6=6, // M6
   UNI_SLOT_M10=7, // M10
   UNI_SLOT_M12=8, // M12
   UNI_SLOT_M15=9, // M15
   UNI_SLOT_M20=10, // M20
   UNI_SLOT_M30=11, // M30
   UNI_SLOT_H1=12, // H1
   UNI_SLOT_H2=13, // H2
   UNI_SLOT_H3=14, // H3
   UNI_SLOT_H4=15, // H4
   UNI_SLOT_H6=16, // H6
   UNI_SLOT_H8=17, // H8
   UNI_SLOT_H12=18, // H12
   UNI_SLOT_D1=19, // D1
   UNI_SLOT_W1=20, // W1
   UNI_SLOT_MN1=21 // MN1
  };
ENUM_TIMEFRAMES UniSlotTimeframe(const ENUM_UNI_SLOT_TIMEFRAME choice)
  {
   ENUM_TIMEFRAMES periods[]={PERIOD_CURRENT,PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
   int index=(int)choice;
   return index>=0 && index<ArraySize(periods) ? periods[index] : (ENUM_TIMEFRAMES)-1;
  }

enum ENUM_UNI_TIMEFRAME
  {
   UNI_PERIOD_CURRENT=0, // Tempo corrente
   UNI_PERIOD_M1=1, // 1 minuto
   UNI_PERIOD_M2=2, // 2 minutos
   UNI_PERIOD_M3=3, // 3 minutos
   UNI_PERIOD_M4=4, // 4 minutos
   UNI_PERIOD_M5=5, // 5 minutos
   UNI_PERIOD_M6=6, // 6 minutos
   UNI_PERIOD_M10=10, // 10 minutos
   UNI_PERIOD_M12=12, // 12 minutos
   UNI_PERIOD_M15=15, // 15 minutos
   UNI_PERIOD_M20=20, // 20 minutos
   UNI_PERIOD_M30=30, // 30 minutos
   UNI_PERIOD_H1=16385, // 1 hora
   UNI_PERIOD_H2=16386, // 2 horas
   UNI_PERIOD_H3=16387, // 3 horas
   UNI_PERIOD_H4=16388, // 4 horas
   UNI_PERIOD_H6=16390, // 6 horas
   UNI_PERIOD_H8=16392, // 8 horas
   UNI_PERIOD_H12=16396, // 12 horas
   UNI_PERIOD_D1=16408, // 1 dia
   UNI_PERIOD_W1=32769, // 1 semana
   UNI_PERIOD_MN1=49153 // 1 mês
  };
#endif
