#ifndef GUI_MAGIC_REGISTRY_MQH
#define GUI_MAGIC_REGISTRY_MQH

// FNV-1a over UTF-16 bytes: punctuation, accents and case participate.
uint GuiMagicHash(const string name)
  {
   uint hash=2166136261;
   for(int i=0;i<StringLen(name);i++)
     {
      uint c=StringGetCharacter(name,i);
      hash=(hash^(c&255))*16777619;
      hash=(hash^(c>>8))*16777619;
     }
   return hash;
  }

long GuiMagicCandidate(const string name,const ulong entropy)
  {
   if(name=="Meu setup" || name=="") return 10000+(long)(entropy%90000);
   return 100000+(long)(GuiMagicHash(name)%2147383648);
  }

// The sorted list may contain duplicates (orders and deals share Magics).
bool GuiFindFreeMagic(const string name,const ulong entropy,long &used[],long &candidate)
  {
   int count=ArraySize(used);
   candidate=GuiMagicCandidate(name,entropy);
   bool random_name=(name=="Meu setup" || name=="");
   long minimum=random_name ? 10000 : 100000;
   long maximum=random_name ? 99999 : 2147483647;
   for(long attempt=0;attempt<=count && attempt<=maximum-minimum;attempt++)
     {
      if(count==0) return true;
      int index=ArrayBsearch(used,candidate);
      if(index<0 || used[index]!=candidate) return true;
      candidate=candidate==maximum ? minimum : candidate+1;
     }
   candidate=0;
   return false;
  }

// Exclusive file handle serializes reservations across local terminals.
// Never recycle reservations, including abandoned drafts. A missing remote
// registry or broker history cannot be inferred from a hash.
string GuiNewSetId(const long magic)
  {
   static uint sequence=0;
   string seed=TerminalInfoString(TERMINAL_DATA_PATH)+IntegerToString(ChartID())+
               IntegerToString((long)GetMicrosecondCount())+IntegerToString(TimeLocal())+IntegerToString(++sequence);
   return StringFormat("%08X%08X%08X%08X",GuiMagicHash(seed),GuiMagicHash(seed+"a"),GuiMagicHash(seed+"b"),(uint)magic);
  }

bool GuiValidSetId(const string id,const long magic)
  {
   if(magic<1 || magic>2147483647 || StringLen(id)!=32 || StringSubstr(id,24)!=StringFormat("%08X",(uint)magic)) return false;
   for(int i=0;i<32;i++)
     { ushort c=StringGetCharacter(id,i); if(!((c>='0' && c<='9') || (c>='A' && c<='F'))) return false; }
   return true;
  }

