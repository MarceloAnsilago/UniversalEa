#ifndef CANVAS_GUI_THEME_MQH
#define CANVAS_GUI_THEME_MQH
#define GUI_BG       0xFFF7F8FA
#define GUI_CARD     0xFFFFFFFF
#define GUI_TEXT     0xFF1C293D
#define GUI_MUTED    0xFF718096
// Neutral surfaces; blue is reserved for focus and the primary action.
#define GUI_BORDER          0xFFE2E6ED
#define GUI_BORDER_HOVER    0xFFA5B4C8
#define GUI_BORDER_ACTIVE   0xFF2563EB
#define GUI_BORDER_DISABLED 0xFFDCE3EC
#define GUI_WINDOW_BORDER 0xFF8BAAE0
#define GUI_ACCENT   0xFF2563EB
#define GUI_HOVER    0xFFEFF5FF
#define GUI_DISABLED 0xFFF0F2F5
#define GUI_ERROR    0xFFBA3248
struct GuiRect
  {
   int x,y,w,h;
   void Set(const int px,const int py,const int pw,const int ph) { x=px; y=py; w=pw; h=ph; }
   bool Contains(const int px,const int py) const { return px>=x && py>=y && px<x+w && py<y+h; }
  };
#endif
