#ifndef UNI_PANEL_MQH
#define UNI_PANEL_MQH

// Painel provisório com objetos nativos. Os controles serão implementados depois.
class CUniPanel
  {
private:
   long m_chart;
   string m_prefix;
   bool Label(const string suffix,const int y,const int size,const string text,const color ink)
     {
      string name=m_prefix+suffix;
      return ObjectCreate(m_chart,name,OBJ_LABEL,0,0,0) &&
             ObjectSetInteger(m_chart,name,OBJPROP_CORNER,CORNER_LEFT_UPPER) &&
             ObjectSetInteger(m_chart,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER) &&
             ObjectSetInteger(m_chart,name,OBJPROP_XDISTANCE,26) &&
             ObjectSetInteger(m_chart,name,OBJPROP_YDISTANCE,y) &&
             ObjectSetInteger(m_chart,name,OBJPROP_FONTSIZE,size) &&
             ObjectSetInteger(m_chart,name,OBJPROP_COLOR,ink) &&
             ObjectSetInteger(m_chart,name,OBJPROP_SELECTABLE,false) &&
             ObjectSetInteger(m_chart,name,OBJPROP_HIDDEN,true) &&
             ObjectSetString(m_chart,name,OBJPROP_FONT,"Arial") &&
             ObjectSetString(m_chart,name,OBJPROP_TEXT,text);
     }
public:
   CUniPanel() { m_chart=0; m_prefix=""; }
   ~CUniPanel() { Destroy(); }
   bool Create(const long chart,const string status)
     {
      Destroy();
      m_chart=chart;
      m_prefix="UniEA.Panel."+IntegerToString(chart)+"."+IntegerToString((long)GetMicrosecondCount())+".";
      string name=m_prefix+"Background";
      bool ok=ObjectCreate(m_chart,name,OBJ_RECTANGLE_LABEL,0,0,0) &&
              ObjectSetInteger(m_chart,name,OBJPROP_CORNER,CORNER_LEFT_UPPER) &&
              ObjectSetInteger(m_chart,name,OBJPROP_XDISTANCE,12) &&
              ObjectSetInteger(m_chart,name,OBJPROP_YDISTANCE,20) &&
              ObjectSetInteger(m_chart,name,OBJPROP_XSIZE,340) &&
              ObjectSetInteger(m_chart,name,OBJPROP_YSIZE,106) &&
              ObjectSetInteger(m_chart,name,OBJPROP_BGCOLOR,clrWhiteSmoke) &&
              ObjectSetInteger(m_chart,name,OBJPROP_BORDER_TYPE,BORDER_FLAT) &&
              ObjectSetInteger(m_chart,name,OBJPROP_COLOR,clrSilver) &&
              ObjectSetInteger(m_chart,name,OBJPROP_SELECTABLE,false) &&
              ObjectSetInteger(m_chart,name,OBJPROP_HIDDEN,true);
      if(ok) ok=Label("Title",32,12,"UniEA",clrBlack) &&
                Label("Placeholder",60,9,"Painel padrao - em desenvolvimento",clrDimGray) &&
                Label("Status",88,9,status,clrBlack);
      if(!ok) { Destroy(); return false; }
      ChartRedraw(m_chart);
      return true;
     }
   void Destroy()
     {
      if(m_prefix=="") return;
      ObjectDelete(m_chart,m_prefix+"Status");
      ObjectDelete(m_chart,m_prefix+"Placeholder");
      ObjectDelete(m_chart,m_prefix+"Title");
      ObjectDelete(m_chart,m_prefix+"Background");
      ChartRedraw(m_chart);
      m_prefix="";
     }
  };
#endif
