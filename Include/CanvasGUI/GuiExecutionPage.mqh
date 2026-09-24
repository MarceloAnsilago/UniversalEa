#ifndef GUI_EXECUTION_PAGE_MQH
#define GUI_EXECUTION_PAGE_MQH
#include "GuiState.mqh"
#include "Controls/GuiButton.mqh"
#include "GuiScrollBar.mqh"

class CGuiExecutionPage
  {
private:
   CGuiButton m_apply,m_toggle;
   CGuiScrollBar m_scroll;
   GuiRect m_card;
   int m_focus,m_height;
   bool m_active,m_applied,m_error;
   string m_message,m_applied_name;
   int m_revision;
public:
   CGuiExecutionPage() { m_focus=0; m_active=false; m_applied=false; m_error=false; m_revision=0; }
   void Place(CGuiLayout &layout)
     {
      m_height=layout.height;
      m_card.Set(layout.left,160,layout.content_width,(int)MathMax(100,layout.height-310));
      int half=(layout.content_width-16)/2;
      m_apply.caption="Aplicar ao motor"; m_toggle.caption=m_active ? "Pausar análise" : "Ativar análise";
      m_apply.SetBounds(layout.left,layout.height-134,half,42);
      m_toggle.SetBounds(layout.left+half+16,layout.height-134,half,42);
      m_toggle.enabled=m_applied; m_toggle.secondary=true;
      m_scroll.viewport=(int)MathMax(1,m_card.h-32);
      m_scroll.maximum=(int)MathMax(0,22*24-m_scroll.viewport);
      m_scroll.track.Set(layout.width-20,172,12,(int)MathMax(40,m_card.h-24));
      m_scroll.Set(m_scroll.offset);
     }
   void SetResult(const bool applied,const bool active,const int revision,const string name,const string message,const bool error)
     { m_applied=applied; m_active=active; m_revision=revision; m_applied_name=name; m_message=message; m_error=error;
       m_toggle.enabled=applied; m_toggle.caption=active ? "Pausar análise" : "Ativar análise"; }
   bool Active() { return m_active; }
   int Click(const int x,const int y)
     {
      if(m_apply.ContainsPoint(x,y)) { m_focus=0; return 1; }
      if(m_toggle.enabled && m_toggle.ContainsPoint(x,y)) { m_focus=1; return m_active ? 3 : 2; }
      if(m_scroll.track.Contains(x,y)) Scroll(y<m_scroll.thumb.y ? -144 : 144);
      return 0;
     }
   int Key(const int key)
     {
      if(key==9) { m_focus=1-m_focus; if(!m_toggle.enabled) m_focus=0; }
      if(key==33) Scroll(-144);
      if(key==34) Scroll(144);
      if(key==13 || key==32) return m_focus==0 ? 1 : (m_toggle.enabled ? (m_active ? 3 : 2) : 0);
      return 0;
     }
   void Mouse(const int x,const int y)
     { m_apply.SetHover(m_apply.ContainsPoint(x,y)); m_toggle.SetHover(m_toggle.enabled && m_toggle.ContainsPoint(x,y)); }
   void Scroll(const int delta) { m_scroll.Set(m_scroll.offset+delta); }
   void Render(CGuiRenderer &r,CGuiState &draft,const string symbol)
     {
      r.Box(m_card,GUI_CARD,GUI_BORDER);
      string rows[22];
      rows[0]="CONFIGURAÇÃO DO PAINEL";
      rows[1]="Setup: "+draft.setup.name+"  |  Magic: "+IntegerToString(draft.setup.magic);
      rows[2]="Ativo: "+symbol+"  |  Período: "+draft.setup.Value(3);
      rows[3]="Direção: "+draft.setup.Value(4)+"  |  Lote: "+draft.setup.Value(10);
      rows[4]="Entradas: "+draft.setup.Value(5)+" a "+draft.setup.Value(6)+" (servidor)";
      rows[5]="Posições: "+draft.setup.Value(9)+(draft.setup.trade_mode==GUI_SETUP_DAY_TRADE ? " / encerrar no dia" : " / pode manter entre dias");
      rows[6]="Ordem: "+draft.rules.Value(0);
      string references[]={"Máxima","Mínima","Abertura","Fechamento"};
      int ref=draft.rules.pending_reference;
      rows[7]=draft.rules.order_mode==GUI_ORDER_PENDING ? "Pendente: "+(ref>=0 && ref<4 ? references[ref] : "Inválida")+" / candle "+IntegerToString(draft.rules.pending_bar) : "Entrada a mercado";
      rows[8]="Stop: distância "+draft.rules.Value(2)+" "+draft.rules.Unit();
      rows[9]="+ "+draft.rules.Value(19)+" vezes candle "+draft.rules.Value(20)+" / "+(draft.rules.stop_measure==0 ? "Total" : "Corpo");
      rows[10]="Take Profit: "+draft.rules.TakeSummary();
      rows[11]="Filtro de candle: "+draft.rules.Value(1);
      for(int i=0;i<4;i++)
        {
         IndicatorConfig c=draft.indicators[i];
         int period=c.type==GUI_INDICATOR_MA ? c.maPeriod : (c.type==GUI_INDICATOR_RSI ? c.rsiPeriod : c.adxPeriod);
         rows[12+i]="Indicador "+IntegerToString(i+1)+": "+GuiIndicatorName(c.type)+(c.type==GUI_INDICATOR_NONE ? "" : " / período "+IntegerToString(period));
        }
      rows[16]="Breakeven: "+draft.management.Summary(0);
      rows[17]="Trailing: "+draft.management.Summary(1);
      rows[18]="Stop móvel: "+draft.management.Summary(2);
      rows[19]="ESTA ETAPA ANALISA SINAIS; NÃO ENVIA ORDENS.";
      rows[20]="Gestão e encerramento estão configurados, sem execução.";
      rows[21]="Aplicar atualiza o motor e deixa a análise pausada.";
      for(int i=0;i<22;i++)
        {
         int y=m_card.y+18+i*24-m_scroll.offset;
         if(y<m_card.y+8 || y+18>m_card.y+m_card.h-8) continue;
         r.Text(m_card.x+20,y,rows[i],i==0 || i==19 ? GUI_ACCENT : GUI_TEXT,13,i==0 || i==19,m_card.w-40);
        }
      r.Round(m_scroll.track,GUI_BORDER,6); r.Round(m_scroll.thumb,GUI_ACCENT,6);
      m_apply.focused=m_focus==0; m_toggle.focused=m_focus==1;
      m_apply.Draw(r); m_toggle.Draw(r);
      string state=m_active ? "Análise ativa" : "Análise pausada";
      if(m_applied) state+=" / versão "+IntegerToString(m_revision)+" / "+m_applied_name;
      else state="Nenhuma configuração aplicada ao motor";
      r.Text(m_card.x,m_height-76,state,GUI_ACCENT,12,true,m_card.w);
      r.Text(m_card.x,m_height-52,m_message,m_error ? GUI_ERROR : GUI_MUTED,12,false,m_card.w);
      r.Text(m_card.x,m_height-28,"Editar ou salvar não altera a configuração já aplicada.",GUI_MUTED,11,false,m_card.w);
     }
  };
#endif
