#ifndef GUI_SET_FILE_MQH
#define GUI_SET_FILE_MQH
#include "GuiState.mqh"

// Versioned, fixed-size GUI preset. This is not an MT5 input-parameter preset.
struct GuiSetRecord
  {
   uint signature,version;
   ushort name[49],identity[33];
   long magic;
   int market,timeframe,direction,trade_mode;
   double lot;
   int entry_start,entry_end,close_enabled,close_time;
   IndicatorConfig indicators[4];
   GuiRulesStorage rules;
   GuiManagementStorage management;
  };

bool GuiDecodeSet(const GuiSetRecord &data,CGuiState &state,string &error)
  {
   error="Arquivo de set inválido ou de versão incompatível.";
   if(data.signature!=0x554E4953 || data.version!=1 || data.name[48]!=0 || data.identity[32]!=0) return false;
   string name=ShortArrayToString(data.name),id=ShortArrayToString(data.identity);
   if(!GuiValidSetId(id,data.magic) || (data.close_enabled!=0 && data.close_enabled!=1)) return false;
   CGuiState candidate; candidate.Reset();
   candidate.setup.name=name; candidate.setup.set_id=id; candidate.setup.magic=data.magic;
   candidate.setup.market=data.market; candidate.setup.timeframe=(ENUM_TIMEFRAMES)data.timeframe;
   candidate.setup.direction=data.direction; candidate.setup.trade_mode=data.trade_mode;
   candidate.setup.lot=data.lot;
   // Broker constraints are refreshed by the page, never taken from the file.
   candidate.setup.volume_min=0.00000001; candidate.setup.volume_max=100000000; candidate.setup.volume_step=0.00000001;
   candidate.setup.entry_start=data.entry_start; candidate.setup.entry_end=data.entry_end;
   candidate.setup.close_enabled=data.close_enabled==1; candidate.setup.close_time=data.close_time;
   if(!candidate.setup.Validate(error) || !candidate.rules.ImportStorage(data.rules,error) ||
      !candidate.management.ImportStorage(data.management,error)) return false;
   for(int i=0;i<4;i++)
     {
      IndicatorConfig c=data.indicators[i];
      if(c.type<GUI_INDICATOR_NONE || c.type>GUI_INDICATOR_ADX ||
         c.maPeriod<1 || c.maPeriod>100000 || c.rsiPeriod<1 || c.rsiPeriod>100000 || c.adxPeriod<1 || c.adxPeriod>100000 ||
         c.maMethod<MODE_SMA || c.maMethod>MODE_LWMA || c.maPrice<PRICE_CLOSE || c.maPrice>PRICE_WEIGHTED ||
         c.rsiPrice<PRICE_CLOSE || c.rsiPrice>PRICE_WEIGHTED || c.maShift< -100000 || c.maShift>100000 ||
         !MathIsValidNumber(c.rsiLower) || !MathIsValidNumber(c.rsiUpper) || c.rsiLower<0 || c.rsiUpper>100 || c.rsiLower>=c.rsiUpper)
        { error="Parâmetros de indicador inválidos no set."; return false; }
      candidate.indicators[i]=c;
     }
   candidate.setup.UseSavedIdentity();
   state=candidate; error=""; return true;
  }

bool GuiEncodeSet(CGuiState &state,GuiSetRecord &data,string &error)
  {
   if(StringLen(state.setup.name)>48) { error="Nome do set deve ter no máximo 48 caracteres."; return false; }
   if(!GuiValidSetId(state.setup.set_id,state.setup.magic)) { error="O set ainda não possui identificação válida."; return false; }
   ZeroMemory(data); data.signature=0x554E4953; data.version=1;
   StringToShortArray(state.setup.name,data.name,0,49); StringToShortArray(state.setup.set_id,data.identity,0,33);
   data.magic=state.setup.magic; data.market=state.setup.market; data.timeframe=(int)state.setup.timeframe;
   data.direction=state.setup.direction; data.trade_mode=state.setup.trade_mode; data.lot=state.setup.lot;
   data.entry_start=state.setup.entry_start; data.entry_end=state.setup.entry_end;
   data.close_enabled=state.setup.close_enabled ? 1 : 0; data.close_time=state.setup.close_time;
   for(int i=0;i<4;i++) data.indicators[i]=state.indicators[i];
   state.rules.ExportStorage(data.rules); state.management.ExportStorage(data.management);
   CGuiState check; return GuiDecodeSet(data,check,error);
  }

