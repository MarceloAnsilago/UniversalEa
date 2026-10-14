#ifndef UNI_SIGNALS_MQH
#define UNI_SIGNALS_MQH
#include "MyUnEA.mqh"

struct UniSignalRule
  {
   int op,usage,side,source,bar,comparison,reference,reference_bar,unit;
   double fixed_value,distance;
  };

bool UniSignalNumber(const string text)
  {
   int size=StringLen(text),digits=0,dots=0;
   if(size==0) return false;
   for(int i=0;i<size;i++)
     {
      ushort c=StringGetCharacter(text,i);
      if(c>='0' && c<='9') { digits++; continue; }
      if(c=='.' && ++dots==1) continue;
      if(i==0 && c=='-') continue;
      return false;
     }
   return digits>0 && MathIsValidNumber(StringToDouble(text));
  }

bool UniSignalCompare(const int op,const double a,const double b,const double previous_a,
                      const double previous_b,const double distance,const bool previous)
  {
   double diff=a-b,old=previous_a-previous_b;
   switch(op)
     {
      case 0: return diff>distance;
      case 1: return diff< -distance;
      case 2: return diff>=distance;
      case 3: return diff<= -distance;
      case 4: return MathAbs(diff)<=distance;
      case 5: return MathAbs(diff)>distance;
      case 6: return MathAbs(diff)<=distance || (previous && ((old< -distance && diff>distance) || (old>distance && diff< -distance)));
      case 7: case 9: return previous && old<=0 && diff>distance;
      case 8: case 10: return previous && old>=0 && diff< -distance;
     }
   return false;
  }

