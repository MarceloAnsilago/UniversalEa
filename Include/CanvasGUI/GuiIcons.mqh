#ifndef CANVAS_GUI_ICONS_MQH
#define CANVAS_GUI_ICONS_MQH
#include <Canvas/Canvas.mqh>
// Shared 20x20 line icons. Each segment is x1,y1,x2,y2, separated by |.
// No fonts, bitmap resources or additional chart objects are required.
enum ENUM_GUI_ICON
  {
   GUI_ICON_INDICATORS,GUI_ICON_RULES,GUI_ICON_MANAGEMENT,
   GUI_ICON_FILTERS,GUI_ICON_REVIEW,GUI_ICON_ACTIVATION,
   GUI_ICON_PARAMETERS,GUI_ICON_INDICATOR,GUI_ICON_CLOCK,
   GUI_ICON_ARROW_LEFT,GUI_ICON_ARROW_RIGHT
  };
void GuiDrawIcon(CCanvas &canvas,const ENUM_GUI_ICON icon,const int x,const int y,const int size,const uint ink)
  {
   string path="";
   switch(icon)
     {
      case GUI_ICON_ARROW_LEFT:
         path="17,10,3,10|3,10,9,4|3,10,9,16"; break;
      case GUI_ICON_ARROW_RIGHT:
         path="3,10,17,10|17,10,11,4|17,10,11,16"; break;
      case GUI_ICON_INDICATORS:
         path="2,7,6,3|6,3,14,3|14,3,18,7|18,7,2,7|3,11,17,11|4,15,16,15"; break;
      case GUI_ICON_CLOCK:
         path="7,2,13,2|13,2,18,7|18,7,18,13|18,13,13,18|13,18,7,18|7,18,2,13|2,13,2,7|2,7,7,2|10,5,10,10|10,10,14,12"; break;
      case GUI_ICON_RULES:
         path="3,3,3,17|3,6,16,6|3,14,16,14|12,3,16,6|16,6,12,9|12,11,16,14|16,14,12,17"; break;
      case GUI_ICON_MANAGEMENT:
         path="10,2,17,5|17,5,16,12|16,12,10,18|10,18,4,12|4,12,3,5|3,5,10,2|6,10,9,13|9,13,14,7"; break;
      case GUI_ICON_FILTERS:
         path="2,3,18,3|18,3,12,10|12,10,12,16|12,16,8,18|8,18,8,10|8,10,2,3"; break;
      case GUI_ICON_REVIEW:
         path="5,2,15,2|15,2,17,4|17,4,17,18|17,18,3,18|3,18,3,2|3,2,5,2|6,9,9,12|9,12,14,6|6,15,14,15"; break;
      case GUI_ICON_ACTIVATION:
         path="7,3,7,17|7,17,17,10|17,10,7,3"; break;
      case GUI_ICON_PARAMETERS:
         path="2,5,7,5|11,5,18,5|7,3,11,3|11,3,11,7|11,7,7,7|7,7,7,3|2,14,11,14|15,14,18,14|11,12,15,12|15,12,15,16|15,16,11,16|11,16,11,12"; break;
      case GUI_ICON_INDICATOR:
         path="3,2,17,2|17,2,18,3|18,3,18,17|18,17,17,18|17,18,3,18|3,18,2,17|2,17,2,3|2,3,3,2|4,12,7,8|7,8,11,13|11,13,16,6"; break;

     }
   string segments[]; int n=StringSplit(path,'|',segments);
   for(int i=0;i<n;i++)
     {
      string point[];
      if(StringSplit(segments[i],',',point)!=4) continue;
      int x1=x+(int)MathRound(StringToInteger(point[0])*(size-1)/20.0);
      int y1=y+(int)MathRound(StringToInteger(point[1])*(size-1)/20.0);
      int x2=x+(int)MathRound(StringToInteger(point[2])*(size-1)/20.0);
      int y2=y+(int)MathRound(StringToInteger(point[3])*(size-1)/20.0);
      canvas.Line(x1,y1,x2,y2,ink);
     }
  }
#endif
