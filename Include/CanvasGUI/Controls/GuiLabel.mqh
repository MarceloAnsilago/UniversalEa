#ifndef CANVAS_GUI_LABEL_MQH
#define CANVAS_GUI_LABEL_MQH
#include "GuiControl.mqh"
class CGuiLabel : public CGuiControl
  {
public:
   virtual void Draw(CGuiRenderer &r)
     { if(visible) r.Text(bounds.x,bounds.y,caption,enabled ? GUI_MUTED : GUI_BORDER_DISABLED,13,false,bounds.w); dirty=false; }
  };
#endif
