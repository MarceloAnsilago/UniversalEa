# UniEA

Expert Advisor MQL5 com configuração pelos inputs, motor de indicadores, execução de ordens e gestão de posições.

## Painel Canvas

### Etiquetas de preço

O estilo usa uma faixa fina com borda discreta: a cor do nível aparece no
acento esquerdo, o nome fica em um bloco escuro e o resultado em um bloco
separado, verde para lucro, vermelho para prejuízo e cinza para zero ou valor
indisponível. `InpMarkerProfitColor` e `InpMarkerLossColor` ajustam essas cores.
O preço continua somente na escala lateral, com as tarjas ancoradas à direita.

`InpMarkerShowProfit` mostra ao lado do nome o lucro/prejuízo
bruto estimado na moeda da conta, calculado por `OrderCalcProfit` com entrada,
lado e volume atual da posição ou volume restante da pendente. Cada estimativa
representa o resultado caso a saída ocorra no preço da tarja; na entrada é zero,
e no BE ATIVAR representa o resultado no gatilho, não no novo stop protegido.
Comissões, swap e diferenças de execução não entram na estimativa. Se a
conversão não estiver disponível, aparece **indisponivel**, sem assumir zero.
Desative o input para ocultar o resultado estimado.

As tarjas usam largura compacta de 176 pixels e uma única linha, ancoradas
na borda direita do gráfico junto à escala, sem margem fixa. O preço aparece
somente na escala lateral; a tarja mostra nome e resultado estimado.
Conectores de níveis próximos ficam à esquerda
da tarja, liberando espaço para os candles.

Cada tarja tem uma linha horizontal contínua de 2 pixels no preço exato,
usando a mesma cor do acento da etiqueta. A linha acompanha alterações de preço
e cor e é removida junto com seu marcador. As linhas pontilhadas nativas do
MT5 permanecem, com a linha colorida desenhada por cima.

Quando o breakeven está habilitado, **BE ATIVAR** marca seu nível de ativação
para cada posição aberta do setup. Usa a entrada efetiva, o lado da operação
e a distância em pontos ou percentual configurada. A etiqueta e sua linha somem
quando o SL confirmado atinge a proteção configurada do breakeven ou a supera,
inclusive por trailing. Tocar o gatilho sem conseguir ajustar o stop mantém o
marcador visível. A cor é ajustável em `InpMarkerBreakevenColor`. A etiqueta
STOP continua indicando o SL efetivo após a proteção ser aplicada.

O grupo **Marcadores de preco** dos inputs permite ativar as etiquetas e
alterar cores de entrada, stop, take, pendente e texto, além da fonte.
Um Canvas transparente mostra nome e preço à direita do gráfico principal.
Níveis próximos têm etiquetas separadas com conectores para o preço exato.
Níveis fora da escala ficam ocultos; gráficos muito estreitos ocultam as
etiquetas para preservar o espaço do painel. As linhas nativas do MT5 continuam.

`CUniTradeMarkers` acompanha posições e ordens do símbolo/Magic do EA.
STOP representa o SL atual, incluindo ajustes de breakeven, trailing e stop
móvel; não é uma projeção de um ajuste futuro. Sem SL/TP, a respectiva etiqueta
não aparece. Encerramento, cancelamento e remoção do EA limpam seus marcadores.
Testes sem visualização não criam Canvas.

`Include/UniPriceMarkers.mqh` contém o componente genérico `CUniPriceMarkers`,
independente da execução de ordens. Para futuros níveis de grid, trailing ou
outros módulos, use uma instância própria com `Configure`, `BeginFrame`,
`Set(chave, texto, preço, corFundo, corTexto)` e `Render`. A mesma chave atualiza
o nível; `Remove` apaga uma chave, e `Destroy` libera apenas o Canvas da instância.
O componente reutiliza um único Canvas e evita redesenhar quadros idênticos.
`Tests/PriceMarkerTests.mq5` valida atualização, remoção, limpeza e gera uma
prévia com níveis próximos, sem enviar ordens.

`Include/UniPanel.mqh` desenha um resumo em Canvas com cartões claros, bordas suaves, identificação do indicador, selo Ativo/Inativo e parâmetros dos quatro slots. Anterior/Próximo permitem percorrer os cartões; a altura acompanha o gráfico. O selo identifica indicadores configurados; o estado das entradas aparece no cabeçalho. A configuração continua pelos inputs. Ao remover o EA, o objeto e o recurso do Canvas são liberados.

## Configuração e ativação

`InpStopMode=1` seleciona **Distância fixa**: usa somente `InpStopLoss`, sem
somar nem consultar o candle. Zero desliga o SL nesse modo. A unidade vem de
`InpTargetUnit`. `InpStopMode=0` mantém **Distância + candle**, padrão que
preserva presets antigos. O take em vezes o stop usa a distância efetiva do SL
após ajuste à grade do ativo e exige um stop habilitado. O GeraSet exporta o
novo modo e os intervalos de distância; recompile e reexporte o `.set`.

