# UniEA

Expert Advisor MQL5 com configuração pelos inputs, motor de indicadores, execução de ordens e gestão de posições.

## Painel Canvas

`Include/UniPanel.mqh` desenha um resumo em Canvas com cartões claros, bordas suaves, identificação do indicador, selo Ativo/Inativo e parâmetros dos quatro slots. Anterior/Próximo permitem percorrer os cartões; a altura acompanha o gráfico. O selo identifica indicadores configurados; o estado das entradas aparece no cabeçalho. A configuração continua pelos inputs. Ao remover o EA, o objeto e o recurso do Canvas são liberados.

## Configuração e ativação

- Ajuste os parâmetros nas propriedades do EA. Com pelo menos um indicador selecionado, os inputs são validados e aplicados ao motor na inicialização.
- `InpAutoStart=false` é o padrão fora do testador: entradas pausadas, gestão das posições do símbolo/Magic configurado habilitada. Defina `true` para habilitar novas entradas.
- No testador, a ativação é controlada exclusivamente por `InpTesterAutoStart`; `InpAutoStart` não interfere nos testes.
- Sem indicadores e sem ativação, o EA mostra apenas o painel, sem motor ou gestão. Testes não visuais exigem pelo menos um indicador.
- Ativar aguarda a próxima vela. Parâmetros inválidos impedem a inicialização e geram uma mensagem em Experts.
- Para alterar ou pausar entradas, edite os inputs. Preserve símbolo/Magic e configuração ao retomar a gestão de posições existentes. Remover o EA interrompe a gestão local; não fecha posições automaticamente.

## Organização

### Integração GeraSet — identificação

O GeraSet exporta um preset nativo `.set` (UTF-16LE com BOM) com `InpName`
e `InpMagic`. Carregue nas propriedades do EA, em **Parâmetros de entrada →
Carregar**, e confira os dois valores antes de aplicar. Nesta etapa, os demais
dados do GeraSet são comentários e não configuram o motor. O leitor binário
legado `GuiLoadSet` não participa desse fluxo. O Magic é preservado como input,
sem regeneração ou reserva automática. O Flask valida a faixa de 1 a 2147483647,
mas não verifica exclusividade no histórico de ordens do terminal.

- `UniEA.mq5`: inputs e eventos do EA.
- `Include/UniPanel.mqh`: resumo dos indicadores em Canvas, somente leitura.
- `Include/Configuration`: modelos, validações e persistência, independentes da interface. Os nomes legados `Gui*` foram mantidos para preservar os contratos e testes dos dados.
- `Include/UniRuntime.mqh`, `MyUnEA.mqh`, `UniOrders.mqh`: sinais, execução e gestão.
- `Tests`: regressões de configuração, indicadores, cálculos e requisições simuladas. `RuntimeTests.mq5` verifica o motor sem negociar; `SetupDefaultsTests.mq5` verifica a inicialização padrão.

Compile `UniEA.mq5` no MetaEditor com a biblioteca padrão do MetaTrader 5 disponível. Veja `Tests/ORDER_TESTING.md` para o roteiro de execução no testador.
