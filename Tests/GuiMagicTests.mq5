#property strict
#property script_show_inputs
#include "../Include/CanvasGUI/GuiMagicRegistry.mqh"
int checks=0,failures=0;
void Check(bool condition,string label)
  { checks++; if(!condition) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   long used[],magic=0;
   Check(GuiFindFreeMagic("Meu setup",0,used,magic) && magic==10000,"Limite inferior, registro vazio");
   Check(GuiFindFreeMagic("Meu setup",89999,used,magic) && magic==99999,"Limite superior");
   ArrayResize(used,2); used[0]=10000; used[1]=99999;
   Check(GuiFindFreeMagic("Meu setup",89999,used,magic) && magic==10001,"Colisão e retorno ao início da faixa");
   string names[]={"AB","BA","ab","A B","A-B","ação!","ação?","日本語"};
   for(int i=0;i<ArraySize(names);i++)
     {
      long base=GuiMagicCandidate(names[i],0);
      Check(base>=100000 && base<=2147483647 && base==GuiMagicCandidate(names[i],123),"Hash estável: "+names[i]);
      for(int j=0;j<i;j++) Check(base!=GuiMagicCandidate(names[j],0),"Caracteres e ordem participam");
      ArrayResize(used,3); used[0]=base; used[1]=base; used[2]=base+1;
      Check(GuiFindFreeMagic(names[i],0,used,magic) && magic==base+2,"Colisão de hash e duplicatas");
     }
   ArrayResize(used,90000);
   for(int i=0;i<90000;i++) used[i]=10000+i;
   Check(!GuiFindFreeMagic("Meu setup",45678,used,magic) && magic==0,"Faixa esgotada não reutiliza número");
   ArrayResize(used,89999);
   Check(GuiFindFreeMagic("Meu setup",0,used,magic) && magic==99999,"Último número livre");
   PrintFormat("[GuiMagicTests] %d verificações, %d falhas",checks,failures);
  }
