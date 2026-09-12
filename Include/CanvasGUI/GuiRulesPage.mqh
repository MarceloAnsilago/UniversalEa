#ifndef CANVAS_GUI_RULES_PAGE_MQH
#define CANVAS_GUI_RULES_PAGE_MQH
#include "GuiRulesState.mqh"
#include "GuiLayout.mqh"
#include "Controls/GuiLabel.mqh"
#include "Controls/GuiTextField.mqh"
#include "Controls/GuiSelectBox.mqh"
#include "Controls/GuiButton.mqh"
class CGuiRulesPage
  {
private:
   CGuiLabel m_labels[4];
   CGuiSelectBox m_select[2];
   CGuiTextField m_text[2];
   CGuiButton m_back,m_save,m_next;
   GuiRect m_cards[3],m_status,m_summary;
   int m_open,m_edit,m_focus,m_height;
   bool m_dirty,m_error,m_embedded;
   GuiRect m_embedded_bounds;
   string m_message;
   void Status(const string message,const bool error=false)
     { m_message=message; m_error=error; m_dirty=true; }
   void Focus(const int id)
     {
      m_focus=id;
      for(int i=0;i<2;i++) { m_select[i].focused=id==i; m_text[i].focused=id==i+2; }
      m_back.focused=id==4; m_save.focused=id==5; m_next.focused=id==6; m_dirty=true;
     }
   void Begin(const int id)
     {
      Focus(id);
      if(id>=0 && id<2) { m_select[id].Open(m_height,m_embedded ? 160 : 4); m_open=m_select[id].active ? id : -1; }
      else if(id>=2 && id<4) { m_edit=id-2; m_text[m_edit].Begin(); }
      m_dirty=true;
     }
   void SelectOption(const int option)
     {
      if(m_open<0 || option<0) return;
      if(state.Choose(m_open==1 ? 4 : 0,option)) { m_select[m_open].SetSelected(option); Status("Configuração alterada. Salve para registrar."); }
      UpdateTargets();
      CloseSelect();
     }
   void UpdateTargets()
     {
      m_labels[2].caption="Stop loss ("+state.Unit()+")";
      m_labels[3].caption="Take profit ("+state.Unit()+")";
      for(int i=0;i<2;i++) m_text[i].SetValue(state.Value(i+2));
      m_dirty=true;
     }
public:
   CGuiRulesState state;
   void ReplaceState(CGuiRulesState &loaded)
     {
      Finish(false); CloseSelect(); state=loaded;
      for(int i=0;i<2;i++) m_select[i].SetSelected(state.Choice(i==1 ? 4 : 0));
      UpdateTargets(); m_dirty=true;
     }
   CGuiRulesPage() { m_open=-1; m_edit=-1; m_focus=-1; m_dirty=true; m_error=false; m_embedded=false; }
   void Create()
     {
      state.Reset();
      m_labels[0].caption="Tipo de ordem"; m_labels[1].caption="Unidade dos alvos";
      m_labels[2].caption="Stop loss (pontos)"; m_labels[3].caption="Take profit (pontos)";
      m_select[0].SetOptions("A mercado|Pendente");
      m_select[1].SetOptions("Pontos|Porcentagem");
      for(int i=0;i<2;i++) { m_select[i].SetSelected(state.Choice(i==1 ? 4 : 0)); m_text[i].SetValue(state.Value(i+2)); }
      m_back.caption="Indicadores"; m_back.secondary=true; m_back.show_icon=true; m_back.icon=GUI_ICON_ARROW_LEFT;
      m_save.caption="Salvar regras";
      m_next.caption="Continuar"; m_next.show_icon=true; m_next.icon=GUI_ICON_ARROW_RIGHT; m_next.icon_after=true;
      Status("Defina as regras de entrada e saída.");
     }
   void Place(CGuiLayout &layout)
     {
      m_embedded=false;
      for(int i=0;i<2;i++) m_cards[i]=layout.cards[i];
      m_cards[2]=layout.schedule;
      m_height=layout.height; m_summary=layout.summary;
      for(int id=0;id<4;id++)
        {
         GuiRect c=m_cards[id==0 ? 0 : 1]; int y=c.y+78+(id==0 ? 0 : id-1)*76;
         m_labels[id].SetBounds(c.x+24,y-22,c.w-48,18);
         if(id<2) m_select[id].SetBounds(c.x+24,y,c.w-48,42);
         else m_text[id-2].SetBounds(c.x+24,y,c.w-48,42);
        }
      m_back.SetBounds(layout.left,layout.apply.y,172,44);
      m_save.SetBounds(layout.apply.x-164,layout.apply.y,152,44);
      m_next.SetBounds(layout.apply.x,layout.apply.y,layout.apply.w,44);
      m_status.Set(layout.left,layout.apply.y+56,layout.content_width,40);
      m_dirty=true;
     }
   bool Dirty() { return m_dirty; }
   bool HasPopup() { return m_open>=0; }
   bool HitEmbedded(const int x,const int y)
     { return m_embedded_bounds.Contains(x,y) || (m_open>=0 && m_select[m_open].popup.Contains(x,y)); }
   void LeaveFocus() { Focus(-1); }
   bool FocusBounds(GuiRect &r)
     {
      if(m_focus<0 || m_focus>3) return false;
      if(m_focus<2) r=m_select[m_focus].bounds; else r=m_text[m_focus-2].bounds;
      return true;
     }
   void PlaceEmbedded(CGuiLayout &layout)
     {
      m_embedded=true; m_embedded_bounds=layout.indicator_rules; m_height=layout.height;
      GuiRect c=m_embedded_bounds;
      int columns=c.w>=760 ? 4 : 2;
      int width=(c.w-48-(columns-1)*16)/columns;
      for(int id=0;id<4;id++)
        {
         int x=c.x+24+(id%columns)*(width+16),y=c.y+64+(id/columns)*76;
         m_labels[id].SetBounds(x,y-22,width,18);
         if(id<2) m_select[id].SetBounds(x,y,width,42);
         else m_text[id-2].SetBounds(x,y,width,42);
        }
      m_dirty=true;
     }
   void RenderEmbedded(CGuiRenderer &r,const bool full)
     {
      if(!full && !m_dirty) return;
      GuiRect c=m_embedded_bounds;
      r.Box(c,GUI_CARD,GUI_BORDER);
      r.Icon(GUI_ICON_RULES,c.x+24,c.y+12,GUI_ACCENT,20);
      r.Text(c.x+52,c.y+14,"REGRAS DE ENTRADA E SAÍDA",GUI_TEXT,14,true,c.w-76);
      for(int id=0;id<4;id++) { m_labels[id].Draw(r); if(id<2) m_select[id].Draw(r); else m_text[id-2].Draw(r); }
      r.Text(c.x+24,c.y+c.h-28,m_error ? m_message : "Stop loss e take profit: 0 desativa a saída.",m_error ? GUI_ERROR : GUI_MUTED,12,false,c.w-48);
      m_dirty=false;
     }
   void CloseSelect() { if(m_open>=0) { m_select[m_open].Close(); m_open=-1; m_dirty=true; } }
   void ClearHover()
     {
      for(int i=0;i<2;i++) { m_select[i].SetHover(false); m_text[i].SetHover(false); }
      m_next.SetHover(false); m_next.active=false;
      m_back.SetHover(false); m_save.SetHover(false); m_back.active=false; m_save.active=false; m_dirty=true;
     }
   bool Finish(const bool save)
     {
      if(m_edit<0) return true;
      if(save)
        {
         string error;
         if(!state.Commit(m_edit+2,m_text[m_edit].Buffer(),error))
           { m_text[m_edit].invalid=true; Status(error,true); return false; }
         m_text[m_edit].SetValue(state.Value(m_edit+2));
        }
      m_text[m_edit].End(); m_edit=-1;
      Status(save ? "Configuração alterada. Salve para registrar." : "Edição cancelada."); return true;
     }
   bool Ready()
     {
      if(!Finish(true)) return false;
      string error; if(!state.Validate(error)) { Status(error,true); return false; }
      CloseSelect(); return true;
     }
   void Saved(const bool success)
     { Status(success ? "Regras salvas com o setup e os indicadores no histórico." : "Não foi possível guardar a configuração.",!success); }
   // 1 saves, 2 returns to Indicators, 3 focuses the shared Recolher button.
   int Click(const int x,const int y)
     {
      if(m_open>=0)
        {
         if(m_select[m_open].HandlePopupClick(x,y)) { m_dirty=true; return 0; }
         int option=m_select[m_open].OptionAt(x,y);
         if(option>=0) { SelectOption(option); return 0; }
         bool same=m_select[m_open].ContainsPoint(x,y); CloseSelect(); if(same) return 0;
        }
      int hit=-1;
      for(int i=0;i<2;i++) { if(m_select[i].ContainsPoint(x,y)) hit=i; if(m_text[i].ContainsPoint(x,y)) hit=i+2; }
      if(m_edit>=0 && hit==m_edit+2) return 0;
      if(!Finish(true)) return 0;
      if(hit>=0) Begin(hit);
      else if(!m_embedded && m_back.ContainsPoint(x,y)) { Focus(4); return Ready() ? 2 : 0; }
      else if(!m_embedded && m_next.ContainsPoint(x,y)) { Focus(6); return Ready() ? 4 : 0; }
      else if(!m_embedded && m_save.ContainsPoint(x,y)) { Focus(5); return Ready() ? 1 : 0; }
      return 0;
     }
   void Mouse(const int x,const int y,const string flags)
     {
      bool overlay=m_open>=0 && m_select[m_open].popup.Contains(x,y);
      for(int i=0;i<2;i++)
        {
         if(m_select[i].SetHover(!overlay && m_select[i].ContainsPoint(x,y))) m_dirty=true;
         if(m_text[i].SetHover(!overlay && m_text[i].ContainsPoint(x,y))) m_dirty=true;
        }
      if(m_back.SetHover(!overlay && m_back.ContainsPoint(x,y))) m_dirty=true;
      if(m_save.SetHover(!overlay && m_save.ContainsPoint(x,y))) m_dirty=true;
      if(m_next.SetHover(!overlay && m_next.ContainsPoint(x,y))) m_dirty=true;
      bool down=(StringToInteger(flags)&1)!=0;
      if(m_next.active!=(down && m_next.hover)) m_dirty=true;
      m_next.active=down && m_next.hover;
      if(m_back.active!=(down && m_back.hover) || m_save.active!=(down && m_save.hover)) m_dirty=true;
      m_back.active=down && m_back.hover; m_save.active=down && m_save.hover;
      if(m_open>=0) { int hot=m_select[m_open].OptionAt(x,y); if(hot!=m_select[m_open].hot) { m_select[m_open].hot=hot; m_dirty=true; } }
     }
   int Key(const int key)
     {
      if(key==9)
        {
         if(!Finish(true)) return 0;
         if(m_open>=0) { int option=m_select[m_open].hot; if(option>=0) SelectOption(option); else CloseSelect(); }
         bool back=(TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)&0x8000)!=0;
         int next=m_focus<0 ? (back ? 6 : 0) : m_focus+(back ? -1 : 1);
         if(next<0 || next>(m_embedded ? 3 : 6)) { Focus(-1); return 3; }
         Focus(next); if(next>=2 && next<4) Begin(next); return 0;
        }
      if(m_open>=0)
        {
         if(key==27) CloseSelect();
         else if(m_select[m_open].PopupKey(key)) m_dirty=true;
         else if(key==13) SelectOption(m_select[m_open].hot);
         return 0;
        }
      if(m_edit>=0)
        {
         if(key==27) Finish(false);
         else if(key==13) Finish(true);
         else if(m_text[m_edit].Key(key)) { m_dirty=true; if(m_error) Status("Tab avança; Enter confirma; Esc cancela."); }
         return 0;
        }
      if(key==13 || key==32)
        {
         if(m_focus==4) return Ready() ? 2 : 0;
         if(m_focus==5) return Ready() ? 1 : 0;
         if(m_focus==6) return Ready() ? 4 : 0;
         Begin(m_focus); return 0;
        }
      if(m_focus>=0 && m_focus<2 && (key==38 || key==40)) Begin(m_focus);
      else if(m_focus>=2 && m_focus<4 && ((key>=48 && key<=57) || (key>=96 && key<=105) || key==8 || key==46 || key==189 || key==109 || key==190 || key==188 || key==110))
        { Begin(m_focus); m_text[m_edit].Key(key); m_dirty=true; }
      return 0;
     }
   void EnterFocus(const bool last) { Focus(last ? (m_embedded ? 3 : 6) : 0); }
   void Render(CGuiRenderer &r,const bool full)
     {
      if(!full && !m_dirty) return;
      for(int i=0;i<3;i++)
        {
         GuiRect c=m_cards[i]; r.Box(c,GUI_CARD,GUI_BORDER);
         r.Icon(i==0 ? GUI_ICON_RULES : (i==1 ? GUI_ICON_MANAGEMENT : GUI_ICON_FILTERS),c.x+24,c.y+18,GUI_ACCENT,20);
         r.Text(c.x+52,c.y+20,i==0 ? "ORDEM" : (i==1 ? "ALVOS" : "FILTRO DE CANDLE"),GUI_TEXT,14,true,c.w-76);
         if(i<2) r.Text(c.x+24,c.y+c.h-28,i==0 ? "Defina o tipo de ordem." : "Valores em "+state.Unit()+" · 0 desativa a saída.",GUI_MUTED,12,false,c.w-48);
        }
      for(int id=0;id<4;id++) { m_labels[id].Draw(r); if(id<2) m_select[id].Draw(r); else m_text[id-2].Draw(r); }
      r.Box(m_summary,GUI_CARD,GUI_BORDER);
      r.Icon(GUI_ICON_REVIEW,m_summary.x+24,m_summary.y+16,GUI_ACCENT,20);
      r.Text(m_summary.x+52,m_summary.y+18,"RESUMO DAS REGRAS",GUI_TEXT,13,true,m_summary.w-76);
      r.Text(m_summary.x+24,m_summary.y+50,"Ordem: "+state.Value(0),GUI_TEXT,13,false,m_summary.w-48);
      r.Text(m_summary.x+24,m_summary.y+76,"Stop loss: "+(state.stop_loss==0 ? "Desativado" : state.Value(2)+" "+state.Unit())+"   ·   Take profit: "+(state.take_profit==0 ? "Desativado" : state.Value(3)+" "+state.Unit()),GUI_MUTED,13,false,m_summary.w-48);
      r.Fill(m_status,GUI_BG);
      r.Text(m_status.x,m_status.y,m_message,m_error ? GUI_ERROR : GUI_MUTED,13,false,m_status.w);
      r.Text(m_status.x,m_status.y+22,"Próxima etapa: Gestão",GUI_MUTED,11,false,m_status.w);
      m_back.Draw(r); m_save.Draw(r); m_next.Draw(r); m_dirty=false;
     }
   void DrawOverlay(CGuiRenderer &r) { if(m_open>=0) { r.SaveOverlay(m_select[m_open].popup); m_select[m_open].DrawOverlay(r); } }
  };
#endif
