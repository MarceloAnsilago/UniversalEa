#ifndef CANVAS_GUI_SETUP_STATE_MQH
#define CANVAS_GUI_SETUP_STATE_MQH

enum ENUM_GUI_SETUP_MARKET { GUI_SETUP_FOREX=0, GUI_SETUP_B3=1 };
enum ENUM_GUI_SETUP_DIRECTION { GUI_SETUP_BUY_SELL=0, GUI_SETUP_BUY_ONLY=1, GUI_SETUP_SELL_ONLY=2 };
enum ENUM_GUI_SETUP_TRADE_MODE { GUI_SETUP_DAY_TRADE=0, GUI_SETUP_SWING_TRADE=1 };

string GuiSetupTimeframeOptions()
  { return "M1|M2|M3|M4|M5|M6|M10|M12|M15|M20|M30|H1|H2|H3|H4|H6|H8|H12|D1|W1|MN1"; }

ENUM_TIMEFRAMES GuiSetupTimeframeByIndex(const int index)
  {
   ENUM_TIMEFRAMES periods[]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,
                             PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,
                             PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,
                             PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
   if(index<0 || index>=ArraySize(periods)) return PERIOD_CURRENT;
   return periods[index];
  }

int GuiSetupTimeframeIndex(const ENUM_TIMEFRAMES period)
  {
   if(period==PERIOD_CURRENT) return -1;
   for(int i=0;i<21;i++) if(GuiSetupTimeframeByIndex(i)==period) return i;
   return -1;
  }

string GuiSetupTimeLabel(const int minutes)
  {
   if(minutes<0 || minutes>=1440) return "";
   return StringFormat("%02d:%02d",minutes/60,minutes%60);
  }

string GuiSetupTimeOptions()
  {
   string options="";
   for(int minutes=0;minutes<1440;minutes+=5)
     {
      if(minutes>0) options+="|";
      options+=GuiSetupTimeLabel(minutes);
     }
   return options;
  }

bool GuiSetupParseTime(const string value,int &minutes)
  {
   if(StringLen(value)!=5 || StringGetCharacter(value,2)!=':') return false;
   for(int i=0;i<5;i++)
     {
      if(i==2) continue;
      ushort character=StringGetCharacter(value,i);
      if(character<'0' || character>'9') return false;
     }
   int hours=(int)StringToInteger(StringSubstr(value,0,2));
   int minute=(int)StringToInteger(StringSubstr(value,3,2));
   if(hours>23 || minute>59) return false;
   minutes=hours*60+minute;
   return true;
  }

