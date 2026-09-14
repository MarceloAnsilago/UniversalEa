#ifndef UNI_MY_ADX_MQH
#define UNI_MY_ADX_MQH
#include "MyIndicator.mqh"

// Parametros exclusivos de ADX; independentes da interface grafica.
struct MyADXConfig
  {
   int period;
  };

class MyADX : public MyIndicator
  {
private:
   MyADXConfig m_config;
public:
   // Armazena a configuracao; o recurso so e criado em Initialize.
   MyADX(const MyADXConfig &config) { m_config=config; m_buffer_count=3; }
   // Valida os parametros especificos antes de criar o indicador.
   bool Validate()
     { return !(m_config.period<1 || m_config.period>100000); }
   // Inicializa ou recria o handle. False indica parametros ou recurso invalidos.
   virtual bool Initialize(const string symbol,const ENUM_TIMEFRAMES timeframe)
     {
      Release();
      if(!Validate()) return false;
      m_handle=iADX(symbol,timeframe,m_config.period);
      return m_handle!=INVALID_HANDLE;
     }
  };
#endif
