#property strict
#include "../Include/UniOrders.mqh"
// O transporte é substituído; este script nunca chama OrderSend/OrderCheck.
class COrderProbe : public CUniOrders
  {
protected:
   virtual bool Permissions(string &error) { error=""; return true; }
   virtual bool Send(MqlTradeRequest &request,string &error,const bool entry=false)
     { last=request; sends++; error=""; return true; }
public:
   MqlTradeRequest last;
   int sends;
   COrderProbe() { sends=0; ZeroMemory(last); }
  };
int checks=0,failures=0;
void Check(const bool ok,const string label)
  { checks++; if(!ok) { failures++; Print("FAIL: ",label); } }
void OnStart()
  {
   // Rodar no terminal portátil sem posições ou ordens.
   if(PositionsTotal()!=0 || OrdersTotal()!=0) { Print("FAIL: test requires an empty account"); return; }
   CGuiState state; GuiAppliedConfiguration config;
   config.setup=state.setup; config.rules=state.rules; config.management=state.management;
   config.setup.magic=12345; MqlDateTime clock; TimeToStruct(TimeCurrent(),clock); int minute=(clock.hour*60+clock.min)/5*5; config.setup.entry_start=(minute+1435)%1440; config.setup.entry_end=(minute+10)%1440;
   config.rules.stop_multiplier=0; config.rules.take_mode=1; config.rules.stop_loss=0; config.rules.take_profit=0;
   COrderProbe probe; probe.Configure(_Symbol,config,PERIOD_M1);
   MqlTick quote; string error;
   datetime bar=iTime(_Symbol,PERIOD_M1,0);
   Check(SymbolInfoTick(_Symbol,quote) && bar>0,"Quote and history ready");
   Check(!probe.Busy(),"Empty account allows an entry");
   Check(probe.Enter(1,bar,error) && probe.sends==1,"Buy request reaches mock transport");
   Check(probe.last.action==TRADE_ACTION_DEAL && probe.last.type==ORDER_TYPE_BUY && probe.last.price==quote.ask,"Buy uses Ask");
   Check(probe.last.magic==12345 && probe.last.symbol==_Symbol && probe.last.volume==config.setup.lot,"Identity and volume preserved");
   Check(probe.last.sl==0 && probe.last.tp==0,"Disabled targets stay zero");
   Check(probe.Enter(-1,bar,error) && probe.sends==2 && probe.last.type==ORDER_TYPE_SELL && probe.last.price==quote.bid,"Sell uses Bid");
   Check(!probe.Enter(1,bar-60,error) && probe.sends==2,"Stale signal does not send");
   config.setup.direction=GUI_SETUP_BUY_ONLY; probe.Configure(_Symbol,config,PERIOD_M1);
   Check(probe.Enter(-1,bar,error) && probe.sends==2,"Direction blocks sell");
   config.setup.direction=GUI_SETUP_SELL_ONLY; probe.Configure(_Symbol,config,PERIOD_M1);
   Check(probe.Enter(1,bar,error) && probe.sends==2,"Direction blocks buy");
   config.setup.direction=GUI_SETUP_BUY_SELL;
   config.rules.stop_loss=100000000; probe.Configure(_Symbol,config,PERIOD_M1);
   Check(!probe.Enter(1,bar,error) && probe.sends==2,"Invalid stop prevents send");
   config.rules.stop_loss=0; config.rules.order_mode=GUI_ORDER_PENDING; config.rules.pending_bar=10;
   MqlRates reference[];
   Check(CopyRates(_Symbol,PERIOD_M1,10,1,reference)==1,"Pending history ready");
   if(ArraySize(reference)==1)
      for(int ref=0;ref<4;ref++)
        {
         config.rules.pending_reference=ref; probe.Configure(_Symbol,config,PERIOD_M1);
         double price=ref==0 ? reference[0].high : (ref==1 ? reference[0].low : (ref==2 ? reference[0].open : reference[0].close));
         for(int side=-1;side<=1;side+=2)
           {
            int before=probe.sends;
            double minimum=MathMax(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE),SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point);
            bool close=MathAbs(price-(side==1 ? quote.ask : quote.bid))<minimum-1e-10;
            bool ok=probe.Enter(side,bar,error);
            if(close) Check(!ok && probe.sends==before,"Pending near market rejected");
            else Check(ok && probe.sends==before+1 && probe.last.action==TRADE_ACTION_PENDING &&
                       MathAbs(probe.last.price-price)<_Point*1e-6 && probe.last.type==UniPendingType(side,price,quote) &&
                       probe.last.type_filling==ORDER_FILLING_RETURN,"Pending preserves OHLC and selects type");
           }
        }
   PrintFormat("[OrderRequestTests] %d checks, %d failures; MOCK transport only",checks,failures);
  }
