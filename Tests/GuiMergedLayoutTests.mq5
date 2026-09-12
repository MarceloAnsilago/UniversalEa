#property strict
#include "../Include/CanvasGUI/GuiRulesPage.mqh"
int checks=0,failures=0;
void Check(const bool ok,const string label)
  { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   int widths[]={600,960,1120,1792};
   for(int i=0;i<ArraySize(widths);i++)
     {
      CGuiLayout layout; layout.Calculate(widths[i],1600);
      Check(layout.sidebar>0 && layout.left>layout.sidebar,"Left navigation remains visible");
      Check(layout.indicator_rules.y>=layout.cards[1].y+layout.cards[1].h,"Rules follow indicators");
      Check(layout.summary.y>=layout.indicator_rules.y+layout.indicator_rules.h,"Summary follows rules");
      Check(layout.apply.y>=layout.summary.y+layout.summary.h && !layout.too_small,"Footer fits without overlap");
     }
   CGuiLayout layout; layout.Calculate(1792,733);
   Check(!layout.too_small && layout.status.y+layout.status.h+8<=733,"Merged page fits 1792x733");
   CGuiRulesPage rules; rules.Create(); rules.PlaceEmbedded(layout);
   GuiRect card=layout.indicator_rules;
   int width=(card.w-96)/4;
   rules.Click(card.x+24+2*(width+16)+10,card.y+74);
   rules.Key(49); rules.Key(13);
   Check(rules.state.stop_loss==1,"Embedded stop loss remains editable");
   rules.Click(card.x+30,card.y+74); rules.Key(40); rules.Key(13);
   Check(rules.state.order_mode==GUI_ORDER_PENDING,"Embedded order dropdown works");
   Check(rules.Ready(),"Embedded rules validate before leaving");
   PrintFormat("[GuiMergedLayoutTests] %d checks, %d failures",checks,failures);
  }
