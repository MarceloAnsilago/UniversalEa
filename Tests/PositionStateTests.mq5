#property strict
#include "../Include/Configuration/UniPositionState.mqh"
int failures=0;
void Check(const bool condition,const string label)
  { if(!condition) { failures++; Print("FAIL: ",label); } }

// Dados simulados: nao consulta a conta e nao abre, altera ou fecha operacoes.
void OnStart()
  {
   UniPositionRecord positions[];
   UniPositionSummary summary;
   Check(UniSummarizePositions(positions,"TEST",42,summary) &&
         !summary.buy_opened && !summary.sell_opened,"Sem posicoes");
   ArrayResize(positions,5);
   for(int i=0;i<5;i++)
     {
      positions[i].ticket=(ulong)(i+1);
      positions[i].symbol="TEST"; positions[i].magic=42;
      positions[i].type=POSITION_TYPE_BUY; positions[i].volume=0.1;
     }
   positions[1].volume=0.2;
   positions[2].type=POSITION_TYPE_SELL; positions[2].volume=0.4;
   positions[3].symbol="OTHER";
   positions[4].magic=99;
   Check(UniSummarizePositions(positions,"TEST",42,summary) &&
         summary.buy_opened && summary.sell_opened,"Hedge: compra e venda simultaneas");
   Check(summary.buy_count==2 && summary.sell_count==1 &&
         MathAbs(summary.buy_volume-0.3)<1e-8 && MathAbs(summary.sell_volume-0.4)<1e-8,
         "Soma todas as posicoes e ignora outros ativos e Magics");
   Check(UniSummarizePositions(positions,"TEST",99,summary) &&
         summary.buy_count==1 && !summary.sell_opened,"Outro Magic tem resumo independente");
   ArrayResize(positions,1);
   positions[0].type=POSITION_TYPE_SELL;
   Check(UniSummarizePositions(positions,"TEST",42,summary) &&
         !summary.buy_opened && summary.sell_opened && summary.sell_count==1,
         "Uma posicao vendida: formato de netting");
   positions[0].volume=0;
   Check(!UniSummarizePositions(positions,"TEST",42,summary) &&
         !summary.buy_opened && !summary.sell_opened,"Falha nao publica resumo parcial");
   ArrayFree(positions);
   Check(UniSummarizePositions(positions,"TEST",42,summary) &&
         summary.buy_count==0 && summary.sell_count==0,"Fechamento de todas limpa resumo");
   PrintFormat("PositionStateTests: %d falhas",failures);
  }
