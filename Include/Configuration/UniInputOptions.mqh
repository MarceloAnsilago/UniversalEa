#ifndef UNI_INPUT_OPTIONS_MQH
#define UNI_INPUT_OPTIONS_MQH

// Opcoes de apresentacao em portugues. Os valores numericos correspondem
// aos enums nativos; converter explicitamente ao carregar a configuracao.
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

enum ENUM_UNI_TIMEFRAME
  {
   UNI_PERIOD_CURRENT=0, // Período do gráfico
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
