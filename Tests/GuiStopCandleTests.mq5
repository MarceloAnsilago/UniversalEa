#property strict
#define private public
#include "../Include/CanvasGUI/GuiApp.mqh"
#undef private
int checks=0,failures=0;
void Check(const bool ok,const string label)
  { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   CGuiRulesState state; string error;
   Check(state.stop_multiplier==0 && state.stop_bar==1 && state.stop_measure==0 && state.StopSummary()=="Desativado","Padrões preservam stop desativado");
   Check(state.Commit(2,"25",error) && state.Commit(19,"1,50",error) && state.Choose(20,1) && state.Choose(21,1),"Configurar distância mais corpo do candle");
   Check(state.stop_loss==25 && state.stop_multiplier==1.5 && state.stop_bar==2 && state.stop_measure==1 && state.Validate(error),"Valores independentes e válidos");
   Check(state.StopSummary()=="25.00 pontos + 1.50 vezes o candle 2 (Corpo)","Resumo explicita a soma");
   Check(!state.Commit(19,"-1",error) && !state.Commit(19,"1.001",error) && state.stop_multiplier==1.5,"Multiplicador inválido preserva valor");
   Check(!state.Choose(20,-1) && !state.Choose(20,3) && !state.Commit(20,"2",error) && state.stop_bar==2,"Candle exige inteiro fechado válido");
   Check(!state.Choose(21,2) && state.stop_measure==1,"Medida inválida preserva valor");
   state.Commit(2,"0",error);
   Check(state.StopSummary()!="Desativado","Somente candle mantém stop habilitado");
   state.Choose(4,1);
   Check(state.stop_multiplier==1.5 && state.stop_bar==2 && state.stop_measure==1,"Unidade da distância não altera componente do candle");
   CGuiState combined; combined.Reset(); combined.rules=state;
   Check(combined.Apply() && combined.applications[0].rules.stop_multiplier==1.5 && combined.applications[0].rules.stop_bar==2,"Histórico preserva stop por candle");
   CGuiApp gui;
   if(!gui.Create(ChartID(),false)) { Check(false,"Criar GUI"); return; }
   gui.m_step=1; gui.m_renderer.Resize(1792,733); gui.m_layout.Calculate(1792,733); gui.Reflow();
   gui.m_rules_focus=true; gui.m_rules.Focus(19); gui.RevealFocus(); gui.Render();
   GuiRect field; gui.m_rules.FocusBounds(field);
   Check(field.y>=160 && field.y+field.h<=733,"Foco revela multiplicador");
   gui.Click(field.x+10,field.y+10); gui.Key(50); gui.Key(13);
   Check(gui.m_rules.state.stop_multiplier==2,"Mouse e teclado editam vezes");
   gui.m_rules.Key(9);
   Check(gui.m_rules.m_focus==20 && gui.m_rules.m_edit==-1,"Tab avança para candle");
   gui.m_rules.Key(13); gui.m_rules.Key(40); gui.m_rules.Key(40); gui.m_rules.Key(13); gui.m_rules.Key(9);
   Check(gui.m_rules.state.stop_bar==3 && gui.m_rules.m_focus==21,"Candle editável e Tab para medida");
   gui.m_rules.Key(13); gui.m_rules.Key(40); gui.m_rules.Key(13);
   Check(gui.m_rules.state.stop_measure==1,"Seletor escolhe corpo");
   gui.m_rules.Key(9); Check(gui.m_rules.m_focus==3,"Tab segue para take profit"); gui.m_rules.Finish(false);
   gui.m_rules.Focus(19); gui.RevealFocus(); gui.m_rules.FocusBounds(field);
   gui.Click(field.x+field.w-12,field.y+8);
   Check(gui.m_rules.state.stop_multiplier==2.5,"Botão mais incrementa em 0,50");
   gui.Click(field.x+field.w-12,field.y+32);
   Check(gui.m_rules.state.stop_multiplier==2,"Botão menos decrementa em 0,50");
   gui.Key(38); gui.Key(38); gui.Key(40);
   Check(gui.m_rules.state.stop_multiplier==2.5,"Setas ajustam o multiplicador");
   gui.m_rules.Begin(19); gui.m_rules.Key(51); gui.m_rules.Key(38);
   Check(gui.m_rules.state.stop_multiplier==3.5,"Incremento confirma valor em edição");
   gui.m_rules.Begin(19); gui.m_rules.Key(189); gui.m_rules.Key(38);
   Check(gui.m_rules.state.stop_multiplier==3.5 && gui.m_rules.m_text[10].invalid,"Texto inválido bloqueia incremento sem perder edição");
   gui.m_rules.Finish(false); gui.m_rules.state.Commit(19,"0.05",error); gui.Key(40); gui.Key(40);
   Check(gui.m_rules.state.stop_multiplier==0,"Decremento limitado a zero");
   gui.m_rules.state.Commit(19,"100000000",error); gui.Key(38);
   Check(gui.m_rules.state.stop_multiplier==100000000,"Incremento respeita limite superior");
   gui.m_rules.state.Commit(19,"2",error); gui.m_rules.UpdateTargets();
   gui.ScrollTo(100000); gui.Render();
   ResourceSave(gui.m_renderer.m_canvas.ResourceName(),"stop-candle-wide.bmp");
   int widths[]={600,960,1120,1792};
   for(int i=0;i<ArraySize(widths);i++)
     {
      gui.m_renderer.Resize(widths[i],733); gui.m_layout.Calculate(widths[i],733); gui.Reflow(); gui.ScrollTo(100000); gui.Render();
      GuiRect card=gui.m_rules.m_cards[1],last=gui.m_rules.m_text[1].bounds;
      Check(last.y+last.h<card.y+card.h && gui.m_layout.status.y+gui.m_layout.status.h<=733,"Alvos e rodapé cabem com rolagem");
      Check(gui.m_rules.m_text[10].bounds.x+gui.m_rules.m_text[10].bounds.w<gui.m_rules.m_select[10].bounds.x,"Vezes e candle não se sobrepõem");
      if(widths[i]==600) ResourceSave(gui.m_renderer.m_canvas.ResourceName(),"stop-candle-narrow.bmp");
     }
   gui.Destroy();
   PrintFormat("[GuiStopCandleTests] %d checks, %d failures",checks,failures);
  }
