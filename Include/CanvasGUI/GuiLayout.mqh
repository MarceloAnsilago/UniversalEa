#ifndef CANVAS_GUI_LAYOUT_MQH
#define CANVAS_GUI_LAYOUT_MQH
#include "GuiTheme.mqh"
class CGuiLayout
  {
public:
   int width,height,left,content_width,columns,sidebar;
   bool compact,too_small,dense;
   GuiRect cards[2],apply,status,summary,schedule;
   void Calculate(const int w,const int h,const bool setup=false,const bool rules=false,const bool management=false)
     {
      width=w; height=h; compact=(w>=960); columns=2;
      dense=h<(compact ? (w>=1120 ? 794 : 832) : 1144)+(!setup && !rules ? 40 : 0);
      if(management) dense=h<(w>=1120 ? 858 : 896);
      sidebar=w>=1120 ? 196 : 0;
      content_width=(int)MathMin(w-sidebar-48,1120);
      left=sidebar+(w-sidebar-content_width)/2;
      int top=dense ? (sidebar>0 ? 160 : 184) : (sidebar>0 ? 222 : 260);
      int card_height=dense ? 236 : 292;
      int gap=dense ? 16 : 20;
      if(compact)
        {
         int cw=(content_width-24)/2;
         cards[0].Set(left,top,cw,card_height);
         cards[1].Set(left+cw+24,top,cw,card_height);
        }
      else
        {
         cards[0].Set(left,top,content_width,card_height);
         cards[1].Set(left,top+card_height+gap,content_width,card_height);
        }
      int bottom=cards[1].y+cards[1].h;
      summary.Set(left,bottom+(dense ? 8 : 20),content_width,dense ? 160 : 180);
      int footer=summary.y+summary.h+(dense ? 8 : 24);
      apply.Set(left+content_width-204,footer,204,44);
      status.Set(left,footer,content_width-224,48);
      // Include the footer below the summary in the viewport guard.
      too_small=(w<600 || h<status.y+status.h+8);
      if(!setup)
        {
         if(rules) summary.h=112;
         int footer=summary.y+summary.h+16;
         apply.Set(left+content_width-204,footer,204,44);
         status.Set(left,footer+56,content_width,40);
         too_small=(w<600 || h<status.y+status.h+8);
        }
      if(rules)
        {
         if(compact)
           {
            int cw=(content_width-32)/3;
            card_height=(int)MathMax(card_height,312);
            cards[0].Set(left,top,cw,card_height);
            schedule.Set(left+cw+16,top,cw,card_height);
            cards[1].Set(left+2*(cw+16),top,content_width-2*(cw+16),card_height);
           }
         else
           {
            int cw=(content_width-16)/2;
            cards[0].Set(left,top,cw,180);
            schedule.Set(left+cw+16,top,content_width-cw-16,180);
            cards[1].Set(left,top+196,content_width,312);
           }
         summary.Set(left,cards[1].y+cards[1].h+16,content_width,112);
         apply.Set(left+content_width-204,summary.y+summary.h+16,204,44);
         status.Set(left,apply.y+56,content_width,40);
         too_small=(w<600 || h<status.y+status.h+8);
        }
      if(management)
        {
         int cw=(content_width-32)/3;
         int management_height=dense && cw>=300 ? 312 : 388;
         schedule.Set(left,top,cw,management_height);
         cards[0].Set(left+cw+16,top,cw,management_height);
         cards[1].Set(left+2*(cw+16),top,content_width-2*(cw+16),management_height);
         summary.Set(left,top+management_height+16,content_width,112);
         apply.Set(left+content_width-204,summary.y+summary.h+16,204,44);
         status.Set(left,apply.y+56,content_width,40);
         too_small=(w<600 || h<status.y+status.h+8);
        }
      if(setup)
        {
         if(compact)
           {
            int cw=(content_width-32)/3;
            cards[0].Set(left,top,cw,330);
            cards[1].Set(left+cw+16,top,cw,330);
            schedule.Set(left+2*(cw+16),top,content_width-2*(cw+16),330);
           }
         else
           {
            int cw=(content_width-16)/2;
            cards[0].Set(left,top,cw,316);
            cards[1].Set(left+cw+16,top,content_width-cw-16,316);
            schedule.Set(left,top+332,content_width,236);
           }
         int footer=schedule.y+schedule.h+20;
         apply.Set(left+content_width-204,footer,204,44);
         status.Set(left,footer,content_width-224,48);
         too_small=(w<600 || h<status.y+status.h+8);
        }
     }
   void ManagementFieldBounds(const int id,GuiRect &r)
     {
      int card=id==10 ? 2 : (id<2 ? id : (id<4 ? 0 : (id<7 ? 1 : 2)));
      GuiRect c; if(card==2) c=schedule; else c=cards[card];
      int row=id<2 || id==10 ? 0 : (id<4 ? id-1 : (id<7 ? id-3 : id-6));
      bool pair=c.h==312 && (id==5 || id==6 || id==8 || id==9);
      if(pair) row=2;
      int field_width=pair ? (c.w-64)/2 : c.w-48;
      int x=c.x+24+(pair && (id==6 || id==9) ? field_width+16 : 0);
      r.Set(x,c.y+78+row*76,field_width,42);
     }
   void SlotBounds(const int slot,GuiRect &r)
     {
      int w=(cards[0].w-72)/4;
      r.Set(cards[0].x+24+slot*(w+8),cards[0].y+60,w,36);
     }
   void IndicatorBounds(const int indicator,GuiRect &r)
     { r.Set(cards[0].x+24,cards[0].y+136,cards[0].w-48,42); }
   void ParameterBounds(const int card,const int index,GuiRect &r)
     {
      int w=(cards[1].w-64)/2;
      r.Set(cards[1].x+24+(index%2)*(w+16),cards[1].y+90+(index/2)*76,w,42);
     }
  };
#endif
