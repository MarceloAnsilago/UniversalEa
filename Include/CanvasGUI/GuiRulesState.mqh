#ifndef CANVAS_GUI_RULES_STATE_MQH
#define CANVAS_GUI_RULES_STATE_MQH
enum ENUM_GUI_ORDER_MODE { GUI_ORDER_MARKET,GUI_ORDER_PENDING };
enum ENUM_GUI_CANDLE_FILTER { GUI_CANDLE_DISABLED,GUI_CANDLE_BULLISH,GUI_CANDLE_BEARISH };
enum ENUM_GUI_TARGET_UNIT { GUI_TARGET_POINTS,GUI_TARGET_PERCENT };
class CGuiRulesState
  {
private:
   double m_stop[2],m_take[2];
public:
   ENUM_GUI_TARGET_UNIT target_unit;
   ENUM_GUI_ORDER_MODE order_mode;
   ENUM_GUI_CANDLE_FILTER candle_filter;
   double stop_loss,take_profit;
   CGuiRulesState() { Reset(); }
   void Reset() { order_mode=GUI_ORDER_MARKET; candle_filter=GUI_CANDLE_DISABLED; target_unit=GUI_TARGET_POINTS; stop_loss=0; take_profit=0; ArrayInitialize(m_stop,0); ArrayInitialize(m_take,0); }
   string Unit() { return target_unit==GUI_TARGET_PERCENT ? "%" : "pontos"; }
   int Choice(const int id) { return id==4 ? (int)target_unit : (id==0 ? (int)order_mode : (int)candle_filter); }
   bool Choose(const int id,const int option)
     {
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
      if(id==0) return order_mode==GUI_ORDER_MARKET ? "A mercado" : "Pendente";
      if(id==1) return candle_filter==GUI_CANDLE_DISABLED ? "Desativado" : (candle_filter==GUI_CANDLE_BULLISH ? "Candle de alta" : "Candle de baixa");
      return DoubleToString(id==2 ? stop_loss : take_profit,2);
     }
   bool Commit(const int id,string value,string &error)
     {
      error="";
      if(id!=2 && id!=3) { error="Campo inválido."; return false; }
      StringReplace(value,",",".");
      int digits=0,dots=0;
      for(int i=0;i<StringLen(value);i++)
        {
         ushort c=StringGetCharacter(value,i);
         if(c>='0' && c<='9') { digits++; continue; }
         if(c=='.' && ++dots==1) continue;
         error="Use um valor positivo em "+Unit()+" ou zero para desativar."; return false;
        }
      if(digits==0) { error="Informe o valor em "+Unit()+"."; return false; }
      int decimal=StringFind(value,".");
      if(decimal>=0 && StringLen(value)-decimal-1>2) { error="Use no máximo duas casas decimais."; return false; }
      double number=StringToDouble(value);
      if(!MathIsValidNumber(number) || number<0 || number>100000000)
        { error="Valor permitido: 0 a 100000000 "+Unit()+"."; return false; }
      if(id==2) stop_loss=number; else take_profit=number;
      return true;
     }
   bool Validate(string &error)
     {
      error="";
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
