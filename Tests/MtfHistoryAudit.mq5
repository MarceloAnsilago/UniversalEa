#property strict
#property description "Coleta historica somente no Testador; nunca envia ordens."
int handles[3];
ENUM_TIMEFRAMES frames[3]={PERIOD_M15,PERIOD_M5,PERIOD_H1};
int OnInit()
  {
   if(!MQLInfoInteger(MQL_TESTER)) return INIT_FAILED;
   handles[0]=iMA(_Symbol,PERIOD_M15,20,0,MODE_EMA,PRICE_CLOSE);
   handles[1]=iRSI(_Symbol,PERIOD_M5,14,PRICE_CLOSE);
   handles[2]=iADX(_Symbol,PERIOD_H1,14);
   for(int i=0;i<3;i++) if(handles[i]==INVALID_HANDLE) return INIT_FAILED;
   return INIT_SUCCEEDED;
  }
void OnTick()
  {
   double sample[];
   for(int i=0;i<3;i++) CopyBuffer(handles[i],0,0,1,sample);
  }
void OnDeinit(const int reason)
  {
   if(!MQLInfoInteger(MQL_TESTER)) return;
   int file=FileOpen("MtfHistoryAudit.csv",FILE_WRITE|FILE_CSV|FILE_ANSI,',');
   if(file==INVALID_HANDLE) { Print("AUDIT_FILE_ERROR ",GetLastError()); return; }
   FileWrite(file,"period","time","open","high","low","close","value","di_plus","di_minus");
   int rows=0;
   for(int i=0;i<3;i++)
     {
      MqlRates rates[]; double values[],plus[],minus[];
      datetime from=D'2026.09.01',until=TimeCurrent();
      int n=CopyRates(_Symbol,frames[i],from,until,rates);
      if(n<=0 || CopyBuffer(handles[i],0,from,until,values)!=n)
        { Print("AUDIT_DATA_ERROR ",EnumToString(frames[i])," ",GetLastError()); continue; }
      if(i==2 && (CopyBuffer(handles[i],1,from,until,plus)!=n || CopyBuffer(handles[i],2,from,until,minus)!=n))
        { Print("AUDIT_ADX_ERROR ",GetLastError()); continue; }
      for(int b=0;b<n;b++)
        {
         FileWrite(file,EnumToString(frames[i]),TimeToString(rates[b].time,TIME_DATE|TIME_SECONDS),
                   DoubleToString(rates[b].open,8),DoubleToString(rates[b].high,8),DoubleToString(rates[b].low,8),DoubleToString(rates[b].close,8),
                   DoubleToString(values[b],12),i==2 ? DoubleToString(plus[b],12) : "",i==2 ? DoubleToString(minus[b],12) : "");
         rows++;
        }
      IndicatorRelease(handles[i]);
     }
   FileClose(file); PrintFormat("AUDIT_HISTORY_READY rows=%d through=%s",rows,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));
  }