bool GuiSetChecksum(const int file,uint &checksum)
  {
   uchar bytes[];
   if(!FileSeek(file,0,SEEK_SET) || FileReadArray(file,bytes,0,sizeof(GuiSetRecord))!=sizeof(GuiSetRecord)) return false;
   checksum=2166136261;
   for(int i=0;i<ArraySize(bytes);i++) checksum=(checksum^bytes[i])*16777619;
   return true;
  }

bool GuiReadSetRecord(const string path,GuiSetRecord &data,string &error)
  {
   error="Não foi possível ler o set, ou o arquivo está corrompido.";
   int file=FileOpen(path,FILE_READ|FILE_BIN|FILE_COMMON);
   if(file==INVALID_HANDLE) return false;
   ResetLastError();
   bool ok=FileSize(file)==sizeof(GuiSetRecord)+4 && FileReadStruct(file,data)==sizeof(GuiSetRecord);
   uint expected=(uint)FileReadInteger(file),actual=0;
   ok=ok && GuiSetChecksum(file,actual) && actual==expected && GetLastError()==0;
   FileClose(file);
   if(ok) error="";
   return ok;
  }

bool GuiSaveSet(const string path,CGuiState &state,string &error,const string root="UniEA")
  {
   GuiSetRecord data;
   if(!GuiEncodeSet(state,data,error)) return false;
   int lock=FileOpen(root+"\\sets.lock",FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(lock==INVALID_HANDLE) { error="Arquivo de set ocupado. Tente novamente."; return false; }
   bool ok=true;
   if(FileIsExist(path,FILE_COMMON))
     {
      GuiSetRecord previous;
      ok=GuiReadSetRecord(path,previous,error);
      if(ok && (previous.magic!=data.magic || ShortArrayToString(previous.identity)!=state.setup.set_id))
        { ok=false; error="Esse arquivo pertence a outro set. Escolha outro nome de arquivo."; }
     }
   if(ok) ok=GuiRestoreMagic(data.magic,state.setup.set_id,error,root);
   string temporary=path+".tmp";
   if(ok)
     {
      // Remove only our scratch file under the save lock; never the old set.
      if(FileIsExist(temporary,FILE_COMMON) && !FileDelete(temporary,FILE_COMMON))
        { FileClose(lock); error="Arquivo temporário ocupado. Tente novamente."; return false; }
      int file=FileOpen(temporary,FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
      ok=file!=INVALID_HANDLE;
      if(ok)
        {
         ResetLastError();
         uint checksum=0;
         ok=FileWriteStruct(file,data)==sizeof(GuiSetRecord) && GuiSetChecksum(file,checksum) &&
            FileSeek(file,sizeof(GuiSetRecord),SEEK_SET) && FileWriteInteger(file,(int)checksum)==4;
         FileFlush(file); ok=ok && GetLastError()==0; FileClose(file);
         // Validate the temporary file before replacing the previous save.
         GuiSetRecord verify; if(ok) ok=GuiReadSetRecord(temporary,verify,error);
        }
      if(ok) ok=FileMove(temporary,FILE_COMMON,path,FILE_COMMON|FILE_REWRITE);
      if(!ok && error=="") error="Falha ao gravar o set. O arquivo anterior foi preservado.";
     }
   FileClose(lock); return ok;
  }

bool GuiLoadSet(const string path,CGuiState &state,string &error,const string root="UniEA")
  {
   GuiSetRecord data; CGuiState candidate;
   if(!GuiReadSetRecord(path,data,error) || !GuiDecodeSet(data,candidate,error)) return false;
   if(!GuiRestoreMagic(candidate.setup.magic,candidate.setup.set_id,error,root)) return false;
   state=candidate; return true;
  }
#endif
