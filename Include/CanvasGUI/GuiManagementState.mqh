#ifndef CANVAS_GUI_MANAGEMENT_STATE_MQH
#define CANVAS_GUI_MANAGEMENT_STATE_MQH
// Mode: 0 disabled, 1 points, 2 percent. Values are configuration only.
class CGuiManagementState
  {
private:
   double m_bank[2][8];
   int m_unit[3];
public:
   int mode[3];
   double values[8]; // BE trigger, BE offset, trailing trigger, distance, step.
   CGuiManagementState() { Reset(); }
   void Reset()
     { ArrayInitialize(mode,0); ArrayInitialize(values,0); ArrayInitialize(m_bank,0); ArrayInitialize(m_unit,0); }
   int Owner(const int id) { return id<4 ? 0 : (id<7 ? 1 : 2); }
   string Unit(const int card) { return m_unit[card]==1 ? "%" : "pontos"; }
   int Choice(const int id) { return id>=0 && id<3 ? mode[id] : -1; }
   bool Enabled(const int id) { return id>=2 && id<=9 && mode[Owner(id)]!=0; }
   bool Choose(const int id,const int option)
     {
      if(id<0 || id>2 || option<0 || option>2) return false;
      if(option>0)
        {
         for(int i=0;i<8;i++) if(Owner(i+2)==id)
           { m_bank[m_unit[id]][i]=values[i]; values[i]=m_bank[option-1][i]; }
         m_unit[id]=option-1;
        }
      mode[id]=option; return true;
     }
   string Value(const int id) { return id>=2 && id<=9 ? DoubleToString(values[id-2],2) : ""; }
   bool Commit(const int id,string text,string &error)
     {
      error="";
      if(id<2 || id>9) { error="Campo inválido."; return false; }
      StringReplace(text,",","."); int digits=0,dots=0;
      for(int i=0;i<StringLen(text);i++)
        {
         ushort c=StringGetCharacter(text,i);
         if(c>='0' && c<='9') { digits++; continue; }
         if(c=='.' && ++dots==1) continue;
         error="Informe um número positivo ou zero."; return false;
        }
      if(digits==0) { error="Informe um valor."; return false; }
      int decimal=StringFind(text,".");
      if(decimal>=0 && StringLen(text)-decimal-1>2) { error="Use no máximo duas casas decimais."; return false; }
      double number=StringToDouble(text);
      if(!MathIsValidNumber(number) || number<0 || number>100000000)
        { error="Valor permitido: 0 a 100000000."; return false; }
      values[id-2]=number; return true;
     }
   bool Validate(string &error)
     {
      error="";
      for(int i=0;i<3;i++) if(mode[i]<0 || mode[i]>2)
        { error="Selecione o modo de stop móvel."; return false; }
      for(int i=0;i<8;i++) if(!MathIsValidNumber(values[i]) || values[i]<0 || values[i]>100000000)
        { error="Confira os valores do stop móvel."; return false; }
      if(mode[0]!=0 && (values[0]<=0 || values[1]>=values[0]))
        { error="Breakeven: ativação > 0 e proteção menor que a ativação."; return false; }
      if(mode[1]!=0 && (values[2]<=0 || values[3]<=0 || values[4]<=0))
        { error="Trailing stop: ativação, distância e passo devem ser > 0."; return false; }
      if(mode[2]!=0 && (values[5]<=0 || values[6]<=0 || values[7]<=0))
        { error="Stop móvel: ativação, distância e passo devem ser > 0."; return false; }
      return true;
     }
   string Summary(const int card)
     {
      if(mode[card]==0) return "Desativado";
      if(card==0) return "Ativação: "+Value(2)+" · Proteção: "+Value(3)+" "+Unit(card);
      int first=card==1 ? 4 : 7;
      return "Ativação: "+Value(first)+" · Distância: "+Value(first+1)+" · Passo: "+Value(first+2)+" "+Unit(card);
     }
  };
#endif
