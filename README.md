# UniversalEa

O **Stop loss** no card Alvos aceita **distancia + X vezes o tamanho do candle**, com multiplicador padrao **1**, selecao de ultimo, penultimo ou antepenultimo candle fechado e medida Total ou Corpo. O **Take Profit** permite escolher entre **X vezes o tamanho total do stop** (padrao **2**) ou **distancia fixa** definida pelo usuario. Os modos sao exclusivos: os valores nunca sao somados. Alternar o modo preserva ambos os valores e aplica apenas o escolhido. Os dois multiplicadores possuem botoes + / - com passo **0,5** e permitem digitacao manual. Para desativar o stop, zere sua distancia e seu multiplicador; para desativar o take, zere o valor do modo selecionado. As opcoes sao preservadas no historico e nos sets v11; sets anteriores preservam os valores salvos e recebem multiplicador do take zero. Essa configuracao acompanha a interface; a execucao de ordens continua sendo uma etapa futura.

## Navegação e página Indicadores

A navegação usa uma barra vertical à esquerda: **Setup, Indicadores, Gestão, Filtros, Revisão e Ativação**. As três últimas etapas permanecem futuras. Regras deixa de ser uma etapa separada: os controles de tipo de ordem, unidade dos alvos, stop loss e take profit ficam no bloco **Regras de entrada e saída**, dentro de Indicadores. **Continuar** segue diretamente para Gestão e o retorno de Gestão abre Indicadores.

O salvamento do histórico em Indicadores inclui as regras. Tab/Shift+Tab percorrem os parâmetros e o bloco de regras; erros de edição impedem avançar até serem corrigidos. Os arquivos de set continuam preservando os mesmos dados.

**Rolagem vertical:** na página Indicadores, uma barra na direita da área de conteúdo permite arrastar o indicador de posição ou clicar no trilho. A roda do mouse e Page Up/Page Down também rolam a página. Os cards de seleção e parâmetros ficam lado a lado nas telas largas. Logo abaixo fica o Resumo dos indicadores. Depois, a antiga página Regras aparece como segunda seção, com os cards Ordem, Filtro de candle e Alvos. Os botões ficam ao final das regras. Em telas estreitas, os cards se reorganizam verticalmente. Cabeçalho e menu permanecem fixos. O foco por teclado traz o campo para a área visível, e rolar preserva textos ainda não confirmados. O resumo completo e os botões do rodapé são acessíveis mesmo em áreas baixas, como 1792 × 733.

`GuiScrollInteractionTests.mq5` testa os controles e a renderização reais em um terminal portátil: seleção do indicador, roda, arraste, limites de rolagem, acesso ao rodapé, foco e preservação da edição. Os 12 testes passaram; imagens de topo, parâmetros e rodapé foram geradas e inspecionadas. O evento de roda do gráfico é habilitado durante o uso e sua configuração anterior é restaurada ao remover o EA. `GuiMergedLayoutTests.mq5` verifica os blocos e os controles incorporados.

## ADX

Os quatro slots de Indicadores oferecem ADX, com período padrão 14 e valores inteiros de 1 a 100000. O período é independente de Média Móvel e RSI e é preservado ao alternar o tipo ou desativar o slot. ADX aparece no resumo, no histórico em memória e no log de salvamento. Somente o período é exibido; os campos de preço, método, shift e níveis de RSI não se aplicam ao ADX.

Assim como os indicadores existentes nesta etapa, ADX configura preferências da interface; ainda não calcula valores no gráfico nem gera sinais de negociação. `Tests/GuiStateTests.mq5` cobre validação, alternância e histórico. Validação visual: selecionar ADX nos quatro slots, editar o período, alternar para RSI e voltar, salvar e conferir o resumo; testar Tab/Shift+Tab e redimensionamento.

Projeto UniEA para MetaTrader 5. O desenvolvimento ativo fica em Experts/Uni.

Abra UniversalEa.code-workspace no VS Code para trabalhar neste repositorio. Arquivo principal: UniEA.mq5. Componentes: Include/CanvasGUI. Testes: Tests. A biblioteca padrao do MetaTrader 5 deve estar instalada em MQL5/Include.

No Controle do Codigo-Fonte do VS Code, prepare as alteracoes, escreva a mensagem, crie o commit e use Sincronizar Alteracoes para enviar para origin/main. Compilados e logs sao locais e nao entram nos commits.


## Etapa 4 — Gestão / Stop móvel

