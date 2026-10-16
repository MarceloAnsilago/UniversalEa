#ifndef UNI_PRICE_MARKERS_MQH
#define UNI_PRICE_MARKERS_MQH
#include <Canvas/Canvas.mqh>
#include "UniOrderMath.mqh"

double UniBreakevenMarkerPrice(const int side,const double entry,const int mode,const double trigger,const double point)
  {
   if((side!=1 && side!=-1) || entry<=0 || trigger<=0 || point<=0 || (mode!=1 && mode!=2)) return 0;
   return entry+side*trigger*(mode==2 ? entry/100.0 : point);
  }

bool UniBreakevenProtected(const int side,const double entry,const int mode,const double offset,
                          const double sl,const double point,const double tick,const int digits)
  {
   if((side!=1 && side!=-1) || entry<=0 || sl<=0 || point<=0 || tick<=0 || (mode!=1 && mode!=2)) return false;
   double target=UniPriceGrid(entry+side*UniDistance(offset,mode==2,entry,point),tick,digits,-side);
   return target>0 && side*(sl-target)>=-tick*1e-8;
  }

struct UniPriceMarker
  {
   string key,text,detail;
   double price;
   color background,foreground;
  };

string UniMarkerMoney(const double profit,const string currency)
  {
   double value=NormalizeDouble(profit,2);
   return "Est. "+(value>0 ? "+" : "")+DoubleToString(value==0 ? 0 : value,2)+" "+currency;
  }

string UniMarkerProfitEstimate(const string symbol,const int side,const double volume,const double entry,const double exit_price)
  {
   if((side!=1 && side!=-1) || volume<=0 || entry<=0 || exit_price<=0) return "";
   double profit=0;
   if(!OrderCalcProfit(side==1 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,symbol,volume,entry,exit_price,profit) || !MathIsValidNumber(profit))
      return "Est. indisponivel";
   return UniMarkerMoney(profit,AccountInfoString(ACCOUNT_CURRENCY));
  }

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
   int m_line_count;
   string LineName(const int index) { return m_name+".L"+IntegerToString(index); }
   void ClearLines(const int keep=0)
     {
      for(int i=keep;i<m_line_count;i++) ObjectDelete(m_chart,LineName(i));
      m_line_count=keep;
     }
   bool SyncLines()
     {
      for(int i=0;i<Count();i++)
        {
         string name=LineName(i);
         if(ObjectFind(m_chart,name)<0)
           {
            if(!ObjectCreate(m_chart,name,OBJ_HLINE,0,0,m_levels[i].price)) return false;
            m_line_count=(int)MathMax(m_line_count,i+1);
            ObjectSetInteger(m_chart,name,OBJPROP_SELECTABLE,false);
            ObjectSetInteger(m_chart,name,OBJPROP_HIDDEN,true);
            ObjectSetInteger(m_chart,name,OBJPROP_BACK,false);
            ObjectSetInteger(m_chart,name,OBJPROP_STYLE,STYLE_SOLID);
            ObjectSetInteger(m_chart,name,OBJPROP_WIDTH,2);
            ObjectSetString(m_chart,name,OBJPROP_TOOLTIP,"\n");
           }
         if(ObjectGetDouble(m_chart,name,OBJPROP_PRICE)!=m_levels[i].price)
            ObjectSetDouble(m_chart,name,OBJPROP_PRICE,m_levels[i].price);
         if((color)ObjectGetInteger(m_chart,name,OBJPROP_COLOR)!=m_levels[i].background)
            ObjectSetInteger(m_chart,name,OBJPROP_COLOR,m_levels[i].background);
        }
      ClearLines(Count()); return true;
     }
