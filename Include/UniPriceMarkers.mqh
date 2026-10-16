#ifndef UNI_PRICE_MARKERS_MQH
#define UNI_PRICE_MARKERS_MQH
#include <Canvas/Canvas.mqh>

struct UniPriceMarker
  {
   string key,text;
   double price;
   color background,foreground;
  };

// Generic presentation only: callers own the meaning and lifetime of each level.
// BeginFrame / Set / Render rebuilds a frame; Set also updates an existing key.
class CUniPriceMarkers
  {
private:
   CCanvas m_canvas;
   UniPriceMarker m_levels[];
   long m_chart;
   string m_name,m_signature;
   int m_width,m_height,m_x,m_digits,m_font;
   bool m_ready;
public:
   CUniPriceMarkers() { m_chart=0; m_ready=false; m_width=0; m_height=0; m_x=0; m_digits=5; m_font=13; }
   ~CUniPriceMarkers() { Destroy(); }
   void Configure(const long chart,const int digits,const int font=13)
     {
      Destroy(); m_chart=chart; m_digits=digits; m_font=(int)MathMax(10,MathMin(20,font));
      m_name="UniEA.PriceMarkers."+IntegerToString(chart)+"."+IntegerToString((long)GetMicrosecondCount());
     }
   void Destroy() { m_canvas.Destroy(); m_ready=false; m_signature=""; ArrayResize(m_levels,0); }
   void BeginFrame() { ArrayResize(m_levels,0); }
   int Count() { return ArraySize(m_levels); }
   bool Set(const string key,const string text,const double price,const color background,const color foreground=clrWhite)
     {
      if(key=="" || !MathIsValidNumber(price) || price<=0) return false;
      int index=-1,n=ArraySize(m_levels);
      for(int i=0;i<n;i++) if(m_levels[i].key==key) { index=i; break; }
      if(index<0) { index=n; if(ArrayResize(m_levels,n+1)!=n+1) return false; }
      m_levels[index].key=key; m_levels[index].text=text; m_levels[index].price=price;
      m_levels[index].background=background; m_levels[index].foreground=foreground;
      return true;
     }
   bool Remove(const string key)
     {
      int n=ArraySize(m_levels);
      for(int i=0;i<n;i++) if(m_levels[i].key==key)
        { for(int j=i;j<n-1;j++) m_levels[j]=m_levels[j+1]; ArrayResize(m_levels,n-1); return true; }
      return false;
     }
   bool Render()
     {
      int chart_width=(int)ChartGetInteger(m_chart,CHART_WIDTH_IN_PIXELS,0);
      int height=(int)ChartGetInteger(m_chart,CHART_HEIGHT_IN_PIXELS,0);
      int width=(int)MathMin(254,chart_width-410);
      if(width<150 || height<60 || Count()==0)
        { if(m_ready) { m_canvas.Destroy(); m_ready=false; m_signature=""; } return true; }
      // Keep clear of the native price scale and the left setup panel.
      int x=chart_width-width-66;
      if(!m_ready || m_width!=width || m_height!=height)
        {
         m_canvas.Destroy(); m_ready=false;
         if(!m_canvas.CreateBitmapLabel(m_chart,0,m_name,x,0,width,height,COLOR_FORMAT_ARGB_NORMALIZE)) return false;
         m_width=width; m_height=height; m_signature=""; m_ready=true;
         ObjectSetInteger(m_chart,m_name,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(m_chart,m_name,OBJPROP_HIDDEN,true);
         ObjectSetInteger(m_chart,m_name,OBJPROP_BACK,false);
         ObjectSetInteger(m_chart,m_name,OBJPROP_ZORDER,0);
         ObjectSetString(m_chart,m_name,OBJPROP_TOOLTIP,"\n");
        }
      if(x!=m_x) { ObjectSetInteger(m_chart,m_name,OBJPROP_XDISTANCE,x); m_x=x; m_signature=""; }
      int order[],anchor[],center[]; int n=0;
      datetime time=iTime(ChartSymbol(m_chart),(ENUM_TIMEFRAMES)ChartPeriod(m_chart),0);
      for(int i=0;i<Count();i++)
        {
         int px,py;
         if(!ChartTimePriceToXY(m_chart,0,time,m_levels[i].price,px,py) || py<0 || py>=height) continue;
         ArrayResize(order,n+1); ArrayResize(anchor,n+1); ArrayResize(center,n+1);
         order[n]=i; anchor[n]=py; n++;
        }
      for(int i=1;i<n;i++)
         for(int j=i;j>0 && anchor[j]<anchor[j-1];j--)
           { int a=anchor[j]; anchor[j]=anchor[j-1]; anchor[j-1]=a; a=order[j]; order[j]=order[j-1]; order[j-1]=a; }
      int badge=m_font+14,gap=badge+4,half=badge/2;
      // If the viewport cannot hold every badge, retain exact anchors and compact the spacing.
      if(n>1) gap=(int)MathMin(gap,(height-badge-4)/(n-1));
      for(int i=0;i<n;i++) center[i]=(int)MathMax(half+2,MathMax(anchor[i],i>0 ? center[i-1]+gap : 0));
      if(n>0 && center[n-1]>height-half-2)
        {
         center[n-1]=height-half-2;
         for(int i=n-2;i>=0;i--) center[i]=(int)MathMin(center[i],center[i+1]-gap);
        }
      string signature=IntegerToString(x)+":"+IntegerToString(height);
      for(int i=0;i<n;i++)
        {
         UniPriceMarker level=m_levels[order[i]];
         signature+="|"+level.key+":"+level.text+":"+DoubleToString(level.price,m_digits)+":"+
                    IntegerToString(anchor[i])+":"+IntegerToString(center[i])+":"+
                    IntegerToString((long)level.background)+":"+IntegerToString((long)level.foreground);
        }
      if(signature==m_signature) return true;
      m_canvas.Erase(0);
      m_canvas.FontSet("Segoe UI",m_font);
      for(int i=0;i<n;i++)
        {
         UniPriceMarker level=m_levels[order[i]];
         uint bg=ColorToARGB(level.background),fg=ColorToARGB(level.foreground);
         int cy=center[i],top=cy-half;
         string price=DoubleToString(level.price,m_digits),label=level.text;
         int price_width=m_canvas.TextWidth(price);
         while(StringLen(label)>0 && m_canvas.TextWidth(label)>width-52-price_width)
            label=StringSubstr(label,0,StringLen(label)-1);
         m_canvas.FillRectangle(2,top,width-23,top+badge,bg);
         m_canvas.FillTriangle(width-23,cy-5,width-17,cy,width-23,cy+5,bg);
         m_canvas.Line(width-17,cy,width-7,anchor[i],bg);
         m_canvas.LineHorizontal(width-7,width-1,anchor[i],bg);
         m_canvas.TextOut(10,cy-m_canvas.TextHeight(price)/2,label,fg);
         m_canvas.TextOut(width-31-price_width,cy-m_canvas.TextHeight(price)/2,price,fg);
        }
      m_canvas.Update(); m_signature=signature; return true;
     }
  };

// Adapter: only orders and positions owned by this symbol/Magic are displayed.
class CUniTradeMarkers
  {
private:
   CUniPriceMarkers m_view;
   string m_symbol;
   long m_magic;
   bool m_enabled;
   color m_entry,m_stop,m_take,m_pending,m_text;
   ulong m_updated;
   bool m_refreshed;
   void Levels(const string key,const string entry_text,const double entry,const double sl,const double tp,const color entry_color)
     {
      m_view.Set(key+".entry",entry_text,entry,entry_color,m_text);
      m_view.Set(key+".sl","STOP",sl,m_stop,m_text);
      m_view.Set(key+".tp","TAKE",tp,m_take,m_text);
     }
public:
   CUniTradeMarkers() { m_enabled=false; m_refreshed=false; m_updated=0; }
   void Configure(const long chart,const string symbol,const long magic,const bool enabled,
                  const color entry,const color stop,const color take,const color pending,const color text,const int font)
     {
      m_symbol=symbol; m_magic=magic; m_enabled=enabled; m_entry=entry; m_stop=stop;
      m_take=take; m_pending=pending; m_text=text; m_refreshed=false;
      m_view.Configure(chart,(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS),font);
     }
   void Destroy() { m_view.Destroy(); m_enabled=false; }
   void Refresh(const bool force=false)
     {
      if(!m_enabled) return;
      ulong now=GetTickCount64();
      if(!force && m_refreshed && now-m_updated<100) return;
      m_updated=now; m_refreshed=true; m_view.BeginFrame();
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=m_symbol || PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;
         string key="P"+IntegerToString((long)ticket);
         Levels(key,PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? "COMPRA" : "VENDA",
                PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP),m_entry);
        }
      for(int i=0;i<OrdersTotal();i++)
        {
         ulong ticket=OrderGetTicket(i);
         if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=m_symbol || OrderGetInteger(ORDER_MAGIC)!=m_magic) continue;
         Levels("O"+IntegerToString((long)ticket),"PENDENTE",OrderGetDouble(ORDER_PRICE_OPEN),
                OrderGetDouble(ORDER_SL),OrderGetDouble(ORDER_TP),m_pending);
        }
      m_view.Render();
     }
  };
#endif
