# Migração para listas do SharePoint

Plano completo, formatado para leitura: **plano-implantacao.html** (abra no navegador)
ou https://claude.ai/code/artifact/283adb6a-d689-4fd6-907d-75c2c6f9db64

## Arquivos

| Arquivo | Para quê |
|---|---|
| `SharePoint_Importacao.xlsx` | Os dados de hoje, uma aba por lista, já no formato de colagem |
| `listas/MP_*.xlsx` | A mesma coisa, um arquivo por lista — para quando a importação do SharePoint não deixa escolher a tabela |
| `formatacao/coluna_Situacao.json` | Badge colorido na coluna Situação |
| `formatacao/coluna_ConsumoSLA.json` | Barra de prazo com cor por faixa |
| `formatacao/coluna_DiasAtraso.json` | Número em vermelho quando há atraso |
| `formatacao/exibicao_Projetos.json` | Faixa de severidade na linha inteira |
| `plano-implantacao.html` | As sete listas, os dois fluxos, a ordem de montagem |

Para aplicar a formatação: na lista, abra o menu da coluna →
**Configurações de coluna → Formatar esta coluna → Modo avançado** e cole o JSON.

## Conteúdo do arquivo de importação

| Aba | Linhas | Vira a lista |
|---|---|---|
| Projetos | 78 | Projetos |
| Itens | 21 | Itens |
| Entregas | 12 | Entregas |
| HistoricoEtapas | 56 | HistoricoEtapas |
| Produtos | 26 | Produtos |
| ObjetosCusto | 108 | ObjetosCusto |
| EtapasSLA | 12 | EtapasSLA |

Só colunas de entrada: tudo que era fórmula foi deixado de fora de propósito, porque
no SharePoint vira coluna calculada ou fluxo. O plano diz qual é qual.

## Os dois pontos que decidem se isso funciona

1. **Coluna calculada não recalcula com o tempo.** Um cálculo com `HOJE()` só é refeito
   quando alguém edita o item. Por isso "dias na etapa" depende do fluxo diário.
2. **Coluna calculada não lê coluna de pesquisa.** Por isso `SLADias` fica em Projetos
   como número comum, copiado pelo fluxo, e não buscado de EtapasSLA.

Nenhum dos dois aparece na documentação de primeira leitura, e os dois quebram o
sistema em silêncio.
