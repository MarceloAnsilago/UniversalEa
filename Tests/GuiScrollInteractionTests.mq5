#property strict
// Test-only visibility: exercise the real event routing and Canvas renderer.
#define private public
#include "../Include/CanvasGUI/GuiApp.mqh"
#undef private
int checks=0,failures=0;
void Check(const bool ok,const string label)
  { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   CGuiApp gui;
   if(!gui.Create(ChartID(),false)) { Print("FAIL: GUI creation"); return; }
   gui.m_step=1; gui.m_renderer.Resize(1792,733); gui.m_layout.Calculate(1792,733);
   gui.Reflow(); gui.Render();
   Check(!gui.m_layout.too_small && gui.m_scroll.maximum>0,"Content taller than viewport enables scrolling");
   Check(gui.m_scroll.track.x>gui.m_layout.left+gui.m_layout.content_width,"Scrollbar is right of the content");
   ResourceSave(gui.m_renderer.m_canvas.ResourceName(),"scroll-top.bmp");
   GuiRect field=gui.m_fields[0].select.bounds;
   gui.Click(field.x+20,field.y+20); gui.Key(40); gui.Key(13); gui.Render();
   Check(gui.m_state.indicators[0].type==GUI_INDICATOR_MA,"Indicator selection through real controls");
   Check(gui.m_layout.cards[1].y==gui.m_layout.cards[0].y && gui.m_layout.cards[1].x>gui.m_layout.cards[0].x+gui.m_layout.cards[0].w &&
         gui.m_layout.cards[1].w==gui.m_layout.cards[0].w,"Indicator cards remain side by side");
   ResourceSave(gui.m_renderer.m_canvas.ResourceName(),"scroll-parameters.bmp");
   Check(gui.FieldVisible(5) && gui.m_fields[5].field==GUI_MA_SLOPE_BARS,"Slope field visible for MA");
   Check(gui.m_fields[5].edit.bounds.y+gui.m_fields[5].edit.bounds.h<=gui.m_layout.cards[1].y+gui.m_layout.cards[1].h,
         "Slope field stays inside expanded card");
   gui.SetFocus(8); gui.TabFocus(false);
   Check(gui.m_focus==9 && gui.m_edit==5,"Tab reaches slope after shift");
   gui.FinishEdit(false);
   gui.TabFocus(false);
   Check(gui.m_rules_focus,"Tab leaves slope for rules");
   gui.m_rules.LeaveFocus(); gui.m_rules_focus=false; gui.SetFocus(-1);
   gui.ScrollTo(0);
   long wheel_position=0; double wheel_delta=-120; string wheel_text="";
   gui.Event(CHARTEVENT_MOUSE_WHEEL,wheel_position,wheel_delta,wheel_text);
   Check(gui.m_scroll.offset==64,"Wheel scrolls content");
   gui.ScrollTo(100000); gui.Render();
   Check(gui.m_scroll.offset==gui.m_scroll.maximum && gui.m_layout.status.y+gui.m_layout.status.h<=733,"Bottom including footer is reachable");
   ResourceSave(gui.m_renderer.m_canvas.ResourceName(),"scroll-bottom.bmp");
   gui.ScrollTo(gui.m_layout.indicator_rules.y+gui.m_scroll.offset-176); gui.Render();
   Check(gui.m_rules.m_cards[0].y>=160 && gui.m_rules.m_cards[1].y+gui.m_rules.m_cards[1].h<=733,"Former rules page is fully visible after scrolling");
   ResourceSave(gui.m_renderer.m_canvas.ResourceName(),"scroll-rules.bmp");
   GuiRect candle=gui.m_rules.m_select[2].bounds;
   gui.Click(candle.x+10,candle.y+10); gui.Key(40); gui.Key(13);
   Check(gui.m_rules.state.candle_filter==GUI_CANDLE_BULLISH,"Candle filter in second section remains interactive");
   gui.ScrollTo(0);
   GuiRect thumb=gui.m_scroll.thumb;
   gui.Mouse(thumb.x+5,thumb.y+5,"1");
   gui.Mouse(thumb.x+5,gui.m_scroll.track.y+gui.m_scroll.track.h,"1");
   gui.Mouse(thumb.x+5,gui.m_scroll.track.y+gui.m_scroll.track.h,"0");
   Check(gui.m_scroll.offset==gui.m_scroll.maximum && !gui.m_scroll_drag,"Dragging reaches bottom and releases");
   gui.ScrollTo(0); gui.m_rules_focus=true; gui.m_rules.Focus(3); gui.RevealFocus();
   GuiRect focused; gui.m_rules.FocusBounds(focused);
   Check(focused.y>=160 && focused.y+focused.h<=733,"Keyboard focus reveals offscreen rule field");
   gui.m_rules.Click(focused.x+10,focused.y+10); gui.m_rules.Key(49);
   string pending=gui.m_rules.m_text[1].Buffer();
   gui.ScrollTo(0);
   Check(gui.m_rules.m_text[1].Buffer()==pending && gui.m_rules.m_edit==1,"Scrolling preserves uncommitted edit");
   gui.m_rules.Finish(false);
   gui.ScrollTo(-100); Check(gui.m_scroll.offset==0,"Scroll clamps at top");
   // A expansão deve ser causada pela seleção real, mantendo o rodapé acessível.
   int market_height=gui.m_layout.indicator_rules.h;
   gui.m_rules_focus=true; gui.m_rules.Focus(0); gui.RevealFocus();
   gui.m_rules.Begin(0); gui.m_rules.SelectOption(1); gui.m_dirty=true; gui.Render();
   Check(gui.m_rules.Pending() && gui.m_rules.FieldVisible(6) && gui.m_rules.FieldVisible(9) && !gui.m_rules.FieldVisible(8),"OHLC: referencia e vela, sem distancia");
   gui.m_rules.Focus(6); gui.RevealFocus(); gui.m_rules.Key(13);
   Check(gui.m_rules.m_open==4,"Seletor acessivel por teclado");
   gui.m_rules.SelectOption(1);
   gui.m_dirty=true; gui.Render();
   Check(!gui.m_rules.FieldVisible(7) && !gui.m_rules.FieldVisible(8),"Campos de distancia removidos");
   Check(!gui.m_rules.state.Choose(6,4),"Opcao distancia rejeitada");
   gui.m_rules.Focus(9); gui.RevealFocus();
   gui.m_rules.Begin(9); gui.m_rules.Key(51); gui.m_rules.Key(13);
   Check(gui.m_rules.state.pending_bar==3,"Editar vela pelo controle real");
   gui.m_dirty=true; gui.Render();
   Check(gui.m_rules.state.pending_reference==1 && !gui.m_rules.FieldVisible(8) && gui.m_rules.FieldVisible(9),"Minima oculta distancia e mantem vela");
   gui.m_rules.Focus(6); gui.m_rules.Key(9);
   Check(gui.m_rules.m_focus==9,"Tab ignora campos ocultos");
   gui.m_rules.Finish(false);
   gui.m_rules.Focus(0); gui.RevealFocus();
   gui.m_rules.Begin(0); gui.m_rules.SelectOption(0); gui.m_dirty=true; gui.Render();
   Check(!gui.m_rules.Pending() && gui.m_layout.indicator_rules.h==market_height && gui.m_rules.state.pending_bar==3,"Mercado recolhe painel e preserva configuração pendente");
   gui.Destroy();
   PrintFormat("[GuiScrollInteractionTests] %d checks, %d failures",checks,failures);
  }
