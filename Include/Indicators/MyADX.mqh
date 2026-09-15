#ifndef UNI_MY_ADX_MQH
#define UNI_MY_ADX_MQH
#include "MyIndicator.mqh"

// Parametros exclusivos de ADX; independentes da interface grafica.
struct MyADXConfig
  {
   int period;
   double minimum; // Limiar configuravel de forca; referencia inicial: 25.
  };

class MyADX : public MyIndicator
  {
private:
   MyADXConfig m_config;
   // Confirma direcao e forca na ultima vela fechada; nao exige novo cruzamento.
   bool CheckDirection(const MqlRates &rates[],MyIndicatorValues &values,const bool buy)
     {
      if(ArraySize(rates)<2 || !Validate()) return false;
      double adx,plus,minus;
      if(!values.Get(0,1,adx) || !values.Get(1,1,plus) || !values.Get(2,1,minus)) return false;
      if(!MathIsValidNumber(adx) || !MathIsValidNumber(plus) || !MathIsValidNumber(minus) ||
         adx==EMPTY_VALUE || plus==EMPTY_VALUE || minus==EMPTY_VALUE ||
         adx<0 || adx>100 || plus<0 || plus>100 || minus<0 || minus>100) return false;
      if(adx<=m_config.minimum) return false; // Igualdade tambem nao confirma forca.
      return buy ? plus>minus : minus>plus;
     }
public:
   // Armazena a configuracao; o recurso so e criado em Initialize.
   MyADX(const MyADXConfig &config) { m_config=config; m_buffer_count=3; }
   // Compra quando +DI > -DI e ADX supera o minimo configurado.
   virtual bool CheckBuy(const MqlRates &rates[],MyIndicatorValues &values)
     { return CheckDirection(rates,values,true); }
   // Venda quando -DI > +DI e ADX supera o minimo configurado.
   virtual bool CheckSell(const MqlRates &rates[],MyIndicatorValues &values)
     { return CheckDirection(rates,values,false); }
   // Valida os parametros especificos antes de criar o indicador.
   bool Validate()
     { return m_config.period>=1 && m_config.period<=100000 &&
              MathIsValidNumber(m_config.minimum) && m_config.minimum>=0 && m_config.minimum<=100; }
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
