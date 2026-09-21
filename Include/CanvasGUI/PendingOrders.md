# Ordens pendentes na Canvas

O card Ordem apresenta o seletor Posicionar em: Máxima, Mínima, Abertura,
Fechamento ou Distância. O campo Vela aparece para todas essas opções.
A unidade (pontos ou porcentagem) e o valor aparecem somente em Distância.

OHLC representa o preço exato da vela, sem adicionar a distância guardada.
O seletor Stop/Limit foi removido. Trocar as opções preserva os valores.
Vela 1 corresponde à última fechada; intervalo permitido: 1 a 100000.

Os conjuntos agora usam v5. V1/v2/v3 recebem os padrões. V4 preserva referência,
vela e valores, descartando Stop/Limit; a distância antiga deixa de ser aplicada
às referências OHLC.

Esta etapa configura a interface e a persistência; não envia ordens.
A base e o sentido do cálculo da opção Distância serão definidos na etapa de
execução. Ainda não existe cálculo de preço dessa opção.
