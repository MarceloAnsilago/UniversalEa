# Ordens — implementação e roteiro de teste

## Comportamento

- Um sinal por nova vela, após ativar. Uma exposição por símbolo/Magic: sem pirâmide, reversão ou compra e venda simultâneas do mesmo setup.
- A mercado: compra pelo Ask e venda pelo Bid. Desvio solicitado: 20 pontos. O servidor determina o preço executado; SL/TP são enviados junto com a entrada, referidos ao preço solicitado.
- Pendentes: OHLC exato da vela selecionada. Compra acima do Ask vira Buy Stop; abaixo, Buy Limit. Venda abaixo do Bid vira Sell Stop; acima, Sell Limit. Referência fora da grade de ticks ou próxima demais do mercado é rejeitada, sem deslocamento silencioso.
- SL: distância em pontos ou percentual do preço de entrada + multiplicador do candle (total ou corpo). TP: distância fixa OU múltiplo do SL efetivo após ajuste à grade do ativo. Stop configurado com tamanho zero é rejeitado.
- Breakeven e trailing avaliam a cada tick. Stop móvel avalia na primeira atualização da nova vela, usando o preço disponível naquele momento. Todos só apertam o SL; percentuais de gestão usam o preço de abertura da posição. TP é preservado.
- Day trade: zeragem no fim das entradas do ciclo. Janela atravessando meia-noite termina no dia seguinte. Se o EA perder esse horário, tenta zerar a posição vencida quando voltar a funcionar, mesmo dentro de uma nova janela.
- Swing: mantém posições fora do horário e entre dias. Pendentes de ambos os modos são canceladas ao pausar, ao vencer o ciclo ou fora da janela. Usa expiração no servidor quando permitida; caso contrário, cancelamento depende do EA conectado.
- Pausa impede novas entradas e mantém gestão/zeragem. Aplicar outra configuração fica bloqueado enquanto a configuração atual tiver exposição ou confirmação pendente.
- Contas netting: qualquer exposição no símbolo bloqueia entrada, inclusive de outro Magic. Use o símbolo exclusivamente para este EA: negociações manuais/outros EAs podem misturar a posição líquida. Hedging: operações são selecionadas por ticket, símbolo e Magic.
- Falhas aparecem em Experts com retorno do servidor. Uma entrada recusada não é repetida na mesma vela. Timeout/conexão com resultado incerto bloqueia novas entradas até reconciliação manual e reinício. Gestão e cancelamentos continuam.
- Remover/reiniciar o EA interrompe gestão local e não fecha posições automaticamente. Reaplique o mesmo setup/Magic para retomar a gestão. SL/TP já aceitos continuam no servidor; zeragem e trailing precisam do EA funcionando.

## Primeiro teste

1. No Testador de Estratégias, selecione UniEA, um ativo com histórico, período e intervalo de datas. Prefira ticks reais quando disponíveis.
2. Configure `InpTesterAutoStart=true`, ao menos um indicador (por exemplo, `InpIndicator1Type=GUI_INDICATOR_MA`), lote válido e horários adequados ao servidor. Esse início automático é ignorado fora do testador.
3. Comece com ordens a mercado; confira entradas, direção, volume, SL/TP e ausência de repetição enquanto há posição. Depois teste pendentes e cada referência OHLC.
4. Verifique breakeven, trailing e stop móvel separadamente e combinados. Confira compras e vendas, grade de ticks, passo e preservação do TP.
5. Teste passagem pelo fim do horário, pausa com pendente, pausa com posição e janela atravessando meia-noite. Day trade deve zerar; Swing deve manter posições e cancelar pendentes.
6. Em teste visual, também é possível deixar `InpTesterAutoStart=false` e usar Revisão → Aplicar ao motor → Ativar ordens. Fora do testador, esse fluxo manual é obrigatório.
7. Antes de uso real, valide em conta demo a aceitação da corretora, políticas de preenchimento/expiração, netting/hedging e rejeições por margem, stops e mercado fechado.

Os scripts `OrderLogicTests.mq5` e `OrderRequestTests.mq5` testam cálculos e montagem de requisições. O segundo usa transporte simulado e exige terminal sem posições/ordens. Eles não validam execução na corretora. `CanvasRuntimeTests.mq5` testa a integração de configuração, sinais e painel sem negociação.

Referências oficiais: [OrderSend e retorno do servidor](https://www.mql5.com/en/docs/trading/ordersend), [OrderCheck](https://www.mql5.com/en/docs/trading/ordercheck), [propriedades do ativo](https://www.mql5.com/en/docs/constants/environment_state/marketinfoconstants).
