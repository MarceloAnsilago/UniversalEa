#ifndef UNI_MY_INDICATOR_DATA_MQH
#define UNI_MY_INDICATOR_DATA_MQH
#include "MyIndicator.mqh"

// Guarda a quantidade de valores solicitada por cada indicador, sem limitar a quantidade de linhas do indicador.
// A barra 0 e a atual; 1 e a ultima fechada; 2 e a fechada anterior.
class MyIndicatorData : public MyIndicatorValues
  {
private:
   double m_values[]; // Indice interno: buffer * m_bars + barra.
   int m_buffers,m_bars;
public:
   // Inicia sem dados publicados.
   MyIndicatorData() { m_buffers=0; m_bars=0; }
   // Invalida a leitura anterior para nunca usar valores antigos apos falha.
   void Clear() { ArrayFree(m_values); m_buffers=0; m_bars=0; }
   // Le todas as linhas e publica apenas quando cada uma tem todos os valores validos.
   bool Load(MyIndicator *indicator,string &error)
     {
      Clear(); error="";
      if(indicator==NULL) { error="Indicador não configurado."; return false; }
      int buffers=indicator.BufferCount();
      int bars=indicator.RequiredValues();
      if(bars<3 || bars>100001) { error="Quantidade de barras inválida."; return false; }
      if(buffers<1) { error="Indicador sem buffers disponíveis."; return false; }
      double candidate[];
      if(ArrayResize(candidate,buffers*bars)!=buffers*bars)
        { error="Sem memória para os buffers."; return false; }
      for(int buffer=0;buffer<buffers;buffer++)
        {
         double values[];
         ResetLastError();
         if(!indicator.Update(buffer,0,bars,values) || ArraySize(values)!=bars)
           {
            error=StringFormat("Buffer %d ainda não está pronto. Erro do terminal: %d.",buffer,GetLastError());
            return false;
           }
         // Update entrega ordem cronologica. Padronizar antes de inverter.
         ArraySetAsSeries(values,false);
         for(int bar=0;bar<bars;bar++)
           {
            double value=values[bars-1-bar];
            if(value==EMPTY_VALUE || !MathIsValidNumber(value))
              { error=StringFormat("Buffer %d, barra %d: valor indisponível.",buffer,bar); return false; }
            candidate[buffer*bars+bar]=value;
           }
        }
      if(ArrayCopy(m_values,candidate)!=buffers*bars)
        { Clear(); error="Falha ao guardar os buffers."; return false; }
      m_buffers=buffers; m_bars=bars;
      return true;
     }
   // Consulta um valor validado; false indica indice invalido ou leitura ausente.
   virtual bool Get(const int buffer,const int bar,double &value)
     {
      value=EMPTY_VALUE;
      if(buffer<0 || buffer>=m_buffers || bar<0 || bar>=m_bars) return false;
      value=m_values[buffer*m_bars+bar];
      return true;
     }
  };
#endif
