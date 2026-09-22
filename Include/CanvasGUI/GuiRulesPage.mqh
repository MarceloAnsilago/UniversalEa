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
   CGuiLabel m_labels[22];
   CGuiSelectBox m_select[10];
   CGuiTextField m_text[12];
   CGuiButton m_back,m_save,m_next;
   GuiRect m_cards[3],m_status,m_summary;
   int m_open,m_edit,m_focus,m_height;
   bool m_dirty,m_error,m_embedded;
   GuiRect m_embedded_bounds;
   string m_message;
   // IDs 5 a 9 pertencem somente ao painel condicional de ordens pendentes.
   bool Pending() { return m_embedded && state.order_mode==GUI_ORDER_PENDING; }
   // A pendente permite somente o preço da vela e seu índice.
   bool FieldVisible(const int id)
     {
      if(!m_embedded) return id>=0 && id<=6;
      if(id>=19 && id<=21) return true;
      if(id>=0 && id<=4) return true;
      if(id>=10 && id<=18)
        {
         if(state.candle_filter==GUI_CANDLE_DISABLED) return false;
         if(id==10 || id==18) return true;
         if(id==11 || id==12 || id==13) return state.candle_filter==GUI_CANDLE_SIZE;
         return state.candle_filter==GUI_CANDLE_WICKS;
        }
      if(id==6 || id==9) return Pending();
      return false;
     }
   int LastFocus() { return m_embedded ? 21 : 6; }
   // A unidade vem antes dos limites também na navegação por teclado.
   int NextFocus(const bool back)
     {
      if(!m_embedded) return m_focus<0 ? (back ? 6 : 0) : m_focus+(back ? -1 : 1);
      int order[]={0,1,2,19,20,21,3,4,6,9,10,11,18,12,13,14,15,16,17};
      int index=back ? ArraySize(order) : -1;
      for(int i=0;i<ArraySize(order);i++) if(order[i]==m_focus) { index=i; break; }
      for(index+=back ? -1 : 1;index>=0 && index<ArraySize(order);index+=back ? -1 : 1)
         if(FieldVisible(order[index])) return order[index];
      return -1;
     }
   int TextFieldId(const int index) { return index>=10 ? index+9 : (index>=4 ? index+8 : (index<2 ? index+2 : index+6)); }
   int SelectFieldId(const int index) { return index==9 ? 21 : (index==8 ? 18 : (index>=6 ? index+4 : (index==0 ? 0 : (index==1 ? 4 : (index==2 ? 1 : index+2))))); }
   void Status(const string message,const bool error=false)
     { m_message=message; m_error=error; m_dirty=true; }
   void Focus(const int id)
     {
      m_focus=id;
      for(int i=0;i<2;i++) { m_select[i].focused=id==i; m_text[i].focused=id==i+2; }
      m_select[2].focused=m_embedded && id==4;
      for(int i=3;i<6;i++) m_select[i].focused=Pending() && id==i+2;
      for(int i=2;i<4;i++) m_text[i].focused=Pending() && id==i+6;
      for(int i=6;i<8;i++) m_select[i].focused=m_embedded && id==i+4;
      for(int i=4;i<10;i++) m_text[i].focused=m_embedded && id==i+8;
      m_select[8].focused=m_embedded && id==18;
      m_select[9].focused=m_embedded && id==21;
      for(int i=10;i<12;i++) m_text[i].focused=m_embedded && id==TextFieldId(i);
      m_back.focused=!m_embedded && id==4; m_save.focused=!m_embedded && id==5; m_next.focused=!m_embedded && id==6; m_dirty=true;
     }
   void Begin(const int id)
     {
      if(!FieldVisible(id)) return;
      Focus(id);
      if(id>=0 && id<2) { m_select[id].Open(m_height,m_embedded ? 160 : 4); m_open=m_select[id].active ? id : -1; }
      else if(m_embedded && id==4) { m_select[2].Open(m_height,160); m_open=m_select[2].active ? 2 : -1; }
      else if(id>=2 && id<4) { m_edit=id-2; m_text[m_edit].Begin(); }
      else if(Pending() && id>=5 && id<=7) { m_select[id-2].Open(m_height,160); m_open=m_select[id-2].active ? id-2 : -1; }
      else if(Pending() && id>=8 && id<=9) { m_edit=id-6; m_text[m_edit].Begin(); }
      else if(m_embedded && id>=10 && id<=11) { m_select[id-4].Open(m_height,160); m_open=m_select[id-4].active ? id-4 : -1; }
      else if(m_embedded && id>=12 && id<=17) { m_edit=id-8; m_text[m_edit].Begin(); }
      else if(m_embedded && id==18) { m_select[8].Open(m_height,160); m_open=m_select[8].active ? 8 : -1; }
      if(m_embedded && id>=19 && id<=20) { m_edit=id-9; m_text[m_edit].Begin(); }
      if(m_embedded && id==21) { m_select[9].Open(m_height,160); m_open=m_select[9].active ? 9 : -1; }
      m_dirty=true;
     }
   void SelectOption(const int option)
     {
      if(m_open<0 || option<0) return;
      if(state.Choose(SelectFieldId(m_open),option)) { m_select[m_open].SetSelected(option); Status("Configuração alterada. Salve para registrar."); }
      UpdateTargets();
      CloseSelect();
     }
   void UpdateTargets()
     {
      m_labels[2].caption="Stop loss ("+state.Unit()+")";
      m_labels[3].caption="Take profit ("+state.Unit()+")";
      for(int i=0;i<2;i++) m_text[i].SetValue(state.Value(i+2));
      for(int i=2;i<12;i++) m_text[i].SetValue(state.Value(TextFieldId(i)));
      for(int i=6;i<10;i++) m_select[i].SetSelected(state.Choice(SelectFieldId(i)));
      m_dirty=true;
     }
