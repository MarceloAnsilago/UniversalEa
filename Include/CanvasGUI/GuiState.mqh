#ifndef CANVAS_GUI_STATE_MQH
#define CANVAS_GUI_STATE_MQH
#include "GuiSetupState.mqh"
#include "GuiRulesState.mqh"
#include "GuiManagementState.mqh"
enum ENUM_GUI_INDICATOR_TYPE { GUI_INDICATOR_NONE=-1, GUI_INDICATOR_MA, GUI_INDICATOR_RSI };
enum ENUM_GUI_FIELD { GUI_TYPE, GUI_PERIOD, GUI_METHOD, GUI_PRICE, GUI_SHIFT, GUI_LOWER, GUI_UPPER };
struct IndicatorConfig
  {
   ENUM_GUI_INDICATOR_TYPE type;
   int maPeriod;
   ENUM_MA_METHOD maMethod;
   ENUM_APPLIED_PRICE maPrice;
   int maShift;
   int rsiPeriod;
   ENUM_APPLIED_PRICE rsiPrice;
   double rsiLower,rsiUpper;
  };
struct GuiAppliedConfiguration
  {
   CGuiSetupState setup;
   CGuiRulesState rules;
   CGuiManagementState management;
   IndicatorConfig indicators[4];
  };
string GuiMethodName(const int index)
  { string names[]={"SMA","EMA","SMMA","LWMA"}; return index>=0 && index<4 ? names[index] : ""; }
string GuiPriceName(const int index)
  { string names[]={"Close","Open","High","Low","Median","Typical","Weighted"}; return index>=0 && index<7 ? names[index] : ""; }
