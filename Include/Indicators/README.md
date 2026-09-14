# Indicadores

`MyIndicator` define inicializacao, leitura de buffers e liberacao. `MyMA`,
`MyRSI` e `MyADX` armazenam apenas os parametros do respectivo tipo. Cada objeto
possui seu handle; nao copie instancias que possuem recursos ou ponteiros.

`MyIndicatorFactory` converte a configuracao compartilhada em um objeto concreto.
`MyUnEA.ConfigureIndicator` assume a propriedade desse objeto em um dos quatro
slots (0 a 3). Um slot desativado usa NULL. Uma configuracao invalida preserva
o objeto anterior. Os construtores e a fabrica nao criam handles.

Os metodos Initialize e Update estao disponiveis, mas ainda nao sao chamados
pelos eventos do EA. Os inputs tambem aguardam a transferencia para a classe.
Initialize pode falhar; Update pode retornar false enquanto os dados nao estao
prontos. A saida de Update fica vazia em caso de falha e usa ordem cronologica
em caso de sucesso. MA e RSI usam buffer 0; ADX usa 0 (ADX), 1 (+DI) e 2 (-DI).

Para acrescentar um indicador:

1. Criar sua configuracao e classe derivada, com validacao e Initialize.
2. Acrescentar um valor ao final do enum compartilhado, mantendo os IDs antigos.
3. Acrescentar a conversao na fabrica.
4. Acrescentar campos e mapeamentos de entrada, interface e persistencia.
5. Testar validacao, leitura dos buffers e liberacao.

O formato IndicatorConfig continua como adaptador dos sets e da GUI existente.
Os inputs possuem quatro grupos de selecao (Indicador 1 a 4) e grupos de
parametros por tipo (Media Movel, RSI e ADX). Dentro de cada tipo, os campos
identificam o slot e preservam valores independentes: dois slots com RSI podem
usar periodos diferentes. A estrutura de execucao extensivel nao
gera automaticamente controles, inputs ou migracoes de arquivos.

Referencia: https://www.mql5.com/en/docs/series/copybuffer

`Tests/IndicatorArchitectureTests.mq5` verifica fabrica e slots sem negociacao.
Compilar o script nao equivale a executar os testes.
