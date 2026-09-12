#ifndef GUI_SCROLL_BAR_MQH
#define GUI_SCROLL_BAR_MQH
#include "GuiTheme.mqh"
class CGuiScrollBar
  {
public:
   GuiRect track,thumb;
   int offset,maximum,viewport;
   CGuiScrollBar() { offset=0; maximum=0; viewport=1; }
   void Configure(const int x,const int height,const int bottom)
     {
      viewport=(int)MathMax(1,height-160);
      maximum=(int)MathMax(0,bottom-height+8);
      track.Set(x,176,12,(int)MathMax(32,height-192));
      Set(offset);
     }
   bool Set(const int value)
     {
      int previous=offset;
      offset=(int)MathMax(0,MathMin(value,maximum));
      int size=maximum==0 ? track.h : (int)MathMax(32,(double)track.h*viewport/(viewport+maximum));
      int y=track.y+(maximum>0 ? (int)((double)(track.h-size)*offset/maximum) : 0);
      thumb.Set(track.x,y,track.w,size);
      return previous!=offset;
     }
   int DragOffset(const int y,const int grab)
     {
      int travel=track.h-thumb.h;
      if(travel<=0) return 0;
      return (int)MathRound((double)(y-grab-track.y)*maximum/travel);
     }
  };
#endif
