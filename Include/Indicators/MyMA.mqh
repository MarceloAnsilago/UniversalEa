#ifndef UNI_MY_MA_MQH
#define UNI_MY_MA_MQH
#include "MyIndicator.mqh"

// Parametros exclusivos de MA; independentes da interface grafica.
struct MyMAConfig
  {
   int period,shift;
   ENUM_MA_METHOD method;
   ENUM_APPLIED_PRICE price;
  };

class MyMA : public MyIndicator
  {
private:
   MyMAConfig m_config;
public:
   // Armazena a configuracao; o recurso so e criado em Initialize.
   MyMA(const MyMAConfig &config) { m_config=config; m_buffer_count=1; }
   // Valida os parametros especificos antes de criar o indicador.
   bool Validate()
     { return !(m_config.period<1 || m_config.period>100000 || m_config.shift< -100000 || m_config.shift>100000 || (int)m_config.method<0 || (int)m_config.method>3 || (int)m_config.price<1 || (int)m_config.price>7); }
   // Inicializa ou recria o handle. False indica parametros ou recurso invalidos.
   virtual bool Initialize(const string symbol,const ENUM_TIMEFRAMES timeframe)
     {
      Release();
      if(!Validate()) return false;
      m_handle=iMA(symbol,timeframe,m_config.period,m_config.shift,m_config.method,m_config.price);
      return m_handle!=INVALID_HANDLE;
     }
  };
#endif
