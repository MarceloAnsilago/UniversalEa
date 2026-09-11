#ifndef CANVAS_GUI_SETUP_PAGE_MQH
#define CANVAS_GUI_SETUP_PAGE_MQH
#include "GuiSetupState.mqh"
#include "GuiLayout.mqh"
#include "Controls/GuiLabel.mqh"
#include "Controls/GuiTextField.mqh"
#include "Controls/GuiSelectBox.mqh"
#include "Controls/GuiButton.mqh"

// The first step reuses Canvas controls; indicator editing keeps its own bindings.
class CGuiSetupPage
  {
private:
   CGuiLabel m_labels[11];
   CGuiTextField m_text[3];
   CGuiSelectBox m_select[8];
   CGuiButton m_continue;
   GuiRect m_cards[3],m_status;
   int m_open,m_edit,m_focus,m_height;
   bool m_dirty,m_error;
   string m_message,m_symbol;
   int TextIndex(const int id)
     { return id==10 ? 2 : (id>=0 && id<2 ? id : -1); }
   int SelectIndex(const int id)
     { return id>=2 && id<=9 ? id-2 : -1; }
   int TextId(const int index) { return index==2 ? 10 : index; }
   int SelectId(const int index) { return index+2; }
   bool FocusAvailable(const int id) { return id>=0 && id<=11 && (id!=8 || state.close_enabled); }
   int NextFocus(const bool backward)
     {
      // Follow the visible rows, including timeframe and lot on the same row.
      int order[]={0,1,2,9,3,10,4,5,6,7,8,11};
      int position=backward ? ArraySize(order) : -1;
      for(int i=0;i<ArraySize(order);i++) if(order[i]==m_focus) { position=i; break; }
      for(position+=backward ? -1 : 1;position>=0 && position<ArraySize(order);position+=backward ? -1 : 1)
         if(FocusAvailable(order[position])) return order[position];
      return -1;
     }
   void RefreshVolumeLimits()
     {
      state.volume_min=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MIN);
      state.volume_max=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MAX);
      state.volume_step=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_STEP);
     }
   void UpdateCloseField()
     {
      m_select[6].enabled=state.close_enabled;
      m_select[6].SetSelected(state.close_enabled ? state.Choice(8) : -1);
      if(!state.close_enabled) m_select[6].SetHover(false);
      m_dirty=true;
     }
   void Status(const string message,const bool error=false)
     { m_message=message; m_error=error; m_dirty=true; }
   void Focus(const int index)
     {
      m_focus=index;
      for(int i=0;i<3;i++) { m_text[i].focused=index==TextId(i); m_text[i].dirty=true; }
      for(int i=0;i<8;i++) { m_select[i].focused=index==SelectId(i); m_select[i].dirty=true; }
      m_continue.focused=index==11; m_continue.dirty=true; m_dirty=true;
     }
   void SelectOption(const int option)
     {
      if(m_open<0 || option<0) return;
      if(state.Choose(SelectId(m_open),option))
        { m_select[m_open].SetSelected(option); Status("Configuração atualizada."); }
      UpdateCloseField();
      CloseSelect();
     }
   void Begin(const int index)
     {
      Focus(index);
      int text=TextIndex(index),select=SelectIndex(index);
      if(text>=0 && m_text[text].enabled) { m_edit=text; m_text[text].Begin(); Status("Tab avança; Enter confirma; Esc cancela."); }
      else if(select>=0 && m_select[select].enabled)
        { m_select[select].Open(m_height); m_open=m_select[select].active ? select : -1; }
     }
