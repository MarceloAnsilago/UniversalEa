#ifndef UNI_ORDERS_MQH
#define UNI_ORDERS_MQH
#include "UniOrderMath.mqh"

// Uma exposição por ativo/Magic. Não aumenta nem inverte posições existentes.
class CUniOrders
  {
private:
   string m_symbol;
   GuiAppliedConfiguration m_config;
   ENUM_TIMEFRAMES m_period;
   datetime m_moving_bar,m_last_service,m_modify_failure;
   ulong m_wait_order;
   bool m_uncertain;

   bool OwnPosition()
     { return PositionGetString(POSITION_SYMBOL)==m_symbol && PositionGetInteger(POSITION_MAGIC)==m_config.setup.magic; }
   bool OwnOrder()
     { return OrderGetString(ORDER_SYMBOL)==m_symbol && OrderGetInteger(ORDER_MAGIC)==m_config.setup.magic; }
   bool Netting()
     { return AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING; }
protected:
   // Transporte substituível em testes: nenhuma ordem real é enviada pelos mocks.
   virtual bool Permissions(string &error)
     {
      if(!TerminalInfoInteger(TERMINAL_CONNECTED) || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
         !MQLInfoInteger(MQL_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
         !AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
        { error="Negociação indisponível: confira conexão e negociação algorítmica."; return false; }
      return true;
     }
private:
   ENUM_ORDER_TYPE_FILLING Filling()
     {
      long flags=SymbolInfoInteger(m_symbol,SYMBOL_FILLING_MODE);
      if((flags&SYMBOL_FILLING_FOK)!=0) return ORDER_FILLING_FOK;
      if((flags&SYMBOL_FILLING_IOC)!=0) return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }
protected:
   virtual bool Send(MqlTradeRequest &request,string &error,const bool entry=false)
     {
      if(!Permissions(error)) return false;
      MqlTradeCheckResult check={}; MqlTradeResult result={};
      ResetLastError();
      if(!OrderCheck(request,check))
        { error=StringFormat("OrderCheck: %u / %s / erro %d",check.retcode,check.comment,GetLastError()); return false; }
      bool sent=OrderSend(request,result);
      PrintFormat("Uni ordem: action=%d type=%d retcode=%u order=%I64u deal=%I64u / %s",
                  request.action,request.type,result.retcode,result.order,result.deal,result.comment);
      if(entry && (result.retcode==TRADE_RETCODE_TIMEOUT || result.retcode==TRADE_RETCODE_CONNECTION)) m_uncertain=true;
      if(!sent || (result.retcode!=TRADE_RETCODE_DONE && result.retcode!=TRADE_RETCODE_DONE_PARTIAL &&
                   result.retcode!=TRADE_RETCODE_PLACED && result.retcode!=TRADE_RETCODE_NO_CHANGES))
        { error=StringFormat("Ordem recusada ou não confirmada: %u / %s",result.retcode,result.comment); return false; }
      if(entry)
        {
         m_wait_order=result.order;
         if(result.order==0 && result.deal==0) m_uncertain=true;
        }
      return true;
     }
private:
   void Base(MqlTradeRequest &request)
     {
      ZeroMemory(request); request.symbol=m_symbol; request.magic=(ulong)m_config.setup.magic;
      request.deviation=20; request.comment="UniEA";
     }
public:
   CUniOrders() { m_symbol=""; m_wait_order=0; m_uncertain=false; m_moving_bar=0; m_last_service=0; m_modify_failure=0; }
   void Configure(const string symbol,GuiAppliedConfiguration &config,const ENUM_TIMEFRAMES period)
     { m_symbol=symbol; m_config=config; m_period=period; m_moving_bar=iTime(symbol,period,0); m_last_service=0; m_modify_failure=0; }
   bool Busy()
     {
      if(m_uncertain) return true;
      if(m_wait_order>0)
        {
         if(OrderSelect(m_wait_order)) return true;
         if(!HistoryOrderSelect(m_wait_order)) return true;
         ENUM_ORDER_STATE state=(ENUM_ORDER_STATE)HistoryOrderGetInteger(m_wait_order,ORDER_STATE);
         if(state!=ORDER_STATE_FILLED && state!=ORDER_STATE_CANCELED && state!=ORDER_STATE_REJECTED && state!=ORDER_STATE_EXPIRED) return true;
         m_wait_order=0;
        }
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         if(PositionGetTicket(i)==0) return true;
         if(PositionGetString(POSITION_SYMBOL)==m_symbol && (Netting() || OwnPosition())) return true;
        }
      for(int i=OrdersTotal()-1;i>=0;i--)
        {
         if(OrderGetTicket(i)==0) return true;
         if(OrderGetString(ORDER_SYMBOL)==m_symbol && (Netting() || OwnOrder())) return true;
        }
      return false;
     }
   bool Enter(const int side,const datetime signal_bar,string &error)
     {
      error="";
      if(side!=1 && side!=-1) return true;
      if(m_uncertain) { error="Resultado de entrada incerto. Reconcilie as ordens no terminal antes de reiniciar o EA."; return false; }
      if(Busy()) return true;
      if(!Permissions(error)) return false;
      if((side==1 && m_config.setup.direction==GUI_SETUP_SELL_ONLY) ||
         (side==-1 && m_config.setup.direction==GUI_SETUP_BUY_ONLY)) return true;
      MqlTick quote;
      if(!SymbolInfoTick(m_symbol,quote) || quote.bid<=0 || quote.ask<quote.bid) { error="Cotação inválida."; return false; }
      if(!UniEntryWindow(m_config.setup.entry_start,m_config.setup.entry_end,TimeCurrent())) return true;
      if(iTime(m_symbol,m_period,0)!=signal_bar) { error="Vela mudou durante a preparação da ordem."; return false; }
      double point=SymbolInfoDouble(m_symbol,SYMBOL_POINT),tick=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_SIZE);
      int digits=(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
      if(point<=0 || tick<=0) { error="Precisão do ativo indisponível."; return false; }
      MqlTradeRequest request; Base(request);
      bool pending=m_config.rules.order_mode==GUI_ORDER_PENDING;
      request.action=pending ? TRADE_ACTION_PENDING : TRADE_ACTION_DEAL;
      request.type=side==1 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      request.price=side==1 ? quote.ask : quote.bid;
      request.volume=m_config.setup.lot;
      request.type_filling=pending ? ORDER_FILLING_RETURN : Filling();
      if(pending)
        {
         MqlRates bar[];
         if(CopyRates(m_symbol,m_period,m_config.rules.pending_bar,1,bar)!=1) { error="Aguardando candle da pendente."; return false; }
         int reference=m_config.rules.pending_reference;
         request.price=reference==0 ? bar[0].high : (reference==1 ? bar[0].low : (reference==2 ? bar[0].open : bar[0].close));
         double aligned=UniPriceGrid(request.price,tick,digits);
         if(MathAbs(request.price-aligned)>tick*1e-6) { error="OHLC fora do incremento de preço do ativo."; return false; }
         request.price=aligned; request.type=UniPendingType(side,request.price,quote);
         double gap=MathAbs(request.price-(side==1 ? quote.ask : quote.bid));
         if(gap<MathMax(tick,SymbolInfoInteger(m_symbol,SYMBOL_TRADE_STOPS_LEVEL)*point)-tick*1e-8)
           { error="Preço da pendente muito próximo do mercado."; return false; }
         long expiration=SymbolInfoInteger(m_symbol,SYMBOL_EXPIRATION_MODE);
         if((expiration&SYMBOL_EXPIRATION_SPECIFIED)!=0)
           { request.type_time=ORDER_TIME_SPECIFIED; request.expiration=UniEntryDeadline(TimeCurrent(),m_config.setup.entry_start,m_config.setup.entry_end); }
         else if((expiration&SYMBOL_EXPIRATION_GTC)!=0) request.type_time=ORDER_TIME_GTC;
         else if((expiration&SYMBOL_EXPIRATION_DAY)!=0) request.type_time=ORDER_TIME_DAY;
         else { error="Ativo sem validade compatível para a pendente."; return false; }
        }
      MqlRates stop_candle; ZeroMemory(stop_candle);
      if(m_config.rules.stop_multiplier>0)
        {
         MqlRates bars[];
         if(CopyRates(m_symbol,m_period,m_config.rules.stop_bar,1,bars)!=1) { error="Aguardando candle do stop."; return false; }
         stop_candle=bars[0];
        }
      if(!UniOrderTargets(m_config.rules,side,request.price,stop_candle,point,tick,digits,request.sl,request.tp,error)) return false;
      // Distâncias de stops de mercado são verificadas pelo lado de saída (Bid/Ask).
      double anchor=pending ? request.price : (side==1 ? quote.bid : quote.ask);
      double minimum=SymbolInfoInteger(m_symbol,SYMBOL_TRADE_STOPS_LEVEL)*point;
      if((request.sl>0 && side*(anchor-request.sl)<MathMax(tick,minimum)-tick*1e-8) ||
         (request.tp>0 && side*(request.tp-anchor)<MathMax(tick,minimum)-tick*1e-8))
        { error="SL/TP não respeita spread ou distância mínima do ativo."; return false; }
      if(iTime(m_symbol,m_period,0)!=signal_bar) { error="Vela mudou antes do envio."; return false; }
      return Send(request,error,true);
     }
   // Executado também durante a pausa. Cancelamento e zeragem são tentados novamente.
   bool Service(const bool active,string &error)
     {
      error=""; if(m_symbol=="") return true;
      datetime now=TimeCurrent();
      bool window=UniEntryWindow(m_config.setup.entry_start,m_config.setup.entry_end,now);
      bool maintenance=now!=m_last_service; m_last_service=now;
      if(maintenance)
         for(int i=OrdersTotal()-1;i>=0;i--)
           {
            ulong ticket=OrderGetTicket(i); if(ticket==0 || !OwnOrder()) continue;
            ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            if(type==ORDER_TYPE_BUY || type==ORDER_TYPE_SELL) continue;
            datetime created=(datetime)OrderGetInteger(ORDER_TIME_SETUP);
            if(active && window && now<UniEntryDeadline(created,m_config.setup.entry_start,m_config.setup.entry_end)) continue;
            MqlTradeRequest request; Base(request); request.action=TRADE_ACTION_REMOVE; request.order=ticket;
            string issue; if(!Send(request,issue)) error=issue;
           }
      MqlTick quote;
      if(!SymbolInfoTick(m_symbol,quote) || quote.bid<=0 || quote.ask<quote.bid) return error=="";
      double point=SymbolInfoDouble(m_symbol,SYMBOL_POINT),tick=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_SIZE);
      int digits=(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
      if(point<=0 || tick<=0) return error=="";
      datetime bar=iTime(m_symbol,m_period,0);
      bool moving=bar>0 && m_moving_bar>0 && bar>m_moving_bar;
      if(bar>0) m_moving_bar=bar;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         ulong ticket=PositionGetTicket(i); if(ticket==0 || !OwnPosition()) continue;
         int side=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? 1 : -1;
         double entry=PositionGetDouble(POSITION_PRICE_OPEN),sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
         double price=side==1 ? quote.bid : quote.ask;
         datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
         bool due=m_config.setup.trade_mode==GUI_SETUP_DAY_TRADE &&
                  (!window || now>=UniEntryDeadline(opened,m_config.setup.entry_start,m_config.setup.entry_end));
         if(due)
           {
            if(!maintenance) continue;
            MqlTradeRequest request; Base(request); request.action=TRADE_ACTION_DEAL; request.position=ticket;
            request.volume=PositionGetDouble(POSITION_VOLUME); request.price=price;
            request.type=side==1 ? ORDER_TYPE_SELL : ORDER_TYPE_BUY; request.type_filling=Filling();
            string issue; if(!Send(request,issue)) error=issue;
            continue;
           }
         if(m_modify_failure==now) continue;
         double next=UniManagedStop(m_config.management,side,entry,price,sl,point,tick,digits,moving);
         if(next==0 || MathAbs(next-sl)<tick*0.5) continue;
         double freeze=SymbolInfoInteger(m_symbol,SYMBOL_TRADE_FREEZE_LEVEL)*point;
         double minimum=MathMax(SymbolInfoInteger(m_symbol,SYMBOL_TRADE_STOPS_LEVEL)*point,freeze);
         if(side*(price-next)<MathMax(tick,minimum)-tick*1e-8 ||
            (freeze>0 && ((sl>0 && side*(price-sl)<=freeze) || (tp>0 && side*(tp-price)<=freeze)))) continue;
         MqlTradeRequest request; Base(request); request.action=TRADE_ACTION_SLTP; request.position=ticket;
         request.sl=next; request.tp=tp;
         string issue; if(!Send(request,issue)) { error=issue; m_modify_failure=now; }
        }
      return error=="";
     }
  };
#endif
