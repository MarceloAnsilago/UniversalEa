#ifndef CANVAS_GUI_BUTTON_MQH
#define CANVAS_GUI_BUTTON_MQH
#include "GuiControl.mqh"
class CGuiButton : public CGuiControl
  {
public:
   bool secondary;
   bool show_icon,icon_after;
   ENUM_GUI_ICON icon;
   CGuiButton() { secondary=false; show_icon=false; icon_after=false; icon=GUI_ICON_ARROW_RIGHT; }
   virtual void Draw(CGuiRenderer &r)
     {
      if(visible)
        {
         uint bg=!enabled ? GUI_BORDER_DISABLED : (active ? 0xFF163C99 : (hover ? 0xFF1D4ED8 : GUI_ACCENT));
         if(secondary) r.Box(bounds,hover && enabled ? GUI_HOVER : GUI_CARD,GUI_BORDER);
         else r.Round(bounds,bg);
         if(focused) r.FocusOutline(bounds,secondary ? GUI_ACCENT : GUI_CARD);
         uint ink=!enabled ? GUI_MUTED : (secondary ? GUI_TEXT : GUI_CARD);
         int text_x=bounds.x+24;
         int text_width=bounds.w-36;
         if(show_icon)
           {
            r.Icon(icon,icon_after ? bounds.x+bounds.w-36 : bounds.x+20,bounds.y+(bounds.h-20)/2,ink,20);
            if(!icon_after) text_x+=24;
            text_width-=32;
           }
         r.Text(text_x,bounds.y+(bounds.h-18)/2,caption,ink,14,true,text_width);
        }
      dirty=false;
     }
  };
#endif