public:
   CUniPriceMarkers() { m_chart=0; m_ready=false; m_width=0; m_height=0; m_x=0; m_digits=5; m_font=13; m_line_count=0; }
   ~CUniPriceMarkers() { Destroy(); }
   void Configure(const long chart,const int digits,const int font=13)
     {
      Destroy(); m_chart=chart; m_digits=digits; m_font=(int)MathMax(10,MathMin(20,font));
      m_name="UniEA.PriceMarkers."+IntegerToString(chart)+"."+IntegerToString((long)GetMicrosecondCount());
     }
   void Destroy() { ClearLines(); m_canvas.Destroy(); m_ready=false; m_signature=""; ArrayResize(m_levels,0); }
   void BeginFrame() { ArrayResize(m_levels,0); }
   int Count() { return ArraySize(m_levels); }
   bool Set(const string key,const string text,const double price,const color background,const color foreground=clrWhite,const string detail="")
     {
      if(key=="" || !MathIsValidNumber(price) || price<=0) return false;
      int index=-1,n=ArraySize(m_levels);
      for(int i=0;i<n;i++) if(m_levels[i].key==key) { index=i; break; }
      if(index<0) { index=n; if(ArrayResize(m_levels,n+1)!=n+1) return false; }
      m_levels[index].key=key; m_levels[index].text=text; m_levels[index].price=price;
      m_levels[index].background=background; m_levels[index].foreground=foreground;
      m_levels[index].detail=detail;
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
      int width=(int)MathMin(176,chart_width-410);
      if(width<150 || height<60 || Count()==0)
        { ClearLines(); if(m_ready) { m_canvas.Destroy(); m_ready=false; m_signature=""; } return true; }
      if(!SyncLines()) return false;
      // Anchor to the chart's right edge instead of reserving a guessed scale width.
      int x=0;
      if(!m_ready || m_width!=width || m_height!=height)
        {
         m_canvas.Destroy(); m_ready=false;
         if(!m_canvas.CreateBitmapLabel(m_chart,0,m_name,x,0,width,height,COLOR_FORMAT_ARGB_NORMALIZE)) return false;
         m_width=width; m_height=height; m_signature=""; m_ready=true;
         ObjectSetInteger(m_chart,m_name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
         ObjectSetInteger(m_chart,m_name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
         ObjectSetInteger(m_chart,m_name,OBJPROP_XDISTANCE,0);
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
      int badge=m_font+8,gap=badge+3,half=badge/2;
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
         signature+="|"+level.key+":"+level.text+":"+level.detail+":"+DoubleToString(level.price,m_digits)+":"+
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
         m_canvas.FontSet("Segoe UI",m_font);
         string label=level.text,profit=level.detail;
         // The exact price is already shown by the horizontal line on the native scale.
         if(StringFind(profit,"Est. ")==0) profit=StringSubstr(profit,5);
         int size=m_font;
         while(size>8 && m_canvas.TextWidth(label+"  "+profit)>width-26)
            m_canvas.FontSet("Segoe UI",--size);
         int profit_width=m_canvas.TextWidth(profit);
         while(StringLen(label)>0 && m_canvas.TextWidth(label)>width-26-profit_width)
            label=StringSubstr(label,0,StringLen(label)-1);
         m_canvas.FillRectangle(7,top,width-1,top+badge,bg);
         m_canvas.Line(0,anchor[i],7,cy,bg);
         int text_y=cy-m_canvas.TextHeight(label)/2;
         m_canvas.TextOut(13,text_y,label,fg);
         if(profit!="") m_canvas.TextOut(width-6-profit_width,text_y,profit,fg);
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
   color m_breakeven;
   int m_be_mode;
   double m_be_trigger,m_be_offset;
   bool m_show_profit;
   ulong m_updated;
   bool m_refreshed;
   void Level(const string key,const string text,const double price,const color ink,const int side,const double volume,const double entry)
     {
      if(price<=0) return;
      m_view.Set(key,text,price,ink,m_text,m_show_profit ? UniMarkerProfitEstimate(m_symbol,side,volume,entry,price) : "");
     }
   void Levels(const string key,const string entry_text,const double entry,const double sl,const double tp,const color entry_color,const int side,const double volume)
     {
      Level(key+".entry",entry_text,entry,entry_color,side,volume,entry);
      Level(key+".sl","STOP",sl,m_stop,side,volume,entry);
      Level(key+".tp","TAKE",tp,m_take,side,volume,entry);
     }
public:
   CUniTradeMarkers() { m_enabled=false; m_refreshed=false; m_updated=0; m_be_mode=0; m_be_trigger=0; m_be_offset=0; m_breakeven=clrDarkOrchid; m_show_profit=true; }
   void ShowProfit(const bool enabled) { m_show_profit=enabled; m_refreshed=false; }
   void ConfigureBreakeven(const int mode,const double trigger,const color ink,const double offset=0)
     { m_be_mode=mode; m_be_trigger=trigger; m_be_offset=offset; m_breakeven=ink; m_refreshed=false; }
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
         int side=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? 1 : -1;
         double volume=PositionGetDouble(POSITION_VOLUME);
         Levels(key,PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? "COMPRA" : "VENDA",
                PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP),m_entry,side,volume);
         double activation=UniBreakevenMarkerPrice(side,PositionGetDouble(POSITION_PRICE_OPEN),
                                                  m_be_mode,m_be_trigger,SymbolInfoDouble(m_symbol,SYMBOL_POINT));
         if(!UniBreakevenProtected(side,PositionGetDouble(POSITION_PRICE_OPEN),m_be_mode,m_be_offset,
                                  PositionGetDouble(POSITION_SL),SymbolInfoDouble(m_symbol,SYMBOL_POINT),
                                  SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_SIZE),(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS)))
            Level(key+".be","BE ATIVAR",activation,m_breakeven,side,volume,PositionGetDouble(POSITION_PRICE_OPEN));
        }
      for(int i=0;i<OrdersTotal();i++)
        {
         ulong ticket=OrderGetTicket(i);
         if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=m_symbol || OrderGetInteger(ORDER_MAGIC)!=m_magic) continue;
         ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         int side=(type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_BUY_STOP_LIMIT || type==ORDER_TYPE_BUY) ? 1 : -1;
         Levels("O"+IntegerToString((long)ticket),"PENDENTE",OrderGetDouble(ORDER_PRICE_OPEN),
                OrderGetDouble(ORDER_SL),OrderGetDouble(ORDER_TP),m_pending,side,OrderGetDouble(ORDER_VOLUME_CURRENT));
        }
      m_view.Render();
     }
  };
#endif
