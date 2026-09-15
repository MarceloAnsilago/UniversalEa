#ifndef UNI_MY_INDICATOR_VALUES_MQH
#define UNI_MY_INDICATOR_VALUES_MQH

// Consulta comum dos buffers para as regras de qualquer indicador.
// Barra 0 = atual; 1 = ultima fechada; 2 = fechada anterior.
class MyIndicatorValues
  {
public:
   virtual ~MyIndicatorValues() {}
   // Retorna false quando o valor solicitado nao estiver disponivel.
   virtual bool Get(const int buffer,const int bar,double &value)=0;
  };
#endif
