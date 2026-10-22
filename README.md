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
e `InpMagic`, além de mercado, modalidade, lote, direção, horários, ordens,
SL/TP, breakeven, indicadores e condições. Carregue nas propriedades do EA,
em **Parâmetros de entrada → Carregar**, e confira os valores antes de aplicar.
Os comentários JSON preservam o rascunho da interface, inclusive campos que
ainda não são exportados como inputs; sua presença não configura o motor.
O leitor binário legado `GuiLoadSet` não participa desse fluxo. O navegador
gera o Magic a partir do nome e valida a faixa de 1 a 2147483647; o Bridge
também valida essa faixa. Não há verificação de exclusividade no histórico
de ordens do terminal.

Direção e timeframes dos indicadores incluem intervalos da aba Otimizar.
Limites diferentes ativam a otimização; iguais a desativam. Mercado,
Modalidade e Lote permanecem fixos na exportação atual. Confira as colunas
Valor, Iniciar, Passo, Terminar e as marcações no Testador de Estratégias.
O timeframe base vem do gráfico/testador: não existe input `InpStrategyTimeframe`
no EA atual. Cada `InpIndicatorNTimeframe` usa índices de `ENUM_UNI_SLOT_TIMEFRAME`
(0 = corrente, 12 = H1, 21 = MN1), não os códigos nativos `PERIOD_*`.
Os grupos RSI e ADX são compartilhados por finalidade (entrada/saída);
MA possui parâmetros independentes por slot. Trailing e stop móvel exportam
modo, ativação, distância e passo de ajuste, com intervalos de otimização.
Pontos e percentuais do preço de abertura usam a implementação padrão do Uni;
acompanhamento por indicador permanece futuro. Trailing ajusta nos ticks;
stop móvel na primeira atualização da nova vela do período base. Ambos só
apertam o stop e preservam o TP. Não é necessário alterar o motor para essa
exportação. Ao importar no GeraSet um arquivo antigo que não emitia esses
inputs, os modos permanecem desativados até revisão explícita do usuário.

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
As dez condicoes do GeraSet chegam pelos inputs InpSignal1 a InpSignal10; sets antigos com cinco continuam aceitos.
Os inputs de inclinacao MA, niveis RSI e limiar ADX foram retirados.
Os campos binarios legados permanecem apenas para compatibilidade.

## Grade Sinal integrada

O exportador mapeia os quatro indicadores (MA, RSI e ADX), seus parametros e
intervalos, a finalidade Entrada/Saida e dez condicoes. RSI e ADX agora tem
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

O indicador visual avalia as regras pelo mesmo `CUniSignals`, com adaptador
somente de leitura dos indicadores nativos (`Include/UniHistogramEvaluation.mqh`).
Slots, regras, periodos e niveis sao copiados na criacao. Leituras repetidas sao
compartilhadas dentro de cada calculo e invalidadas antes do proximo calculo.
O histograma nao envia ordens.

`Include/UniSignalHistogram.mqh` controla as subjanelas e
`Indicators/UniSignalHistogram.mq5` desenha buffers `DRAW_COLOR_HISTOGRAM`.
Nao ha arquivos de snapshots, temporizadores ou espera em milissegundos reais.
No fim do testador visual, as faixas sao preservadas. No testador nao visual,
nenhum histograma e criado. Use o timeframe da estrategia no grafico.

O historico usa os deslocamentos temporais das condicoes. Comparacoes comuns
da vela atual sao reconstruidas pelo fechamento. Cruzamentos/toques intrabar
e vela atual de periodo superior ao grafico nao sao reconstruidos sem ticks
e podem ficar indisponiveis. Cada faixa representa somente suas proprias regras.

Compile `Indicators/UniSignalHistogram.mq5` antes de `UniEA.mq5` (recurso embutido).
`Tests/HistogramPanelTests.mq5` verifica buffers, cores, ativacao e ciclo de vida.
`Tests/HistogramVisualAudit.mq5` inclui o EA e exporta os buffers no fim do Tester.

Validacao de 20/10/2026: 26 verificacoes de histograma, 67 de sinais e 40 de MTF
passaram sem falhas; compilacoes sem erros nem avisos. Apos os ajustes de cache
e da ultima barra fechada, T05/T06 passaram na auditoria numerica dos buffers:
1.800 amostras, nenhuma indisponivel ou divergente, e 112 solicitacoes de negocio
identicas as anteriores. A tela final do UniEA de producao foi confirmada no T06,
com os tres histogramas preenchidos ate o ultimo candle e operacoes identicas.
Verificacao aprovada para esses cenarios T05/T06.
Evidencias locais: `.test-results/histogram-fix-20261019/RELATORIO.md`.