// Caller holds magic-v1.bin exclusively, including during owner file I/O.
bool GuiWriteMagicOwner(const long magic,const string id,const string root="UniEA")
  {
   int file=FileOpen(root+"\\owners\\"+IntegerToString(magic)+".txt",FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(file==INVALID_HANDLE) return false;
   ResetLastError();
   bool ok=FileWriteString(file,id)==32;
   FileFlush(file); ok=ok && GetLastError()==0; FileClose(file);
   return ok;
  }

bool GuiRestoreMagic(const long magic,const string id,string &error,const string root="UniEA")
  {
   error="";
   if(!GuiValidSetId(id,magic)) { error="Identificação do set ou Magic inválido."; return false; }
   int lock=FileOpen(root+"\\magic-v1.bin",FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(lock==INVALID_HANDLE) { error="Registro de Magic ocupado ou indisponível."; return false; }
   bool exists=false,ok=FileSize(lock)%8==0;
   ResetLastError();
   while(ok && !FileIsEnding(lock))
     { long value=FileReadLong(lock); if(value<1 || value>2147483647) ok=false; if(value==magic) exists=true; }
   ok=ok && GetLastError()==0;
   string path=root+"\\owners\\"+IntegerToString(magic)+".txt";
   bool owner_exists=FileIsExist(path,FILE_COMMON);
   if(ok && owner_exists)
     {
      int file=FileOpen(path,FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
      ok=file!=INVALID_HANDLE;
      if(ok) { ok=FileSize(file)==32 && FileReadString(file)==id; FileClose(file); }
     }
   else if(exists) ok=false; // Legacy reservation has no provable owner.
   if(!ok)
     { FileClose(lock); error="Magic já reservado por outro set ou registro inválido. O número foi preservado."; return false; }
   if(!exists)
     {
      ResetLastError();
      ok=FileSeek(lock,0,SEEK_END) && FileWriteLong(lock,magic)==8;
      FileFlush(lock); ok=ok && GetLastError()==0;
     }
   if(ok && !owner_exists) ok=GuiWriteMagicOwner(magic,id,root);
   FileClose(lock);
   if(!ok) error="Não foi possível registrar a identidade do set.";
   return ok;
  }

bool GuiReserveMagic(const string name,long &magic,string &error,string &set_id)
  {
   error="";
   if(!TerminalInfoInteger(TERMINAL_CONNECTED) || !HistorySelect(0,TimeCurrent()))
     { error="Conecte à conta para verificar o histórico do Magic Number."; return false; }
   int file=FileOpen("UniEA\\magic-v1.bin",FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(file==INVALID_HANDLE)
     { error="Registro de Magic indisponível ou ocupado. Tente novamente."; return false; }
   long used[];
   ulong size=FileSize(file);
   if(size%8!=0 || size/8>2147483647)
     { FileClose(file); error="Registro de Magic inválido. Restaure o backup."; return false; }
   int count=(int)(size/8);
   int positions=PositionsTotal(),orders=OrdersTotal();
   int history_orders=HistoryOrdersTotal(),deals=HistoryDealsTotal();
   int extra=positions+orders+history_orders+deals;
   if(ArrayResize(used,count+extra)!=count+extra)
     { FileClose(file); error="Memória insuficiente para verificar os Magics."; return false; }
   ResetLastError();
   bool ok=true;
   for(int i=0;i<count;i++)
     {
      used[i]=FileReadLong(file);
      if(used[i]<1 || used[i]>2147483647) ok=false;
     }
   ok=ok && GetLastError()==0;
   for(int i=0;i<positions;i++)
     { if(PositionGetTicket(i)==0) { ok=false; break; } used[count++]=PositionGetInteger(POSITION_MAGIC); }
   for(int i=0;i<orders;i++)
     { if(OrderGetTicket(i)==0) { ok=false; break; } used[count++]=OrderGetInteger(ORDER_MAGIC); }
   for(int i=0;i<history_orders;i++)
     { ulong ticket=HistoryOrderGetTicket(i); if(ticket==0) { ok=false; break; } used[count++]=HistoryOrderGetInteger(ticket,ORDER_MAGIC); }
   for(int i=0;i<deals;i++)
     { ulong ticket=HistoryDealGetTicket(i); if(ticket==0) { ok=false; break; } used[count++]=HistoryDealGetInteger(ticket,DEAL_MAGIC); }
   ok=ok && positions==PositionsTotal() && orders==OrdersTotal();
   if(!ok)
     { FileClose(file); error="Não foi possível verificar todos os Magics. Tente novamente."; return false; }
   ArrayResize(used,count); ArraySort(used);
   static ulong sequence=0;
   ulong entropy=GetMicrosecondCount()^GetTickCount64()^(ulong)ChartID()^(ulong)TimeLocal()^(++sequence*2654435761);
   long candidate=0;
   if(!GuiFindFreeMagic(name,entropy,used,candidate))
     { FileClose(file); error="Faixa de Magic esgotada. Use um nome personalizado."; return false; }
   ResetLastError();
   bool saved=FileSeek(file,0,SEEK_END) && FileWriteLong(file,candidate)==8;
   FileFlush(file);
   saved=saved && GetLastError()==0;
   string identity=GuiNewSetId(candidate);
   if(saved) saved=GuiWriteMagicOwner(candidate,identity);
   FileClose(file);
   if(!saved) { error="Não foi possível persistir o Magic Number."; return false; }
   magic=candidate;
   set_id=identity;
   return true;
  }
#endif
