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
   GuiPendingStorage pending;
   GuiCandleFilterConfig candle_sizes[3];
   int candle_units[3];
   GuiCandleFilterConfig candle_percent[3];
   double stop_multiplier;
   int stop_bar,stop_measure;
  };

// Layout v7/v8 preservado para sets anteriores ao stop por candle.
struct GuiSetRecordV8
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
   GuiPendingStorage pending;
   GuiCandleFilterConfig candle_sizes[3];
   int candle_units[3];
   GuiCandleFilterConfig candle_percent[3];
  };

// V6 preservado: todos os filtros eram em pontos.
struct GuiSetRecordV6
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
   GuiPendingStorage pending;
   GuiCandleFilterConfig candle_sizes[3];
  };

// Layout v4/v5 anterior aos limites de tamanho dos candles.
struct GuiSetRecordV5
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
   GuiPendingStorage pending;
  };

// Layout v3 congelado para leitura dos arquivos anteriores às ordens pendentes.
struct GuiSetRecordV3
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

// Formato binario original, preservado para migrar os sets da versao 1.
struct GuiIndicatorConfigV1
  {
   ENUM_GUI_INDICATOR_TYPE type;
   int maPeriod;
   ENUM_MA_METHOD maMethod;
   ENUM_APPLIED_PRICE maPrice;
   int maShift;
   int rsiPeriod;
   int adxPeriod;
   ENUM_APPLIED_PRICE rsiPrice;
   double rsiLower,rsiUpper;
  };
struct GuiSetRecordV1
  {
   uint signature,version;
   ushort name[49],identity[33];
   long magic;
   int market,timeframe,direction,trade_mode;
   double lot;
   int entry_start,entry_end,close_enabled,close_time;
   GuiIndicatorConfigV1 indicators[4];
   GuiRulesStorage rules;
   GuiManagementStorage management;
  };

// Formato v2: inclui ADX minimo, ainda sem quantidade de velas de inclinacao.
struct GuiIndicatorConfigV2
  {
   ENUM_GUI_INDICATOR_TYPE type;
   int maPeriod;
   ENUM_MA_METHOD maMethod;
   ENUM_APPLIED_PRICE maPrice;
   int maShift;
   int rsiPeriod;
   int adxPeriod;
   ENUM_APPLIED_PRICE rsiPrice;
   double rsiLower,rsiUpper;
   double adxMinimum;
  };
struct GuiSetRecordV2
  {
   uint signature,version;
   ushort name[49],identity[33];
   long magic;
   int market,timeframe,direction,trade_mode;
   double lot;
   int entry_start,entry_end,close_enabled,close_time;
   GuiIndicatorConfigV2 indicators[4];
   GuiRulesStorage rules;
   GuiManagementStorage management;
  };

bool GuiUpgradeSetV1(const GuiSetRecordV1 &old,GuiSetRecord &data)
  {
   if(old.signature!=0x554E4953 || old.version!=1) return false;
   ZeroMemory(data); data.signature=old.signature; data.version=9; data.stop_bar=1;
   for(int i=0;i<49;i++) data.name[i]=old.name[i];
   for(int i=0;i<33;i++) data.identity[i]=old.identity[i];
   data.magic=old.magic;
   data.market=old.market;
   data.timeframe=old.timeframe;
   data.direction=old.direction;
   data.trade_mode=old.trade_mode;
   data.lot=old.lot;
   data.entry_start=old.entry_start;
   data.entry_end=old.entry_end;
   data.close_enabled=old.close_enabled;
   data.close_time=old.close_time;
   data.rules=old.rules; data.rules.candle=0;
   data.management=old.management;
   CGuiRulesState defaults; defaults.ExportPending(data.pending);
   for(int i=0;i<4;i++)
     {
      data.indicators[i].type=old.indicators[i].type;
      data.indicators[i].maPeriod=old.indicators[i].maPeriod;
      data.indicators[i].maMethod=old.indicators[i].maMethod;
      data.indicators[i].maPrice=old.indicators[i].maPrice;
      data.indicators[i].maShift=old.indicators[i].maShift;
      data.indicators[i].rsiPeriod=old.indicators[i].rsiPeriod;
      data.indicators[i].adxPeriod=old.indicators[i].adxPeriod;
      data.indicators[i].rsiPrice=old.indicators[i].rsiPrice;
      data.indicators[i].rsiLower=old.indicators[i].rsiLower;
      data.indicators[i].rsiUpper=old.indicators[i].rsiUpper;
      data.indicators[i].maSlopeBars=3;
      data.indicators[i].adxMinimum=25.0; // Padrao para arquivos anteriores ao novo campo.
     }
   return true;
  }