O terceiro card, **Stop móvel**, replica os campos do **Trailing stop**: modo Desativado/Pontos/Porcentagem, ativação, distância do preço e passo de ajuste. Seus valores e unidades são independentes e entram no resumo, histórico e log. Os três cards ficam lado a lado; em telas largas com pouca altura, distância e passo compartilham uma linha para manter a página dentro de 1792 × 733 px.

**Continuar →** em Regras abre Gestão. Os cards **Breakeven** e **Trailing stop** oferecem os modos Desativado (padrão), Pontos e Porcentagem, independentes dos alvos fixos. Breakeven recebe ativação e proteção na entrada (zero representa o preço de entrada); trailing recebe ativação, distância do preço e passo de ajuste. Cada unidade preserva seus valores, sem conversão automática.

Os campos desativados ficam indisponíveis e são ignorados pelo Tab. Ao ativar, o breakeven exige ativação positiva e proteção menor que a ativação; trailing exige os três valores positivos. Valores negativos, texto inválido e mais de duas casas decimais são rejeitados. **Salvar gestão** registra setup, indicadores, regras e gestão no histórico em memória e no log. **← Regras** retorna preservando os dados.

Esta etapa configura preferências; ainda não modifica stops de posições. A base de cálculo percentual será definida na implementação da execução. O card Filtro de candle continua vazio. `Tests/GuiManagementStateTests.mq5` cobre validação, troca de unidades, independência do histórico e limites do layout; compilar não equivale a executar o script.

## Etapa 3 — Regras

O seletor **Unidade dos alvos**, no card Alvos, permite escolher **Pontos** (padrão) ou **Porcentagem** para stop loss e take profit. Os rótulos, o resumo e o log refletem a unidade selecionada. Cada unidade preserva seus próprios valores ao alternar, sem conversão automática; zero desativa a saída. Ambas aceitam até duas casas decimais. O histórico registra a unidade junto com os valores. O card Filtro de candle continua vazio.

Em Indicadores, **Continuar →** abre Regras. O card **Ordem** oferece **A mercado** ou **Pendente**. O card **Filtro de candle** permanece vazio para desenvolvimento futuro. O card **Alvos** permite configurar stop loss e take profit em **pontos**, com até duas casas decimais; **0 desativa** a respectiva saída.

**← Indicadores** retorna preservando os valores. Nas telas com menu lateral, Setup, Indicadores e Regras também permitem navegação por clique. **Salvar regras** registra uma cópia conjunta do setup, indicadores e regras no histórico em memória e no log de Experts. A configuração não persiste após remover/reiniciar o EA. Esta etapa configura preferências; a execução de ordens e a avaliação do candle ainda não estão implementadas.

Os controles seguem o estilo Canvas existente, com cards, ícones, resumo, foco, hover e setas nos botões de navegação. Tab/Shift+Tab percorrem os campos e botões; Enter confirma e Esc cancela uma edição. Valores inválidos impedem salvar ou sair da aba. Recolher e redimensionar preservam o buffer de edição de Regras.

Validação manual: configurar uma ordem pendente, stop de `150,25` e take de `300.50`; salvar, voltar a Indicadores e retornar a Regras; conferir valores e log. Testar também zero, negativos, campo vazio, três casas decimais, Tab/Shift+Tab, dropdowns, recolher e redimensionar. `Tests/GuiRulesStateTests.mq5` cobre validação, cópias do histórico e limites do layout; compilar não equivale a executar o script.

## Etapa 1 — Setup

A interface inicia em **Setup**, antes de **Indicadores** (etapa 2 de 7). O card Identificação contém nome opcional (até 48 caracteres) e Magic Number automático (1 a 2147483647). O card Mercado e operação contém Forex/B3, os 21 timeframes MT5 e direção permitida: Compra e venda, Somente compra ou Somente venda.

Padrões: Meu setup, Magic aleatório de cinco dígitos, Forex, período do gráfico e Compra e venda. **Continuar** valida os campos e abre Indicadores; **< Setup** retorna preservando os valores dos dois passos. Tab/Shift+Tab percorrem os controles e Enter confirma/aciona. Valores inválidos impedem sair do campo. Recolher mantém a edição pendente.

O seletor **Modalidade**, ao lado de Mercado, oferece **Day trade** (padrão) e **Swing trade**. A escolha é preservada ao voltar de Indicadores e incluída no histórico e no log de salvamento. Trocar a modalidade mantém os horários, a direção e a opção de encerramento já escolhidos. O Tab segue a ordem visual: Mercado → Modalidade → Timeframe → Lote → Direção.

