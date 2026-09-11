#ifndef CANVAS_GUI_RENDERER_MQH
#define CANVAS_GUI_RENDERER_MQH
#include <Canvas/Canvas.mqh>
#include "GuiTheme.mqh"
#include "GuiIcons.mqh"
class CGuiRenderer
  {
private:
   CCanvas m_canvas;
   uint m_overlay_pixels[];
   GuiRect m_overlay_rect;
   bool m_overlay_saved;
public:
   CGuiRenderer() { m_overlay_saved=false; }
   bool Create(const long chart,const string name,const int w,const int h)
     {
      if(!m_canvas.CreateBitmapLabel(chart,0,name,0,0,w,h,COLOR_FORMAT_XRGB_NOALPHA)) return false;
      ObjectSetInteger(chart,name,OBJPROP_BACK,false);
      ObjectSetInteger(chart,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(chart,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(chart,name,OBJPROP_ZORDER,100);
      ObjectSetString(chart,name,OBJPROP_TOOLTIP,"\n");
      return true;
     }
   void Destroy() { m_canvas.Destroy(); }
   bool Resize(const int w,const int h) { m_overlay_saved=false; return m_canvas.Resize(w,h); }
   void RestoreOverlay()
     {
      if(!m_overlay_saved) return;
      m_canvas.BitBlt(m_overlay_rect.x,m_overlay_rect.y,m_overlay_pixels,m_overlay_rect.w,m_overlay_rect.h,0,0,m_overlay_rect.w,m_overlay_rect.h);
      m_overlay_saved=false;
     }
   void SaveOverlay(const GuiRect &rect)
     {
      m_overlay_rect.Set(rect.x,rect.y,(int)MathMin(rect.w+4,m_canvas.Width()-rect.x),(int)MathMin(rect.h+4,m_canvas.Height()-rect.y));
      int n=m_overlay_rect.w*m_overlay_rect.h;
      if(ArrayResize(m_overlay_pixels,n)!=n) return;
      for(int y=0;y<m_overlay_rect.h;y++)
         for(int x=0;x<m_overlay_rect.w;x++) m_overlay_pixels[y*m_overlay_rect.w+x]=m_canvas.PixelGet(m_overlay_rect.x+x,m_overlay_rect.y+y);
      m_overlay_saved=true;
     }
   void Clear() { m_canvas.Erase(GUI_BG); }
   void Present() { m_canvas.Update(true); }
   void Fill(const GuiRect &r,const uint c) { m_canvas.FillRectangle(r.x,r.y,r.x+r.w-1,r.y+r.h-1,c); }
   void Round(const GuiRect &r,const uint c,const int radius=7)
     {
      int k=(int)MathMin(radius,MathMin(r.w/2,r.h/2));
      if(k<=0) return;
      m_canvas.FillRectangle(r.x+k,r.y,r.x+r.w-k-1,r.y+r.h-1,c);
      m_canvas.FillRectangle(r.x,r.y+k,r.x+r.w-1,r.y+r.h-k-1,c);
      m_canvas.FillCircle(r.x+k,r.y+k,k,c);
      m_canvas.FillCircle(r.x+r.w-k-1,r.y+k,k,c);
      m_canvas.FillCircle(r.x+k,r.y+r.h-k-1,k,c);
      m_canvas.FillCircle(r.x+r.w-k-1,r.y+r.h-k-1,k,c);
     }
   void Box(const GuiRect &r,const uint bg,const uint border)
     { Round(r,border); GuiRect inner; inner.Set(r.x+1,r.y+1,r.w-2,r.h-2); Round(inner,bg,6); }
   void Text(const int x,const int y,string value,const uint c=GUI_TEXT,const int size=15,const bool bold=false,const int max_width=0)
     {
      m_canvas.FontSet("Segoe UI",size,bold ? FW_BOLD : FW_NORMAL);
      if(max_width>0 && m_canvas.TextWidth(value)>max_width)
        {
         while(StringLen(value)>0 && m_canvas.TextWidth(value+"...")>max_width) value=StringSubstr(value,0,StringLen(value)-1);
         value+="...";
        }
      m_canvas.TextOut(x,y,value,c);
     }
   string EditViewport(string value,const int cursor,const int max_width)
     {
      m_canvas.FontSet("Segoe UI",15,FW_NORMAL);
      int start=0;
      while(start<cursor && m_canvas.TextWidth(StringSubstr(value,start,cursor-start+1))>max_width) start++;
      return StringSubstr(value,start);
     }
   void Icon(const ENUM_GUI_ICON icon,const int x,const int y,const uint ink=GUI_ACCENT,const int size=20)
     { GuiDrawIcon(m_canvas,icon,x,y,size,ink); }
   void FocusOutline(const GuiRect &r,const uint c)
     { m_canvas.Rectangle(r.x+3,r.y+3,r.x+r.w-4,r.y+r.h-4,c); }
   void Chevron(const int x,const int y,const uint c)
     { m_canvas.Line(x-4,y-2,x,y+2,c); m_canvas.Line(x,y+2,x+4,y-2,c); }
  };
#endif
