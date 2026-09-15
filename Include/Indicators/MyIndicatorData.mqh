#ifndef UNI_MY_INDICATOR_DATA_MQH
#define UNI_MY_INDICATOR_DATA_MQH
#include "MyIndicator.mqh"

// Guarda tres valores por buffer, sem limitar a quantidade de linhas do indicador.
// A barra 0 e a atual; 1 e a ultima fechada; 2 e a fechada anterior.
class MyIndicatorData
  {
private:
   double m_values[]; // Indice interno: buffer * 3 + barra.
   int m_buffers;
public:
   // Inicia sem dados publicados.
   MyIndicatorData() { m_buffers=0; }
   // Invalida a leitura anterior para nunca usar valores antigos apos falha.
   void Clear() { ArrayFree(m_values); m_buffers=0; }
   // Le todas as linhas e publica apenas quando cada uma tem tres valores validos.
   bool Load(MyIndicator *indicator,string &error)
     {
      Clear(); error="";
      if(indicator==NULL) { error="Indicador não configurado."; return false; }
      int buffers=indicator.BufferCount();
      if(buffers<1) { error="Indicador sem buffers disponíveis."; return false; }
      double candidate[];
      if(ArrayResize(candidate,buffers*3)!=buffers*3)
        { error="Sem memória para os buffers."; return false; }
      for(int buffer=0;buffer<buffers;buffer++)
        {
         double values[];
         ResetLastError();
         if(!indicator.Update(buffer,0,3,values) || ArraySize(values)!=3)
           {
            error=StringFormat("Buffer %d ainda não está pronto. Erro do terminal: %d.",buffer,GetLastError());
            return false;
           }
         // Update entrega ordem cronologica. Padronizar antes de inverter.
         ArraySetAsSeries(values,false);
         for(int bar=0;bar<3;bar++)
           {
            double value=values[2-bar];
            if(value==EMPTY_VALUE || !MathIsValidNumber(value))
              { error=StringFormat("Buffer %d, barra %d: valor indisponível.",buffer,bar); return false; }
            candidate[buffer*3+bar]=value;
           }
        }
      if(ArrayCopy(m_values,candidate)!=buffers*3)
        { Clear(); error="Falha ao guardar os buffers."; return false; }
      m_buffers=buffers;
      return true;
     }
   // Consulta um valor validado; false indica indice invalido ou leitura ausente.
   bool Get(const int buffer,const int bar,double &value)
     {
      value=EMPTY_VALUE;
      if(buffer<0 || buffer>=m_buffers || bar<0 || bar>=3) return false;
      value=m_values[buffer*3+bar];
      return true;
     }
  };
#endif