bool GuiUpgradeSetV2(const GuiSetRecordV2 &old,GuiSetRecord &data)
  {
   if(old.signature!=0x554E4953 || old.version!=2) return false;
   ZeroMemory(data); data.signature=old.signature; data.version=9; data.stop_bar=1;
   for(int i=0;i<49;i++) data.name[i]=old.name[i];
   for(int i=0;i<33;i++) data.identity[i]=old.identity[i];
   data.magic=old.magic;
   data.market=old.market;
   data.timeframe=old.timeframe;
   data.direction=old.direction;
   data.trade_mode=old.trade_mode;
   data.lot=old.lot;
   data.entry_start=old.entry_start;
   data.entry_end=old.entry_end;
   data.close_enabled=old.close_enabled;
   data.close_time=old.close_time;
   data.rules=old.rules; data.rules.candle=0;
   data.management=old.management;
   CGuiRulesState defaults; defaults.ExportPending(data.pending);
   for(int i=0;i<4;i++)
     {
      data.indicators[i].type=old.indicators[i].type;
      data.indicators[i].maPeriod=old.indicators[i].maPeriod;
      data.indicators[i].maMethod=old.indicators[i].maMethod;
      data.indicators[i].maPrice=old.indicators[i].maPrice;
      data.indicators[i].maShift=old.indicators[i].maShift;
      data.indicators[i].rsiPeriod=old.indicators[i].rsiPeriod;
      data.indicators[i].adxPeriod=old.indicators[i].adxPeriod;
      data.indicators[i].rsiPrice=old.indicators[i].rsiPrice;
      data.indicators[i].rsiLower=old.indicators[i].rsiLower;
      data.indicators[i].rsiUpper=old.indicators[i].rsiUpper;
      data.indicators[i].maSlopeBars=3;
      data.indicators[i].adxMinimum=old.indicators[i].adxMinimum;
     }
   return true;
  }

// A versão intermediária 2 com tamanho de v3 também é aceita.
bool GuiUpgradeSetV3(const GuiSetRecordV3 &old,GuiSetRecord &data)
  {
   if(old.signature!=0x554E4953 || (old.version!=3 && old.version!=2)) return false;
   ZeroMemory(data); data.signature=old.signature; data.version=9; data.stop_bar=1;
   for(int i=0;i<49;i++) data.name[i]=old.name[i];
   for(int i=0;i<33;i++) data.identity[i]=old.identity[i];
   data.magic=old.magic; data.market=old.market; data.timeframe=old.timeframe;
   data.direction=old.direction; data.trade_mode=old.trade_mode; data.lot=old.lot;
   data.entry_start=old.entry_start; data.entry_end=old.entry_end;
   data.close_enabled=old.close_enabled; data.close_time=old.close_time;
   for(int i=0;i<4;i++) data.indicators[i]=old.indicators[i];
   data.rules=old.rules; data.rules.candle=0; data.management=old.management;
   CGuiRulesState defaults; defaults.ExportPending(data.pending);
   return true;
  }

bool GuiUpgradeSetV5(const GuiSetRecordV5 &old,GuiSetRecord &data)
  {
   if(old.signature!=0x554E4953 || (old.version!=4 && old.version!=5)) return false;
   ZeroMemory(data); data.signature=old.signature; data.version=9; data.stop_bar=1;
   for(int i=0;i<49;i++) data.name[i]=old.name[i];
   for(int i=0;i<33;i++) data.identity[i]=old.identity[i];
   data.magic=old.magic; data.market=old.market; data.timeframe=old.timeframe;
   data.direction=old.direction; data.trade_mode=old.trade_mode; data.lot=old.lot;
   data.entry_start=old.entry_start; data.entry_end=old.entry_end;
   data.close_enabled=old.close_enabled; data.close_time=old.close_time;
   for(int i=0;i<4;i++) data.indicators[i]=old.indicators[i];
   data.rules=old.rules; data.rules.candle=0; data.management=old.management;
   data.pending=old.pending;
   if(old.version==4)
     {
      if(data.pending.kind<0 || data.pending.kind>1 || data.pending.reference<0 || data.pending.reference>3) return false;
      data.pending.kind=0;
     }
   // ZeroMemory mantém os novos limites desativados para arquivos antigos.
   return true;
  }

