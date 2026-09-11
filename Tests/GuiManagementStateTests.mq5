#property script_show_inputs
#include "../Include/CanvasGUI/GuiState.mqh"
#include "../Include/CanvasGUI/GuiLayout.mqh"
int checks=0,failures=0;
void Check(const bool ok,const string message)
  { checks++; if(!ok) { failures++; Print("FAIL: ",message); } }
void OnStart()
  {
   CGuiState state; state.Reset(); string error;
   Check(state.management.Validate(error) && !state.management.Enabled(2) && !state.management.Enabled(6),"Default stops disabled");
   Check(state.management.Choose(0,1) && !state.management.Validate(error),"Enabled breakeven requires trigger");
   Check(state.management.Commit(2,"150,25",error) && state.management.Commit(3,"10",error) && state.management.Validate(error),"Valid breakeven");
   state.management.Commit(3,"150.25",error);
   Check(!state.management.Validate(error),"Protection must be below trigger");
   state.management.Commit(3,"0",error);
   Check(state.management.Validate(error),"Zero protection accepted");
   state.management.Choose(1,1);
   Check(!state.management.Validate(error),"Trailing requires positive parameters");
   state.management.Commit(4,"300",error); state.management.Commit(5,"100",error); state.management.Commit(6,"10",error);
   Check(state.management.Validate(error),"Both stops can be enabled");
   string invalid[]={"","-1","1e3","NaN","1.001","100000001"};
   for(int i=0;i<ArraySize(invalid);i++) Check(!state.management.Commit(6,invalid[i],error) && state.management.values[4]==10,"Invalid step preserves value");
   state.management.Choose(0,2);
   Check(state.management.values[0]==0 && state.management.values[2]==300,"Independent units and resources");
   state.management.Commit(2,"1.25",error); state.management.Commit(3,"0.25",error);
   Check(state.Apply(),"Save percentage breakeven and point trailing");
   state.management.Choose(0,1);
   Check(state.management.values[0]==150.25 && state.management.values[1]==0,"Point values restored");
   state.management.Choose(0,0); state.management.Choose(0,2);
   Check(state.management.values[0]==1.25 && state.management.values[1]==0.25,"Values restored after disabling");
   state.management.Commit(2,"2",error);
   Check(state.applications[0].management.mode[0]==2 && state.applications[0].management.values[0]==1.25 && state.applications[0].management.values[2]==300,"Snapshot independent of edits");
   Check(!state.management.Choose(0,3) && !state.management.Choose(-1,0),"Invalid options rejected");
   state.management.mode[1]=3;
   Check(!state.Apply() && ArraySize(state.applications)==1,"Invalid mode cannot enter history");
   state.Reset();
   Check(state.management.mode[0]==0 && state.management.values[0]==0,"Reset clears management");
   int widths[]={600,960,1120,1600};
   for(int i=0;i<ArraySize(widths);i++)
     {
      CGuiLayout layout; layout.Calculate(widths[i],1000,false,false,true);
      Check(!layout.too_small && layout.status.y+layout.status.h+8<=1000,"Management fits viewport");
      Check(layout.cards[1].h>=376 && layout.cards[0].x+layout.cards[0].w<layout.cards[1].x,"Fields and cards do not overlap");
     }
   CGuiLayout screenshot; screenshot.Calculate(1792,733,false,false,true);
   Check(!screenshot.too_small && screenshot.status.y+screenshot.status.h+8<=733,"User viewport 1792x733 shows management");
   for(int id=0;id<11;id++)
     {
      GuiRect field; screenshot.ManagementFieldBounds(id,field);
      GuiRect card;
      if(id>=7) card=screenshot.schedule;
      else card=screenshot.cards[id<2 ? id : (id<4 ? 0 : 1)];
      Check(field.x>=card.x+24 && field.x+field.w<=card.x+card.w-24 && field.y+field.h<=card.y+card.h-28,"Compact field stays inside card above hint");
     }
   GuiRect distance,step; screenshot.ManagementFieldBounds(5,distance); screenshot.ManagementFieldBounds(6,step);
   Check(distance.y==step.y && distance.x+distance.w<step.x,"Distance and step share a row without overlap");
   screenshot.Calculate(1792,719,false,false,true);
   Check(screenshot.too_small,"Guard remains active below compact footer");
   state.Reset();
   Check(state.management.Choose(2,1) && !state.management.Validate(error),"Mobile stop requires positive parameters when enabled");
   state.management.Commit(7,"200",error); state.management.Commit(8,"80",error); state.management.Commit(9,"5",error);
   Check(state.management.Validate(error) && state.management.values[2]==0 && state.management.mode[1]==0,"Mobile stop independent from trailing stop");
   Check(state.Apply(),"Save mobile stop");
   state.management.Choose(2,2);
   Check(state.management.values[5]==0 && state.management.values[6]==0 && state.management.values[7]==0,"Mobile percentages independent from points");
   state.management.Commit(7,"2",error); state.management.Commit(8,"1",error); state.management.Commit(9,"0.25",error);
   state.management.Choose(2,1);
   Check(state.management.values[5]==200 && state.management.values[6]==80 && state.management.values[7]==5,"Mobile points restored");
   state.management.Commit(7,"250",error);
   Check(state.applications[0].management.mode[2]==1 && state.applications[0].management.values[5]==200,"History preserves mobile stop");
   PrintFormat("[GuiManagementStateTests] %d checks, %d failures",checks,failures);
  }
