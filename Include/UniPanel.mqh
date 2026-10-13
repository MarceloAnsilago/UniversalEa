#ifndef UNI_PANEL_MQH
#define UNI_PANEL_MQH
#include <Canvas/Canvas.mqh>
#include "Configuration/GuiState.mqh"

// Resumo somente leitura; a configuracao continua nas propriedades do EA.
class CUniPanel
  {
private:
   CCanvas m_canvas;
   long m_chart;
   string m_name,m_status;
   IndicatorConfig m_indicators[4];
   int m_scroll,m_total;
   bool m_ready;
   void Box(const int x,const int y,const int w,const int h,const int r,const uint ink)
     {
      m_canvas.FillRectangle(x+r,y,x+w-r-1,y+h-1,ink);
      m_canvas.FillRectangle(x,y+r,x+w-1,y+h-r-1,ink);
      m_canvas.FillCircle(x+r,y+r,r,ink);
      m_canvas.FillCircle(x+w-r-1,y+r,r,ink);
      m_canvas.FillCircle(x+r,y+h-r-1,r,ink);
      m_canvas.FillCircle(x+w-r-1,y+h-r-1,r,ink);
     }
   void Text(const int x,const int y,const string value,const int size=15,const uint ink=0xFF16324F)
     {
      m_canvas.FontSet("Segoe UI",size);
      m_canvas.TextOut(x,y,value,ink);
     }
   int Rows(const IndicatorConfig &c)
     { return c.type==GUI_INDICATOR_MA ? 5 : (c.type==GUI_INDICATOR_RSI ? 3 : (c.type==GUI_INDICATOR_ADX ? 2 : 1)); }
   string Row(const IndicatorConfig &c,const int i)
     {
      if(c.type==GUI_INDICATOR_NONE) return "Selecione o tipo nos inputs do EA.";
      if(i==0) return "Fonte de dados para a grade Sinal";
      if(c.type==GUI_INDICATOR_RSI)
        {
         if(i==1) return "Período: "+IntegerToString(c.rsiPeriod);
         return "Preço aplicado: "+GuiPriceName((int)c.rsiPrice-1);
        }
      if(c.type==GUI_INDICATOR_ADX)
         return "Período: "+IntegerToString(c.adxPeriod);
      if(i==1) return "Período: "+IntegerToString(c.maPeriod);
      if(i==2) return "Método: "+GuiMethodName((int)c.maMethod);
      if(i==3) return "Deslocamento: "+IntegerToString(c.maShift);
      return "Preço aplicado: "+GuiPriceName((int)c.maPrice-1);
     }
   void Draw()
     {
      int w=m_canvas.Width(),h=m_canvas.Height();
      int viewport=h-140;
      m_total=0;
      for(int i=0;i<4;i++) m_total+=100+Rows(m_indicators[i])*44+18;
      m_scroll=(int)MathMax(0,MathMin(m_scroll,m_total-viewport));
      m_canvas.Erase(0xFFFDFDFD);
      int y=98-m_scroll;
      for(int i=0;i<4;i++)
        {
         IndicatorConfig c=m_indicators[i];
         int rows=Rows(c),ch=100+rows*44;
         bool active=c.type!=GUI_INDICATOR_NONE;
         if(y+ch>=98 && y<h-42)
           {
            Box(17,y+3,w-32,ch,4,0xFFF0F0F0);
            Box(15,y,w-32,ch,4,0xFFD8D8D8);
            Box(16,y+1,w-34,ch-2,3,0xFFFFFEFC);
            Text(34,y+22,"Indicador "+IntegerToString(i+1),13,0xFF7890A5);
            Box(w-99,y+19,64,24,11,active ? 0xFFE8F7F3 : 0xFFF0F1F3);
            Text(w-89,y+23,active ? "Ativo" : "Inativo",12,active ? 0xFF009F89 : 0xFF7B8793);
            string type=GuiIndicatorName(c.type);
            m_canvas.FontSet("Segoe UI",16,FW_BOLD);
            int badge=m_canvas.TextWidth(type)+20;
            Box(34,y+52,badge,33,3,0xFFF2F3F5);
            m_canvas.TextOut(44,y+59,type,active ? 0xFF00A58D : 0xFF7B8793);
            for(int row=0;row<rows;row++)
              {
               int ry=y+108+row*44;
               Text(34,ry,Row(c,row),14);
               if(row<rows-1) m_canvas.LineHorizontal(34,w-37,ry+30,0xFFD8D8D8);
              }
           }
         y+=ch+18;
        }
      // Fixed header and footer also clip scrolled card content.
      m_canvas.FillRectangle(0,0,w-1,97,0xFFFDFDFD);
      Text(16,12,"UniEA",13,0xFF009F89);
      Text(16,34,"Resumo dos indicadores e sinal",20);
      Text(16,66,m_status,12,0xFF718096);
      m_canvas.FillRectangle(0,h-42,w-1,h-1,0xFFFDFDFD);
      m_canvas.LineHorizontal(16,w-17,h-42,0xFFE7E9EC);
      Text(22,h-28,"Anterior",13,m_scroll>0 ? 0xFF009F89 : 0xFFAAB2BB);
      Text(w-91,h-28,"Próximo",13,m_scroll<m_total-viewport ? 0xFF009F89 : 0xFFAAB2BB);
      m_canvas.Update();
     }
public:
   CUniPanel() { m_chart=0; m_scroll=0; m_total=0; m_ready=false; }
   ~CUniPanel() { Destroy(); }
   bool Create(const long chart,const string status,const CGuiState &config)
     {
      Destroy();
      m_chart=chart; m_status=status; m_scroll=0;
      for(int i=0;i<4;i++) m_indicators[i]=config.indicators[i];
      m_name="UniEA.Panel."+IntegerToString(chart)+"."+IntegerToString((long)GetMicrosecondCount());
      int height=(int)MathMax(220,MathMin(820,ChartGetInteger(chart,CHART_HEIGHT_IN_PIXELS)-40));
      if(!m_canvas.CreateBitmapLabel(chart,0,m_name,12,20,366,height,COLOR_FORMAT_XRGB_NOALPHA))
        { m_canvas.Destroy(); return false; }
      ObjectSetInteger(chart,m_name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(chart,m_name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(chart,m_name,OBJPROP_ZORDER,10);
      m_ready=true;
      Draw();
      return true;
     }
   void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!m_ready) return;
      if(id==CHARTEVENT_CHART_CHANGE)
        {
         int h=(int)MathMax(220,MathMin(820,ChartGetInteger(m_chart,CHART_HEIGHT_IN_PIXELS)-40));
         if(h!=m_canvas.Height() && m_canvas.Resize(366,h)) Draw();
        }
      if(id==CHARTEVENT_OBJECT_CLICK && sparam==m_name)
        {
         int x=(int)lparam-12,y=(int)dparam-20;
         if(y<m_canvas.Height()-42 || y>=m_canvas.Height()) return;
         if(x>=16 && x<115) m_scroll-=180;
         else if(x>=m_canvas.Width()-110 && x<m_canvas.Width()-16) m_scroll+=180;
         else return;
         Draw();
        }
     }
   void Destroy()
     { m_ready=false; m_canvas.Destroy(); }
  };
#endif
