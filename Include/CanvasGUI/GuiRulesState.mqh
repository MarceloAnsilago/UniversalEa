#ifndef CANVAS_GUI_RULES_STATE_MQH
#define CANVAS_GUI_RULES_STATE_MQH
#include "../Configuration/UniTypes.mqh"



struct GuiRulesStorage
  { int unit,order,candle; double stop[2],take[2]; };
// Armazenamento separado: preserva o formato das regras dos sets antigos.
struct GuiPendingStorage
  {
   int kind,reference,unit,bar; // kind reservado (zero), conserva o tamanho binário v4.
   double distance[2];
  };
class CGuiRulesState
  {
private:
   double m_stop[2],m_take[2],m_distance[2];
public:
   void ExportStorage(GuiRulesStorage &data)
     {
      data.unit=(int)target_unit; data.order=(int)order_mode; data.candle=(int)candle_filter;
      for(int i=0;i<2;i++) { data.stop[i]=m_stop[i]; data.take[i]=m_take[i]; }
      if(data.unit>=0 && data.unit<2) { data.stop[data.unit]=stop_loss; data.take[data.unit]=take_profit; }
     }
   bool ImportStorage(const GuiRulesStorage &data,string &error)
     {
      CGuiRulesState candidate;
      candidate.order_mode=(ENUM_GUI_ORDER_MODE)data.order; candidate.candle_filter=(ENUM_GUI_CANDLE_FILTER)data.candle;
      if(data.unit<0 || data.unit>1) { error="Unidade dos alvos inválida."; return false; }
      for(int i=0;i<2;i++)
        {
         candidate.target_unit=(ENUM_GUI_TARGET_UNIT)i; candidate.stop_loss=data.stop[i]; candidate.take_profit=data.take[i];
         if(!candidate.Validate(error)) return false;
         candidate.m_stop[i]=data.stop[i]; candidate.m_take[i]=data.take[i];
        }
      candidate.target_unit=(ENUM_GUI_TARGET_UNIT)data.unit;
      candidate.stop_loss=data.stop[data.unit]; candidate.take_profit=data.take[data.unit];
      this=candidate; return true;
     }
   // Configuração da futura entrada pendente; não envia ordens.
   // Referência: 0 máxima, 1 mínima, 2 abertura, 3 fechamento, 4 distância.
   // OHLC usa o preço exato; o valor de distância só é usado na opção 4.
   int pending_reference,pending_bar;
   ENUM_GUI_TARGET_UNIT pending_unit;
   double pending_distance;
   // Exporta as duas unidades sem converter silenciosamente os valores digitados.
   void ExportPending(GuiPendingStorage &data)
     {
      data.kind=0; data.reference=pending_reference;
      data.unit=(int)pending_unit; data.bar=pending_bar;
      for(int i=0;i<2;i++) data.distance[i]=m_distance[i];
      if(data.unit>=0 && data.unit<2) data.distance[data.unit]=pending_distance;
     }
   // Valida em uma cópia para não modificar o estado em caso de arquivo inválido.
   bool ImportPending(const GuiPendingStorage &data,string &error)
     {
      CGuiRulesState candidate; candidate=this;
      if(data.kind!=0) { error="Formato da ordem pendente inválido."; return false; }
      candidate.pending_reference=data.reference;
      candidate.pending_bar=data.bar;
      if(data.unit<0 || data.unit>1) { error="Unidade da distância inválida."; return false; }
      for(int i=0;i<2;i++)
        {
         candidate.pending_unit=(ENUM_GUI_TARGET_UNIT)i; candidate.pending_distance=data.distance[i];
         if(!candidate.Validate(error)) return false;
         candidate.m_distance[i]=data.distance[i];
        }
      candidate.pending_unit=(ENUM_GUI_TARGET_UNIT)data.unit; candidate.pending_distance=data.distance[data.unit];
      this=candidate; return true;
     }
   // Unidade exclusiva da entrada, independente dos alvos de saída.
   string PendingUnit() { return pending_unit==GUI_TARGET_PERCENT ? "%" : "pontos"; }
   ENUM_GUI_TARGET_UNIT target_unit;
   ENUM_GUI_ORDER_MODE order_mode;
   ENUM_GUI_CANDLE_FILTER candle_filter;
   double stop_loss,take_profit;
   CGuiRulesState() { Reset(); }
   // Restaura os padrões e limpa os valores guardados para cada unidade.
   void Reset()
     {
      pending_reference=3; pending_bar=1;
      pending_unit=GUI_TARGET_POINTS; pending_distance=0;
      order_mode=GUI_ORDER_MARKET; candle_filter=GUI_CANDLE_DISABLED;
      target_unit=GUI_TARGET_POINTS; stop_loss=0; take_profit=0;
      ArrayInitialize(m_distance,0); ArrayInitialize(m_stop,0); ArrayInitialize(m_take,0);
     }
   string Unit() { return target_unit==GUI_TARGET_PERCENT ? "%" : "pontos"; }
   // Retorna a opção selecionada; os IDs existentes permanecem compatíveis.
   int Choice(const int id)
     {
      if(id==6) return pending_reference;
      if(id==7) return (int)pending_unit;
      return id==4 ? (int)target_unit : (id==0 ? (int)order_mode : (int)candle_filter);
     }
   bool Choose(const int id,const int option)
     {
      if(id==6 && option>=0 && option<=4) { pending_reference=option; return true; }
      if(id==7 && option>=0 && option<=1)
        {
         if((int)pending_unit<0 || (int)pending_unit>1) return false;
         m_distance[(int)pending_unit]=pending_distance;
         pending_unit=(ENUM_GUI_TARGET_UNIT)option; pending_distance=m_distance[option]; return true;
        }
      if(id==4 && option>=0 && option<=1)
        {
         if((int)target_unit<0 || (int)target_unit>1) return false;
         m_stop[(int)target_unit]=stop_loss; m_take[(int)target_unit]=take_profit;
         target_unit=(ENUM_GUI_TARGET_UNIT)option;
         stop_loss=m_stop[option]; take_profit=m_take[option]; return true;
        }
      if(id==0 && option>=0 && option<=1) { order_mode=(ENUM_GUI_ORDER_MODE)option; return true; }
      if(id==1 && option>=0 && option<=2) { candle_filter=(ENUM_GUI_CANDLE_FILTER)option; return true; }
      return false;
     }
   string Value(const int id)
     {
      if(id==8) return DoubleToString(pending_distance,2);
      if(id==9) return IntegerToString(pending_bar);
      if(id==0) return order_mode==GUI_ORDER_MARKET ? "A mercado" : "Pendente";
      if(id==1) return candle_filter==GUI_CANDLE_DISABLED ? "Desativado" : (candle_filter==GUI_CANDLE_BULLISH ? "Candle de alta" : "Candle de baixa");
      return DoubleToString(id==2 ? stop_loss : take_profit,2);
     }
   bool Commit(const int id,string value,string &error)
     {
      error="";
      if(id!=2 && id!=3 && id!=8 && id!=9) { error="Campo inválido."; return false; }
      string unit=id==8 ? PendingUnit() : (id==9 ? "velas" : Unit());
      StringReplace(value,",",".");
      int digits=0,dots=0;
      for(int i=0;i<StringLen(value);i++)
        {
         ushort c=StringGetCharacter(value,i);
         if(c>='0' && c<='9') { digits++; continue; }
         if(c=='.' && ++dots==1) continue;
         error="Use apenas números positivos ou zero."; return false;
        }
      if(digits==0) { error="Informe o valor em "+unit+"."; return false; }
      int decimal=StringFind(value,".");
      if(id==9 && (decimal>=0 || StringToDouble(value)<1 || StringToDouble(value)>100000)) { error="Vela de referência: inteiro de 1 a 100000; 1 = última fechada."; return false; }
      if(decimal>=0 && StringLen(value)-decimal-1>2) { error="Use no máximo duas casas decimais."; return false; }
      double number=StringToDouble(value);
      if(!MathIsValidNumber(number) || number<0 || number>100000000)
        { error="Valor permitido: 0 a 100000000 "+unit+"."; return false; }
      if(id==8 && pending_unit==GUI_TARGET_PERCENT && number>100) { error="Distância percentual: 0 a 100%."; return false; }
      if(id==8) pending_distance=number;
      else if(id==9) pending_bar=(int)number;
      else if(id==2) stop_loss=number; else take_profit=number;
      return true;
     }
   bool Validate(string &error)
     {
      error="";
      if(pending_reference<0 || pending_reference>4 ||
         (int)pending_unit<0 || (int)pending_unit>1 || pending_bar<1 || pending_bar>100000 ||
         !MathIsValidNumber(pending_distance) || pending_distance<0 ||
         pending_distance>(pending_unit==GUI_TARGET_PERCENT ? 100.0 : 100000000.0))
        { error="Confira o tipo, a referência, a vela e a distância da ordem pendente."; return false; }
      if((int)target_unit<0 || (int)target_unit>1)
        { error="Selecione a unidade dos alvos."; return false; }
      if((int)order_mode<0 || (int)order_mode>1 || (int)candle_filter<0 || (int)candle_filter>2)
        { error="Selecione o tipo de ordem e o filtro de candle."; return false; }
      if(!MathIsValidNumber(stop_loss) || !MathIsValidNumber(take_profit) || stop_loss<0 || take_profit<0 || stop_loss>100000000 || take_profit>100000000)
        { error="Confira o stop loss e o take profit em "+Unit()+"."; return false; }
      return true;
     }
  };
#endif
