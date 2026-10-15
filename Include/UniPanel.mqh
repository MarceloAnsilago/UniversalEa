#ifndef UNI_PANEL_MQH
#define UNI_PANEL_MQH
#include <Canvas/Canvas.mqh>
#include "Configuration/GuiState.mqh"

// Resumo somente leitura; a configuracao continua nas propriedades do EA.
class CUniPanel
  {
private:
   CCanvas m_canvas;
   long m_chart;
   string m_name,m_status;
   CGuiState m_config;
   string m_overview[];
   datetime m_updated;
   string m_error;
   void Add(const string value)
     { int n=ArraySize(m_overview); ArrayResize(m_overview,n+1); m_overview[n]=value; }
   IndicatorConfig m_indicators[4];
   int m_scroll,m_total;
   bool m_ready;
   void Box(const int x,const int y,const int w,const int h,const int r,const uint ink)
     {
      m_canvas.FillRectangle(x+r,y,x+w-r-1,y+h-1,ink);
      m_canvas.FillRectangle(x,y+r,x+w-1,y+h-r-1,ink);
      m_canvas.FillCircle(x+r,y+r,r,ink);
      m_canvas.FillCircle(x+w-r-1,y+r,r,ink);
      m_canvas.FillCircle(x+r,y+h-r-1,r,ink);
      m_canvas.FillCircle(x+w-r-1,y+h-r-1,r,ink);
     }
   void Text(const int x,const int y,const string value,const int size=15,const uint ink=0xFF16324F)
     {
      m_canvas.FontSet("Segoe UI",size);
      string visible=value;
      while(StringLen(visible)>0 && m_canvas.TextWidth(visible)>m_canvas.Width()-x-16)
         visible=StringSubstr(visible,0,StringLen(visible)-1);
      m_canvas.TextOut(x,y,visible,ink);
     }
   int Rows(const IndicatorConfig &c)
     { return c.type==GUI_INDICATOR_MA ? 5 : (c.type==GUI_INDICATOR_RSI ? 3 : (c.type==GUI_INDICATOR_ADX ? 2 : 1)); }
   string Row(const IndicatorConfig &c,const int i)
     {
      if(c.type==GUI_INDICATOR_NONE) return "Selecione o tipo nos inputs do EA.";
      if(i==0) return "Fonte de dados para a grade Sinal";
      if(c.type==GUI_INDICATOR_RSI)
        {
         if(i==1) return "Período: "+IntegerToString(c.rsiPeriod);
         return "Preço aplicado: "+GuiPriceName((int)c.rsiPrice-1);
        }
      if(c.type==GUI_INDICATOR_ADX)
         return "Período: "+IntegerToString(c.adxPeriod);
      if(i==1) return "Período: "+IntegerToString(c.maPeriod);
      if(i==2) return "Método: "+GuiMethodName((int)c.maMethod);
      if(i==3) return "Deslocamento: "+IntegerToString(c.maShift);
      return "Preço aplicado: "+GuiPriceName((int)c.maPrice-1);
     }
   void Draw()
     {
      int w=m_canvas.Width(),h=m_canvas.Height();
      int viewport=h-140;
      m_total=ArraySize(m_overview)>0 ? ArraySize(m_overview)*36+4*(64+18) : 0;
      for(int i=0;i<4;i++) m_total+=100+Rows(m_indicators[i])*44+18;
      m_scroll=(int)MathMax(0,MathMin(m_scroll,m_total-viewport));
      m_canvas.Erase(0xFFFDFDFD);
      int y=98-m_scroll;
      int starts[]={0,9,16,18};
      string titles[]={"Setup e operação","Posições e resultados","Alvos configurados","Monitor de execução"};
      for(int group=0;group<4 && ArraySize(m_overview)>0;group++)
        {
         int first=starts[group],last=group<3 ? starts[group+1] : ArraySize(m_overview);
         int ch=64+(last-first)*36;
         if(y+ch>=98 && y<h-42)
           {
            Box(17,y+3,w-32,ch,4,0xFFF0F0F0);
            Box(15,y,w-32,ch,4,0xFFD8D8D8);
            Box(16,y+1,w-34,ch-2,3,0xFFFFFEFC);
            Text(34,y+22,titles[group],15,0xFF009F89);
            m_canvas.LineHorizontal(34,w-37,y+49,0xFFE7E9EC);
            for(int row=first;row<last;row++)
              {
               int ry=y+62+(row-first)*36;
               uint ink=0xFF16324F;
               string line=m_overview[row];
               if(row==0) ink=StringFind(line,"Fora")==0 ? 0xFFB7791F : 0xFF009F89;
               if(row==11 || row==12 || row==13 || row==14)
                  ink=StringFind(line,": -")>=0 ? 0xFFC44444 : 0xFF009F89;
               if(StringFind(line,"Erro:")==0 || StringFind(line,"Bloqueado")>=0 || StringFind(line,"Desconectado")>=0)
                  ink=0xFFC44444;
               Text(34,ry,line,13,ink);
               if(row<last-1) m_canvas.LineHorizontal(34,w-37,ry+26,0xFFE7E9EC);
              }
           }
         y+=ch+18;
        }
      for(int i=0;i<4;i++)
        {
         IndicatorConfig c=m_indicators[i];
         int rows=Rows(c),ch=100+rows*44;
         bool active=c.type!=GUI_INDICATOR_NONE;
         if(y+ch>=98 && y<h-42)
           {
            Box(17,y+3,w-32,ch,4,0xFFF0F0F0);
            Box(15,y,w-32,ch,4,0xFFD8D8D8);
            Box(16,y+1,w-34,ch-2,3,0xFFFFFEFC);
            Text(34,y+22,"Indicador "+IntegerToString(i+1),13,0xFF7890A5);
            Box(w-99,y+19,64,24,11,active ? 0xFFE8F7F3 : 0xFFF0F1F3);
            Text(w-89,y+23,active ? "Ativo" : "Inativo",12,active ? 0xFF009F89 : 0xFF7B8793);
            string type=GuiIndicatorName(c.type);
            m_canvas.FontSet("Segoe UI",16,FW_BOLD);
            int badge=m_canvas.TextWidth(type)+20;
            Box(34,y+52,badge,33,3,0xFFF2F3F5);
            m_canvas.TextOut(44,y+59,type,active ? 0xFF00A58D : 0xFF7B8793);
            for(int row=0;row<rows;row++)
              {
               int ry=y+108+row*44;
               Text(34,ry,Row(c,row),14);
               if(row<rows-1) m_canvas.LineHorizontal(34,w-37,ry+30,0xFFD8D8D8);
              }
           }
         y+=ch+18;
        }
      // Fixed header and footer also clip scrolled card content.
      m_canvas.FillRectangle(0,0,w-1,97,0xFFFDFDFD);
      Text(16,12,"UniEA",13,0xFF009F89);
      Text(16,34,"Operação e resultados",20);
      Text(16,66,m_status,12,0xFF718096);
      m_canvas.FillRectangle(0,h-42,w-1,h-1,0xFFFDFDFD);
      m_canvas.LineHorizontal(16,w-17,h-42,0xFFE7E9EC);
      Text(22,h-28,"Anterior",13,m_scroll>0 ? 0xFF009F89 : 0xFFAAB2BB);
      Text(w-91,h-28,"Próximo",13,m_scroll<m_total-viewport ? 0xFF009F89 : 0xFFAAB2BB);
      m_canvas.Update();
     }
public:
   CUniPanel() { m_chart=0; m_scroll=0; m_total=0; m_ready=false; m_updated=0; }
   ~CUniPanel() { Destroy(); }
   bool Create(const long chart,const string status,const CGuiState &config)
     {
      Destroy();
      m_chart=chart; m_status=status; m_scroll=0; m_config=config; m_updated=0;
      for(int i=0;i<4;i++) m_indicators[i]=config.indicators[i];
      m_name="UniEA.Panel."+IntegerToString(chart)+"."+IntegerToString((long)GetMicrosecondCount());
      int height=(int)MathMax(220,MathMin(820,ChartGetInteger(chart,CHART_HEIGHT_IN_PIXELS)-40));
      if(!m_canvas.CreateBitmapLabel(chart,0,m_name,12,20,366,height,COLOR_FORMAT_XRGB_NOALPHA))
        { m_canvas.Destroy(); return false; }
      ObjectSetInteger(chart,m_name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(chart,m_name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(chart,m_name,OBJPROP_ZORDER,10);
      m_ready=true;
      Draw();
      return true;
     }
   void Refresh(const bool active,const bool configured,const string error="")
     {
      if(!m_ready) return;
      datetime now=TimeCurrent();
      if(now==m_updated && error==m_error) return;
      m_updated=now; m_error=error;
      ArrayResize(m_overview,0);
      MqlDateTime date; TimeToStruct(now,date);
      int minute=date.hour*60+date.min;
      int start=m_config.setup.entry_start,end=m_config.setup.entry_end;
      bool window=start<end ? minute>=start && minute<end : minute>=start || minute<end;
      int positions=0,orders=0; double volume=0,floating=0,positive=0,negative=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         if(PositionGetTicket(i)==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol ||
            PositionGetInteger(POSITION_MAGIC)!=m_config.setup.magic) continue;
         positions++; volume+=PositionGetDouble(POSITION_VOLUME);
         floating+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
        }
      for(int i=OrdersTotal()-1;i>=0;i--)
         if(OrderGetTicket(i)>0 && OrderGetString(ORDER_SYMBOL)==_Symbol &&
            OrderGetInteger(ORDER_MAGIC)==m_config.setup.magic) orders++;
      date.hour=0; date.min=0; date.sec=0;
      bool history=HistorySelect(StructToTime(date),now);
      if(history)
         for(int i=0;i<HistoryDealsTotal();i++)
           {
            ulong deal=HistoryDealGetTicket(i);
            if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol ||
               HistoryDealGetInteger(deal,DEAL_MAGIC)!=m_config.setup.magic) continue;
            double net=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_SWAP)+
                       HistoryDealGetDouble(deal,DEAL_COMMISSION)+HistoryDealGetDouble(deal,DEAL_FEE);
            if(net>=0) positive+=net; else negative+=net;
           }
      string currency=AccountInfoString(ACCOUNT_CURRENCY);
      bool permitted=MQLInfoInteger(MQL_TRADE_ALLOWED) && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&
                     AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) && AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
      m_status=!configured ? "Sem configuração" : !active ? "Entradas pausadas" :
               !window ? "Fora do horário de operação" : error!="" ? "Erro na execução" :
               !permitted ? "Negociação bloqueada" : positions>0 ? "Gerenciando posição" :
               orders>0 ? "Aguardando ordem pendente" : "Aguardando sinal";
      Add(window ? "Dentro do horário de operação" : "Fora do horário de operação");
      Add("EA: UniEA | Setup: "+m_config.setup.name);
      Add("Magic: "+IntegerToString(m_config.setup.magic));
      ENUM_TIMEFRAMES period=m_config.setup.timeframe==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : m_config.setup.timeframe;
      Add("Ativo: "+_Symbol+" | "+EnumToString(period));
      Add("Servidor: "+TimeToString(now,TIME_DATE|TIME_SECONDS));
      Add("Entradas: "+GuiSetupTimeLabel(start)+" até "+GuiSetupTimeLabel(end));
      Add("Modo: "+(m_config.setup.trade_mode==0 ? "Day trade" : "Swing trade"));
      Add("Direção: "+(m_config.setup.direction==0 ? "Compra e venda" : m_config.setup.direction==1 ? "Compra" : "Venda"));
      Add("Lote: "+DoubleToString(m_config.setup.lot,4)+" | "+(m_config.rules.order_mode==GUI_ORDER_PENDING ? "Pendente" : "A mercado"));
      Add("Posições: "+IntegerToString(positions)+" | Pendentes: "+IntegerToString(orders));
      Add("Volume aberto: "+DoubleToString(volume,4));
      Add("Em aberto: "+DoubleToString(floating,2)+" "+currency);
      Add(history ? "Ganhos hoje: "+DoubleToString(positive,2)+" "+currency : "Histórico do dia indisponível");
      Add("Perdas/custos hoje: "+DoubleToString(negative,2)+" "+currency);
      Add("Líquido hoje: "+DoubleToString(positive+negative,2)+" "+currency);
      Add("Resultados: somente este ativo e Magic");
      Add("Stop: "+m_config.rules.StopSummary());
      Add("Take: "+m_config.rules.TakeSummary());
      Add("Conexão: "+(TerminalInfoInteger(TERMINAL_CONNECTED) ? "OK" : "Desconectado"));
      Add("AutoTrading: "+(MQLInfoInteger(MQL_TRADE_ALLOWED) && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) && AccountInfoInteger(ACCOUNT_TRADE_EXPERT) ? "Permitido" : "Bloqueado"));
      if(error!="") Add("Erro: "+error);
      else if(positions>0 || orders>0) Add("Nova entrada bloqueada por exposição");
      else Add("Sem posição ou pendente deste setup");
      Draw();
     }
   void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(!m_ready) return;
      if(id==CHARTEVENT_CHART_CHANGE)
        {
         int h=(int)MathMax(220,MathMin(820,ChartGetInteger(m_chart,CHART_HEIGHT_IN_PIXELS)-40));
         if(h!=m_canvas.Height() && m_canvas.Resize(366,h)) Draw();
        }
      if(id==CHARTEVENT_OBJECT_CLICK && sparam==m_name)
        {
         int x=(int)lparam-12,y=(int)dparam-20;
         if(y<m_canvas.Height()-42 || y>=m_canvas.Height()) return;
         if(x>=16 && x<115) m_scroll-=180;
         else if(x>=m_canvas.Width()-110 && x<m_canvas.Width()-16) m_scroll+=180;
         else return;
         Draw();
        }
     }
   void Destroy()
     { m_ready=false; m_canvas.Destroy(); }
  };
#endif