class CGuiSetupState
  {
private:
   int VolumeDigits(const double value)
     {
      if(!MathIsValidNumber(value) || value<=0.0) return -1;
      double scale=1.0;
      for(int digits=0;digits<=8;digits++)
        {
         double scaled=value*scale;
         double rounded=MathRound(scaled);
         double tolerance=8.0*2.2204460492503131e-16*MathMax(1.0,MathAbs(scaled));
         if(rounded>0.0 && MathAbs(scaled-rounded)<=tolerance) return digits;
         scale*=10.0;
        }
      return -1;
     }

   bool VolumeLimitsValid()
     {
      return MathIsValidNumber(volume_min) && MathIsValidNumber(volume_max) &&
             MathIsValidNumber(volume_step) && volume_min>0.0 && volume_max>=volume_min &&
             volume_step>0.0 && VolumeDigits(volume_min)>=0 && VolumeDigits(volume_step)>=0;
     }

public:
   string name;
   long magic;
   int market;
   ENUM_TIMEFRAMES timeframe;
   int direction;
   int trade_mode;
   double lot;
   double volume_min;
   double volume_max;
   double volume_step;
   int entry_start;
   int entry_end;
   bool close_enabled;
   int close_time;

   void Reset(const ENUM_TIMEFRAMES chart_period,const double min_volume=0.01,
              const double max_volume=100.0,const double step_volume=0.01)
     {
      name="Meu setup";
      magic=1;
      market=GUI_SETUP_FOREX;
      timeframe=chart_period;
      direction=GUI_SETUP_BUY_SELL;
      trade_mode=GUI_SETUP_DAY_TRADE;
      volume_min=min_volume;
      volume_max=max_volume;
      volume_step=step_volume;
      lot=0.0;
      if(VolumeLimitsValid())
        {
         // Respect both the minimum and the symbol's absolute volume grid.
         double units=volume_min/volume_step;
         double candidate=NormalizeDouble(MathCeil(units-1.0e-8)*volume_step,LotDigits());
         string error;
         if(ValidateLot(candidate,error)) lot=candidate;
        }
      entry_start=0;
      entry_end=1435;
      close_enabled=false;
      close_time=1435;
     }

   int LotDigits()
     {
      return (int)MathMax(0,MathMax(VolumeDigits(volume_min),VolumeDigits(volume_step)));
     }

   bool ValidateLot(const double candidate,string &error)
     {
      error="";
      if(!VolumeLimitsValid())
        { error="Lote: limites de volume do ativo indisponíveis."; return false; }
      if(!MathIsValidNumber(candidate) || candidate<=0.0)
        { error="Lote: informe um volume maior que zero."; return false; }
      double tolerance=volume_step*1.0e-8;
      if(candidate<volume_min-tolerance || candidate>volume_max+tolerance)
        {
         error="Lote: use de "+DoubleToString(volume_min,LotDigits())+" a "+
               DoubleToString(volume_max,LotDigits())+".";
         return false;
        }
      double units=candidate/volume_step;
      double unit_tolerance=MathMin(1.0e-5,MathMax(1.0e-8,
                            8.0*2.2204460492503131e-16*MathAbs(units)));
      if(!MathIsValidNumber(units) || MathAbs(units-MathRound(units))>unit_tolerance)
        {
         error="Lote: use múltiplos de "+DoubleToString(volume_step,LotDigits())+".";
         return false;
        }
      return true;
     }

   // Text indexes: 0 = optional name, 1 = positive magic number, 10 = lot.
   // Also accepts 5 = entry start, 6 = entry end, 8 = closing time
   // (server HH:MM, restricted to the same five-minute selection grid).
   // Never change the stored value until the complete input is valid.
   bool CommitText(const int index,string value,string &error)
     {
      error="";
      if(index==10)
        {
         bool separator=false,has_digit=false;
         for(int i=0;i<StringLen(value);i++)
           {
            ushort character=StringGetCharacter(value,i);
            if(character>='0' && character<='9') { has_digit=true; continue; }
            if((character=='.' || character==',') && !separator) { separator=true; continue; }
            error="Lote: use números com ponto ou vírgula decimal.";
            return false;
           }
         if(!has_digit) { error="Informe o lote."; return false; }
         StringReplace(value,",",".");
         double candidate=StringToDouble(value);
         if(!ValidateLot(candidate,error)) return false;
         lot=candidate;
         return true;
        }
      if(index==0)
        {
         if(StringLen(value)>48) { error="Nome: use no máximo 48 caracteres."; return false; }
         StringTrimLeft(value);
         StringTrimRight(value);
         name=value;
         return true;
        }
      if(index==5 || index==6 || index==8)
        {
         int minutes=0;
         if(!GuiSetupParseTime(value,minutes) || minutes%5!=0)
           { error="Horário: selecione de 00:00 a 23:55, de 5 em 5 minutos."; return false; }
         if(index==5) entry_start=minutes;
         else if(index==6) entry_end=minutes;
         else close_time=minutes;
         return true;
        }
      if(index!=1) { error="Campo de configuração inválido."; return false; }
      if(StringLen(value)==0) { error="Informe o magic number."; return false; }
      long candidate=0;
      for(int i=0;i<StringLen(value);i++)
        {
         ushort character=StringGetCharacter(value,i);
         if(character<'0' || character>'9')
           { error="Magic number: use apenas números inteiros positivos."; return false; }
         int digit=(int)character-'0';
         if(candidate>(2147483647-digit)/10)
           { error="Magic number: 1 a 2147483647."; return false; }
         candidate=candidate*10+digit;
        }
      if(candidate<1) { error="Magic number: 1 a 2147483647."; return false; }
      magic=candidate;
      return true;
     }

   // Select indexes: 2 = market, 3 = timeframe option, 4 = direction.
   // 5 = entry start, 6 = entry end, 8 = closing time (option * 5 minutes).
   // 7 = closing mode: 0 = disabled, 1 = close at the selected time.
   // 9 = trade mode: 0 = day trade, 1 = swing trade.
   bool Choose(const int index,const int option)
     {
      if(index==2 && option>=GUI_SETUP_FOREX && option<=GUI_SETUP_B3)
        { market=option; return true; }
      if(index==3)
        {
         ENUM_TIMEFRAMES period=GuiSetupTimeframeByIndex(option);
         if(period==PERIOD_CURRENT) return false;
         timeframe=period;
         return true;
        }
      if(index==4 && option>=GUI_SETUP_BUY_SELL && option<=GUI_SETUP_SELL_ONLY)
        { direction=option; return true; }
      if(index==5 || index==6 || index==8)
        {
         if(option<0 || option>=288) return false;
         if(index==5) entry_start=option*5;
         else if(index==6) entry_end=option*5;
         else close_time=option*5;
         return true;
        }
      if(index==7 && option>=0 && option<=1)
        { close_enabled=(option==1); return true; }
      if(index==9 && option>=GUI_SETUP_DAY_TRADE && option<=GUI_SETUP_SWING_TRADE)
        { trade_mode=option; return true; }
      return false;
     }

   int Choice(const int index)
     {
      if(index==2) return market>=GUI_SETUP_FOREX && market<=GUI_SETUP_B3 ? market : -1;
      if(index==3) return GuiSetupTimeframeIndex(timeframe);
      if(index==4) return direction>=GUI_SETUP_BUY_SELL && direction<=GUI_SETUP_SELL_ONLY ? direction : -1;
      if(index==5 || index==6 || index==8)
        {
         int minutes=(index==5 ? entry_start : (index==6 ? entry_end : close_time));
         return minutes>=0 && minutes<1440 && minutes%5==0 ? minutes/5 : -1;
        }
      if(index==7) return close_enabled ? 1 : 0;
      if(index==9) return trade_mode>=GUI_SETUP_DAY_TRADE && trade_mode<=GUI_SETUP_SWING_TRADE ? trade_mode : -1;
      return -1;
     }

   string Value(const int index)
     {
      if(index==0) return name;
      if(index==1) return IntegerToString(magic);
      if(index==2 && Choice(index)>=0) return market==GUI_SETUP_B3 ? "B3" : "Forex";
      if(index==3 && Choice(index)>=0)
        {
         string label=EnumToString(timeframe);
         StringReplace(label,"PERIOD_","");
         return label;
        }
      if(index==4 && Choice(index)>=0)
        {
         if(direction==GUI_SETUP_BUY_ONLY) return "Somente compra";
         if(direction==GUI_SETUP_SELL_ONLY) return "Somente venda";
         return "Compra e venda";
        }
      if(index==5) return GuiSetupTimeLabel(entry_start);
      if(index==6) return GuiSetupTimeLabel(entry_end);
      if(index==7) return close_enabled ? "Encerrar no horário" : "Não encerrar";
      if(index==8) return GuiSetupTimeLabel(close_time);
      if(index==9 && Choice(index)>=0) return trade_mode==GUI_SETUP_SWING_TRADE ? "Swing trade" : "Day trade";
      if(index==10) return MathIsValidNumber(lot) && lot>0.0 ? DoubleToString(lot,LotDigits()) : "";
      return "";
     }

   bool Validate(string &error)
     {
      error="";
      if(StringLen(name)>48) { error="Nome: use no máximo 48 caracteres."; return false; }
      if(magic<1 || magic>2147483647) { error="Magic number: 1 a 2147483647."; return false; }
      if(Choice(2)<0) { error="Selecione o mercado: Forex ou B3."; return false; }
      if(Choice(3)<0) { error="Selecione um timeframe válido."; return false; }
      if(Choice(4)<0) { error="Selecione a direção permitida."; return false; }
      if(Choice(9)<0) { error="Selecione a modalidade: Day trade ou Swing trade."; return false; }
      if(!ValidateLot(lot,error)) return false;
      if(Choice(5)<0)
        { error="Início das entradas: selecione de 00:00 a 23:55, de 5 em 5 minutos."; return false; }
      if(Choice(6)<0)
        { error="Fim das entradas: selecione de 00:00 a 23:55, de 5 em 5 minutos."; return false; }
      if(Choice(8)<0)
        { error="Encerramento: selecione de 00:00 a 23:55, de 5 em 5 minutos."; return false; }
      if(entry_start==entry_end)
        { error="Início e fim das entradas devem ser diferentes."; return false; }
      // Measure both times from the entry start to support overnight windows.
      // Validate the relationship here so each field can be edited in any order.
      if(close_enabled && (close_time-entry_start+1440)%1440<(entry_end-entry_start+1440)%1440)
        { error="Encerramento deve ocorrer no fim das entradas ou depois, no mesmo ciclo diário."; return false; }
      return true;
     }
  };
#endif
