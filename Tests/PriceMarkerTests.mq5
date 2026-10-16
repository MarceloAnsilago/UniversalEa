#property strict
#include "../Include/UniPriceMarkers.mqh"
int checks=0,failures=0;
void Check(const bool ok,const string text)
  { checks++; if(!ok) { failures++; Print("FAIL: ",text); } }
void OnStart()
  {
   CUniPriceMarkers markers;
   Check(UniMarkerMoney(12.5,"USD")=="Est. +12.50 USD" && UniMarkerMoney(-8,"BRL")=="Est. -8.00 BRL","Profit estimates show sign and account currency");
   Check(UniMarkerMoney(-0.001,"USD")=="Est. 0.00 USD","Avoid negative zero after rounding");
   Check(UniMarkerProfitEstimate(_Symbol,1,0,1.1,1.2)=="" && UniMarkerProfitEstimate(_Symbol,0,1,1.1,1.2)=="","Reject incomplete estimate inputs");
   Check(UniMarkerProfitEstimate("__missing_symbol__",1,1,1.1,1.2)=="Est. indisponivel","Failed valuation never displays misleading zero");
   double estimated=0;
   if(OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,0.01,1.1,1.1008,estimated))
     {
      Check(UniMarkerProfitEstimate(_Symbol,1,0.01,1.1,1.1008)==UniMarkerMoney(estimated,AccountInfoString(ACCOUNT_CURRENCY)),"Buy estimate uses broker calculation");
      Check(UniMarkerProfitEstimate(_Symbol,-1,0.01,1.1,1.1008)==UniMarkerMoney(-estimated,AccountInfoString(ACCOUNT_CURRENCY)),"Sell estimate has opposite sign");
     }
   else Check(UniMarkerProfitEstimate(_Symbol,1,0.01,1.1,1.1008)=="Est. indisponivel","Unavailable account conversion is explicit");
   Check(!UniBreakevenProtected(1,100,1,2,99,1,0.5,2) && !UniBreakevenProtected(1,100,1,2,0,1,0.5,2),"Keep BE until stop protection is confirmed");
   Check(!UniBreakevenProtected(1,100,1,2,100,1,0.5,2) && UniBreakevenProtected(1,100,1,2,102,1,0.5,2),"Buy protection includes configured offset");
   Check(UniBreakevenProtected(-1,100,1,2,98,1,0.5,2) && !UniBreakevenProtected(-1,100,1,2,99,1,0.5,2),"Sell protection checks opposite direction");
   Check(UniBreakevenProtected(1,200,2,1,202,0.01,0.01,2) && UniBreakevenProtected(-1,200,2,1,198,0.01,0.01,2),"Percent protection uses opening price");
   Check(UniBreakevenProtected(1,100,1,0.2,100,1,0.5,2) && UniBreakevenProtected(-1,100,1,0.2,100,1,0.5,2),"Protection follows trading tick rounding");
   Check(UniBreakevenProtected(1,100,1,2,105,1,0.5,2),"More protective trailing also hides BE");
   Check(MathAbs(UniBreakevenMarkerPrice(1,1.1,1,40,0.00001)-1.1004)<1e-9,"Buy BE trigger in points");
   Check(MathAbs(UniBreakevenMarkerPrice(-1,1.1,1,40,0.00001)-1.0996)<1e-9,"Sell BE trigger in points");
   Check(MathAbs(UniBreakevenMarkerPrice(1,200,2,2,0.01)-204)<1e-9 &&
         MathAbs(UniBreakevenMarkerPrice(-1,200,2,2,0.01)-196)<1e-9,"BE percent uses opening price for both sides");
   Check(UniBreakevenMarkerPrice(1,100,0,40,0.01)==0 && UniBreakevenMarkerPrice(1,100,1,0,0.01)==0,"Disabled BE has no marker");
   markers.Configure(ChartID(),(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
   int before=ObjectsTotal(ChartID());
   double low=ChartGetDouble(ChartID(),CHART_PRICE_MIN,0),high=ChartGetDouble(ChartID(),CHART_PRICE_MAX,0);
   double middle=(low+high)/2,range=high-low;
   Check(!markers.Set("bad","Invalid",0,clrRed) && markers.Count()==0,"Reject zero price");
   Check(markers.Set("entry","COMPRA",middle,clrRoyalBlue),"Add entry");
   Check(markers.Set("entry","COMPRA",middle+range*0.02,clrRoyalBlue) && markers.Count()==1,"Update key without duplicate");
   markers.Set("stop","STOP",middle-range*0.2,clrCrimson,clrWhite,"Est. -8.00 USD");
   markers.Set("take","TAKE",middle+range*0.2,clrSeaGreen,clrWhite,"Est. +16.00 USD");
   markers.Set("trailing","TRAILING",middle-range*0.195,clrDarkOrchid);
   markers.Set("grid","GRID 1",middle+range*0.205,clrDarkOrange);
   Check(markers.Count()==5 && markers.Render(),"Render reusable marker types and nearby levels");
   Check(ObjectsTotal(ChartID())==before+6,"One Canvas and one line per marker");
   Check(markers.Render() && ObjectsTotal(ChartID())==before+6,"Unchanged render reuses Canvas and lines");
   int lines=0;
   for(int i=0;i<ObjectsTotal(ChartID());i++)
     {
      string name=ObjectName(ChartID(),i);
      if(StringFind(name,"UniEA.PriceMarkers.")!=0 || (ENUM_OBJECT)ObjectGetInteger(ChartID(),name,OBJPROP_TYPE)!=OBJ_HLINE) continue;
      lines++;
      Check(ObjectGetInteger(ChartID(),name,OBJPROP_STYLE)==STYLE_SOLID && ObjectGetInteger(ChartID(),name,OBJPROP_WIDTH)==2,
            "Solid colored overlay line");
     }
   Check(lines==5,"All five marker levels have horizontal lines");
   ChartRedraw(); Sleep(300);
   Check(ChartScreenShot(ChartID(),"price-markers-preview.png",(int)ChartGetInteger(ChartID(),CHART_WIDTH_IN_PIXELS),
                         (int)ChartGetInteger(ChartID(),CHART_HEIGHT_IN_PIXELS),ALIGN_RIGHT),"Save visual preview");
   Check(markers.Remove("grid") && !markers.Remove("missing") && markers.Count()==4,"Remove by key");
   Check(markers.Render() && ObjectsTotal(ChartID())==before+5,"Removed marker also removes its line");
   markers.BeginFrame();
   Check(markers.Count()==0 && markers.Render() && ObjectsTotal(ChartID())==before,"Empty frame removes Canvas");
   markers.Set("again","TAKE",middle,clrSeaGreen);
   Check(markers.Render() && ObjectsTotal(ChartID())==before+2,"Recreate after empty frame");
   markers.Destroy(); markers.Destroy();
   Check(ObjectsTotal(ChartID())==before,"Destroy is repeatable and removes only owned object");
   PrintFormat("[PriceMarkerTests] %d checks, %d failures",checks,failures);
  }