public:
   CGuiSetupState state;
   CGuiSetupPage() { m_open=-1; m_edit=-1; m_focus=-1; m_dirty=true; m_error=false; }
   void Create(const ENUM_TIMEFRAMES chart_period,const string symbol)
     {
      m_symbol=symbol;
      RefreshVolumeLimits();
      state.Reset(chart_period,state.volume_min,state.volume_max,state.volume_step);
      m_labels[0].caption="Nome do setup (opcional)";
      m_labels[1].caption="Magic Number";
      m_labels[2].caption="Mercado";
      m_labels[3].caption="Timeframe";
      m_labels[4].caption="Direção permitida";
      m_labels[5].caption="Início entradas";
      m_labels[6].caption="Fim entradas";
      m_labels[7].caption="Encerrar posições";
      m_labels[8].caption="Horário de encerramento";
      m_labels[9].caption="Modalidade";
      m_labels[10].caption="Lote";
      m_text[0].text_mode=true; m_text[0].max_length=48;
      m_text[1].max_length=10;
      m_text[2].max_length=16;
      for(int i=0;i<3;i++) m_text[i].SetValue(state.Value(TextId(i)));
      m_select[0].SetOptions("Forex|B3");
      m_select[1].SetOptions(GuiSetupTimeframeOptions());
      m_select[2].SetOptions("Compra e venda|Somente compra|Somente venda");
      m_select[3].SetOptions(GuiSetupTimeOptions());
      m_select[4].SetOptions(GuiSetupTimeOptions());
      m_select[5].SetOptions("Não encerrar|Encerrar no horário");
      m_select[6].SetOptions(GuiSetupTimeOptions());
      m_select[7].SetOptions("Day trade|Swing trade");
      for(int i=0;i<8;i++) m_select[i].SetSelected(state.Choice(SelectId(i)));
      UpdateCloseField();
      m_continue.caption="Continuar";
      m_continue.show_icon=true; m_continue.icon=GUI_ICON_ARROW_RIGHT; m_continue.icon_after=true;
      Status("Defina a identificação e as preferências do setup.");
      string error;
      if(!state.ValidateLot(state.lot,error)) Status(error,true);
     }
   void Place(CGuiLayout &layout)
     {
      m_cards[0]=layout.cards[0]; m_cards[1]=layout.cards[1];
      m_cards[2]=layout.schedule;
      m_status=layout.status; m_height=layout.height;
      for(int i=0;i<5;i++)
        {
         GuiRect c=m_cards[i<2 ? 0 : 1];
         int row=i<2 ? i : i-2;
         int y=c.y+78+row*76;
         m_labels[i].SetBounds(c.x+24,y-22,c.w-48,18);
         if(i<2) m_text[i].SetBounds(c.x+24,y,c.w-48,42);
         else m_select[i-2].SetBounds(c.x+24,y,c.w-48,42);
        }
      GuiRect market=m_cards[1];
      int market_width=(market.w-64)/2;
      if(market_width<130) market_width=80;
      int mode_x=market.x+24+market_width+16,mode_width=market.w-64-market_width;
      m_labels[2].SetBounds(market.x+24,market.y+56,market_width,18);
      m_select[0].SetBounds(market.x+24,market.y+78,market_width,42);
      m_labels[9].SetBounds(mode_x,market.y+56,mode_width,18);
      m_select[7].SetBounds(mode_x,market.y+78,mode_width,42);
      int operation_width=(market.w-64)/2;
      int lot_x=market.x+24+operation_width+16;
      m_labels[3].SetBounds(market.x+24,market.y+132,operation_width,18);
      m_select[1].SetBounds(market.x+24,market.y+154,operation_width,42);
      m_labels[10].SetBounds(lot_x,market.y+132,market.w-64-operation_width,18);
      m_text[2].SetBounds(lot_x,market.y+154,market.w-64-operation_width,42);
      GuiRect c=m_cards[2];
      int half=(c.w-64)/2;
      for(int id=5;id<=8;id++)
        {
         bool pair=id<7 || !layout.compact;
         int row=id<7 ? 0 : (layout.compact ? id-6 : 1);
         int col=id==6 || (!layout.compact && id==8) ? 1 : 0;
         int x=c.x+24+(pair ? col*(half+16) : 0),y=c.y+78+row*76;
         int w=pair ? half : c.w-48;
         m_labels[id].SetBounds(x,y-22,w,18);
         int text=TextIndex(id),select=SelectIndex(id);
         if(text>=0) m_text[text].SetBounds(x,y,w,42);
         else m_select[select].SetBounds(x,y,w,42);
        }
      GuiRect r=layout.apply; m_continue.SetBounds(r.x,r.y,r.w,r.h);
      m_dirty=true;
     }
   bool Dirty() { return m_dirty; }
   void CloseSelect()
     { if(m_open>=0) { m_select[m_open].Close(); m_open=-1; m_dirty=true; } }
   void ClearHover()
     {
      for(int i=0;i<3;i++) m_text[i].SetHover(false);
      for(int i=0;i<8;i++) m_select[i].SetHover(false);
      m_continue.SetHover(false); m_continue.active=false; m_dirty=true;
     }
   bool Finish(const bool save)
     {
      if(m_edit<0) return true;
      int index=m_edit;
      if(save)
        {
         if(index==2) RefreshVolumeLimits();
         string error;
         if(!state.CommitText(TextId(index),m_text[index].Buffer(),error))
           { m_text[index].invalid=true; m_text[index].dirty=true; Status(error,true); return false; }
         m_text[index].SetValue(state.Value(TextId(index)));
        }
      m_text[index].End(); m_edit=-1;
      Status(save ? "Configuração atualizada." : "Edição cancelada.");
      return true;
     }
   bool Ready()
     {
      RefreshVolumeLimits();
      if(!Finish(true)) return false;
      string error;
      if(!state.Validate(error)) { Status(error,true); return false; }
      CloseSelect(); return true;
     }
   bool Click(const int x,const int y)
     {
      if(m_open>=0)
        {
         if(m_select[m_open].HandlePopupClick(x,y)) { m_dirty=true; return false; }
         int option=m_select[m_open].OptionAt(x,y);
         if(option>=0) { SelectOption(option); return false; }
         bool same=m_select[m_open].ContainsPoint(x,y);
         CloseSelect(); if(same) return false;
        }
      int hit=-1;
      for(int i=0;i<3;i++) if(m_text[i].ContainsPoint(x,y)) hit=TextId(i);
      for(int i=0;i<8;i++) if(m_select[i].ContainsPoint(x,y)) hit=SelectId(i);
      if(m_edit>=0 && hit==TextId(m_edit)) return false;
      if(!Finish(true)) return false;
      if(hit>=0) Begin(hit);
      else if(m_continue.ContainsPoint(x,y)) { Focus(11); return Ready(); }
      return false;
     }
   void Mouse(const int x,const int y,const string flags)
     {
      bool overlay=m_open>=0 && m_select[m_open].popup.Contains(x,y);
      for(int i=0;i<3;i++) if(m_text[i].SetHover(!overlay && m_text[i].ContainsPoint(x,y))) m_dirty=true;
      for(int i=0;i<8;i++) if(m_select[i].SetHover(!overlay && m_select[i].ContainsPoint(x,y))) m_dirty=true;
      if(m_continue.SetHover(!overlay && m_continue.ContainsPoint(x,y))) m_dirty=true;
      bool down=(StringToInteger(flags)&1)!=0 && m_continue.hover;
      if(down!=m_continue.active) { m_continue.active=down; m_dirty=true; }
      if(m_open>=0)
        {
         int hot=m_select[m_open].OptionAt(x,y);
         if(hot!=m_select[m_open].hot) { m_select[m_open].hot=hot; m_dirty=true; }
        }
     }
   // Return 1 to advance, 2 to focus the shared Recolher button.
   int Key(const int key)
     {
      if(key==9)
        {
         if(!Finish(true)) return 0;
         if(m_open>=0) { int option=m_select[m_open].hot; if(option>=0) SelectOption(option); else CloseSelect(); }
         bool back=(TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT)&0x8000)!=0;
         int next=NextFocus(back);
         if(next<0) { Focus(-1); return 2; }
         Focus(next);
         int text=TextIndex(next);
         if(text>=0) { m_edit=text; m_text[text].Begin(); }
         return 0;
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
      if(m_focus<0) return 0;
      if(key==13 || key==32)
        { if(m_focus==11) return Ready() ? 1 : 0; Begin(m_focus); return 0; }
      if(TextIndex(m_focus)>=0 && FocusAvailable(m_focus))
        {
         // Ignore modifier keys until a printable/editing key arrives.
         if(key==16 || key==17 || key==18 || key==20) return 0;
         Begin(m_focus); if(m_text[m_edit].Key(key)) m_dirty=true;
        }
      else if(SelectIndex(m_focus)>=0 && (key==38 || key==40)) Begin(m_focus);
      return 0;
     }
   void EnterFocus(const bool last)
     {
      if(!Finish(true)) { Focus(TextId(m_edit)); return; }
      Focus(last ? 11 : 0);
      if(!last) { m_edit=0; m_text[0].Begin(); }
     }
   void Render(CGuiRenderer &r,const bool full)
     {
      if(!full && !m_dirty) return;
      for(int card=0;card<3;card++)
        {
         GuiRect c=m_cards[card]; r.Box(c,GUI_CARD,GUI_BORDER);
         r.Icon(card==0 ? GUI_ICON_REVIEW : (card==1 ? GUI_ICON_PARAMETERS : GUI_ICON_CLOCK),c.x+24,c.y+18,GUI_ACCENT,20);
         r.Text(c.x+52,c.y+20,card==0 ? "IDENTIFICAÇÃO" : (card==1 ? "MERCADO E OPERAÇÃO" : "HORÁRIOS"),GUI_TEXT,14,true,c.w-76);
        }
      for(int id=0;id<11;id++)
        {
         m_labels[id].Draw(r);
         int text=TextIndex(id),select=SelectIndex(id);
         if(text>=0) m_text[text].Draw(r); else m_select[select].Draw(r);
        }
      r.Text(m_cards[0].x+24,m_cards[0].y+211,"Magic Number identifica as ordens deste setup.",GUI_MUTED,12,false,m_cards[0].w-48);
      string lot_hint="Lote: mín. "+DoubleToString(state.volume_min,state.LotDigits())+" · Passo "+DoubleToString(state.volume_step,state.LotDigits());
      r.Text(m_cards[1].x+24,m_cards[1].y+m_cards[1].h-28,lot_hint,GUI_MUTED,11,false,m_cards[1].w-48);
      r.Text(m_cards[2].x+24,m_cards[2].y+m_cards[2].h-28,"Horário do servidor da corretora · HH:MM",GUI_MUTED,11,false,m_cards[2].w-48);
      r.Fill(m_status,GUI_BG);
      r.Text(m_status.x,m_status.y,m_message,m_error ? GUI_ERROR : GUI_MUTED,13,false,m_status.w);
      r.Text(m_status.x,m_status.y+24,"Próxima etapa: Indicadores",GUI_MUTED,11,false,m_status.w);
      m_continue.Draw(r);
      m_dirty=false;
     }
   void DrawOverlay(CGuiRenderer &r)
     { if(m_open>=0) { r.SaveOverlay(m_select[m_open].popup); m_select[m_open].DrawOverlay(r); } }
  };
#endif
