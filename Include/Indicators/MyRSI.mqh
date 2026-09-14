#ifndef UNI_MY_RSI_MQH
#define UNI_MY_RSI_MQH
#include "MyIndicator.mqh"

// Parametros exclusivos de RSI; independentes da interface grafica.
struct MyRSIConfig
  {
   int period;
   ENUM_APPLIED_PRICE price;
   double lower,upper;
  };

class MyRSI : public MyIndicator
  {
private:
   MyRSIConfig m_config;
public:
   // Armazena a configuracao; o recurso so e criado em Initialize.
   MyRSI(const MyRSIConfig &config) { m_config=config; m_buffer_count=1; }
   // Valida os parametros especificos antes de criar o indicador.
   bool Validate()
     { return !(m_config.period<1 || m_config.period>100000 || (int)m_config.price<1 || (int)m_config.price>7 || !MathIsValidNumber(m_config.lower) || !MathIsValidNumber(m_config.upper) || m_config.lower<0 || m_config.upper>100 || m_config.lower>=m_config.upper); }
   // Inicializa ou recria o handle. False indica parametros ou recurso invalidos.
   virtual bool Initialize(const string symbol,const ENUM_TIMEFRAMES timeframe)
     {
      Release();
      if(!Validate()) return false;
      m_handle=iRSI(symbol,timeframe,m_config.period,m_config.price);
      return m_handle!=INVALID_HANDLE;
     }
  };
#endif
