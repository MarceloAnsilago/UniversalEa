#property strict
#property script_show_inputs
#include "../Include/CanvasGUI/Controls/GuiSelectBox.mqh"

int failures=0,checks=0;
void Check(const bool condition,const string label)
  { checks++; if(!condition) { failures++; Print("FAIL: ",label); } }

string TimeOptions()
  {
   string options="";
   for(int minute=0;minute<1440;minute+=5)
     {
      if(minute>0) options+="|";
      options+=StringFormat("%02d:%02d",minute/60,minute%60);
     }
   return options;
  }

bool IsVisible(CGuiSelectBox &select,const int index)
  {
   for(int y=select.popup.y;y<select.popup.y+select.popup.h;y++)
      if(select.OptionAt(select.popup.x+8,y)==index) return true;
   return false;
  }

void CheckLongList()
  {
   CGuiSelectBox select;
   select.SetBounds(20,500,200,40);
   select.SetOptions(TimeOptions());
   select.Open(600);
   Check(select.active && select.row_height==30 && select.popup.h==296,"Long list retains readable eight-row popup");
   Check(select.popup.y>=4 && select.popup.y+select.popup.h+4<=600,"Popup and shadow stay within chart height");
   Check(IsVisible(select,0) && IsVisible(select,7) && !IsVisible(select,8),"First page displays exactly indices 0 through 7");
   Check(select.OptionAt(select.popup.x+8,select.popup.y+6)==-1 &&
         select.OptionAt(select.popup.x+8,select.popup.y+select.popup.h-6)==-1,"Navigation bands are not options");
   Check(select.OptionAt(select.popup.x+2,select.popup.y+40)==-1 &&
         select.OptionAt(select.popup.x+select.popup.w-2,select.popup.y+40)==-1 &&
         select.OptionAt(select.popup.x+8,select.popup.y+select.popup.h-2)==-1,"Popup padding is not an option");
   Check(select.HandlePopupClick(select.popup.x+8,select.popup.y+select.popup.h-6) &&
         select.active && select.selected==0 && IsVisible(select,8) && IsVisible(select,15) && !IsVisible(select,7),
         "Next band scrolls one page without committing or closing");
   Check(select.HandlePopupClick(select.popup.x+8,select.popup.y+6) && IsVisible(select,0),"Previous band returns to first page");
   Check(select.HandlePopupClick(select.popup.x+8,select.popup.y+6) && IsVisible(select,0),"Previous band at first page consumes click without wrapping");
   Check(!select.HandlePopupClick(select.popup.x+8,select.popup.y+40),"Option rows remain available for normal selection");
   Check(select.PopupKey(35) && select.hot==287 && IsVisible(select,287) && !IsVisible(select,279),"End reveals last time 23:55");
   Check(select.HandlePopupClick(select.popup.x+8,select.popup.y+select.popup.h-6) && select.hot==287 && IsVisible(select,287),
         "Next band at final page consumes click without wrapping");
   Check(select.PopupKey(36) && select.hot==0 && IsVisible(select,0),"Home reveals first time 00:00");
   Check(select.PopupKey(34) && select.hot==8 && IsVisible(select,8),"PageDown moves eight options and reveals highlight");
   Check(select.PopupKey(33) && select.hot==0 && IsVisible(select,0),"PageUp returns highlight to first option");
   Check(select.PopupKey(38) && select.hot==287 && IsVisible(select,287),"Up from first option wraps and reveals final option");
   Check(select.PopupKey(40) && select.hot==0 && IsVisible(select,0),"Down from final option wraps and reveals first option");
   Check(!select.PopupKey(13) && !select.PopupKey(27) && !select.PopupKey(9),"Enter Escape and Tab stay owned by page");
   select.SetSelected(287); select.Close(); select.Open(600);
   Check(select.hot==287 && IsVisible(select,287),"Reopening reveals selected final option");
   select.MoveHot(-8);
   Check(select.hot==279 && IsVisible(select,279),"MoveHot keeps highlight visible across pages");
   select.Close();
   Check(!select.PopupKey(35) && !select.HandlePopupClick(28,select.popup.y+6) && select.OptionAt(28,select.popup.y+40)==-1,
         "Closed popup consumes no input");
   select.Open(128);
   Check(select.active && select.row_height==30 && select.popup.h==116 && select.popup.y>=4 &&
         select.popup.y+select.popup.h+4<=128 && IsVisible(select,287),"Short chart reduces visible rows while retaining font and selected item");
   select.Close(); select.Open(80);
   Check(!select.active,"Insufficient height does not open an unreadable long popup");
  }

void CheckSmallList()
  {
   CGuiSelectBox select;
   select.SetBounds(20,40,200,40); select.SetOptions("None|MA|RSI"); select.SetSelected(1); select.Open(600);
   Check(select.active && select.popup.h==98 && select.row_height==30 && select.hot==1,"Small list keeps original layout and selection");
   Check(select.OptionAt(28,select.popup.y+4)==0 && select.OptionAt(28,select.popup.y+34)==1 &&
         select.OptionAt(28,select.popup.y+64)==2 && select.OptionAt(28,select.popup.y+94)==-1,"Small list maps exact row boundaries");
   Check(!select.HandlePopupClick(28,select.popup.y+6),"Small list has no paging bands");
   select.MoveHot(1); Check(select.hot==2,"Small list moves down");
   select.MoveHot(1); Check(select.hot==0,"Small list retains wrap navigation");
   select.Close(); select.enabled=false; select.Open(600);
   Check(!select.active,"Disabled select cannot open");
   select.enabled=true; select.visible=false; select.Open(600);
   Check(!select.active,"Hidden select cannot open");
   select.visible=true; select.SetOptions(""); select.Open(600);
   Check(!select.active,"Empty select cannot open");
  }

void OnStart()
  {
   CheckLongList(); CheckSmallList();
   PrintFormat("[GuiSelectBoxTests] %d checks, %d failures",checks,failures);
  }
