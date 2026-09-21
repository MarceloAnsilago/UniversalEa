# Filtros de tamanho de candle

No card Filtro de candle, o seletor Configurar candle alterna entre 1, 2 e 3.
Cada candle guarda seus próprios valores; 1 corresponde ao último fechado.
O seletor apenas escolhe qual configuração está sendo editada.

Cada configuração contém:

- Medida do candle: corpo (diferença absoluta entre abertura e fechamento)
  ou total (máxima menos mínima).
- Unidade: pontos ou porcentagem, independente para cada candle.
- Tamanho mínimo e máximo do candle.
- Tamanho mínimo e máximo do pavio superior.
- Tamanho mínimo e máximo do pavio inferior.

A unidade selecionada vale para os seis limites. Os bancos em pontos e em
porcentagem são independentes e preservados ao alternar a unidade.
Em porcentagem, 100% representa máxima menos mínima da própria vela.
Corpo e pavios são frações dessa amplitude; quando a medida escolhida é Total,
ela representa 100% (para uma vela com amplitude positiva).
O percentual permitido é de 0 a 100. O padrão continua sendo pontos.

Todos os limites começam em zero. Zero desativa somente aquele limite.
Quando mínimo e máximo estão ativos, mínimo não pode superar máximo.
O modo inicial é Corpo. A condição anterior de alta/baixa permanece separada.

A configuração acompanha o histórico e os conjuntos salvos (formato v7).
Arquivos v6 preservam seus limites em pontos e recebem o banco percentual zerado.
Arquivos mais antigos recebem os novos limites zerados.
Esta etapa prepara a Canvas e a persistência. A aplicação desses limites aos
sinais e às futuras ordens no motor do EA ainda não está conectada.