O card Alvos do GeraSet agora exporta os parâmetros de SL/TP e seus intervalos.
`InpTakeMode=1` seleciona distância fixa (zero desliga o take), `0` seleciona
vezes o stop e `-1` preserva a inferência de presets antigos: distância positiva
seleciona fixo, zero seleciona múltiplo. Recompile e reexporte o `.set`.
Pontos são multiplicados pelo `SYMBOL_POINT`; percentuais usam o preço solicitado
da entrada. O TP é arredondado para fora na grade de ticks do ativo.

- Ajuste os parâmetros nas propriedades do EA. Com pelo menos um indicador selecionado, os inputs são validados e aplicados ao motor na inicialização.
- `InpAutoStart=false` é o padrão fora do testador: entradas pausadas, gestão das posições do símbolo/Magic configurado habilitada. Defina `true` para habilitar novas entradas.
- No testador, a ativação é controlada exclusivamente por `InpTesterAutoStart`; `InpAutoStart` não interfere nos testes.
- Sem indicadores e sem ativação, o EA mostra apenas o painel, sem motor ou gestão. Testes não visuais exigem pelo menos um indicador.
- Ativar aguarda a próxima vela. Parâmetros inválidos impedem a inicialização e geram uma mensagem em Experts.
- Para alterar ou pausar entradas, edite os inputs. Preserve símbolo/Magic e configuração ao retomar a gestão de posições existentes. Remover o EA interrompe a gestão local; não fecha posições automaticamente.

## Organização

### Integração GeraSet — identificação, mercado e operação

O GeraSet exporta um preset nativo `.set` (UTF-16LE com BOM) com `InpName`
e `InpMagic`, além de `InpMarket`, `InpTradeMode`, `InpStrategyTimeframe`,
`InpLot` e `InpDirection`. Carregue nas propriedades do EA, em **Parâmetros de entrada →
Carregar**, e confira os valores antes de aplicar. Nesta etapa, os demais
dados do GeraSet são comentários e não configuram o motor. O leitor binário
legado `GuiLoadSet` não participa desse fluxo. O Magic é preservado como input,
sem regeneração ou reserva automática. O Flask valida a faixa de 1 a 2147483647,
mas não verifica exclusividade no histórico de ordens do terminal.

Timeframe e Direção incluem os intervalos da aba Otimizar do GeraSet.
Limites diferentes ativam a otimização; iguais a desativam. Mercado,
Modalidade e Lote permanecem fixos. Confira as colunas Valor, Iniciar, Passo,
Terminar e as marcações no Testador de Estratégias após carregar o arquivo.
O timeframe usa os códigos do `ENUM_UNI_TIMEFRAME`, incluindo Tempo corrente=0.
Não é necessário recompilar o Uni para carregar esses inputs.

O card **Horários** exporta `InpEntryStart` e `InpEntryEnd` em minutos desde
00:00 no servidor (09:30 = 570), com intervalos de otimização em passo 5.
Limites iguais desativam a otimização. Os valores fixos de início e encerramento
devem ser diferentes; uma janela que atravessa meia-noite é preservada.
Combinações otimizadas com início igual ao encerramento são rejeitadas pelo Uni.
Recompile para ver o nome e as descrições atualizados do grupo Horários.

- `UniEA.mq5`: inputs e eventos do EA.
- `Include/UniPanel.mqh`: resumo dos indicadores em Canvas, somente leitura.
- `Include/Configuration`: modelos, validações e persistência, independentes da interface. Os nomes legados `Gui*` foram mantidos para preservar os contratos e testes dos dados.
- `Include/UniRuntime.mqh`, `MyUnEA.mqh`, `UniOrders.mqh`: sinais, execução e gestão.
- `Tests`: regressões de configuração, indicadores, cálculos e requisições simuladas. `RuntimeTests.mq5` verifica o motor sem negociar; `SetupDefaultsTests.mq5` verifica a inicialização padrão.

Compile `UniEA.mq5` no MetaEditor com a biblioteca padrão do MetaTrader 5 disponível. Veja `Tests/ORDER_TESTING.md` para o roteiro de execução no testador.

## Transicao do modelo de sinais

As regras prontas de MA, RSI e ADX e a confirmacao conjunta foram removidas.
Os indicadores fornecem buffers para o novo avaliador `Include/UniSignals.mqh`.
As cinco condicoes do GeraSet chegam pelos inputs InpSignal1 a InpSignal5.
Os inputs de inclinacao MA, niveis RSI e limiar ADX foram retirados.
Os campos binarios legados permanecem apenas para compatibilidade.

## Grade Sinal integrada

O exportador mapeia os quatro indicadores (MA, RSI e ADX), seus parametros e
intervalos, a finalidade Entrada/Saida e cinco condicoes. RSI e ADX agora tem
parametros independentes por slot. Reexporte presets antigos com esses tipos.
Normal/Inverter e resolvido pelo Flask para o lado final. Os payloads dos
inputs de condicao sao gerados pela grade; nao exigem edicao manual.

