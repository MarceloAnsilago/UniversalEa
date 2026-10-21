#ifndef UNI_OPTIMIZATION_CURVES_MQH
#define UNI_OPTIMIZATION_CURVES_MQH

// Agents send compact balance samples; only the terminal writes the shared file.
// No per-tick collection and no disk writes from parallel agents.
bool UniCurveSessionValid(const string session)
  {
   if(StringLen(session)!=36) return false;
   for(int i=0;i<36;i++)
     {
      ushort ch=StringGetCharacter(session,i);
      if(i==8 || i==13 || i==18 || i==23) { if(ch!=45) return false; }
      else if(!((ch>=48 && ch<=57) || (ch>=97 && ch<=102))) return false;
     }
   return true;
  }

void UniSendBalanceCurve(const string session)
  {
   if(!MQLInfoInteger(MQL_OPTIMIZATION) || !UniCurveSessionValid(session)) return;
   if(!HistorySelect(0,TimeCurrent())) { Print("GeraSet curve: history unavailable"); return; }
   int total=HistoryDealsTotal();
   int stride=(int)MathMax(1,MathCeil((double)total/126.0));
   double data[]; ArrayResize(data,256);
   datetime first=total>0 ? (datetime)HistoryDealGetInteger(HistoryDealGetTicket(0),DEAL_TIME) : TimeCurrent();
   double balance=TesterStatistics(STAT_INITIAL_DEPOSIT);
   data[0]=(double)first; data[1]=balance;
   int used=2;
   for(int i=0;i<total;i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      // Initial deposit already appears in STAT_INITIAL_DEPOSIT.
      if((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE)!=DEAL_TYPE_BALANCE)
         balance+=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_COMMISSION)
                 +HistoryDealGetDouble(deal,DEAL_SWAP)+HistoryDealGetDouble(deal,DEAL_FEE);
      if((i+1)%stride==0 && used<254)
        { data[used++]=(double)HistoryDealGetInteger(deal,DEAL_TIME); data[used++]=balance; }
     }
   data[used++]=(double)TimeCurrent();
   data[used++]=AccountInfoDouble(ACCOUNT_BALANCE);
   ArrayResize(data,used);
   if(!FrameAdd("geraset.balance.v1",1,TesterStatistics(STAT_TRADES),data))
      Print("GeraSet curve: FrameAdd failed ",GetLastError());
  }

class CUniOptimizationCurves
  {
private:
   int handle;
public:
   CUniOptimizationCurves():handle(INVALID_HANDLE) {}
   void Open(const string session)
     {
      if(!UniCurveSessionValid(session)) return;
      FolderCreate("GeraSetCurves");
      handle=FileOpen("GeraSetCurves\\"+session+".jsonl",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ,0,CP_UTF8);
      if(handle==INVALID_HANDLE) Print("GeraSet curve: file unavailable ",GetLastError());
     }
   void Drain()
     {
      ulong pass; string name; long id; double trades; double data[];
      while(FrameNext(pass,name,id,trades,data))
        {
         if(handle==INVALID_HANDLE || name!="geraset.balance.v1" || id!=1) continue;
         int size=ArraySize(data);
         if(size<4 || size>256 || size%2!=0) continue;
         string line="{\"pass\":\""+IntegerToString((long)pass)+"\",\"trades\":"+DoubleToString(trades,0)+",\"points\":[";
         for(int i=0;i<size;i+=2)
           {
            if(i>0) line+=",";
            line+="["+DoubleToString(data[i],0)+","+DoubleToString(data[i+1],8)+"]";
           }
         line+="]}";
         FileWriteString(handle,line+"\n");
        }
      if(handle!=INVALID_HANDLE) FileFlush(handle);
     }
   void Close()
     {
      Drain();
      if(handle!=INVALID_HANDLE) { FileClose(handle); handle=INVALID_HANDLE; }
     }
  };
#endif