O campo **Lote**, ao lado de Timeframe, inicia no volume mínimo do ativo anexado. Aceita ponto ou vírgula decimal e valida mínimo, máximo e incremento informados pelo MT5 (`SYMBOL_VOLUME_MIN`, `SYMBOL_VOLUME_MAX`, `SYMBOL_VOLUME_STEP`). Valores fora desses limites ou do incremento são rejeitados sem arredondamento silencioso. As regras vêm do símbolo real do gráfico, inclusive para B3, e são consultadas novamente ao confirmar o lote ou continuar. O lote é preservado entre as páginas e copiado para o histórico e o log de salvamento. Essas preferências continuam sem executar ordens.

O card **Horários** contém seletores de início, fim das entradas e encerramento, com intervalos de 5 minutos: 00:00, 00:05, …, 23:55. Os horários usam o servidor da corretora. O padrão é 00:00–23:55 com encerramento desativado; são valores de configuração, não uma indicação da sessão de negociação do ativo.

Os seletores longos mostram até oito opções por vez. As faixas de navegação na própria lista mudam a página; setas, Page Up/Down e Home/End permitem percorrer as opções pelo teclado. A lista abre na seleção atual, inclusive 23:55. Enter confirma, Esc cancela e Tab confirma a opção destacada e avança. Início e fim devem ser diferentes; um fim anterior ao início representa uma janela que atravessa a meia-noite. Quando habilitado, o encerramento deve ocorrer no fim das entradas ou depois dele, dentro do ciclo iniciado no horário de início. Essas relações são verificadas ao continuar, permitindo escolher os campos em qualquer ordem.

O campo de encerramento desativado é ignorado pelo Tab, mas seu valor é preservado ao reativar. Os horários também são preservados ao voltar de Indicadores ou recolher e são copiados para o histórico ao salvar. Ainda são apenas configuração; não foi acrescentada execução de ordens. Em telas largas, os três cards ficam lado a lado; abaixo de 960 pixels de largura, Horários fica abaixo dos demais.

O cabeçalho exibe UNIVERSAL EA e o ativo/período reais do gráfico. O timeframe selecionado é uma preferência do setup e não muda o gráfico. Mercado e direção são configurações preparadas para a estratégia futura; este experimento continua sem enviar ordens. Salvar indicadores inclui a identificação e as preferências em cada cópia do histórico.

