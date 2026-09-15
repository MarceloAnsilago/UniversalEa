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
   // Compara as duas ultimas velas fechadas, da barra 2 para a barra 1.
   bool CheckCross(const MqlRates &rates[],MyIndicatorValues &values,const bool buy)
     {
      if(ArraySize(rates)<3 || !Validate()) return false;
      double previous,current;
      if(!values.Get(0,2,previous) || !values.Get(0,1,current)) return false;
      if(!MathIsValidNumber(previous) || !MathIsValidNumber(current) ||
         previous==EMPTY_VALUE || current==EMPTY_VALUE ||
         previous<0 || previous>100 || current<0 || current>100) return false;
      // A vela 1 precisa fechar alem do nivel; apenas tocar nao confirma.
      // A vela 2 pode estar no nivel. Sem cruzamento, a faixa neutra nao sinaliza.
      return buy ? previous<=m_config.lower && current>m_config.lower :
                   previous>=m_config.upper && current<m_config.upper;
     }
public:
   // Armazena a configuracao; o recurso so e criado em Initialize.
   MyRSI(const MyRSIConfig &config) { m_config=config; m_buffer_count=1; }
   // Compra: sai da sobrevenda, cruzando o nivel inferior para cima (padrao 30).
   virtual bool CheckBuy(const MqlRates &rates[],MyIndicatorValues &values)
     { return CheckCross(rates,values,true); }
   // Venda: sai da sobrecompra, cruzando o nivel superior para baixo (padrao 70).
   // Ambas as regras usam os niveis configurados e ignoram a vela em formacao.
   virtual bool CheckSell(const MqlRates &rates[],MyIndicatorValues &values)
     { return CheckCross(rates,values,false); }
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