bool GuiUpgradeSetV6(const GuiSetRecordV6 &old,GuiSetRecord &data)
  {
   if(old.signature!=0x554E4953 || old.version!=6) return false;
   ZeroMemory(data); data.signature=old.signature; data.version=9; data.stop_bar=1;
   for(int i=0;i<49;i++) data.name[i]=old.name[i];
   for(int i=0;i<33;i++) data.identity[i]=old.identity[i];
   data.magic=old.magic; data.market=old.market; data.timeframe=old.timeframe;
   data.direction=old.direction; data.trade_mode=old.trade_mode; data.lot=old.lot;
   data.entry_start=old.entry_start; data.entry_end=old.entry_end;
   data.close_enabled=old.close_enabled; data.close_time=old.close_time;
   for(int i=0;i<4;i++) data.indicators[i]=old.indicators[i];
   data.rules=old.rules; data.rules.candle=0; data.management=old.management;
   data.pending=old.pending;
   for(int i=0;i<3;i++)
     {
      data.candle_sizes[i]=old.candle_sizes[i];
      data.candle_percent[i].measure=old.candle_sizes[i].measure;
     }
   // Unidade zero = pontos; os limites percentuais novos começam em zero.
   return true;
  }

bool GuiUpgradeSetV8(const GuiSetRecordV8 &old,GuiSetRecord &data)
  {
   if(old.signature!=0x554E4953 || (old.version!=7 && old.version!=8)) return false;
   ZeroMemory(data); data.signature=old.signature; data.version=9; data.stop_bar=1;
   for(int i=0;i<49;i++) data.name[i]=old.name[i];
   for(int i=0;i<33;i++) data.identity[i]=old.identity[i];
   data.magic=old.magic;
   data.market=old.market;
   data.timeframe=old.timeframe;
   data.direction=old.direction;
   data.trade_mode=old.trade_mode;
   data.lot=old.lot;
   data.entry_start=old.entry_start;
   data.entry_end=old.entry_end;
   data.close_enabled=old.close_enabled;
   data.close_time=old.close_time;
   data.rules=old.rules;
   data.management=old.management;
   data.pending=old.pending;
   for(int i=0;i<4;i++) data.indicators[i]=old.indicators[i];
   for(int i=0;i<3;i++)
     {
      data.candle_sizes[i]=old.candle_sizes[i]; data.candle_units[i]=old.candle_units[i];
      data.candle_percent[i]=old.candle_percent[i];
     }
   if(old.version==7) data.rules.candle=0;
   return true;
  }

bool GuiDecodeSet(const GuiSetRecord &data,CGuiState &state,string &error)
  {
   error="Arquivo de set inválido ou de versão incompatível.";
   if(data.signature!=0x554E4953 || data.version!=9 || data.name[48]!=0 || data.identity[32]!=0) return false;
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
      !candidate.rules.ImportPending(data.pending,error) || !candidate.management.ImportStorage(data.management,error)) return false;
   for(int i=0;i<4;i++)
     {
      IndicatorConfig c=data.indicators[i];
      if(c.type<GUI_INDICATOR_NONE || c.type>GUI_INDICATOR_ADX ||
         c.maSlopeBars<2 || c.maSlopeBars>100000 || c.maPeriod<1 || c.maPeriod>100000 || c.rsiPeriod<1 || c.rsiPeriod>100000 || c.adxPeriod<1 || c.adxPeriod>100000 ||
         c.maMethod<MODE_SMA || c.maMethod>MODE_LWMA || c.maPrice<PRICE_CLOSE || c.maPrice>PRICE_WEIGHTED ||
         c.rsiPrice<PRICE_CLOSE || c.rsiPrice>PRICE_WEIGHTED || c.maShift< -100000 || c.maShift>100000 ||
         !MathIsValidNumber(c.rsiLower) || !MathIsValidNumber(c.rsiUpper) || c.rsiLower<0 || c.rsiUpper>100 || c.rsiLower>=c.rsiUpper ||
         !MathIsValidNumber(c.adxMinimum) || c.adxMinimum<0 || c.adxMinimum>100)
        { error="Parâmetros de indicador inválidos no set."; return false; }
      candidate.indicators[i]=c;
     }
   for(int i=0;i<3;i++)
     {
      candidate.rules.candle_sizes[i]=data.candle_sizes[i];
      candidate.rules.candle_units[i]=data.candle_units[i];
      candidate.rules.candle_percent[i]=data.candle_percent[i];
     }
   candidate.rules.stop_multiplier=data.stop_multiplier;
   candidate.rules.stop_bar=data.stop_bar; candidate.rules.stop_measure=data.stop_measure;
   if(!candidate.rules.Validate(error)) return false;
   candidate.setup.UseSavedIdentity();
   state=candidate; error=""; return true;
  }

