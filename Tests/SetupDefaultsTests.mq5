#property strict
#define private public
#define OnInit UniTestInit
#define OnDeinit UniTestDeinit
#define OnTick UniTestTick
#define OnChartEvent UniTestChartEvent
#include "../UniEA.mq5"
#undef private
#undef OnInit
#undef OnDeinit
#undef OnTick
#undef OnChartEvent
int setup_checks=0,setup_failures=0;
void SetupCheck(const bool ok,const string label)
  { setup_checks++; if(!ok) { setup_failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   CGuiState initial; BuildInitialConfiguration(initial);
   SetupCheck(initial.setup.timeframe==PERIOD_CURRENT,"Actual EA input defaults to current timeframe");
   SetupCheck(gui.Create(ChartID(),false),"Create actual panel");
   initial.setup.magic=1234567;
   gui.LoadInitialConfiguration(initial);
   SetupCheck(gui.m_setup.state.timeframe==PERIOD_CURRENT && gui.m_setup.m_select[1].selected==GuiSetupTimeframeIndex(PERIOD_CURRENT),"Initial load renders current timeframe");
   SetupCheck(!gui.m_setup.m_select[5].visible && !gui.m_setup.m_select[6].visible && !gui.m_setup.FocusAvailable(7) && !gui.m_setup.FocusAvailable(8),"Legacy position controls hidden and skipped by keyboard");
   initial.setup.timeframe=PERIOD_H1; gui.LoadInitialConfiguration(initial);
   SetupCheck(gui.m_setup.state.timeframe==PERIOD_H1 && gui.m_setup.m_select[1].selected==GuiSetupTimeframeIndex(PERIOD_H1),"Explicit timeframe is preserved");
   initial.setup.timeframe=PERIOD_CURRENT; gui.LoadInitialConfiguration(initial);
   int widths[]={1792,600};
   for(int i=0;i<ArraySize(widths);i++)
     {
      int height=widths[i]<960 ? 1400 : 733;
      gui.m_renderer.Resize(widths[i],height); gui.m_layout.Calculate(widths[i],height,true); gui.Reflow(); gui.Render();
      ResourceSave(gui.m_renderer.m_canvas.ResourceName(),"setup-default-"+IntegerToString(widths[i])+".bmp");
     }
   gui.Destroy();
   PrintFormat("[SetupDefaultsTests] %d checks, %d failures",setup_checks,setup_failures);
  }