public:
   CGuiRulesState state;
   void ReplaceState(CGuiRulesState &loaded)
     {
      Finish(false); CloseSelect(); state=loaded;
      for(int i=0;i<2;i++) m_select[i].SetSelected(state.Choice(i==1 ? 4 : 0));
      m_select[2].SetSelected(state.Choice(1));
      for(int i=3;i<6;i++) m_select[i].SetSelected(state.Choice(SelectFieldId(i)));
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
      m_labels[4].caption="Condição";
      m_select[2].SetOptions("Desativado|Candles|Pavios");
      m_select[2].SetSelected(state.Choice(1));
      for(int i=0;i<2;i++) { m_select[i].SetSelected(state.Choice(i==1 ? 4 : 0)); m_text[i].SetValue(state.Value(i+2)); }
      // Índice 3 reservado: antigo seletor Stop/Limit removido da interface.
      m_labels[6].caption="Posicionar em"; m_select[4].SetOptions("Máxima|Mínima|Abertura|Fechamento");
      m_labels[9].caption="Vela (1 = última fechada)";
      for(int i=3;i<6;i++) m_select[i].SetSelected(state.Choice(SelectFieldId(i)));
      m_labels[10].caption="Configurar candle"; m_select[6].SetOptions("Candle 1 (último fechado)|Candle 2|Candle 3");
      m_labels[11].caption="Medir tamanho do candle"; m_select[7].SetOptions("Corpo|Total (máxima − mínima)");
      string captions[]={"Candle: mín.","Candle: máx.","Pavio sup.: mín.","Pavio sup.: máx.","Pavio inf.: mín.","Pavio inf.: máx."};
      for(int i=0;i<6;i++) m_labels[i+12].caption=captions[i];
      m_labels[18].caption="Unidade dos tamanhos"; m_select[8].SetOptions("Pontos|Porcentagem");
      m_labels[19].caption="+ Vezes"; m_labels[20].caption="Candle";
      m_labels[21].caption="Tamanho do candle"; m_select[9].SetOptions("Total (com pavios)|Corpo");
      UpdateTargets();
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
      if(!FieldVisible(m_focus)) return false;
      if(!m_embedded && m_focus>=4)
        {
         if(m_focus==4) r=m_back.bounds; else if(m_focus==5) r=m_save.bounds; else r=m_next.bounds;
         return true;
        }
      if(m_focus==21) { r=m_select[9].bounds; return true; }
      if(m_focus==19 || m_focus==20) { r=m_text[m_focus-9].bounds; return true; }
      if(m_focus==18) { r=m_select[8].bounds; return true; }
      if(m_focus>=12) { r=m_text[m_focus-8].bounds; return true; }
      if(m_focus>=10) { r=m_select[m_focus-4].bounds; return true; }
      if(m_focus>=8) { r=m_text[m_focus-6].bounds; return true; }
      if(m_focus>=5) { r=m_select[m_focus-2].bounds; return true; }
      if(m_focus==4) r=m_select[2].bounds; else if(m_focus<2) r=m_select[m_focus].bounds; else r=m_text[m_focus-2].bounds;
      return true;
     }
   void PlaceEmbedded(CGuiLayout &layout)
     {
      m_embedded=true; m_embedded_bounds=layout.indicator_rules; m_height=layout.height;
      GuiRect c=m_embedded_bounds;
      if(c.w>=760)
        {
         int cw=(c.w-32)/3;
         m_cards[0].Set(c.x,c.y+40,cw,312);
         m_cards[2].Set(c.x+cw+16,c.y+40,cw,312);
         m_cards[1].Set(c.x+2*(cw+16),c.y+40,c.w-2*(cw+16),312);
        }
      else
        {
         int cw=(c.w-16)/2;
         m_cards[0].Set(c.x,c.y+40,cw,180);
         m_cards[2].Set(c.x+cw+16,c.y+40,c.w-cw-16,180);
         m_cards[1].Set(c.x,c.y+236,c.w,312);
        }
      // Expande o próprio card Ordem; em telas estreitas, desloca os alvos para baixo.
      if(Pending())
        {
         m_cards[0].h=312;
         if(c.w<760) m_cards[1].y=m_cards[0].y+m_cards[0].h+16;
        }
      // O filtro recebe linhas próprias para não comprimir os seis limites.
      m_cards[2].h=layout.FilterHeight((int)state.candle_filter);
      if(c.w<760)
        {
         m_cards[0].w=c.w;
         m_cards[2].Set(c.x,m_cards[0].y+m_cards[0].h+16,c.w,layout.FilterHeight((int)state.candle_filter));
         m_cards[1].y=m_cards[2].y+m_cards[2].h+16;
        }
      m_cards[1].h=464;
      for(int id=0;id<4;id++)
        {
         GuiRect card=m_cards[id==0 ? 0 : 1];
         int x=card.x+24,y=card.y+78+(id==0 ? 0 : (id==3 ? 4 : id-1))*76,width=card.w-48;
         m_labels[id].SetBounds(x,y-22,width,18);
         if(id<2) m_select[id].SetBounds(x,y,width,42);
         else m_text[id-2].SetBounds(x,y,width,42);
        }
      GuiRect target=m_cards[1];
      int half=(target.w-64)/2;
      for(int i=0;i<2;i++)
        {
         int x=target.x+24+i*(half+16),y=target.y+230;
         m_labels[19+i].SetBounds(x,y-22,half,18);
         m_text[10+i].SetBounds(x,y,half,42);
        }
      m_labels[21].SetBounds(target.x+24,target.y+284,target.w-48,18);
      m_select[9].SetBounds(target.x+24,target.y+306,target.w-48,42);
      m_labels[4].SetBounds(m_cards[2].x+24,m_cards[2].y+56,m_cards[2].w-48,18);
      m_select[2].SetBounds(m_cards[2].x+24,m_cards[2].y+78,m_cards[2].w-48,42);
      GuiRect filter=m_cards[2];
      for(int id=10;id<=17;id++)
        {
         bool pair=id>=12;
         int row=pair ? (state.candle_filter==GUI_CANDLE_SIZE ? 4 : 3+(id-14)/2) : id-9;
         int width=pair ? (filter.w-64)/2 : filter.w-48;
         int x=filter.x+24+(pair ? (id%2)*(width+16) : 0),y=filter.y+78+row*76;
         m_labels[id].SetBounds(x,y-22,width,18);
         if(pair) m_text[id-8].SetBounds(x,y,width,42);
         else m_select[id-4].SetBounds(x,y,width,42);
        }
      int unit_y=filter.y+(state.candle_filter==GUI_CANDLE_SIZE ? 306 : 230);
      m_labels[18].SetBounds(filter.x+24,unit_y-22,filter.w-48,18);
      m_select[8].SetBounds(filter.x+24,unit_y,filter.w-48,42);
      // Ordem visual: tipo de ordem, referência e vela.
      int ids[]={6,9};
      for(int i=0;i<2;i++)
        {
         int id=ids[i],x=m_cards[0].x+24,y=m_cards[0].y+154+i*76,width=m_cards[0].w-48;
         m_labels[id].SetBounds(x,y-22,width,18);
         if(id<=7) m_select[id-2].SetBounds(x,y,width,42);
         else m_text[id-6].SetBounds(x,y,width,42);
        }
      m_dirty=true;
     }
   void RenderEmbedded(CGuiRenderer &r,const bool full)
     {
      if(!full && !m_dirty) return;
      GuiRect c=m_embedded_bounds;
      r.Icon(GUI_ICON_RULES,c.x,c.y+4,GUI_ACCENT,20);
      r.Text(c.x+28,c.y+6,"REGRAS DE ENTRADA E SAÍDA",GUI_TEXT,14,true,c.w-28);
      for(int i=0;i<3;i++)
        {
         GuiRect card=m_cards[i]; r.Box(card,GUI_CARD,GUI_BORDER);
         r.Icon(i==0 ? GUI_ICON_RULES : (i==1 ? GUI_ICON_MANAGEMENT : GUI_ICON_FILTERS),card.x+24,card.y+18,GUI_ACCENT,20);
         r.Text(card.x+52,card.y+20,i==0 ? "ORDEM" : (i==1 ? "ALVOS" : "FILTRO DE CANDLE"),GUI_TEXT,14,true,card.w-76);
        }
      for(int id=0;id<4;id++) { m_labels[id].Draw(r); if(id<2) m_select[id].Draw(r); else m_text[id-2].Draw(r); }
      for(int i=0;i<2;i++) { m_labels[19+i].Draw(r); m_text[10+i].Draw(r); }
      m_labels[21].Draw(r); m_select[9].Draw(r);
      m_labels[4].Draw(r); m_select[2].Draw(r);
      for(int id=6;id<=9;id++)
        if(FieldVisible(id)) { m_labels[id].Draw(r); if(id<=7) m_select[id-2].Draw(r); else m_text[id-6].Draw(r); }
      for(int id=10;id<=17;id++) if(FieldVisible(id)) { m_labels[id].Draw(r); if(id<12) m_select[id-4].Draw(r); else m_text[id-8].Draw(r); }
      if(FieldVisible(18))
        {
         m_labels[18].Draw(r); m_select[8].Draw(r);
         r.Text(m_cards[2].x+24,m_cards[2].y+m_cards[2].h-48,state.CandleUnit()=="%" ? "100% = máxima − mínima" : "Tamanhos em pontos do símbolo",GUI_MUTED,11,false,m_cards[2].w-48);
         r.Text(m_cards[2].x+24,m_cards[2].y+m_cards[2].h-28,"Em "+state.CandleUnit()+" · 0 = sem restrição",GUI_MUTED,11,false,m_cards[2].w-48);
        }
      r.Text(c.x+24,c.y+c.h-28,m_error ? m_message : "Stop = distância + vezes o candle. 1 = último fechado. Stop desligado: distância e vezes = 0.",m_error ? GUI_ERROR : GUI_MUTED,12,false,c.w-48);
      m_dirty=false;
     }
   void CloseSelect() { if(m_open>=0) { m_select[m_open].Close(); m_open=-1; m_dirty=true; } }
   void ClearHover()
     {
      for(int i=0;i<2;i++) { m_select[i].SetHover(false); m_text[i].SetHover(false); }
      for(int i=2;i<10;i++) m_select[i].SetHover(false);
      for(int i=2;i<12;i++) m_text[i].SetHover(false);
      m_next.SetHover(false); m_next.active=false;
      m_back.SetHover(false); m_save.SetHover(false); m_back.active=false; m_save.active=false; m_dirty=true;
     }
   bool Finish(const bool save)
     {
      if(m_edit<0) return true;
      if(save)
        {
         string error;
         if(!state.Commit(TextFieldId(m_edit),m_text[m_edit].Buffer(),error))
           { m_text[m_edit].invalid=true; Status(error,true); return false; }
         m_text[m_edit].SetValue(state.Value(TextFieldId(m_edit)));
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
      if(m_embedded && m_select[2].ContainsPoint(x,y)) hit=4;
      if(Pending())
        {
         for(int i=3;i<6;i++) if(FieldVisible(i+2) && m_select[i].ContainsPoint(x,y)) hit=i+2;
         for(int i=2;i<4;i++) if(FieldVisible(i+6) && m_text[i].ContainsPoint(x,y)) hit=i+6;
        }
      if(m_embedded)
        {
         for(int i=6;i<10;i++) if(FieldVisible(SelectFieldId(i)) && m_select[i].ContainsPoint(x,y)) hit=SelectFieldId(i);
         for(int i=4;i<12;i++) if(FieldVisible(TextFieldId(i)) && m_text[i].ContainsPoint(x,y)) hit=TextFieldId(i);
        }
      if(m_edit>=0 && hit==TextFieldId(m_edit)) return 0;
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
      if(m_embedded && m_select[2].SetHover(!overlay && m_select[2].ContainsPoint(x,y))) m_dirty=true;
      if(Pending())
        {
         for(int i=3;i<6;i++) if(m_select[i].SetHover(FieldVisible(i+2) && !overlay && m_select[i].ContainsPoint(x,y))) m_dirty=true;
         for(int i=2;i<4;i++) if(m_text[i].SetHover(FieldVisible(i+6) && !overlay && m_text[i].ContainsPoint(x,y))) m_dirty=true;
        }
      if(m_embedded)
        {
         for(int i=6;i<10;i++) if(m_select[i].SetHover(FieldVisible(SelectFieldId(i)) && !overlay && m_select[i].ContainsPoint(x,y))) m_dirty=true;
         for(int i=4;i<12;i++) if(m_text[i].SetHover(FieldVisible(TextFieldId(i)) && !overlay && m_text[i].ContainsPoint(x,y))) m_dirty=true;
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
         int next=NextFocus(back);
         while(next>=0 && next<=LastFocus() && !FieldVisible(next)) next+=back ? -1 : 1;
         if(next<0 || next>LastFocus()) { Focus(-1); return 3; }
         Focus(next); if((next>=2 && next<4) || (Pending() && next==9) || (m_embedded && ((next>=12 && next<=17) || next==19 || next==20))) Begin(next); return 0;
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
         if(!m_embedded && m_focus==4) return Ready() ? 2 : 0;
         if(!m_embedded && m_focus==5) return Ready() ? 1 : 0;
         if(!m_embedded && m_focus==6) return Ready() ? 4 : 0;
         Begin(m_focus); return 0;
        }
      if(((m_focus>=0 && m_focus<2) || (m_embedded && m_focus==4) || (Pending() && m_focus>=5 && m_focus<=7) || (m_embedded && m_focus>=10 && m_focus<=11) || (m_embedded && (m_focus==18 || m_focus==21))) && (key==38 || key==40)) Begin(m_focus);
      else if(((m_focus>=2 && m_focus<4) || (Pending() && m_focus>=8 && m_focus<=9) || (m_embedded && ((m_focus>=12 && m_focus<=17) || m_focus==19 || m_focus==20))) && ((key>=48 && key<=57) || (key>=96 && key<=105) || key==8 || key==46 || key==189 || key==109 || key==190 || key==188 || key==110))
        { Begin(m_focus); m_text[m_edit].Key(key); m_dirty=true; }
      return 0;
     }
   void EnterFocus(const bool last)
     {
      if(!last) { Focus(0); return; }
      Focus(-1); Focus(NextFocus(true));
     }
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
      r.Text(m_summary.x+24,m_summary.y+76,"Stop loss: "+state.StopSummary()+"   ·   Take profit: "+(state.take_profit==0 ? "Desativado" : state.Value(3)+" "+state.Unit()),GUI_MUTED,13,false,m_summary.w-48);
      r.Fill(m_status,GUI_BG);
      r.Text(m_status.x,m_status.y,m_message,m_error ? GUI_ERROR : GUI_MUTED,13,false,m_status.w);
      r.Text(m_status.x,m_status.y+22,"Próxima etapa: Gestão",GUI_MUTED,11,false,m_status.w);
      m_back.Draw(r); m_save.Draw(r); m_next.Draw(r); m_dirty=false;
     }
   void DrawOverlay(CGuiRenderer &r) { if(m_open>=0) { r.SaveOverlay(m_select[m_open].popup); m_select[m_open].DrawOverlay(r); } }
  };
#endif
