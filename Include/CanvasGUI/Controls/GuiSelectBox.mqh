#ifndef CANVAS_GUI_SELECT_MQH
#define CANVAS_GUI_SELECT_MQH
#include "GuiControl.mqh"
class CGuiSelectBox : public CGuiControl
  {
private:
   string m_options[];
   int m_first_visible,m_visible_count,m_scroll_height;
   void EnsureHotVisible()
     {
      if(m_visible_count<1) return;
      if(hot>=0 && hot<m_first_visible) m_first_visible=hot;
      else if(hot>=m_first_visible+m_visible_count) m_first_visible=hot-m_visible_count+1;
      m_first_visible=(int)MathMax(0,MathMin(m_first_visible,ArraySize(m_options)-m_visible_count));
     }
   void ScrollPage(const int direction)
     {
      int old_first=m_first_visible;
      m_first_visible=(int)MathMax(0,MathMin(m_first_visible+direction*m_visible_count,
                                          ArraySize(m_options)-m_visible_count));
      int current_hot=hot>=old_first && hot<old_first+m_visible_count ? hot : old_first;
      hot=current_hot+m_first_visible-old_first;
      dirty=true;
     }
public:
   int selected,hot,row_height;
   bool indicator_icons;
   GuiRect popup;
   CGuiSelectBox()
     { selected=0; hot=-1; row_height=30; indicator_icons=false; m_first_visible=0; m_visible_count=0; m_scroll_height=0; popup.Set(0,0,0,0); }
   void SetOptions(const string values) { StringSplit(values,'|',m_options); dirty=true; }
   void SetSelected(const int index) { selected=index; dirty=true; }
   void Open(const int screen_height)
     {
      Close();
      int count=ArraySize(m_options),available=screen_height-12;
      if(!visible || !enabled || count<1 || available<38) return;
      row_height=30;
      m_scroll_height=count>8 || count*row_height+8>available ? 24 : 0;
      m_visible_count=(int)MathMin(count,MathMin(8,(available-8-2*m_scroll_height)/row_height));
      if(m_visible_count<1) return;
      active=true; hot=(int)MathMax(0,MathMin(selected,count-1));
      m_first_visible=0; EnsureHotVisible();
      int h=m_visible_count*row_height+8+2*m_scroll_height;
      int y=bounds.y+bounds.h+4;
      if(y+h>screen_height-8) y=bounds.y-h-4;
      popup.Set(bounds.x,(int)MathMax(4,MathMin(y,screen_height-h-8)),bounds.w,h);
     }
   void Close() { active=false; hot=-1; dirty=true; }
   int OptionAt(const int x,const int y) const
     {
      int top=popup.y+4+m_scroll_height;
      if(!active || x<popup.x+4 || x>=popup.x+popup.w-4 || y<top || y>=top+m_visible_count*row_height) return -1;
      return m_first_visible+(y-top)/row_height;
     }
   // Navigation bands belong to the popup; clicking them never commits a value.
   bool HandlePopupClick(const int x,const int y)
     {
      if(!active || m_scroll_height<1 || x<popup.x+4 || x>=popup.x+popup.w-4) return false;
      int top=popup.y+4,bottom=top+m_scroll_height+m_visible_count*row_height;
      if(y>=top && y<top+m_scroll_height) { ScrollPage(-1); return true; }
      if(y>=bottom && y<bottom+m_scroll_height) { ScrollPage(1); return true; }
      return false;
     }
   bool PopupKey(const int key)
     {
      if(!active || ArraySize(m_options)<1) return false;
      if(key==38 || key==40) { MoveHot(key==38 ? -1 : 1); return true; }
      int current=hot>=0 ? hot : (int)MathMax(0,MathMin(selected,ArraySize(m_options)-1));
      if(key==36) hot=0;
      else if(key==35) hot=ArraySize(m_options)-1;
      else if(key==33) hot=(int)MathMax(0,current-m_visible_count);
      else if(key==34) hot=(int)MathMin(ArraySize(m_options)-1,current+m_visible_count);
      else return false;
      EnsureHotVisible(); dirty=true;
      return true;
     }
   void MoveHot(const int delta)
     {
      int count=ArraySize(m_options);
      if(count<1) return;
      if(hot<0) hot=delta<0 ? count-1 : 0;
      else hot=((hot+delta)%count+count)%count;
      EnsureHotVisible(); dirty=true;
     }
   virtual void Draw(CGuiRenderer &r)
     {
      if(visible)
        {
         Frame(r);
         bool show_icon=indicator_icons && selected>0;
         if(show_icon) r.Icon(GUI_ICON_INDICATOR,bounds.x+12,bounds.y+(bounds.h-16)/2,GUI_ACCENT,16);
         int inset=show_icon ? 36 : 12;
         if(selected>=0 && selected<ArraySize(m_options)) r.Text(bounds.x+inset,bounds.y+11,m_options[selected],enabled ? GUI_TEXT : GUI_MUTED,15,false,bounds.w-inset-30);
         r.Chevron(bounds.x+bounds.w-18,bounds.y+bounds.h/2,GUI_MUTED);
        }
      dirty=false;
     }
   // Invoked after ordinary controls: dropdown always owns the top layer.
   void DrawOverlay(CGuiRenderer &r)
     {
      if(!active) return;
      GuiRect shadow; shadow.Set(popup.x+2,popup.y+3,popup.w,popup.h); r.Round(shadow,0xFFE2E7EE);
      r.Box(popup,GUI_CARD,GUI_BORDER);
      if(m_scroll_height>0)
        {
         GuiRect previous,next;
         previous.Set(popup.x+4,popup.y+4,popup.w-8,m_scroll_height);
         next.Set(popup.x+4,popup.y+4+m_scroll_height+m_visible_count*row_height,popup.w-8,m_scroll_height);
         r.Round(previous,GUI_BG,3); r.Round(next,GUI_BG,3);
         r.Text(previous.x+8,previous.y+4,"▲  Anteriores",m_first_visible>0 ? GUI_MUTED : GUI_BORDER_HOVER,12,false,previous.w-16);
         r.Text(next.x+8,next.y+4,"▼  Próximos",m_first_visible+m_visible_count<ArraySize(m_options) ? GUI_MUTED : GUI_BORDER_HOVER,12,false,next.w-16);
        }
      for(int line=0;line<m_visible_count;line++)
        {
         int i=m_first_visible+line;
         GuiRect row; row.Set(popup.x+4,popup.y+4+m_scroll_height+line*row_height,popup.w-8,row_height);
         if(i==hot || i==selected) r.Round(row,GUI_HOVER,3);
         bool show_icon=indicator_icons && i>0;
         if(show_icon) r.Icon(GUI_ICON_INDICATOR,row.x+8,row.y+7,GUI_ACCENT,16);
         int inset=show_icon ? 32 : 8;
         r.Text(row.x+inset,row.y+6,m_options[i],i==selected ? GUI_ACCENT : GUI_TEXT,14,i==selected,row.w-inset-8);
        }
     }
  };
#endif
