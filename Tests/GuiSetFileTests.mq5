#property strict
#include "../Include/CanvasGUI/GuiSetFile.mqh"
int checks=0,failures=0;
void Check(const bool ok,const string label)
  { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   // Isolated common-folder namespace; never touches real reservations or sets.
   string root="UniEA-Tests\\"+IntegerToString((long)GetMicrosecondCount())+"-"+IntegerToString(ChartID());
   string path=root+"\\joao.set",error;
   CGuiState original,loaded; original.Reset(); loaded.Reset();
   original.setup.name="joao"; original.setup.magic=1234567;
   original.setup.set_id=GuiNewSetId(original.setup.magic);
   original.setup.timeframe=PERIOD_H4; original.setup.lot=0.25;
   original.setup.entry_start=540; original.setup.entry_end=1020;
   original.setup.close_enabled=true; original.setup.close_time=1050;
   original.indicators[0].type=GUI_INDICATOR_ADX; original.indicators[0].adxPeriod=27; original.indicators[0].adxMinimum=22.5; original.indicators[1].maSlopeBars=7;
   original.indicators[3].type=GUI_INDICATOR_RSI; original.indicators[3].rsiLower=22.5;
   original.rules.Choose(0,1); original.rules.Choose(6,0); original.rules.Choose(1,2);
   original.rules.Commit(8,"150",error); original.rules.Choose(7,1);
   original.rules.Commit(8,"0.25",error); original.rules.Commit(9,"3",error);
   original.rules.candle_sizes[0].minimum=12.5;
   original.rules.candle_sizes[1].measure=1; original.rules.candle_sizes[1].upper_maximum=30;
   original.rules.candle_sizes[2].lower_minimum=3; original.rules.candle_sizes[2].lower_maximum=8;
   original.rules.candle_units[1]=1;
   original.rules.candle_percent[1].measure=1; original.rules.candle_percent[1].upper_maximum=25;
   original.rules.take_multiplier=3.5;
   original.rules.stop_multiplier=1.75; original.rules.stop_bar=3; original.rules.stop_measure=1;
   original.rules.stop_loss=123; original.rules.take_profit=456;
   original.rules.Choose(4,1); original.rules.stop_loss=1.5; original.rules.take_profit=2.5;
   original.management.Choose(0,1); original.management.values[0]=100; original.management.values[1]=20;
   original.management.Choose(0,2); original.management.values[0]=2; original.management.values[1]=0.5;
   Check(GuiSaveSet(path,original,error,root),"Salvar joao: "+error);
   Check(GuiLoadSet(path,loaded,error,root),"Carregar joao: "+error);
   Check(loaded.setup.name=="joao" && loaded.setup.magic==1234567 && loaded.setup.set_id==original.setup.set_id,"Restaurar identidade e Magic exatos");
   Check(loaded.setup.lot==0.25 && loaded.setup.timeframe==PERIOD_H4 && loaded.setup.entry_start==540 && loaded.setup.close_time==1050,"Restaurar setup");
   Check(loaded.indicators[0].adxPeriod==27 && loaded.indicators[1].maSlopeBars==7 && loaded.indicators[0].adxMinimum==22.5 && loaded.indicators[3].rsiLower==22.5,"Restaurar quatro indicadores e limiar ADX");
   Check(loaded.rules.stop_loss==1.5 && loaded.management.values[0]==2 && loaded.management.Unit(0)=="%","Restaurar regras e gestão em percentual");
   Check(loaded.rules.pending_reference==0 && loaded.rules.pending_bar==3 &&
         loaded.rules.pending_unit==GUI_TARGET_PERCENT && loaded.rules.pending_distance==0.25,"Restaurar configuração pendente");
   Check(loaded.rules.candle_sizes[0].minimum==12.5 && loaded.rules.candle_sizes[1].measure==1 &&
         loaded.rules.candle_sizes[1].upper_maximum==30 && loaded.rules.candle_sizes[2].lower_minimum==3 &&
         loaded.rules.candle_sizes[2].lower_maximum==8,"Restaurar filtros independentes dos três candles");
   Check(loaded.rules.candle_units[1]==1 && loaded.rules.candle_percent[1].upper_maximum==25 &&
         loaded.rules.candle_sizes[1].upper_maximum==30,"Restaurar unidade e bancos independentes do filtro");
   Check(loaded.rules.candle_filter==GUI_CANDLE_WICKS,"Restaurar condição Pavios");
   loaded.rules.Choose(7,0);
   Check(loaded.rules.pending_distance==150,"Restaurar distância independente em pontos");
   loaded.rules.Choose(4,0); loaded.management.Choose(0,1);
   Check(loaded.rules.stop_loss==123 && loaded.rules.take_profit==456 && loaded.management.values[0]==100 && loaded.management.values[1]==20,"Preservar bancos de valores em pontos");
   Check(loaded.setup.CommitText(0,"joao",error) && loaded.setup.magic==1234567,"Confirmar mesmo nome não gera Magic");
   Check(GuiLoadSet(path,loaded,error,root) && GuiLoadSet(path,loaded,error,root) && loaded.setup.magic==1234567,"Recarregar o próprio set não é colisão");
   Check(GuiSaveSet(path,loaded,error,root),"Salvar novamente mantém proprietário");
   string stranger=GuiNewSetId(1234567);
   Check(stranger!=original.setup.set_id && !GuiRestoreMagic(1234567,stranger,error,root),"Outro set não assume o Magic de joao");
   Check(GuiRestoreMagic(1234567,original.setup.set_id,error,root),"Colisão não altera proprietário original");
   CGuiState other; other.Reset(); other.setup.name="outro"; other.setup.magic=7654321; other.setup.set_id=GuiNewSetId(7654321);
   Check(!GuiSaveSet(path,other,error,root),"Outro set não sobrescreve arquivo de joao");
   Check(GuiLoadSet(path,loaded,error,root) && loaded.setup.magic==1234567,"Arquivo original preservado");
   GuiSetRecord data; Check(GuiEncodeSet(original,data,error),"Codificar set");
   data.magic=7654321;
   Check(!GuiDecodeSet(data,loaded,error) && loaded.setup.magic==1234567,"Magic alterado rejeitado sem mutação");
   GuiEncodeSet(original,data,error); data.version=999;
   Check(!GuiDecodeSet(data,loaded,error),"Versão desconhecida rejeitada");
   GuiEncodeSet(original,data,error); data.indicators[0].adxPeriod=0;
   Check(!GuiDecodeSet(data,loaded,error),"Indicador inválido rejeitado");
   GuiEncodeSet(original,data,error); data.management.unit[0]=7;
   Check(!GuiDecodeSet(data,loaded,error),"Banco de gestão inválido rejeitado");
   string corrupt=root+"\\corrupt.set";
   int file=FileOpen(corrupt,FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(file!=INVALID_HANDLE) { FileWriteInteger(file,42); FileClose(file); }
   Check(!GuiLoadSet(corrupt,loaded,error,root) && loaded.setup.magic==1234567,"Arquivo truncado não altera estado");
   FileCopy(path,FILE_COMMON,corrupt,FILE_COMMON|FILE_REWRITE);
   file=FileOpen(corrupt,FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(file!=INVALID_HANDLE) { FileSeek(file,20,SEEK_SET); FileWriteInteger(file,42); FileClose(file); }
   Check(!GuiLoadSet(corrupt,loaded,error,root) && loaded.setup.magic==1234567,"Checksum rejeita arquivo alterado");
   Check(!GuiLoadSet(root+"\\missing.set",loaded,error,root) && loaded.setup.magic==1234567,"Arquivo inexistente não altera estado");
   file=FileOpen(root+"\\magic-v1.bin",FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   Check(file!=INVALID_HANDLE && !GuiLoadSet(path,loaded,error,root),"Registro ocupado impede carregar sem substituir Magic");
   if(file!=INVALID_HANDLE) FileClose(file);
   Check(GuiLoadSet(path,loaded,error,root),"Carregar após liberar registro");
   // Migracao do formato antigo: campos existentes permanecem, limiar recebe 25.
   GuiSetRecord current_record,migrated;
   GuiEncodeSet(original,current_record,error);
   GuiSetRecordV1 legacy;
   ZeroMemory(legacy); legacy.signature=current_record.signature; legacy.version=1;
   for(int i=0;i<49;i++) legacy.name[i]=current_record.name[i];
   for(int i=0;i<33;i++) legacy.identity[i]=current_record.identity[i];
   legacy.magic=current_record.magic;
   legacy.market=current_record.market;
   legacy.timeframe=current_record.timeframe;
   legacy.direction=current_record.direction;
   legacy.trade_mode=current_record.trade_mode;
   legacy.lot=current_record.lot;
   legacy.entry_start=current_record.entry_start;
   legacy.entry_end=current_record.entry_end;
   legacy.close_enabled=current_record.close_enabled;
   legacy.close_time=current_record.close_time;
   legacy.rules=current_record.rules;
   legacy.management=current_record.management;
   for(int i=0;i<4;i++)
     {
      legacy.indicators[i].type=current_record.indicators[i].type;
      legacy.indicators[i].maPeriod=current_record.indicators[i].maPeriod;
      legacy.indicators[i].maMethod=current_record.indicators[i].maMethod;
      legacy.indicators[i].maPrice=current_record.indicators[i].maPrice;
      legacy.indicators[i].maShift=current_record.indicators[i].maShift;
      legacy.indicators[i].rsiPeriod=current_record.indicators[i].rsiPeriod;
      legacy.indicators[i].adxPeriod=current_record.indicators[i].adxPeriod;
      legacy.indicators[i].rsiPrice=current_record.indicators[i].rsiPrice;
      legacy.indicators[i].rsiLower=current_record.indicators[i].rsiLower;
      legacy.indicators[i].rsiUpper=current_record.indicators[i].rsiUpper;
     }
   CGuiState migrated_state;
   Check(GuiUpgradeSetV1(legacy,migrated) && GuiDecodeSet(migrated,migrated_state,error) &&
         migrated_state.indicators[0].maSlopeBars==3 && migrated_state.indicators[0].adxMinimum==25 && migrated_state.indicators[0].adxPeriod==27 &&
         migrated_state.setup.magic==original.setup.magic,"Migrar v1 preservando configuracao");
   // Exercer tambem leitura binaria e checksum do formato v1.
   string legacy_path=root+"\\legacy.set";
   int legacy_file=FileOpen(legacy_path,FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   bool legacy_ok=false;
   if(legacy_file!=INVALID_HANDLE)
     {
      uint checksum=0;
      legacy_ok=FileWriteStruct(legacy_file,legacy)==sizeof(GuiSetRecordV1) &&
                GuiSetChecksum(legacy_file,checksum,sizeof(GuiSetRecordV1)) &&
                FileSeek(legacy_file,sizeof(GuiSetRecordV1),SEEK_SET) &&
                FileWriteInteger(legacy_file,(int)checksum)==4;
      FileClose(legacy_file);
     }
   Check(legacy_ok && GuiReadSetRecord(legacy_path,migrated,error) &&
         migrated.version==10 && migrated.indicators[0].adxMinimum==25,"Ler arquivo v1 com checksum");
   FileDelete(legacy_path,FILE_COMMON);
   // O formato v2 preserva o limiar ADX e recebe tres velas de inclinacao.
   GuiSetRecordV2 legacy_v2;
   ZeroMemory(legacy_v2); legacy_v2.signature=current_record.signature; legacy_v2.version=2;
   for(int i=0;i<49;i++) legacy_v2.name[i]=current_record.name[i];
   for(int i=0;i<33;i++) legacy_v2.identity[i]=current_record.identity[i];
   legacy_v2.magic=current_record.magic;
   legacy_v2.market=current_record.market;
   legacy_v2.timeframe=current_record.timeframe;
   legacy_v2.direction=current_record.direction;
   legacy_v2.trade_mode=current_record.trade_mode;
   legacy_v2.lot=current_record.lot;
   legacy_v2.entry_start=current_record.entry_start;
   legacy_v2.entry_end=current_record.entry_end;
   legacy_v2.close_enabled=current_record.close_enabled;
   legacy_v2.close_time=current_record.close_time;
   legacy_v2.rules=current_record.rules;
   legacy_v2.management=current_record.management;
   for(int i=0;i<4;i++)
     {
      legacy_v2.indicators[i].type=current_record.indicators[i].type;
      legacy_v2.indicators[i].maPeriod=current_record.indicators[i].maPeriod;
      legacy_v2.indicators[i].maMethod=current_record.indicators[i].maMethod;
      legacy_v2.indicators[i].maPrice=current_record.indicators[i].maPrice;
      legacy_v2.indicators[i].maShift=current_record.indicators[i].maShift;
      legacy_v2.indicators[i].rsiPeriod=current_record.indicators[i].rsiPeriod;
      legacy_v2.indicators[i].adxPeriod=current_record.indicators[i].adxPeriod;
      legacy_v2.indicators[i].rsiPrice=current_record.indicators[i].rsiPrice;
      legacy_v2.indicators[i].rsiLower=current_record.indicators[i].rsiLower;
      legacy_v2.indicators[i].rsiUpper=current_record.indicators[i].rsiUpper;
      legacy_v2.indicators[i].adxMinimum=current_record.indicators[i].adxMinimum;
     }
   legacy_file=FileOpen(legacy_path,FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   legacy_ok=false;
   if(legacy_file!=INVALID_HANDLE)
     {
      uint checksum=0;
      legacy_ok=FileWriteStruct(legacy_file,legacy_v2)==sizeof(GuiSetRecordV2) &&
                GuiSetChecksum(legacy_file,checksum,sizeof(GuiSetRecordV2)) &&
                FileSeek(legacy_file,sizeof(GuiSetRecordV2),SEEK_SET) &&
                FileWriteInteger(legacy_file,(int)checksum)==4;
      FileClose(legacy_file);
     }
   Check(legacy_ok && GuiReadSetRecord(legacy_path,migrated,error) &&
         GuiDecodeSet(migrated,migrated_state,error) &&
         migrated_state.indicators[0].adxMinimum==22.5 &&
         migrated_state.indicators[1].maSlopeBars==3,"Migrar arquivo v2 preservando ADX");
   FileDelete(legacy_path,FILE_COMMON);
   // A versão 3 deve manter a inclinação e receber padrões para os novos campos.
   GuiSetRecordV3 legacy_v3;
   ZeroMemory(legacy_v3); legacy_v3.signature=current_record.signature; legacy_v3.version=3;
   for(int i=0;i<49;i++) legacy_v3.name[i]=current_record.name[i];
   for(int i=0;i<33;i++) legacy_v3.identity[i]=current_record.identity[i];
   legacy_v3.magic=current_record.magic; legacy_v3.market=current_record.market;
   legacy_v3.timeframe=current_record.timeframe; legacy_v3.direction=current_record.direction;
   legacy_v3.trade_mode=current_record.trade_mode; legacy_v3.lot=current_record.lot;
   legacy_v3.entry_start=current_record.entry_start; legacy_v3.entry_end=current_record.entry_end;
   legacy_v3.close_enabled=current_record.close_enabled; legacy_v3.close_time=current_record.close_time;
   legacy_v3.rules=current_record.rules; legacy_v3.management=current_record.management;
   for(int i=0;i<4;i++) legacy_v3.indicators[i]=current_record.indicators[i];
   legacy_file=FileOpen(legacy_path,FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   legacy_ok=false;
   if(legacy_file!=INVALID_HANDLE)
     {
      uint checksum=0;
      legacy_ok=FileWriteStruct(legacy_file,legacy_v3)==sizeof(GuiSetRecordV3) &&
                GuiSetChecksum(legacy_file,checksum,sizeof(GuiSetRecordV3)) &&
                FileSeek(legacy_file,sizeof(GuiSetRecordV3),SEEK_SET) && FileWriteInteger(legacy_file,(int)checksum)==4;
      FileClose(legacy_file);
     }
   Check(legacy_ok && GuiReadSetRecord(legacy_path,migrated,error) && GuiDecodeSet(migrated,migrated_state,error) &&
         migrated_state.indicators[1].maSlopeBars==7 && migrated_state.rules.pending_bar==1 &&
         migrated_state.rules.pending_distance==0,"Migrar arquivo v3 com checksum e valores padrão");
   FileDelete(legacy_path,FILE_COMMON);
   GuiEncodeSet(original,data,error); data.pending.bar=0;
   Check(!GuiDecodeSet(data,loaded,error),"Rejeitar referência pendente inválida no arquivo");
   GuiEncodeSet(original,data,error); data.indicators[1].maSlopeBars=1;
   Check(!GuiDecodeSet(data,loaded,error),"Rejeitar inclinacao invalida no set");
   GuiEncodeSet(original,data,error);
   Check(GuiDecodeSet(data,loaded,error) && loaded.rules.take_multiplier==3.5 && loaded.rules.stop_multiplier==1.75 &&
         loaded.rules.stop_bar==3 && loaded.rules.stop_measure==1,"Stop por candle preservado no set");
   data.stop_bar=0;
   Check(!GuiDecodeSet(data,loaded,error) && loaded.rules.stop_bar==3,"Candle inválido não altera estado carregado");
   GuiEncodeSet(original,data,error); data.stop_multiplier=-1;
   Check(!GuiDecodeSet(data,loaded,error),"Multiplicador negativo rejeitado no set");
   GuiEncodeSet(original,data,error); data.stop_measure=2;
   Check(!GuiDecodeSet(data,loaded,error),"Medida inválida rejeitada no set");
   // Grava o prefixo binário antigo e seu checksum para exercitar a migração real.
   GuiEncodeSet(original,data,error);
   legacy_file=FileOpen(legacy_path,FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   legacy_ok=false;
   if(legacy_file!=INVALID_HANDLE)
     {
      uint checksum=0; data.version=8;
      legacy_ok=FileWriteStruct(legacy_file,data,sizeof(GuiSetRecordV8))==sizeof(GuiSetRecordV8) &&
                GuiSetChecksum(legacy_file,checksum,sizeof(GuiSetRecordV8)) &&
                FileSeek(legacy_file,sizeof(GuiSetRecordV8),SEEK_SET) && FileWriteInteger(legacy_file,(int)checksum)==4;
      FileClose(legacy_file);
     }
   Check(legacy_ok && GuiReadSetRecord(legacy_path,migrated,error) && GuiDecodeSet(migrated,loaded,error) &&
         loaded.rules.take_multiplier==0 && loaded.rules.stop_multiplier==0 && loaded.rules.stop_bar==1 && loaded.rules.stop_measure==0 &&
         loaded.rules.stop_loss==original.rules.stop_loss && loaded.rules.candle_filter==original.rules.candle_filter,
         "Set v8 preserva distância e filtros e inicia multiplicador desativado");
   FileDelete(legacy_path,FILE_COMMON);
   GuiEncodeSet(original,data,error); data.take_multiplier=-1;
   Check(!GuiDecodeSet(data,loaded,error),"Take multiplier invalid rejected");
   GuiEncodeSet(original,data,error);
   legacy_file=FileOpen(legacy_path,FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   legacy_ok=false;
   if(legacy_file!=INVALID_HANDLE)
     {
      uint checksum=0; data.version=9;
      legacy_ok=FileWriteStruct(legacy_file,data,sizeof(GuiSetRecordV9))==sizeof(GuiSetRecordV9) &&
                GuiSetChecksum(legacy_file,checksum,sizeof(GuiSetRecordV9)) &&
                FileSeek(legacy_file,sizeof(GuiSetRecordV9),SEEK_SET) && FileWriteInteger(legacy_file,(int)checksum)==4;
      FileClose(legacy_file);
     }
   Check(legacy_ok && GuiReadSetRecord(legacy_path,migrated,error) && GuiDecodeSet(migrated,loaded,error) &&
         loaded.rules.take_multiplier==0 && loaded.rules.stop_multiplier==1.75 && loaded.rules.stop_bar==3,
         "V9 preserves stop and fixed take");
   FileDelete(legacy_path,FILE_COMMON);
   FileDelete(path,FILE_COMMON); FileDelete(corrupt,FILE_COMMON);
   FileDelete(root+"\\owners\\1234567.txt",FILE_COMMON);
   FileDelete(root+"\\magic-v1.bin",FILE_COMMON); FileDelete(root+"\\sets.lock",FILE_COMMON);
   FolderDelete(root+"\\owners",FILE_COMMON); FolderDelete(root,FILE_COMMON);
   PrintFormat("[GuiSetFileTests] %d verificações, %d falhas",checks,failures);
  }
