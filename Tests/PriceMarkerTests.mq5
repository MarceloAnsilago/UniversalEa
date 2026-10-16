#property strict
#include "../Include/UniPriceMarkers.mqh"
int checks=0,failures=0;
void Check(const bool ok,const string text)
  { checks++; if(!ok) { failures++; Print("FAIL: ",text); } }
void OnStart()
  {
   CUniPriceMarkers markers;
   markers.Configure(ChartID(),(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
   int before=ObjectsTotal(ChartID());
   double low=ChartGetDouble(ChartID(),CHART_PRICE_MIN,0),high=ChartGetDouble(ChartID(),CHART_PRICE_MAX,0);
   double middle=(low+high)/2,range=high-low;
   Check(!markers.Set("bad","Invalid",0,clrRed) && markers.Count()==0,"Reject zero price");
   Check(markers.Set("entry","COMPRA",middle,clrRoyalBlue),"Add entry");
   Check(markers.Set("entry","COMPRA",middle+range*0.02,clrRoyalBlue) && markers.Count()==1,"Update key without duplicate");
   markers.Set("stop","STOP",middle-range*0.2,clrCrimson);
   markers.Set("take","TAKE",middle+range*0.2,clrSeaGreen);
   markers.Set("trailing","TRAILING",middle-range*0.195,clrDarkOrchid);
   markers.Set("grid","GRID 1",middle+range*0.205,clrDarkOrange);
   Check(markers.Count()==5 && markers.Render(),"Render reusable marker types and nearby levels");
   Check(ObjectsTotal(ChartID())==before+1,"One Canvas for all markers");
   Check(markers.Render() && ObjectsTotal(ChartID())==before+1,"Unchanged render reuses Canvas");
   ChartRedraw(); Sleep(300);
   Check(ChartScreenShot(ChartID(),"price-markers-preview.png",(int)ChartGetInteger(ChartID(),CHART_WIDTH_IN_PIXELS),
                         (int)ChartGetInteger(ChartID(),CHART_HEIGHT_IN_PIXELS),ALIGN_RIGHT),"Save visual preview");
   Check(markers.Remove("grid") && !markers.Remove("missing") && markers.Count()==4,"Remove by key");
   markers.BeginFrame();
   Check(markers.Count()==0 && markers.Render() && ObjectsTotal(ChartID())==before,"Empty frame removes Canvas");
   markers.Set("again","TAKE",middle,clrSeaGreen);
   Check(markers.Render() && ObjectsTotal(ChartID())==before+1,"Recreate after empty frame");
   markers.Destroy(); markers.Destroy();
   Check(ObjectsTotal(ChartID())==before,"Destroy is repeatable and removes only owned object");
   PrintFormat("[PriceMarkerTests] %d checks, %d failures",checks,failures);
  }
