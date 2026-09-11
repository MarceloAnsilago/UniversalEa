#ifndef CANVAS_GUI_TEXTFIELD_MQH
#define CANVAS_GUI_TEXTFIELD_MQH
#include "GuiControl.mqh"
class CGuiTextField : public CGuiControl
  {
private:
   string m_value,m_buffer;
   int m_cursor;
   bool m_replace;
public:
   bool invalid,text_mode,time_mode;
   int max_length;
   CGuiTextField() { invalid=false; text_mode=false; time_mode=false; max_length=12; m_cursor=0; m_replace=false; }
   void SetValue(const string value) { m_value=value; dirty=true; }
   string Buffer() const { return m_buffer; }
   void Begin() { m_buffer=m_value; m_cursor=StringLen(m_buffer); m_replace=true; active=true; invalid=false; dirty=true; }
   void End() { active=false; invalid=false; dirty=true; }
   // First digit replaces the previous value; arrows switch to insertion.
   bool Key(const int key)
     {
      string before=m_buffer; int cursor=m_cursor; bool replace=m_replace;
      if(key==37) { m_cursor=(int)MathMax(0,m_cursor-1); m_replace=false; }
      else if(key==39) { m_cursor=(int)MathMin(StringLen(m_buffer),m_cursor+1); m_replace=false; }
      else if(key==36) { m_cursor=0; m_replace=false; }
      else if(key==35) { m_cursor=StringLen(m_buffer); m_replace=false; }
      else if(key==8 || key==46)
        {
         if(m_replace) { m_buffer=""; m_cursor=0; }
         else if(key==8 && m_cursor>0) { m_buffer=StringSubstr(m_buffer,0,m_cursor-1)+StringSubstr(m_buffer,m_cursor); m_cursor--; }
         else if(key==46 && m_cursor<StringLen(m_buffer)) m_buffer=StringSubstr(m_buffer,0,m_cursor)+StringSubstr(m_buffer,m_cursor+1);
         m_replace=false;
        }
      else
        {
         string ch="";
         if(time_mode)
           {
            if(key>=48 && key<=57) ch=ShortToString((ushort)key);
            else if(key>=96 && key<=105) ch=ShortToString((ushort)(key-48));
            else if(TranslateKey(key)==':') ch=":";
           }
         else if(text_mode)
           {
            // Respect the terminal's input language, Shift and Caps Lock.
            short code=TranslateKey(key);
            if(code>=32) ch=ShortToString((ushort)code);
           }
         else if(key>=48 && key<=57) ch=ShortToString((ushort)key);
         else if(key>=96 && key<=105) ch=ShortToString((ushort)(key-48));
         else if(key==190 || key==188 || key==110) ch=".";
         else if(key==189 || key==109) ch="-";
         if(ch=="") return false;
         if(m_replace) { m_buffer=""; m_cursor=0; m_replace=false; }
         if(time_mode && ch!=":" && m_cursor==2 && StringLen(m_buffer)==2)
           { m_buffer+=":"; m_cursor++; }
         if(StringLen(m_buffer)<max_length) { m_buffer=StringSubstr(m_buffer,0,m_cursor)+ch+StringSubstr(m_buffer,m_cursor); m_cursor++; }
        }
      bool changed=(before!=m_buffer || cursor!=m_cursor || replace!=m_replace);
      if(changed) { invalid=false; dirty=true; }
      return changed;
     }
   virtual void Draw(CGuiRenderer &r)
     {
      if(visible)
        {
         Frame(r);
         if(invalid) r.Box(bounds,GUI_CARD,GUI_ERROR);
         string display=m_value;
         if(active) display=StringSubstr(m_buffer,0,m_cursor)+"|"+StringSubstr(m_buffer,m_cursor);
         // Long names keep the caret and the insertion position visible.
         if(text_mode && active) display=r.EditViewport(display,m_cursor,bounds.w-32);
         if(active && m_replace) { GuiRect selection; selection.Set(bounds.x+8,bounds.y+7,bounds.w-16,bounds.h-14); r.Round(selection,GUI_HOVER,3); }
         r.Text(bounds.x+12,bounds.y+11,display,enabled ? GUI_TEXT : GUI_MUTED,15,false,bounds.w-24);
        }
      dirty=false;
     }
  };
#endif