A mesma seção do GeraSet possui **Exibir painel do UNI**, exportado como
`InpExibirPainel=true` por padrão. Desmarcar impede a criação e a atualização
do painel; a execução da estratégia, os histogramas e as etiquetas de preço
continuam controlados pelas respectivas configurações. As duas checkboxes ficam
salvas na aba Configurações; a escolha anterior do histograma é migrada.


Desempenho do histograma no tester: o indicador não registra timer em testes,
para evitar eventos a cada segundo simulado. A captura de estados continua a cada
tick em um buffer circular limitado a `InpHistogramasBarras`; publicações em
arquivo e leituras visuais são limitadas a intervalos de 250 ms de tempo real.
Isso preserva os candles capturados mesmo quando a simulação avança várias
barras entre duas atualizações visuais. As tentativas iniciais de histórico também
usam tempo real. O timer permanece apenas fora do tester, para atualização entre
cotações. O teste HistogramPanelTests verifica a limitação de publicações com
5.000 mudanças de estado consecutivas.


### Sinais de compra e venda espelhados (20/10/2026)

O GeraSet organiza cinco condicoes na aba Compra e cinco na aba Venda.
Espelhar compra cria uma copia editavel das regras, preservando finalidade,
candles, E/Ou, periodos e distancia. Niveis RSI inferior/superior e linhas DI
sao trocados conforme a direcao; filtros de forca ADX mantem a comparacao.
Valores fixos ambiguos exigem revisao explicita e bloqueiam a exportacao.
A finalidade Saida continua fechando o lado oposto, sem abrir outra posicao.

O EA aceita os novos inputs InpSignal6..InpSignal10 (vazios por padrao),
incluindo-os no avaliador, na configuracao do histograma e nos recursos embutidos.
Validacao desta alteracao: 70 testes JavaScript; 72 verificacoes de sinais,
26 de histograma e 40 de MTF, sem falhas. Compilacoes sem erros nem avisos.
A auditoria visual T05/T06 descrita acima pertence a versao anterior: a nova
configuracao com dez condicoes ainda nao foi exercitada no Testador visual.


### Espelhamento da referencia de ordens pendentes (20/10/2026)

Em Gestao > Ordem, a opcao Espelhar referencia da pendente na venda usa a
referencia configurada como base de compra e troca Maxima/Minima na venda.
Abertura, Fechamento e numero da vela permanecem iguais. Cada passe de
 otimizacao aplica essa regra a referencia base escolhida naquele passe.
A previa mostra Compra/Venda. A opcao persiste e aparece na Revisao e Sets.
O botao Espelhar compra em Sinais tambem a ativa; ela pode ser desmarcada em
Gestao. Desligada, ambos os lados continuam usando a mesma referencia.

O set exporta InpPendingMirrorSell; o UniEA atualizado le esse input (padrao
false para compatibilidade) e aplica a troca ao preco OHLC antes de selecionar
Stop/Limit. Sets antigos carregam sem ativar a opcao, mesmo se o rascunho
anterior estava espelhado. Conferido com helo world08 rsi.set.

Stop por candle no motor utiliza o tamanho do candle como distancia, nao a
minima/maxima como ancora. Stop/take, breakeven, trailing e stop movel calculam
os precos pelo lado da posicao; nao se invertem sinais dos numeros digitados.
A exportacao de trailing/stop movel pelo GeraSet continua uma etapa futura;
essa alteracao nao a implementa nem inventa novas regras de gestao.

Validacao: 72 testes JavaScript, 55 verificacoes matematicas de ordens/gestao e
28 de requisicoes com transporte simulado, sem falhas. Compilacoes sem erros
ou avisos. No navegador: minima/maxima, persistencia, integracao do botao,
revisao da opcao e importacao legada conferidas. Sem ordens reais e sem novo
teste visual de ponta a ponta no MT5 nesta etapa.


### Politica atual de presets no GeraSet

O GeraSet exporta e importa somente sets no formato versao 2. Foram removidas
as migracoes de layouts e paginas antigas, timeframes globais, campos sem
nome e sinais misturados entre compra/venda. Os arquivos antigos nao sao
alterados nem apagados. Para novos testes, crie e exporte novamente o setup
pelo GeraSet atual. A leitura verifica exatamente os parametros exportados,
sem remapear posicoes de sinais. 70 testes JavaScript passaram nesta limpeza.
Esta alteracao e do GeraSet; nao modifica a logica operacional do UniEA.