class CGuiState
  {
public:
   CGuiSetupState setup;
   CGuiRulesState rules;
   CGuiManagementState management;
   IndicatorConfig indicators[4];
   IndicatorConfig applied[4];
   GuiAppliedConfiguration applications[];
   bool has_applied;
   bool Apply()
     {
      string error; if(!rules.Validate(error) || !management.Validate(error)) return false;
      int count=ArraySize(applications);
      if(ArrayResize(applications,count+1,32)!=count+1) return false;
      applications[count].setup=setup;
      applications[count].rules=rules;
      applications[count].management=management;
      for(int i=0;i<4;i++)
        { applications[count].indicators[i]=indicators[i]; applied[i]=indicators[i]; }
      has_applied=true;
      return true;
     }
   void Reset()
     {
      has_applied=false;
      setup.Reset(PERIOD_M1); rules.Reset(); management.Reset();
      ArrayFree(applications);
      for(int i=0;i<4;i++)
        {
         indicators[i].type=GUI_INDICATOR_NONE;
         indicators[i].maPeriod=20; indicators[i].maMethod=MODE_EMA;
         indicators[i].maPrice=PRICE_CLOSE; indicators[i].maShift=0;
         indicators[i].rsiPeriod=14; indicators[i].rsiPrice=PRICE_CLOSE;
         indicators[i].rsiLower=30; indicators[i].rsiUpper=70;
        }
     }
   int Choice(const int card,const ENUM_GUI_FIELD field)
     {
      IndicatorConfig c=indicators[card];
      if(field==GUI_TYPE) return (int)c.type+1;
      if(field==GUI_METHOD) return (int)c.maMethod;
      return (int)(c.type==GUI_INDICATOR_MA ? c.maPrice : c.rsiPrice)-1;
     }
   void Choose(const int card,const ENUM_GUI_FIELD field,const int index)
     {
      if(field==GUI_TYPE) indicators[card].type=(ENUM_GUI_INDICATOR_TYPE)(index-1);
      else if(field==GUI_METHOD) indicators[card].maMethod=(ENUM_MA_METHOD)index;
      else if(indicators[card].type==GUI_INDICATOR_MA) indicators[card].maPrice=(ENUM_APPLIED_PRICE)(index+1);
      else indicators[card].rsiPrice=(ENUM_APPLIED_PRICE)(index+1);
     }
   string Value(const int card,const ENUM_GUI_FIELD field)
     {
      IndicatorConfig c=indicators[card];
      if(field==GUI_PERIOD) return IntegerToString(c.type==GUI_INDICATOR_MA ? c.maPeriod : c.rsiPeriod);
      if(field==GUI_SHIFT) return IntegerToString(c.maShift);
      return DoubleToString(field==GUI_LOWER ? c.rsiLower : c.rsiUpper,2);
     }
   // Validate before mutation: invalid edits never enter the definitive state.
   bool Commit(const int card,const ENUM_GUI_FIELD field,string value,string &error)
     {
      StringReplace(value,",",".");
      int digits=0,dots=0;
      bool integer=(field==GUI_PERIOD || field==GUI_SHIFT);
      for(int i=0;i<StringLen(value);i++)
        {
         ushort c=StringGetCharacter(value,i);
         if(c>='0' && c<='9') { digits++; continue; }
         if(c=='-' && i==0 && field==GUI_SHIFT) continue;
         if(c=='.' && !integer && ++dots==1) continue;
         error="Valor numérico inválido."; return false;
        }
      if(digits==0) { error="Informe um valor."; return false; }
      int decimal=StringFind(value,".");
      if(decimal>=0 && StringLen(value)-decimal-1>2) { error="Use no máximo duas casas decimais."; return false; }
      double v=StringToDouble(value);
      if(field==GUI_PERIOD && (v<1 || v>100000)) { error="Período: 1 a 100000."; return false; }
      if(field==GUI_SHIFT && (v< -100000 || v>100000)) { error="Shift: -100000 a 100000."; return false; }
      if(field==GUI_LOWER || field==GUI_UPPER)
        {
         if(v<0 || v>100) { error="Nível: 0 a 100."; return false; }
         if((field==GUI_LOWER && v>=indicators[card].rsiUpper) || (field==GUI_UPPER && v<=indicators[card].rsiLower))
           { error="Inferior deve ser menor que superior."; return false; }
        }
      if(field==GUI_PERIOD)
        {
         if(indicators[card].type==GUI_INDICATOR_MA) indicators[card].maPeriod=(int)v;
         else indicators[card].rsiPeriod=(int)v;
        }
      else if(field==GUI_SHIFT) indicators[card].maShift=(int)v;
      else if(field==GUI_LOWER) indicators[card].rsiLower=v;
      else if(field==GUI_UPPER) indicators[card].rsiUpper=v;
      return true;
     }
   void PrintConfiguration()
     {
      Print("===================================="); Print("CONFIGURAÇÃO"); Print("====================================");
      Print("Setup: ",setup.name," | Magic: ",setup.magic);
      Print("Mercado: ",setup.Value(2)," | Timeframe: ",setup.Value(3)," | Direção: ",setup.Value(4));
      Print("Modalidade: ",setup.Value(9)," | Lote: ",setup.Value(10));
      Print("Entradas: ",setup.Value(5)," a ",setup.Value(6)," | Encerramento: ",setup.close_enabled ? setup.Value(8) : "Não encerrar"," | Horário do servidor");
      Print("Breakeven: ",management.Summary(0));
      Print("Trailing stop: ",management.Summary(1));
      Print("Stop móvel: ",management.Summary(2));
      Print("Ordem: ",rules.Value(0)," | Filtro de candle: ",rules.Value(1));
      Print("Stop loss: ",rules.Value(2)," ",rules.Unit()," | Take profit: ",rules.Value(3)," ",rules.Unit()," | 0 = desativado");
      for(int i=0;i<4;i++)
        {
         IndicatorConfig c=indicators[i];
         if(c.type==GUI_INDICATOR_NONE) continue;
         PrintFormat("Indicador %d: %s",i+1,c.type==GUI_INDICATOR_MA ? "Média Móvel" : "RSI");
         Print("Período: ",c.type==GUI_INDICATOR_MA ? c.maPeriod : c.rsiPeriod);
         if(c.type==GUI_INDICATOR_MA) Print("Método: ",GuiMethodName((int)c.maMethod));
         Print("Preço: ",GuiPriceName((int)(c.type==GUI_INDICATOR_MA ? c.maPrice : c.rsiPrice)-1));
         if(c.type==GUI_INDICATOR_MA) Print("Shift: ",c.maShift);
         else { Print("Inferior: ",DoubleToString(c.rsiLower,2)); Print("Superior: ",DoubleToString(c.rsiUpper,2)); }
        }
      Print("====================================");
     }
  };
#endif
