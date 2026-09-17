#property strict
#include "../Include/Indicators/MyIndicatorData.mqh"

// Fonte simulada: permite verificar falhas sem negociar ou depender de historico.
class BufferSource : public MyIndicator
  {
public:
   int fault,bars;
   BufferSource() { m_buffer_count=3; fault=0; bars=3; }
   virtual int RequiredValues() { return bars; }
   virtual bool Initialize(const string symbol,const ENUM_TIMEFRAMES timeframe) { return true; }
   virtual bool Update(const int buffer,const int start,const int count,double &values[])
     {
      if(fault==1 && buffer==1) return false;
      ArrayResize(values,(fault==2 ? count-1 : count));
      for(int i=0;i<ArraySize(values);i++) values[i]=buffer*10+i+1;
      if(fault==3) values[0]=EMPTY_VALUE;
      return true;
     }
  };
int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }

void OnStart()
  {
   BufferSource source;
   MyIndicatorData data,other;
   string error;
   double value;
   Check(!data.Get(0,0,value) && value==EMPTY_VALUE,"Sem leitura nao publica valor");
   Check(data.Load(GetPointer(source),error) && error=="","Le os tres buffers");
   Check(data.Get(0,0,value) && value==3,"Barra atual e o valor mais recente");
   Check(data.Get(0,2,value) && value==1,"Barra 2 e o valor mais antigo");
   Check(data.Get(1,1,value) && value==12,"Buffer +DI independente");
   Check(data.Get(2,0,value) && value==23,"Buffer -DI independente");
   Check(!data.Get(3,0,value) && !data.Get(0,3,value),"Limites de buffer e barra");
   Check(!other.Get(0,0,value),"Armazenamento independente por indicador");
   source.fault=1;
   Check(!data.Load(GetPointer(source),error) && error!="" && !data.Get(0,0,value),"Falha no segundo buffer descarta todos");
   source.fault=2;
   Check(!data.Load(GetPointer(source),error) && !data.Get(0,0,value),"Copia parcial rejeitada");
   source.fault=3;
   Check(!data.Load(GetPointer(source),error),"EMPTY_VALUE rejeitado");
   source.fault=0;
   Check(data.Load(GetPointer(source),error) && data.Get(2,2,value) && value==21,"Nova tentativa recupera a leitura");
   source.bars=6;
   Check(data.Load(GetPointer(source),error) && data.Get(0,5,value) && value==1,"Buffer dinamico comporta cinco velas fechadas");
   Check(data.Get(2,0,value) && value==26,"Stride dinamico preserva outros buffers");
   data.Clear();
   Check(!data.Get(0,0,value),"Limpeza invalida dados");
   PrintFormat("IndicatorBufferTests: %d falhas",failures);
  }