bool GuiEncodeSet(CGuiState &state,GuiSetRecord &data,string &error)
  {
   if(StringLen(state.setup.name)>48) { error="Nome do set deve ter no máximo 48 caracteres."; return false; }
   if(!GuiValidSetId(state.setup.set_id,state.setup.magic)) { error="O set ainda não possui identificação válida."; return false; }
   ZeroMemory(data); data.signature=0x554E4953; data.version=9; data.stop_bar=1;
   StringToShortArray(state.setup.name,data.name,0,49); StringToShortArray(state.setup.set_id,data.identity,0,33);
   data.magic=state.setup.magic; data.market=state.setup.market; data.timeframe=(int)state.setup.timeframe;
   data.direction=state.setup.direction; data.trade_mode=state.setup.trade_mode; data.lot=state.setup.lot;
   data.entry_start=state.setup.entry_start; data.entry_end=state.setup.entry_end;
   data.close_enabled=state.setup.close_enabled ? 1 : 0; data.close_time=state.setup.close_time;
   for(int i=0;i<4;i++) data.indicators[i]=state.indicators[i];
   for(int i=0;i<3;i++)
     {
      data.candle_sizes[i]=state.rules.candle_sizes[i];
      data.candle_units[i]=state.rules.candle_units[i];
      data.candle_percent[i]=state.rules.candle_percent[i];
     }
   data.stop_multiplier=state.rules.stop_multiplier;
   data.stop_bar=state.rules.stop_bar; data.stop_measure=state.rules.stop_measure;
   state.rules.ExportPending(data.pending);
   state.rules.ExportStorage(data.rules); state.management.ExportStorage(data.management);
   CGuiState check; return GuiDecodeSet(data,check,error);
  }

bool GuiSetChecksum(const int file,uint &checksum,const int record_size=0)
  {
   int size=record_size>0 ? record_size : sizeof(GuiSetRecord);
   uchar bytes[];
   if(!FileSeek(file,0,SEEK_SET) || FileReadArray(file,bytes,0,size)!=size) return false;
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
   bool legacy=FileSize(file)==sizeof(GuiSetRecordV1)+4;
   bool legacy_v2=FileSize(file)==sizeof(GuiSetRecordV2)+4;
   bool legacy_v3=FileSize(file)==sizeof(GuiSetRecordV3)+4;
   bool legacy_v5=FileSize(file)==sizeof(GuiSetRecordV5)+4;
   bool legacy_v6=FileSize(file)==sizeof(GuiSetRecordV6)+4;
   bool legacy_v8=FileSize(file)==sizeof(GuiSetRecordV8)+4;
   int record_size=legacy ? sizeof(GuiSetRecordV1) : (legacy_v2 ? sizeof(GuiSetRecordV2) : (legacy_v3 ? sizeof(GuiSetRecordV3) : (legacy_v5 ? sizeof(GuiSetRecordV5) : (legacy_v6 ? sizeof(GuiSetRecordV6) : sizeof(GuiSetRecord)))));
   if(legacy_v8) record_size=sizeof(GuiSetRecordV8);
   bool ok=false;
   if(legacy)
     {
      GuiSetRecordV1 previous;
      ok=FileReadStruct(file,previous)==sizeof(GuiSetRecordV1) && GuiUpgradeSetV1(previous,data);
     }
   else if(legacy_v2)
     {
      GuiSetRecordV2 previous;
      ok=FileReadStruct(file,previous)==sizeof(GuiSetRecordV2) && GuiUpgradeSetV2(previous,data);
     }
   else if(legacy_v3)
     {
      GuiSetRecordV3 previous;
      ok=FileReadStruct(file,previous)==sizeof(GuiSetRecordV3) && GuiUpgradeSetV3(previous,data);
     }
   else if(legacy_v5)
     {
      GuiSetRecordV5 previous;
      ok=FileReadStruct(file,previous)==sizeof(GuiSetRecordV5) && GuiUpgradeSetV5(previous,data);
     }
   else if(legacy_v6)
     {
      GuiSetRecordV6 previous;
      ok=FileReadStruct(file,previous)==sizeof(GuiSetRecordV6) && GuiUpgradeSetV6(previous,data);
     }
   else if(legacy_v8)
     {
      GuiSetRecordV8 previous;
      ok=FileReadStruct(file,previous)==sizeof(GuiSetRecordV8) && GuiUpgradeSetV8(previous,data);
     }
   else
     {
      ok=FileSize(file)==sizeof(GuiSetRecord)+4 && FileReadStruct(file,data)==sizeof(GuiSetRecord);
     }
   uint expected=(uint)FileReadInteger(file),actual=0;
   ok=ok && GuiSetChecksum(file,actual,record_size) && actual==expected && GetLastError()==0;
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
