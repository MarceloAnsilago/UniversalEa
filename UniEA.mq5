#property strict
#property version "1.00"
#property description "Experimento de GUI Canvas. Sem trading ou indicadores reais."
#include "Include/CanvasGUI/GuiApp.mqh"

input bool DebugGUI=true;
CGuiApp gui;
int OnInit() { return gui.Create(ChartID(),DebugGUI) ? INIT_SUCCEEDED : INIT_FAILED; }
void OnDeinit(const int reason) { gui.Destroy(); }
void OnTick() {}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  { gui.Event(id,lparam,dparam,sparam); }
