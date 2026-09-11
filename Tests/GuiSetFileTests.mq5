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
   original.indicators[0].type=GUI_INDICATOR_ADX; original.indicators[0].adxPeriod=27;
   original.indicators[3].type=GUI_INDICATOR_RSI; original.indicators[3].rsiLower=22.5;
   original.rules.stop_loss=123; original.rules.take_profit=456;
   original.rules.Choose(4,1); original.rules.stop_loss=1.5; original.rules.take_profit=2.5;
   original.management.Choose(0,1); original.management.values[0]=100; original.management.values[1]=20;
   original.management.Choose(0,2); original.management.values[0]=2; original.management.values[1]=0.5;
   Check(GuiSaveSet(path,original,error,root),"Salvar joao: "+error);
   Check(GuiLoadSet(path,loaded,error,root),"Carregar joao: "+error);
   Check(loaded.setup.name=="joao" && loaded.setup.magic==1234567 && loaded.setup.set_id==original.setup.set_id,"Restaurar identidade e Magic exatos");
   Check(loaded.setup.lot==0.25 && loaded.setup.timeframe==PERIOD_H4 && loaded.setup.entry_start==540 && loaded.setup.close_time==1050,"Restaurar setup");
   Check(loaded.indicators[0].adxPeriod==27 && loaded.indicators[3].rsiLower==22.5,"Restaurar quatro indicadores");
   Check(loaded.rules.stop_loss==1.5 && loaded.management.values[0]==2 && loaded.management.Unit(0)=="%","Restaurar regras e gestão em percentual");
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
   FileDelete(path,FILE_COMMON); FileDelete(corrupt,FILE_COMMON);
   FileDelete(root+"\\owners\\1234567.txt",FILE_COMMON);
   FileDelete(root+"\\magic-v1.bin",FILE_COMMON); FileDelete(root+"\\sets.lock",FILE_COMMON);
   FolderDelete(root+"\\owners",FILE_COMMON); FolderDelete(root,FILE_COMMON);
   PrintFormat("[GuiSetFileTests] %d verificações, %d falhas",checks,failures);
  }