`GuiSetupState.mqh` contém o estado e validação; `GuiSetupPage.mqh` reutiliza os controles Canvas para o formulário, teclado e dropdowns. O modo texto de `GuiTextField` usa [TranslateKey](https://www.mql5.com/en/docs/common/translatekey) para respeitar idioma e maiúsculas do teclado. O modo numérico existente é preservado.

`Tests/GuiSetupStateTests.mq5` cobre limites, entradas inválidas, independência e mapeamento dos períodos. `GuiStateTests` também verifica que mudar Setup não altera configurações anteriores. Compilar esses scripts não equivale a executá-los.

## Padrão de ícones dos cards

`Include/CanvasGUI/GuiIcons.mqh` centraliza a família de ícones de traço fino em uma grade de 20 × 20. Use `renderer.Icon(GUI_ICON_..., x, y, cor, tamanho)` nos próximos cards, sem fontes de símbolos, imagens externas ou objetos adicionais. Títulos usam 20 pixels; indicadores e opções usam 16 pixels, com espaço reservado antes do texto. Azul identifica a estrutura, verde a Média Móvel e laranja o RSI. O nome permanece ao lado do ícone.

A família inclui Indicadores, Regras, Gestão, Filtros, Revisão, Ativação, Parâmetros, Média Móvel e RSI. A opção Não usar mantém parâmetros e resumo vazios. Compilação verificada; conferência visual dos ícones no terminal ainda pendente.

Experimento de interface MQL5 com `CCanvas`, sem dependências externas além da biblioteca padrão do MT5. Não envia ordens, não cria handles de indicadores e não implementa estratégia.

## Compilar e testar

1. Abra `UniEA.mqproj` no MetaEditor e compile `UniEA.mq5` com F7.
2. No Navegador do MT5, atualize a lista de Experts e arraste `UniEA` para um gráfico. Não é necessário habilitar negociação algorítmica.
3. O card **Indicadores** oferece quatro botões numerados com seleção exclusiva. Escolha 1, 2, 3 ou 4 e selecione Não usar, Média Móvel ou RSI. O card **Parâmetros / Indicador N** mostra o nome e os quatro campos do indicador ativo. Os quatro indicadores iniciam em Não usar. Nessa opção, o painel de parâmetros e a coluna correspondente do resumo ficam vazios. Os parâmetros anteriores são preservados em memória ao desabilitar e reativar um indicador. **Continuar →** abre Regras.
4. Configure períodos diferentes nos quatro indicadores e alterne entre eles. Troque MA ↔ RSI: os valores de cada tipo permanecem independentes por indicador. Uma edição inválida bloqueia a troca até ser corrigida ou cancelada com Escape. As etapas 5–7 continuam apenas visuais.
5. Clique num campo e digite: o primeiro dígito substitui o valor anterior. Enter, Tab ou clique fora confirmam; Escape cancela. Setas, Home, End, Backspace e Delete permitem edição por posição. Ponto, vírgula e decimal do teclado numérico são aceitos.
6. Teste período zero, texto vazio, níveis fora de 0–100 e inferior ≥ superior: o campo deve ficar vermelho, sem alterar o estado. Corrija ou use Escape para continuar.
7. Selecione cada indicador e abra sua lista de preço no card de parâmetros. Verifique sobreposição, abertura para cima perto da borda, fechamento por clique externo e navegação por setas/Enter/Escape.
8. Clique Salvar indicadores e confira os valores no log de Experts da Caixa de Ferramentas. `Print()` de EA é exibido em **Experts**, não necessariamente na aba separada **Diário/Journal**. O botão sempre imprime a configuração; `DebugGUI=false` desativa apenas mensagens de diagnóstico.
9. Redimensione o gráfico e remova o EA: o Canvas deve acompanhar o tamanho e as propriedades do gráfico alteradas pelo experimento devem ser restauradas na remoção.
10. Clique **Recolher**, no canto superior direito. O gráfico reaparece e seus controles de rolagem e teclado voltam à configuração original. Clique **EXIBIR INTERFACE**, no canto superior esquerdo, para retornar. Teste também redimensionar o gráfico enquanto a interface está recolhida.

Recolher preserva as configurações e até uma edição ainda não confirmada; dropdowns são fechados. O mesmo Canvas é reduzido a 176 × 40 pixels para desenhar o botão de retorno, mantendo apenas um objeto gráfico e liberando o restante do gráfico para interação. Ao reabrir, as dimensões atuais são lidas novamente.

O script `Tests/GuiStateTests.mq5` contém verificações do estado: valores iniciais, independência, preservação MA/RSI, validação e mapeamentos. Para executar, copie o script para `MQL5/Scripts`, ajustando seu include para o caminho de `GuiState.mqh`, compile e arraste para um gráfico. Ele não cria objetos nem opera. Resultado esperado: `0 falhas`. A compilação do script não equivale à sua execução.

## Arquivos e responsabilidades

- `UniEA.mq5`: entrada do EA; OnInit, OnDeinit, OnChartEvent e OnTick vazio.
- `UniEA.mqproj`: projeto existente, atualizado com os arquivos da biblioteca.
- `Include/CanvasGUI/GuiApp.mqh`: ciclo de vida, despacho de eventos, bindings e invalidação.
- `Include/CanvasGUI/GuiTheme.mqh`: cores ARGB e retângulos.
- `Include/CanvasGUI/GuiRenderer.mqh`: Canvas, primitivas, apresentação e backup da região do dropdown.
- `Include/CanvasGUI/GuiState.mqh`: configuração definitiva dos quatro indicadores, validação e impressão.
- `Include/CanvasGUI/GuiLayout.mqh`: medidas e distribuição responsiva.
- `Include/CanvasGUI/Controls/GuiControl.mqh`: base, bounds, visibilidade, habilitação, hover, active e dirty.
- `Include/CanvasGUI/Controls/GuiLabel.mqh`: rótulos.
- `Include/CanvasGUI/Controls/GuiButton.mqh`: botão e estados visuais.
- `Include/CanvasGUI/Controls/GuiTextField.mqh`: editor numérico Canvas; buffer temporário separado do estado.
- `Include/CanvasGUI/Controls/GuiSelectBox.mqh`: seletor e camada de opções.
- `Include/CanvasGUI/Controls/GuiField.mqh`: adaptação reutilizável entre componentes e campos do estado.
- `Tests/GuiStateTests.mq5`: verificações de estado executáveis como script.
- `README.md`: arquitetura, limites e roteiro de validação.
- `UniEA.ex5`, `UniEA.compile.log`, `Tests/GuiStateTests.ex5` e `Tests/GuiStateTests.compile.log`: artefatos locais de compilação.

## Renderização e objetos

A GUI cria **1 objeto MT5**, um `OBJ_BITMAP_LABEL`, inclusive durante edição e dropdowns. Objetos preexistentes no gráfico não entram nessa contagem. Nenhum `OBJ_EDIT` é utilizado.

`Render()` sai imediatamente quando `m_dirty=false`. Hover só invalida ao mudar de controle/opção. Edição redesenha o campo e a mensagem; troca de tipo redesenha o card afetado. O fundo inteiro é desenhado apenas na inicialização ou mudança de dimensões. A região sob o dropdown é copiada antes de desenhá-lo e restaurada antes da próxima composição. O dropdown é sempre desenhado por último.

Há uma chamada `CCanvas.Update(true)` por atualização visual efetiva. A biblioteca padrão ainda transfere o bitmap inteiro para o recurso nessa chamada; a otimização parcial economiza desenho, não promete upload parcial. Não há timer, animação contínua ou trabalho em OnTick.

O teclado numérico foi implementado em Canvas porque o escopo não exige edição de texto geral. Não há criação/destruição de objetos auxiliares nem cursor piscante. Os eventos seguem a [documentação oficial de teclado MQL5](https://www.mql5.com/en/book/applications/events/events_keyboard).

## Limitações conhecidas

- Layout adaptável à altura: em áreas mais baixas, reduz os espaçamentos e mantém campos, ação e histórico. Exemplos mínimos: 1120 × 628 com navegação lateral; 960 × 652 com cards lado a lado e etapas no topo; 600 × 904 com cards empilhados. Abaixo do espaço necessário, o aviso informa a área atual e a altura calculada. Não há rolagem. A navegação lateral aparece a partir de 1120 pixels de largura.
- Medidas em pixels; escala de DPI não é ajustada automaticamente.
- Edição numérica limitada a 12 caracteres; períodos 1–100000, shift ±100000 e níveis RSI 0–100 com até duas casas decimais e inferior < superior.
- Sem clipboard, seleção arbitrária ou Ctrl+A. Tab confirma a edição e avança; Shift+Tab volta. O gráfico deve estar com foco para receber teclado.
- Uma edição inválida impede mudar de campo ou aplicar até corrigir/cancelar. Ao redimensionar, uma edição válida é confirmada; uma inválida é descartada com aviso.
- Estado apenas em memória; reinicialização do EA, troca de símbolo/timeframe ou remoção retorna aos valores iniciais.
- Ocupa a janela principal do gráfico, não sub-janelas de indicadores existentes. Destina-se preferencialmente a um gráfico limpo.
- Compilação verificada no MetaEditor instalado. O roteiro de interação visual e o script de estado devem ser executados no terminal; não foram executados automaticamente nesta entrega.

## Resumo e histórico de aplicações

A área inferior tem quatro colunas fixas, uma por indicador, com tipo, período, preço e método/shift ou níveis RSI. Ao editar, acompanha os valores confirmados, inclusive a seleção Não usar. **Salvar indicadores** registra uma cópia dos quatro indicadores e imprime seus parâmetros no log. Depois de salvar, o resumo exibe a aplicação selecionada, identificada no título; uma nova edição volta ao resumo atual, sem modificar o histórico; os botões de navegação foram removidos. Um novo salvamento mostra a aplicação mais recente.

O histórico e os parâmetros permanecem em memória, inclusive ao recolher/reabrir. Reinicializar ou remover o EA restaura os padrões. Continua existindo apenas um objeto Canvas.

## Validação da configuração de quatro indicadores

EA e script de estado compilados no MetaEditor. Os testes incluem independência dos quatro slots, preservação de valores MA/RSI, captura do indicador 4 no histórico e reset. Compilar o script não equivale a executá-lo; sua execução no terminal continua pendente.

Roteiro visual: selecionar 1–4, editar períodos distintos, alternar tipos, tentar trocar de indicador com valor inválido, abrir dropdowns, salvar duas configurações, conferir o resumo salvo e recolher/reabrir com edição pendente.

O botão **Salvar indicadores** fica abaixo do resumo, alinhado à direita. As mensagens ficam à esquerda na mesma área. O histórico continua armazenado em memória; a interface mostra a última aplicação ou a edição atual, sem setas de navegação.


## Magic Number automático

No card Identificação, “Meu setup” (ou nome vazio) reserva um número de 10000 a 99999. Nomes personalizados usam FNV-1a sobre os bytes UTF-16: letras, acentos, números, espaços internos e pontuação participam, com distinção entre maiúsculas e minúsculas. Espaços externos são removidos. O candidato fica entre 100000 e 2147483647; colisões avançam até o próximo número livre. Confirmar o mesmo nome na mesma instância preserva o Magic. Renomear ou criar um novo set reserva outro identificador, mesmo quando o nome já foi usado. **Carregar um set salvo restaura seu Magic original sem gerar outro.**

O campo Magic é somente leitura e é ignorado pelo Tab. A reserva é gravada imediatamente em `UniEA\magic-v1.bin` na pasta comum dos terminais (`Terminal/Common/Files`), sem expiração nem reciclagem dos números de rascunhos. `UniEA\owners\<magic>.txt` registra a identificação permanente do set proprietário. Um arquivo aberto exclusivamente serializa as reservas entre terminais que compartilham essa pasta. Para gerar novos números, também são consultadas posições, ordens e o histórico disponível da conta conectada. Carregar o próprio set não precisa de conexão e aceita sua reserva existente. Um proprietário diferente ou uma reserva antiga sem proprietário comprovável bloqueia o carregamento, sem renumerar o arquivo.

A proteção cobre esse registro compartilhado e o histórico disponibilizado pelo servidor. Outro computador/VPS sem o registro, um registro apagado, histórico indisponível ou robôs externos que atribuam números simultaneamente não permitem garantia global. Ao migrar, preserve o registro; uso simultâneo entre máquinas exige um serviço central de reservas. Apenas o hash não garante exclusividade.

`Tests/GuiMagicTests.mq5` verifica limites, hash, caracteres, colisões, duplicatas, retorno ao começo da faixa e esgotamento sem acessar o registro real. Roteiro de integração: abrir dois gráficos e conferir Magics distintos; confirmar o mesmo nome sem alteração; renomear; reiniciar e conferir que reservas antigas não são reutilizadas; desconectar e tentar renomear. Os testes de estado legados usam o modo sem reserva; o card habilita explicitamente o modo automático.

## Salvar e carregar sets

O card Identificação oferece **Salvar set** e **Carregar set**, acessíveis também pelo Tab e Enter. O diálogo começa em `Terminal/Common/Files/UniEA/Sets`. O nome sugerido inclui o nome do setup e o Magic para distinguir sets homônimos. Ao concluir as alterações nas outras etapas, volte a Setup e use **Salvar set**. Os botões de salvar indicadores/regras/gestão continuam registrando o histórico em memória; o arquivo completo é gravado pelo botão **Salvar set**.

O arquivo `.set` deste painel usa o formato binário versionado **UniEA**, com verificação de integridade. É carregado pelo botão do painel, não pela aba de parâmetros nativa do MT5. Inclui nome, identidade permanente, Magic, mercado, timeframe, direção, modalidade, lote, horários, quatro indicadores, regras e gestão, inclusive os valores preservados ao alternar pontos/porcentagem. Limites de lote vêm do ativo atual; um lote incompatível é preservado para correção antes de continuar.

Exemplo: criar “joao”, salvar, reiniciar e usar **Carregar set** restaura nome e Magic exatos. A comparação de propriedade usa a identidade salva, não apenas o nome do arquivo. Recarregar o mesmo set é permitido; outro set que reivindique seu Magic é rejeitado. Cópias do mesmo arquivo representam o mesmo set. Renomear pelo campo de nome cria uma nova identidade e um novo Magic; o arquivo anterior permanece intacto. Um novo set não sobrescreve o arquivo de outro proprietário. Gravações passam por arquivo temporário validado antes da substituição; falhas de leitura/validação deixam a configuração atual intacta.

`Tests/GuiSetFileTests.mq5` cobre salvar/carregar, recargas repetidas, preservação de bancos de valores, colisão entre proprietários, sobrescrita indevida, registro ocupado, versão inválida, truncamento e corrupção. Usa um diretório temporário exclusivo `UniEA-Tests` na pasta comum, sem alterar o registro de produção.

Validação desta alteração: EA e `Tests/RunStateTests.mq5` compilados com zero erros/avisos. O agregador foi executado em um terminal portátil isolado: **3184 verificações, zero falhas**, incluindo 24 verificações de persistência. O agregador não envia ordens. Para repetir, compile e execute `RunStateTests` como script no MT5; a pasta comum deve permitir a criação dos arquivos temporários de teste. A interação visual com os botões e o diálogo de arquivos ainda deve ser conferida no terminal.
