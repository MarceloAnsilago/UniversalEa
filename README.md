# UniEA

Expert Advisor MQL5 com configuração pelos inputs, motor de indicadores, execução de ordens e gestão de posições.

## Painel Canvas

### Etiquetas de preço

Cada tarja tem uma linha horizontal contínua de 2 pixels no preço exato,
usando a mesma cor de fundo da etiqueta. A linha acompanha alterações de preço
e cor e é removida junto com seu marcador. As linhas pontilhadas nativas do
MT5 permanecem, com a linha colorida desenhada por cima.

Quando o breakeven está habilitado, **BE ATIVAR** marca seu nível de ativação
para cada posição aberta do setup. Usa a entrada efetiva, o lado da operação
e a distância em pontos ou percentual configurada; permanece como referência
até o fechamento. A cor é ajustável em `InpMarkerBreakevenColor`. A etiqueta
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
