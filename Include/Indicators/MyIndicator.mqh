#ifndef UNI_MY_INDICATOR_MQH
#define UNI_MY_INDICATOR_MQH
#include "MyIndicatorValues.mqh"

// Contrato comum. Cada instancia possui exclusivamente seu proprio handle.
class MyIndicator
  {
protected:
   int m_handle;
   int m_buffer_count;
public:
   // Cria um indicador ainda sem recursos do terminal.
   MyIndicator() { m_handle=INVALID_HANDLE; m_buffer_count=1; }
   // Destrutor virtual permite liberar a classe concreta pelo ponteiro base.
   virtual ~MyIndicator() { Release(); }
   // Cada tipo cria seu handle para o ativo e timeframe informados.
   virtual bool Initialize(const string symbol,const ENUM_TIMEFRAMES timeframe)=0;
   // Informa quantas linhas precisam ser lidas: MA/RSI = 1; ADX = 3.
   int BufferCount() { return m_buffer_count; }
   // Quantidade de valores por buffer, incluindo a barra atual.
   virtual int RequiredValues() { return 3; }
   // Regras individuais: rates[0] e a vela atual, rates[1] a ultima fechada.
   // Novos indicadores sobrescrevem estes metodos. Sem regra definida,
   // o tipo nao confirma nenhuma direcao (RSI e ADX por enquanto).
   virtual bool CheckBuy(const MqlRates &rates[],MyIndicatorValues &values) { return false; }
   virtual bool CheckSell(const MqlRates &rates[],MyIndicatorValues &values) { return false; }
   // Copia valores de um buffer: barra 0 = atual, barra 1 = ultima fechada.
   // Saida em ordem cronologica: indice 0 e o valor mais antigo solicitado.
   // Retorna false se os dados ainda nao estiverem prontos; limpa a saida.
   virtual bool Update(const int buffer,const int start,const int count,double &values[])
     {
      ArrayFree(values);
      ArraySetAsSeries(values,false);
      if(m_handle==INVALID_HANDLE || buffer<0 || buffer>=m_buffer_count || start<0 || count<1)
         return false;
      if(BarsCalculated(m_handle)<start+count) return false;
      if(CopyBuffer(m_handle,buffer,start,count,values)!=count)
        { ArrayFree(values); return false; }
      return true;
     }
   // Libera o recurso; pode ser chamado repetidamente.
   virtual void Release()
     {
      if(m_handle!=INVALID_HANDLE) IndicatorRelease(m_handle);
      m_handle=INVALID_HANDLE;
     }
  };
#endif
