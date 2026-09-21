#ifndef CANVAS_GUI_THEME_MQH
#define CANVAS_GUI_THEME_MQH
#define GUI_BG       0xFFF7F8FA
#define GUI_CARD     0xFFFFFFFF
#define GUI_TEXT     0xFF1C293D
#define GUI_MUTED    0xFF718096
// Contornos mais escuros para leitura em monitores com pouco contraste.
// O azul continua identificando o campo ativo ou com foco.
#define GUI_BORDER          0xFF78879D
#define GUI_BORDER_HOVER    0xFF475569
#define GUI_BORDER_ACTIVE   0xFF2563EB
#define GUI_BORDER_DISABLED 0xFFA5AFBF
#define GUI_WINDOW_BORDER 0xFF536F9C
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
