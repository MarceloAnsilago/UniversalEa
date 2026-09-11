#ifndef CANVAS_GUI_FIELD_MQH
#define CANVAS_GUI_FIELD_MQH
#include "GuiLabel.mqh"
#include "GuiTextField.mqh"
#include "GuiSelectBox.mqh"
#include "../GuiState.mqh"
// Binding adapter: controls cache presentation only; CGuiState owns configuration.
class CGuiField
  {
public:
   int card;
   ENUM_GUI_FIELD field;
   bool is_select;
   CGuiLabel label;
   CGuiTextField edit;
   CGuiSelectBox select;
   void Bind(CGuiState &state,const int owner,const ENUM_GUI_FIELD key,const string title,const GuiRect &bounds,const string options="")
     {
      card=owner; field=key; is_select=(options!="");
      label.caption=title; label.SetBounds(bounds.x,bounds.y-22,bounds.w,18);
      select.Close(); edit.End(); select.SetHover(false); edit.SetHover(false);
      select.SetBounds(bounds.x,bounds.y,bounds.w,bounds.h); edit.SetBounds(bounds.x,bounds.y,bounds.w,bounds.h);
      if(is_select) { select.SetOptions(options); select.SetSelected(state.Choice(card,field)); }
      else edit.SetValue(state.Value(card,field));
     }
   bool ContainsPoint(const int x,const int y) { return is_select ? select.ContainsPoint(x,y) : edit.ContainsPoint(x,y); }
   bool Hover(const bool value) { return is_select ? select.SetHover(value) : edit.SetHover(value); }
   void Draw(CGuiRenderer &r,const bool all)
     {
      if(all) label.Draw(r);
      if(is_select) { if(all || select.dirty) select.Draw(r); }
      else if(all || edit.dirty) edit.Draw(r);
     }
  };
#endif
