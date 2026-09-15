# Indicadores

`MyIndicator` define inicializacao, leitura de buffers e liberacao. `MyMA`,
`MyRSI` e `MyADX` armazenam apenas os parametros do respectivo tipo. Cada objeto
possui seu handle; nao copie instancias que possuem recursos ou ponteiros.

`MyIndicatorFactory` converte a configuracao compartilhada em um objeto concreto.
`MyUnEA.ConfigureIndicator` assume a propriedade desse objeto em um dos quatro
slots (0 a 3). Um slot desativado usa NULL. Uma configuracao invalida preserva
o objeto anterior. Os construtores e a fabrica nao criam handles.

OnInit transfere os inputs pelos setters da classe e configura os indicadores.
Depois, doInit consulta os limites de volume, valida o setup e chama Initialize
em cada indicador ativo. Falhas liberam os handles ja criados. OnDeinit chama
doDeinit, que libera os handles e preserva os objetos para reinicializacao.
Alterar configuracoes pelos setters tambem libera os handles anteriores.
OnTick chama getBuffers antes de registrar a nova barra. A edicao pela GUI ainda e independente
dos inputs e da configuracao ativa da classe.
Initialize pode falhar; Update pode retornar false enquanto os dados nao estao
prontos. A saida de Update fica vazia em caso de falha e usa ordem cronologica
em caso de sucesso. MA e RSI usam buffer 0; ADX usa 0 (ADX), 1 (+DI) e 2 (-DI).

Para acrescentar um indicador:

1. Criar sua configuracao e classe derivada, com validacao e Initialize.
2. Acrescentar um valor ao final do enum compartilhado, mantendo os IDs antigos.
3. Acrescentar a conversao na fabrica.
   Implementar CheckBuy e CheckSell na classe concreta; a base retorna false
   para ambas ate que a regra do tipo seja definida.
4. Acrescentar campos e mapeamentos de entrada, interface e persistencia.
5. Testar validacao, leitura dos buffers e liberacao.

O formato IndicatorConfig continua como adaptador dos sets e da GUI existente.
Os inputs possuem quatro grupos de selecao (Indicador 1 a 4) e grupos de
parametros por tipo (Media Movel, RSI e ADX). Apenas Media Movel possui valores
independentes por posicao. RSI e ADX possuem um grupo unico, compartilhado por
todas as posicoes que selecionarem o mesmo tipo nos inputs. Novos tipos devem
seguir esse padrao. A GUI usa TryChoose para rejeitar tipos repetidos, exceto MA
e a opcao Nao usar, indicando onde o tipo ja foi selecionado. A leitura dos sets
existentes continua preservando os dados; essa restricao e da selecao interativa.
A estrutura de execucao extensivel nao
gera automaticamente controles, inputs ou migracoes de arquivos.

Referencia: https://www.mql5.com/en/docs/series/copybuffer

`Tests/IndicatorArchitectureTests.mq5` verifica fabrica e slots sem negociacao.
Compilar o script nao equivale a executar os testes.

`Tests/MyUnEAInitTests.mq5` cobre o ciclo de vida e rejeicao de parametros,
usando as especificacoes de volume do ativo do grafico e sem enviar ordens.

OnTick chama MyUnEA.doTick: exige 60 velas, obtem a cotacao e copia exatamente
tres velas no ativo e periodo configurados. Os indices 0, 1 e 2 representam
a vela atual e as duas ultimas fechadas. Uma falha permite tentar novamente
no tick seguinte; a mesma mensagem nao e repetida continuamente no log.
O primeiro retrato valido conta como nova vela. Depois, o retorno true ocorre
somente quando o horario de abertura muda. doDeinit limpa esse controle.
O minimo de 60 velas segue o exemplo desta etapa; nao garante que os buffers
dos indicadores estejam prontos. getBuffers verifica a leitura completa e valores
validos; as regras de negociacao ainda nao foram conectadas. A futura gestao por tick deve preceder o filtro de vela.

`Tests/MyUnEATickTests.mq5` verifica o controle por instancia e reinicializacao
em um grafico com historico disponivel. Referencia de leitura:
https://www.mql5.com/pt/docs/series/copyrates

Antes do filtro de historico/nova barra, doTick chama EvaluatePositions.
A leitura percorre PositionsTotal por ticket e filtra por ativo e Magic.
GetPositionSummary retorna flags de compra/venda, contagens e volumes separados;
seu retorno deve ser verificado para distinguir falha de ausencia de posicoes.
Em hedge, os dois lados podem estar abertos. IsHedgingAccount consulta o modelo
da conta. Em netting, o filtro usa o Magic informado pela posicao agregada:
nao separa participacoes de varios EAs que negociem o mesmo ativo nessa posicao.
Ordens pendentes e modificacao/fechamento por ticket ainda nao foram implementados.
O resumo e um retrato da leitura; deve ser atualizado antes de futuras operacoes.

`Tests/PositionStateTests.mq5` testa a agregacao com posicoes simuladas, incluindo
hedge, filtro por ativo/Magic e ausencia de posicoes, sem realizar negociacoes.
Referencia: https://www.mql5.com/en/docs/trading/positiongetticket

getBuffers le tres valores de cada buffer dos quatro indicadores ativos, usando
MyIndicatorData. GetIndicatorValue consulta indicador 0..3, buffer e barra 0..2.
A barra 0 corresponde a atual; 1 e 2 sao fechadas. MA e RSI usam buffer 0;
ADX usa 0 (ADX), 1 (+DI) e 2 (-DI). A leitura de MA respeita o deslocamento do
handle, sem compensacao adicional de shift ao chamar CopyBuffer.
Falha, copia parcial, EMPTY_VALUE ou numero invalido descarta a leitura completa.
Uma nova tentativa ocorre no proximo tick, sem registrar prematuramente a barra.
Os erros seguem o fluxo existente de error/Print, sem alertas repetidos.
Tests/IndicatorBufferTests.mq5 cobre ordenacao, multiplos buffers, falhas e
recuperacao com fonte simulada. Compilar nao equivale a executar os testes.

Regras individuais: MyMA confirma compra quando o fechamento da vela 1 esta
acima da media da vela 1, e venda quando esta abaixo. Igualdade e neutra.
Nao exige cruzamento nem inclinacao; a vela atual nao entra na comparacao.
MyUnEA.checkBuy/checkSell exigem confirmacao de todos os indicadores ativos
e respeitam a direcao permitida no setup. Sem indicadores, nao ha sinal.
ADX e tipos futuros permanecem sem confirmacao ate terem regras proprias.
OnTick avalia uma vez por nova barra e apenas registra sinais no log.
Horarios, posicionamento e envio de ordens ainda nao fazem parte dessa decisao.
Tests/IndicatorSignalTests.mq5 verifica a regra da media com valores simulados.

RSI: compra quando RSI[2] <= nivel inferior e RSI[1] > nivel inferior;
venda quando RSI[2] >= nivel superior e RSI[1] < nivel superior.
Os padroes sao 30 e 70, respeitando niveis personalizados. Tocar o nivel na
ultima vela fechada nao confirma; sair do nivel na vela seguinte confirma.
Permanecer entre os niveis sem cruzar nao sinaliza. Entrar nessa faixa vindo
da sobrevenda/sobrecompra pode confirmar o respectivo cruzamento.
A Canvas identifica Sobrevenda/Sobrecompra e mostra a regra no resumo.
A integracao das edicoes da GUI com a classe continua pendente.
Tests/RsiSignalTests.mq5 cobre cruzamentos, igualdade e niveis personalizados.