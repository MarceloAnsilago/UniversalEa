# Ordens pendentes na Canvas

O card Ordem apresenta o seletor Posicionar em: Máxima, Mínima, Abertura,
ou Fechamento. O campo Vela aparece para todas essas opções.
A opção Distância e seus campos de valor e unidade foram retirados.

OHLC representa o preço exato da vela, sem adicionar a distância guardada.
O seletor Stop/Limit foi removido. Trocar as opções preserva os valores.
Vela 1 corresponde à última fechada; intervalo permitido: 1 a 100000.

Os conjuntos agora usam v5. V1/v2/v3 recebem os padrões. V4 preserva referência,
vela e valores, descartando Stop/Limit; a distância antiga deixa de ser aplicada
às referências OHLC.

Esta etapa configura a interface e a persistência; não envia ordens.
Os campos binários antigos de distância permanecem somente para compatibilidade
dos arquivos. Sets v5 que selecionavam Distância são rejeitados com mensagem
explícita, para evitar trocar silenciosamente seu posicionamento por outro preço.