O motor agrupa por finalidade e lado, com E antes de Ou. Vela atual e lida a
cada tick; grupos somente de velas fechadas sao avaliados uma vez por barra.
Grupos mistos sao avaliados por tick usando tambem os dados fechados.
Os buffers incluem barras 0 a 4, cobrindo a antepenultima e seu cruzamento.
Toque usa a tolerancia configurada ou a passagem entre lados em ticks
consecutivos; nao usa maxima/minima da vela como substituto do preco escolhido.
Um resultado intrabar persistente so dispara novamente depois de ficar falso.

Saida Compra fecha vendas; Saida Venda fecha compras. Saidas sao priorizadas,
nao abrem reversao e cancelam pendentes do lado a encerrar. Somente ativo/Magic
do EA sao afetados. Saidas continuam durante pausa de entradas e fora da janela.
Falhas/fechamentos parciais sao retomados; resultado incerto bloqueia nova
solicitacao de fechamento ate reconciliacao no terminal. Nao reabre no tick
em que uma saida e tratada. Compra e venda simultaneas de entrada nao negociam.
Ao ativar, Vela atual pode disparar no proximo tick; grupos somente de velas
fechadas aguardam uma nova vela.

Para testar: recompile UniEA, atualize o Flask com Ctrl+F5 e exporte novo .set.
Carregue no Testador e use ticks reais para conferir Toque/Vela atual.
Ative InpTesterAutoStart manualmente para permitir entradas no teste.
Gestao e demais regras ainda nao sao exportadas: confira seus inputs no Uni.
Tests/SignalGridTests.mq5 usa leituras simuladas e nao envia ordens.


### Histograma de sinais dos indicadores

`InpExibirHistogramas=true` ativa, por padrão, uma subjanela compacta por slot habilitado;
`false` não cria indicadores visuais nem canais de dados do histograma.
`InpHistogramasBarras=300` limita o histórico (1 a 5000 candles).
No GeraSet: **Configurações > Visualização no MetaTrader 5**, marque/desmarque
**Exibir histograma de sinais** e exporte novamente o `.set`.

Azul representa compra, vermelho venda e cinza neutralidade. Falta de dados, sinais
simultâneos de compra/venda ou indicadores sem condições aplicáveis ficam sem
preenchimento. Cada faixa combina somente as condições que referenciam o respectivo
indicador, preservando E/Ou e o lado já resolvido pelo GeraSet. Não representa a
aprovação final de toda a estratégia.

O estado atual vem dos resultados da mesma avaliação operacional (`CUniSignals`).
O histórico reutiliza esse avaliador e os handles existentes, com deslocamento temporal.
Comparações comuns da vela atual são reconstruídas pelo fechamento; cruzamentos e
toques intrabar passados não são reconstruídos sem ticks. Os estados observados ao vivo
são mantidos até saírem do limite de candles ou o EA reinicializar.

`Include/UniSignalHistogram.mqh` controla o ciclo de vida e snapshots binários
limitados no sandbox `MQL5/Files`; `Indicators/UniSignalHistogram.mq5` exibe buffers
`DRAW_COLOR_HISTOGRAM`, sem objetos por candle. Os arquivos temporários são removidos
na desinicialização normal. Atualizações do canal ocorrem ao mudar estado/candle,
com até três tentativas iniciais de preenchimento do histórico. A leitura visual
pode atrasar até um segundo. Use o mesmo timeframe da estratégia no gráfico.
No testador não visual, o histograma não é criado.

Compilar `Indicators/UniSignalHistogram.mq5` antes de `UniEA.mq5`, pois o indicador
é incorporado como recurso. Testes: `Tests/SignalGridTests.mq5` e
`Tests/HistogramPanelTests.mq5` (este último usa o indicador instalado no terminal
isolado como `UniSignalHistogram.ex5`, com negociação desabilitada).


Validação desta implementação (17/10/2026): UniEA e indicador compilados com
zero erros e avisos; SignalGridTests: 67 verificações sem falhas; HistogramPanelTests:
15 verificações sem falhas em terminal portátil com negociação desabilitada.
O teste do painel confere buffers, cores, uma/três faixas, desativação e limpeza,
sem inspeção visual por screenshot. GeraSet: 54 testes JavaScript sem falhas e
renderização Flask da checkbox confirmada. Testador visual, troca de timeframe,
zoom/rolagem e operações reais não foram exercitados nesta validação.

Integração: UniEA.mq5, UniEA.mqproj, Include/MyUnEA.mqh,
Include/UniRuntime.mqh, Include/UniSignals.mqh e os dois componentes novos de
histograma. No GeraSet, os arquivos alterados são templates/page.html,
static/app.js, static/export.js e tests/export.test.cjs, dentro de flask_version.


A mesma seção do GeraSet possui **Exibir painel do UNI**, exportado como
`InpExibirPainel=true` por padrão. Desmarcar impede a criação e a atualização
do painel; a execução da estratégia, os histogramas e as etiquetas de preço
continuam controlados pelas respectivas configurações. As duas checkboxes ficam
salvas na aba Configurações; a escolha anterior do histograma é migrada.
