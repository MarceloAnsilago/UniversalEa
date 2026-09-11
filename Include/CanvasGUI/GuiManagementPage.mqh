#ifndef CANVAS_GUI_MANAGEMENT_PAGE_MQH
#define CANVAS_GUI_MANAGEMENT_PAGE_MQH
#include "GuiManagementState.mqh"
#include "GuiLayout.mqh"
#include "Controls/GuiLabel.mqh"
#include "Controls/GuiTextField.mqh"
#include "Controls/GuiSelectBox.mqh"
#include "Controls/GuiButton.mqh"
class CGuiManagementPage
  {
private:
   CGuiLabel m_labels[11];
   CGuiSelectBox m_select[3];
   CGuiTextField m_text[8];
   CGuiButton m_back,m_save;
   GuiRect m_cards[3],m_status,m_summary;
   int m_open,m_edit,m_focus,m_height;
   bool m_dirty,m_error;
   string m_message;
   void Status(const string message,const bool error=false)
     { m_message=message; m_error=error; m_dirty=true; }
   void Focus(const int id)
     {
      m_focus=id;
      for(int i=0;i<3;i++) m_select[i].focused=id==(i==2 ? 10 : i);
      for(int i=0;i<8;i++) m_text[i].focused=id==i+2;
      m_back.focused=id==11; m_save.focused=id==12; m_dirty=true;
     }
   void Begin(const int id)
     {
      if(id>=2 && id<=9 && !state.Enabled(id)) return;
      Focus(id);
      if((id>=0 && id<2) || id==10) { int index=id==10 ? 2 : id; m_select[index].Open(m_height); m_open=m_select[index].active ? index : -1; }
      else if(id>=2 && id<10) { m_edit=id-2; m_text[m_edit].Begin(); }
      m_dirty=true;
     }
   void SelectOption(const int option)
     {
      if(m_open<0 || option<0) return;
      if(state.Choose(m_open,option)) { m_select[m_open].SetSelected(option); Status("Configuração alterada. Salve para registrar."); }
      UpdateTargets();
      CloseSelect();
     }
   void UpdateTargets()
     {
      for(int i=0;i<8;i++)
        {
         m_text[i].SetValue(state.Value(i+2)); m_text[i].enabled=state.Enabled(i+2);
         if(!m_text[i].enabled) m_text[i].SetHover(false);
        }
      m_dirty=true;
     }
public:
   CGuiManagementState state;
   CGuiManagementPage() { m_open=-1; m_edit=-1; m_focus=-1; m_dirty=true; m_error=false; }
   void Create()
     {
      state.Reset();
      m_labels[0].caption="Breakeven"; m_labels[1].caption="Trailing stop";
      m_labels[2].caption="Ativar após"; m_labels[3].caption="Proteção na entrada";
      m_labels[4].caption="Ativar após"; m_labels[5].caption="Distância do preço"; m_labels[6].caption="Passo de ajuste";
      for(int i=0;i<3;i++) { m_select[i].SetOptions("Desativado|Pontos|Porcentagem"); m_select[i].SetSelected(0); }
      m_labels[10].caption="Stop móvel"; m_labels[7].caption="Ativar após"; m_labels[8].caption="Distância do preço"; m_labels[9].caption="Passo de ajuste";
      UpdateTargets();
      m_back.caption="Regras"; m_back.secondary=true; m_back.show_icon=true; m_back.icon=GUI_ICON_ARROW_LEFT;
      m_save.caption="Salvar gestão";
      Status("Configure o breakeven e o trailing stop.");
     }
   void Place(CGuiLayout &layout)
     {
      for(int i=0;i<2;i++) m_cards[i]=layout.cards[i];
      m_cards[2]=layout.schedule;
      m_height=layout.height; m_summary=layout.summary;
      for(int id=0;id<11;id++)
        {
         GuiRect field; layout.ManagementFieldBounds(id,field);
         m_labels[id].SetBounds(field.x,field.y-22,field.w,18);
         if(id<2 || id==10) m_select[id==10 ? 2 : id].SetBounds(field.x,field.y,field.w,field.h);
         else m_text[id-2].SetBounds(field.x,field.y,field.w,field.h);
        }
      m_back.SetBounds(layout.left,layout.apply.y,172,44);
      m_save.SetBounds(layout.apply.x,layout.apply.y,layout.apply.w,44);
      m_status.Set(layout.left,layout.apply.y+56,layout.content_width,40);
      m_dirty=true;
     }
   bool Dirty() { return m_dirty; }
   void CloseSelect() { if(m_open>=0) { m_select[m_open].Close(); m_open=-1; m_dirty=true; } }
   void ClearHover()
     {
      for(int i=0;i<3;i++) m_select[i].SetHover(false);
      for(int i=0;i<8;i++) m_text[i].SetHover(false);
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
     { Status(success ? "Gestão salva com a configuração no histórico." : "Não foi possível guardar a configuração.",!success); }
   // 1 saves, 2 returns to Rules, 3 focuses the shared Recolher button.
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
      for(int i=0;i<3;i++) if(m_select[i].ContainsPoint(x,y)) hit=i==2 ? 10 : i;
      for(int i=0;i<8;i++) if(m_text[i].ContainsPoint(x,y)) hit=i+2;
      if(m_edit>=0 && hit==m_edit+2) return 0;
      if(!Finish(true)) return 0;
      if(hit>=0) Begin(hit);
      else if(m_back.ContainsPoint(x,y)) { Focus(11); return Ready() ? 2 : 0; }
      else if(m_save.ContainsPoint(x,y)) { Focus(12); return Ready() ? 1 : 0; }
      return 0;
     }
   void Mouse(const int x,const int y,const string flags)
     {
      bool overlay=m_open>=0 && m_select[m_open].popup.Contains(x,y);
      for(int i=0;i<3;i++)
        {
         if(m_select[i].SetHover(!overlay && m_select[i].ContainsPoint(x,y))) m_dirty=true;

        }
      for(int i=0;i<8;i++) if(m_text[i].SetHover(!overlay && m_text[i].ContainsPoint(x,y))) m_dirty=true;
      if(m_back.SetHover(!overlay && m_back.ContainsPoint(x,y))) m_dirty=true;
      if(m_save.SetHover(!overlay && m_save.ContainsPoint(x,y))) m_dirty=true;
      bool down=(StringToInteger(flags)&1)!=0;
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
         int order[]={10,7,8,9,0,2,3,1,4,5,6,11,12};
         int position=back ? 13 : -1;
         for(int i=0;i<13;i++) if(order[i]==m_focus) { position=i; break; }
         int next=-1;
         for(position+=back ? -1 : 1;position>=0 && position<13;position+=back ? -1 : 1)
           { int id=order[position]; if(id<2 || id>9 || state.Enabled(id)) { next=id; break; } }
         if(next<0) { Focus(-1); return 3; }
         Focus(next); if(next>=2 && next<10) Begin(next); return 0;
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
         if(m_focus==11) return Ready() ? 2 : 0;
         if(m_focus==12) return Ready() ? 1 : 0;
         Begin(m_focus); return 0;
        }
      if(((m_focus>=0 && m_focus<2) || m_focus==10) && (key==38 || key==40)) Begin(m_focus);
      else if(m_focus>=2 && m_focus<10 && ((key>=48 && key<=57) || (key>=96 && key<=105) || key==8 || key==46 || key==189 || key==109 || key==190 || key==188 || key==110))
        { Begin(m_focus); m_text[m_edit].Key(key); m_dirty=true; }
      return 0;
     }
   void EnterFocus(const bool last) { Focus(last ? 12 : 10); }
   void Render(CGuiRenderer &r,const bool full)
     {
      if(!full && !m_dirty) return;
      for(int i=0;i<3;i++)
        {
         GuiRect c=m_cards[i]; r.Box(c,GUI_CARD,GUI_BORDER);
         r.Icon(i==0 ? GUI_ICON_MANAGEMENT : GUI_ICON_RULES,c.x+24,c.y+18,GUI_ACCENT,20);
         r.Text(c.x+52,c.y+20,i==0 ? "BREAKEVEN" : (i==1 ? "TRAILING STOP" : "STOP MÓVEL"),GUI_TEXT,14,true,c.w-76);
         r.Text(c.x+24,c.y+c.h-28,"Valores em "+state.Unit(i),GUI_MUTED,12,false,c.w-48);
        }
      for(int id=0;id<11;id++) { m_labels[id].Draw(r); if(id<2 || id==10) m_select[id==10 ? 2 : id].Draw(r); else m_text[id-2].Draw(r); }
      r.Box(m_summary,GUI_CARD,GUI_BORDER);
      r.Icon(GUI_ICON_REVIEW,m_summary.x+24,m_summary.y+16,GUI_ACCENT,20);
      r.Text(m_summary.x+52,m_summary.y+18,"RESUMO DO STOP MÓVEL",GUI_TEXT,13,true,m_summary.w-76);
      r.Text(m_summary.x+24,m_summary.y+44,"Breakeven: "+state.Summary(0),GUI_TEXT,12,false,m_summary.w-48);
      r.Text(m_summary.x+24,m_summary.y+64,"Trailing stop: "+state.Summary(1),GUI_MUTED,12,false,m_summary.w-48);
      r.Text(m_summary.x+24,m_summary.y+84,"Stop móvel: "+state.Summary(2),GUI_MUTED,12,false,m_summary.w-48);
      r.Fill(m_status,GUI_BG);
      r.Text(m_status.x,m_status.y,m_message,m_error ? GUI_ERROR : GUI_MUTED,13,false,m_status.w);
      r.Text(m_status.x,m_status.y+22,"Próxima etapa: Filtros · em breve",GUI_MUTED,11,false,m_status.w);
      m_back.Draw(r); m_save.Draw(r); m_dirty=false;
     }
   void DrawOverlay(CGuiRenderer &r) { if(m_open>=0) { r.SaveOverlay(m_select[m_open].popup); m_select[m_open].DrawOverlay(r); } }
  };
#endif
