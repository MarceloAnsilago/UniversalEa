#ifndef UNI_POSITION_STATE_MQH
#define UNI_POSITION_STATE_MQH

// Retrato de uma posicao. O ticket identifica cada posicao individual no hedge.
struct UniPositionRecord
  {
   ulong ticket;
   string symbol;
   long magic;
   ENUM_POSITION_TYPE type;
   double volume;
  };

// Compras e vendas sao independentes: ambas podem existir em conta hedge.
struct UniPositionSummary
  {
   bool buy_opened;
   bool sell_opened;
   int buy_count;
   int sell_count;
   double buy_volume;
   double sell_volume;
  };

// Filtra pelo ativo E Magic e resume todas as posicoes, sem negociar.
// Separado da leitura do terminal para permitir testes com dados simulados.
bool UniSummarizePositions(const UniPositionRecord &positions[],const string symbol,
                          const long magic,UniPositionSummary &summary)
  {
   ZeroMemory(summary);
   UniPositionSummary candidate;
   ZeroMemory(candidate);
   for(int i=0;i<ArraySize(positions);i++)
     {
      if(positions[i].symbol!=symbol || positions[i].magic!=magic) continue;
      if(positions[i].ticket==0 || !MathIsValidNumber(positions[i].volume) || positions[i].volume<=0)
         return false;
      if(positions[i].type==POSITION_TYPE_BUY)
        { candidate.buy_count++; candidate.buy_volume+=positions[i].volume; }
      else if(positions[i].type==POSITION_TYPE_SELL)
        { candidate.sell_count++; candidate.sell_volume+=positions[i].volume; }
      else return false;
     }
   candidate.buy_opened=(candidate.buy_count>0);
   candidate.sell_opened=(candidate.sell_count>0);
   summary=candidate;
   return true;
  }
#endif