class CUniSignals
  {
private:
   UniSignalRule m_rules[5];
   bool m_last[4],m_previous[5];
   double m_a[5],m_b[5],m_levels[12];
   bool Constant(const int source) { return source==9 || (source>=22 && source<=33); }
   datetime m_bar[4];
   string m_symbol;
   ENUM_TIMEFRAMES m_period;
   int Scale(const int source,GuiAppliedConfiguration &config)
     {
      if(source==9) return -1;
      if(source>=22) return 1;
      if(source<10) return 0;
      return config.indicators[(source-10)/3].type==GUI_INDICATOR_MA ? 0 : 1;
     }
   bool SourceValid(const int source,GuiAppliedConfiguration &config,const int usage,const int &usages[])
     {
      if(source>=0 && source<=9) return true;
      if(source>=22 && source<=33)
        { int slot=(source-22)/3; return config.indicators[slot].type==GUI_INDICATOR_RSI && usages[slot]==usage; }
      if(source<10 || source>21) return false;
      int slot=(source-10)/3,buffer=(source-10)%3;
      return config.indicators[slot].type!=GUI_INDICATOR_NONE && usages[slot]==usage &&
             (buffer==0 || config.indicators[slot].type==GUI_INDICATOR_ADX);
     }
protected:
   virtual bool Read(MyUnEA *engine,const int source,const int bar,const double fixed_value,double &value)
     {
      if(source==9) { value=fixed_value; return true; }
      if(source>=22 && source<=33) { value=m_levels[source-22]; return true; }
      if(source>=10) return engine.GetIndicatorValue((source-10)/3,(source-10)%3,bar,value);
      MqlRates rates[];
      if(CopyRates(m_symbol,m_period,bar,1,rates)!=1) return false;
      if(source==0) value=rates[0].close;
      else if(source==1) value=rates[0].open;
      else if(source==2) value=rates[0].high;
      else if(source==3) value=rates[0].low;
      else
        {
         int day=iBarShift(m_symbol,PERIOD_D1,bar==0 ? TimeCurrent() : rates[0].time);
         if(day<0) return false;
         MqlRates daily[];
         if(CopyRates(m_symbol,PERIOD_D1,day+(source>=7 ? 1 : 0),1,daily)!=1) return false;
         if(source==4) value=daily[0].open;
         else if(source==7) value=daily[0].high;
         else if(source==8) value=daily[0].low;
         else if(bar==0) value=source==5 ? daily[0].high : daily[0].low;
         else
           {
            // Aggregate only through the selected candle; no later bars leak into closed signals.
            MqlRates intraday[];
            int count=CopyRates(m_symbol,m_period,daily[0].time,rates[0].time,intraday);
            if(count<=0) return false;
            value=source==5 ? intraday[0].high : intraday[0].low;
            for(int i=1;i<count;i++) value=source==5 ? MathMax(value,intraday[i].high) : MathMin(value,intraday[i].low);
           }
        }
      return value!=EMPTY_VALUE && MathIsValidNumber(value);
     }
public:
   CUniSignals() { Reset(); }
   bool LiveEntry(const int side)
     {
      for(int i=0;i<5;i++)
         if(m_rules[i].op!=0 && m_rules[i].usage==0 && m_rules[i].side==side &&
            ((!Constant(m_rules[i].source) && m_rules[i].bar==0) || (!Constant(m_rules[i].reference) && m_rules[i].reference_bar==0))) return true;
      return false;
     }
   void Reset()
     {
      for(int i=0;i<5;i++) { ZeroMemory(m_rules[i]); m_previous[i]=false; m_a[i]=0; m_b[i]=0; }
      for(int i=0;i<4;i++) { m_last[i]=false; m_bar[i]=0; m_levels[i*3]=70; m_levels[i*3+1]=50; m_levels[i*3+2]=30; }
     }
   bool ConfigureRsiLevels(const double &levels[],GuiAppliedConfiguration &config,string &error)
     {
      if(ArraySize(levels)!=12) { error="Quantidade de niveis RSI invalida."; return false; }
      for(int i=0;i<4;i++)
        {
         if(config.indicators[i].type!=GUI_INDICATOR_RSI) continue;
         double upper=levels[i*3],middle=levels[i*3+1],lower=levels[i*3+2];
         if(!MathIsValidNumber(upper) || !MathIsValidNumber(middle) || !MathIsValidNumber(lower) ||
            lower<0 || upper>100 || !(lower<middle && middle<upper))
           { error="RSI: use 0 <= inferior < medio < superior <= 100."; return false; }
        }
      ArrayCopy(m_levels,levels); return true;
     }
   bool Configure(const string &payload[],const int &usages[],const string symbol,const ENUM_TIMEFRAMES period,
                  GuiAppliedConfiguration &config,string &error)
     {
      Reset(); error=""; m_symbol=symbol; m_period=period;
      if(ArraySize(payload)!=5 || ArraySize(usages)!=4) { error="Quantidade de sinais invalida."; return false; }
      bool groups[4]={false,false,false,false};
      for(int i=0;i<5;i++)
        {
         if(payload[i]=="") continue;
         string parts[];
         if(StringSplit(payload[i],',',parts)!=11) { error="Formato da condicao invalido."; return false; }
         for(int j=0;j<11;j++)
           if(!UniSignalNumber(parts[j]) || ((j<8 || j==10) && StringToDouble(parts[j])!=MathFloor(StringToDouble(parts[j]))))
             { error="Valor de condicao invalido."; return false; }
         UniSignalRule r;
         r.op=(int)StringToInteger(parts[0]); r.usage=(int)StringToInteger(parts[1]); r.side=(int)StringToInteger(parts[2]);
         r.source=(int)StringToInteger(parts[3]); r.bar=(int)StringToInteger(parts[4]); r.comparison=(int)StringToInteger(parts[5]);
         r.reference=(int)StringToInteger(parts[6]); r.reference_bar=(int)StringToInteger(parts[7]);
         r.fixed_value=StringToDouble(parts[8]); r.distance=StringToDouble(parts[9]); r.unit=(int)StringToInteger(parts[10]);
         if(r.op<1 || r.op>3 || r.usage<0 || r.usage>1 || (r.side!=1 && r.side!=-1) || r.source==9 ||
            r.bar<0 || r.bar>3 || r.reference_bar<0 || r.reference_bar>3 || r.comparison<0 || r.comparison>10 ||
            r.distance<0 || r.unit<0 || r.unit>2 || (r.unit==0 && r.distance!=0) ||
            !SourceValid(r.source,config,r.usage,usages) || !SourceValid(r.reference,config,r.usage,usages) ||
            (r.comparison>=9 && ((!Constant(r.source) && r.bar==0) || (!Constant(r.reference) && r.reference_bar==0))))
           { error="Condicao ou buffer invalido; confira o GeraSet."; return false; }
         int group=r.usage*2+(r.side==1 ? 0 : 1);
         int a_scale=Scale(r.source,config),b_scale=Scale(r.reference,config);
         if((b_scale>=0 && a_scale!=b_scale) || (r.unit==1 && r.distance>0 && (a_scale==1 || b_scale==1)) ||
            (r.unit==2 && r.distance>0 && r.reference==9 && r.fixed_value==0))
           { error="Escala ou unidade da condicao incompativel."; return false; }
         if((!groups[group] && r.op!=1) || (groups[group] && r.op==1))
           { error="Use Se, seguido de E/Ou por finalidade e lado."; return false; }
         groups[group]=true; m_rules[i]=r;
        }
      return true;
     }
   // bits: 1 entry buy, 2 entry sell, 4 exit buy (close sells), 8 exit sell (close buys).
   bool Evaluate(MyUnEA *engine,const datetime bar,const double point,int &events,string &error)
     {
      events=0; error="";
      bool used[4]={false,false,false,false},live[4]={false,false,false,false};
      bool result[5]; double current_a[5],current_b[5];
      for(int i=0;i<5;i++)
        {
         UniSignalRule r=m_rules[i]; if(r.op==0) continue;
         int group=r.usage*2+(r.side==1 ? 0 : 1);
         used[group]=true;
         bool tick=(!Constant(r.source) && r.bar==0) || (!Constant(r.reference) && r.reference_bar==0);
         live[group]=live[group] || tick;
         double a,b,pa=0,pb=0;
         if(!Read(engine,r.source,r.bar,r.fixed_value,a) || !Read(engine,r.reference,r.reference_bar,r.fixed_value,b))
           { error="Aguardando dados da condicao."; return false; }
         bool previous=false;
         if(tick) { previous=m_previous[i]; pa=m_a[i]; pb=m_b[i]; }
         else if(r.comparison>=7)
           {
            previous=Read(engine,r.source,r.bar+1,r.fixed_value,pa) && Read(engine,r.reference,r.reference_bar+1,r.fixed_value,pb);
            if(!previous) { error="Aguardando candle anterior do cruzamento."; return false; }
           }
         double distance=r.unit==1 ? r.distance*point : r.unit==2 ? MathAbs(b)*r.distance/100.0 : 0;
         if((r.unit==1 && point<=0) || (r.unit==2 && r.distance>0 && b==0) || !MathIsValidNumber(distance))
           { error="Base de distancia indisponivel."; return false; }
         result[i]=UniSignalCompare(r.comparison,a,b,pa,pb,distance,previous);
         current_a[i]=a; current_b[i]=b;
        }
      for(int g=0;g<4;g++)
        {
         if(!used[g] || (!live[g] && bar==m_bar[g])) continue;
         bool total=false,clause=false;
         for(int i=0;i<5;i++)
           {
            UniSignalRule r=m_rules[i]; if(r.op==0 || r.usage*2+(r.side==1 ? 0 : 1)!=g) continue;
            if(r.op==1) clause=result[i];
            else if(r.op==2) clause=clause && result[i];
            else { total=total || clause; clause=result[i]; }
           }
         bool matched=total || clause;
         if(matched && (!live[g] || !m_last[g])) events|=1<<g;
         m_last[g]=matched; m_bar[g]=bar;
        }
      for(int i=0;i<5;i++) if(m_rules[i].op!=0)
        { m_previous[i]=true; m_a[i]=current_a[i]; m_b[i]=current_b[i]; }
      return true;
     }
  };
#endif
