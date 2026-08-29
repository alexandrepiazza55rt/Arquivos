# Handoff — implantar o Monitoramento Patrimonial no SharePoint

Este documento é para o **Claude Code rodando na máquina do Alexandre**. Ele
contém tudo que é preciso saber: não há conversa anterior a recuperar.

- **Site:** https://inpasabr.sharepoint.com/sites/CentraldeProteodoNegcio
- **Idioma do site:** português. Fórmulas usam `SE` e **ponto e vírgula**. Confirmado.
- **Convenção:** toda lista nova leva o prefixo `MP_` e é criada com
  **"Mostrar na navegação do site" DESMARCADO**.
- **Regra de ouro:** não altere nada fora do prefixo `MP_`. O site tem listas e
  bibliotecas de outras equipes.

---

## Como acessar o navegador

O usuário **não vai fornecer credenciais**. Ele vai abrir uma janela já
autenticada e autorizar você a controlá-la, sob supervisão dele.

O navegador é o **Google Chrome**.

Versões recentes do Chrome **ignoram `--remote-debugging-port` quando o perfil
padrão está em uso** — é uma proteção deliberada. Por isso é obrigatório abrir
com um diretório de perfil separado. Peça ao usuário para fechar o Chrome por
completo e reabrir assim:

```powershell
Start-Process chrome -ArgumentList '--remote-debugging-port=9222','--user-data-dir=C:\temp\chrome-claude'
```

Se o PowerShell reclamar, o equivalente pelo Prompt de Comando:

```
"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir="C:\temp\chrome-claude"
```

Essa janela abre com um perfil limpo, **sem login**. O usuário faz o login da
empresa nela, com as próprias mãos — você não pede, não vê e não guarda nada
disso. O perfil persiste em `C:\temp\chrome-claude`, então nas próximas vezes
basta repetir o comando e a sessão continua ativa.

Confirme com ele que a janela está autenticada no site antes de prosseguir.

Depois conecte-se à instância existente, sem abrir navegador novo:

```javascript
const { chromium } = require('playwright');
const browser = await chromium.connectOverCDP('http://localhost:9222');
const ctx = browser.contexts()[0];
const page = ctx.pages()[0] ?? await ctx.newPage();
```

Regras ao operar essa janela:

1. Navegue **apenas** em `inpasabr.sharepoint.com` e `make.powerautomate.com`.
2. Nunca abra outras abas nem toque em nada fora do escopo. É o perfil pessoal
   do usuário, com tudo logado.
3. Antes de qualquer ação destrutiva — excluir lista, excluir coluna, rodar
   fluxo que grava — **pare e peça confirmação**.
4. Descreva o que vai fazer antes de fazer. Ele está supervisionando.

---

## Estado atual

Itens 1 a 7 concluídos. As sete listas estão populadas, os cinco JSON
aplicados, os dois fluxos ligados, cinco exibições criadas e três índices
aplicados em `MP_Projetos`.

| Lista | Itens | Situação |
|---|---|---|
| `MP_Produtos` | 26 | pronta, com badge JSON em TipoItem |
| `MP_ObjetosCusto` | 108 | pronta |
| `MP_EtapasSLA` | 12 | pronta |
| `MP_Projetos` | 78 | completa — SLADias, DiasNaEtapa e Situacao preenchidos |
| `MP_Itens` | 21 | completa — QtdRecebida carregada, soma 38 |
| `MP_Entregas` | 12 | completa |
| `MP_HistoricoEtapas` | 56 | completa |

**Distribuição de `Situacao` depois do Fluxo A rodar** (referência 28/08/2026):

```
ATRASADO   27      CONCLUÍDO  24
NO PRAZO   26      ATENÇÃO     1
```

> Os 27 ATRASADO são metade da carteira ativa (54). Não é defeito do cálculo:
> `DiasNaEtapa` vem da data real de `InicioEtapa` de cada projeto. Ou os SLA
> por etapa estão apertados demais para a realidade do setor, ou o setor está
> mesmo atrás. A resposta a isso é do dono do processo, não do sistema — mas
> ela precisa vir antes de o setor entrar, senão a coluna vira ruído e todo
> mundo aprende a ignorar o vermelho.

Colunas já criadas em `MP_Projetos`:

```
Title (era Chamado)   NomeProjeto   Unidade   AreaDemandante   CodObjetoCusto
ResponsavelDemandante DataAbertura  EtapaAtual InicioEtapa     Status
Bloqueado             Dificuldade   ProximaAcao
SLADias (Número)      DiasNaEtapa (Número)
DiasAtraso (Calculado)  ConsumoSLA (Calculado)  Situacao (Calculado)
```

> **A coluna do número do chamado chama-se `Title`, não `Chamado`.** Foi a
> importação do Excel que mapeou a primeira coluna para o Título. Em fórmulas,
> JSON e fluxos, use `Title`.

> **ARMADILHA MAIOR — nome interno genérico.** A importação do Excel cria as
> colunas com nome interno `field_1`, `field_2`, … e guarda o cabeçalho apenas
> como rótulo de exibição. Em `MP_Projetos`: `EtapaAtual` = `field_7`,
> `InicioEtapa` = `field_8`, `Status` = `field_9`, `Bloqueado` = `field_10`.
>
> Onde isso importa:
> - **REST e Power Automate** usam o nome INTERNO. Um filtro
>   `Status ne 'CONCLUÍDO'` devolve erro 400, e `item()?['InicioEtapa']` volta
>   vazio — o que zeraria `DiasNaEtapa` de todos os projetos ativos sem avisar.
> - **Fórmulas de coluna calculada** usam o nome de EXIBIÇÃO. Por isso
>   `=SE([Status]=...)` funcionou normalmente.
> - **Formatação JSON** usa o nome INTERNO em `[$Campo]`, mas `@currentField`
>   não depende de nome.
>
> Nome interno não pode ser alterado depois de criada a coluna. Levante o mapa
> real com `/_api/web/lists/getbytitle('MP_Projetos')/fields` e use sempre ele
> em fluxo e REST.

> **Por isso, as três listas que faltam NÃO devem ser criadas importando do
> Excel.** Crie as colunas com nome interno limpo (via REST ou pelo painel de
> criar coluna) e só depois carregue as linhas. Custa alguns minutos a mais e
> evita arrastar `field_N` para dentro do Fluxo B, das exibições e da página.

---

## O que falta — em ordem

### 1. Preencher SLADias e DiasNaEtapa

O arquivo `colar_SLADias_DiasNaEtapa.xlsx` traz os 78 valores **na mesma ordem
da lista** (ordem de importação = ordem do ID).

- Abra `MP_Projetos` em **Editar no modo de exibição de grade**
- Garanta que a exibição está na ordem padrão, **sem classificação aplicada**
- Cole **somente as colunas B e C** do arquivo, na primeira célula de `SLADias`
- A coluna A do arquivo é só para conferência de alinhamento

**Conferência obrigatória depois de colar.** Se qualquer uma falhar, desfaça:

| Title | SLADias | DiasNaEtapa |
|---|---|---|
| 440641 | 5 | 8 |
| 123 | 5 | 156 |
| N/A01 | 3 | 3 |
| 461634 | 7 | 2 |

Resultado esperado na coluna `Situacao`, somando 78:

```
NO PRAZO    27      CONCLUÍDO   24
ATRASADO    24      EM RISCO     3
```

### 2. Aplicar a formatação JSON

Coluna → **Configurações de coluna → Formatar esta coluna → Modo avançado**.

| Arquivo | Lista | Coluna |
|---|---|---|
| `coluna_Situacao.json` | MP_Projetos | Situacao |
| `coluna_PrazoDaEtapa.json` | MP_Projetos | DiasNaEtapa |
| `coluna_DiasAtraso.json` | MP_Projetos | DiasAtraso |
| `exibicao_Projetos.json` | MP_Projetos | a exibição (Formatar exibição atual) — v2, ver nota |
| `coluna_SituacaoFisica.json` | MP_Entregas | SituacaoFisica |
| `coluna_TipoItem.json` | MP_Produtos | TipoItem — **já aplicado** |

> **Realce de linha, versão 3.** O critério: **o realce marca o que ainda dá
> para evitar; o badge marca o que já aconteceu.** Por isso ele cobre a faixa
> de ação — BLOQUEADO (vermelho), EM RISCO (laranja) e ATENÇÃO (amarelo) — e
> deixa ATRASADO só com o badge.
>
> A v1 pintava ATRASADO e o rosa da linha engolia o rosa da pílula. Pior que
> isso: são 27 de 78, e realçar um terço da lista não ajuda a varrer. Um
> projeto atrasado há 150 dias não é urgente hoje; um a um dia de estourar é.
>
> A v2 tirou ATRASADO mas ficou só com BLOQUEADO e EM RISCO — que, depois do
> Fluxo A rodar, somam zero. Regra que nunca acende não sinaliza nada.

### 3. Criar as três listas que faltam

Nesta ordem. Importar de `1_listas/MP_*.xlsx` via **+ Novo → Lista → Do Excel**.

**Quem vai na coluna Title.** O SharePoint sempre cria a coluna Title e ela é
obrigatória. A regra aqui: **Title guarda o que uma pessoa fala em voz alta
para identificar a linha**, e não se duplica esse valor numa segunda coluna.
Title não precisa ser único — nunca precisou.

| Lista | Title recebe | Não crie coluna separada para | Filtro de fluxo usa |
|---|---|---|---|
| `MP_Itens` | `IDItem` | IDItem | `Title eq '...'` |
| `MP_Entregas` | `NF` | — | `IDItem eq '...'` |
| `MP_HistoricoEtapas` | `Chamado` | Chamado | `Title eq '...'` |

Em `MP_Entregas` o Title é a NF porque é assim que a pessoa se refere à linha,
mas a NF **não** é a chave estrangeira — quem liga a entrega ao item é
`IDItem`, que existe como coluna própria.

> **`IDItem` REPETE em `MP_Entregas`, por projeto.** Um item pode receber
> entrega parcial: metade numa nota, o resto em outra. Nos 12 dados atuais
> nenhum se repete, mas isso é acaso, não regra — a fórmula original somava
> justamente por isso. Nunca imponha unicidade nessa coluna.
>
> A NF também repete: a 8343 aparece em duas linhas, para itens diferentes.
> Uma nota cobre vários itens.

**`MP_Itens`** — 21 itens, 19 colunas. Cuidado com os tipos:

```
TEXTO   IDItem  Chamado  CodigoProduto  NumRequisicao  NumSC  NumOC
        Comprador  Fornecedor
NÚMERO  QtdPrevista  QtdRequisitada  QtdComprada  QtdLiberada
        QtdInstalada  IPsDisponibilizados  QtdVMS
DATA    DataRequisicao  EnvioSuprimentos  DataOC  PrevisaoEntrega
```

Depois acrescente à mão: `QtdRecebida` (Número, vazia — o Fluxo B preenche).

**`MP_Entregas`** — 12 itens.

```
TEXTO   NF  IDItem  UnidadeRecebedora  LocalCustodia  SituacaoFisica  Observacao
NÚMERO  QtdRecebida
DATA    DataRecebimento
```

**`MP_HistoricoEtapas`** — 56 itens.

```
TEXTO   Chamado  Etapa
DATA    DataInicio  DataConclusao
```

> **Códigos são TEXTO, nunca Número.** NF, SC, OC, requisição, código de
> produto e código de objeto são identificadores. Como número perdem zero à
> esquerda e ganham separador de milhar: 2.586.441.

### 4. Fluxo A — mantém os prazos atualizados

Em `make.powerautomate.com` → Criar → **Fluxo de nuvem agendado**, diário 06:00.
Nome: `MP - Atualiza prazos`.

1. **Obter itens** → `MP_Projetos`, opções avançadas, consulta de filtro:
   `Status ne 'CONCLUÍDO' and Status ne 'CANCELADO'` — renomear para `Obter projetos`
2. **Obter itens** → `MP_EtapasSLA`, sem filtro — renomear para `Obter etapas`
3. **Aplicar a cada** sobre o `value` de `Obter projetos`, contendo:
   - **Filtrar matriz** — de: `value` de `Obter etapas`;
     condição: expressão `item()?['Title']` **é igual a** o campo dinâmico
     `EtapaAtual`. Renomear para `Achar etapa`
   - **Enviar uma solicitação HTTP para o SharePoint** — *não* use a ação
     "Atualizar item"
     - Método: `POST`
     - Uri: `_api/web/lists/getbytitle('MP_Projetos')/items(<ID do item>)`
     - Cabeçalhos:
       ```
       X-HTTP-Method: MERGE
       IF-MATCH: *
       Content-Type: application/json;odata=nometadata
       Accept: application/json;odata=nometadata
       ```
     - Corpo:
       ```json
       {"SLADias": <expressão>, "DiasNaEtapa": <expressão>}
       ```
     - `SLADias` =
       `if(empty(body('Achar_etapa')),0,int(first(body('Achar_etapa'))?['field_2']))`
     - `DiasNaEtapa` =
       `if(empty(item()?['field_8']),0,div(sub(ticks(utcNow()),ticks(item()?['field_8'])),864000000000))`

> **Por que não a ação "Atualizar item".** Ela monta um PATCH com todos os
> campos do cartão, e campo deixado em branco pode ser gravado como vazio —
> é assim que se apaga o número do chamado dos 54 ativos sem perceber. O MERGE
> por HTTP envia **exatamente** os dois campos nomeados no corpo e não tem como
> tocar em mais nada. É o mesmo mecanismo que carregou os 78 valores iniciais
> sem um único incidente.
>
> Nomes internos no corpo e nas expressões: `MP_Projetos` usa `field_8` para
> InicioEtapa e `field_9` para Status; `MP_EtapasSLA` usa `field_2` para
> SLADias. `SLADias` e `DiasNaEtapa` em `MP_Projetos` foram criadas à mão e
> têm nome limpo.

> **Restrinja o filtro a um item antes da primeira ativação de qualquer fluxo
> que grava.** É precaução barata, e vale mesmo sem causa conhecida.
>
> Origem da regra: na primeiríssima ativação do Fluxo A o histórico registrou
> duas execuções, e a hipótese foi que ligar dispara uma execução. **A hipótese
> foi testada depois e não se confirmou** — stop seguido de start gerou zero
> execuções em três tentativas. O mecanismo das duas execuções iniciais
> continua sem explicação isolada.
>
> Ou seja: mantenha a prática, mas não confie na causa. Um fluxo pode executar
> quando você não espera, e o filtro de um item é o que limita o estrago.

### 5. Fluxo B — soma as entregas no item

Gatilho: **Quando um item for criado ou modificado** em `MP_Entregas`.
Nome: `MP - Atualiza recebido`.

1. **Obter itens** → `MP_Entregas`, filtro: `IDItem eq '<IDItem do gatilho>'`
   — devolve **todas** as entregas daquele item, que é o ponto: a soma
2. **Obter itens** → `MP_Itens`, filtro: `Title eq '<IDItem do gatilho>'`
   — em `MP_Itens` o IDItem mora no Title
3. **Aplicar a cada** sobre o resultado de `MP_Itens` → **Atualizar item**
   - `Title` = o Title existente do item
   - `QtdRecebida` = soma de `QtdRecebida` do passo 1

Use uma variável inicializada antes do laço para somar. Cuidado com o
**loop infinito**: este fluxo altera `MP_Itens`, não `MP_Entregas`, então não
dispara a si mesmo. Se algum dia mudar o gatilho para `MP_Itens`, ele vira loop.

> **A lacuna da exclusão — decidida, mas adiada.**
>
> Exclusão de entrega não dispara o gatilho. Confirmado na prática durante o
> teste: ao apagar a linha, `QtdRecebida` ficou em 3 quando a verdade era 2.
>
> **Não faça um segundo fluxo com "Quando um item for excluído".** Esse gatilho
> entrega pouco mais que o ID do item removido, e a linha já não existe para
> dizer qual `IDItem` recalcular. Você saberia que algo foi apagado sem saber
> o que corrigir.
>
> **A saída é não excluir.** Acrescente a MP_Entregas uma coluna `Cancelada`
> (Sim/Não) e filtre a soma do Fluxo B por `Cancelada ne 'Sim'`. Estornar
> passa a ser uma edição — que dispara o gatilho normalmente — e ainda deixa
> rastro de que houve estorno, em vez de a linha sumir sem explicação.
>
> **Quando fazer:** junto com a configuração dos formulários de entrada, não
> agora. Enquanto só a equipe do projeto mexe nas listas, ninguém exclui
> lançamento. O risco começa quando o setor entra, e é o mesmo momento em que
> se define como a pessoa estorna uma nota. Fazer as duas coisas juntas evita
> mexer duas vezes num fluxo já testado.

> **Sinal de saúde do Fluxo A.** A distribuição de Situacao **não** serve de
> conferência recorrente: ela muda todo dia, porque projeto atrasa sozinho com
> o passar do tempo. O que serve é isto: **o chamado 123 sobe exatamente +1 em
> DiasNaEtapa por dia.** Se um dia não subir, o fluxo parou de rodar.

> **Carga inicial de QtdRecebida.** O Fluxo B só calcula a soma de um item
> quando aquele item recebe um novo evento de entrega. Os 21 itens nascem com
> `QtdRecebida` vazia e assim ficariam por tempo indeterminado.
>
> Depois de validar o Fluxo B, carregue os 21 valores por REST a partir de
> `carga_QtdRecebida.xlsx`, casando por `Title` (que em MP_Itens guarda o
> IDItem). Doze itens têm recebimento, nove são zero. A soma total é 38, o
> mesmo número que aparece no funil do painel.
>
> Essa carga também serve de faxina: se o teste do Fluxo B deixar resíduo,
> ela sobrescreve com o valor verdadeiro.

> **Verificação que se compara com a própria suposição não prova nada.**
> Aconteceu quatro vezes neste projeto, sempre passando no teste:
>
> 1. A data gravada em `00:00:00Z` foi conferida por REST contra o próprio
>    valor gravado. Só a tela mostrou o dia anterior.
> 2. A condição de gatilho com `splitOn` seria avaliada antes da divisão do
>    lote, seria sempre falsa, e o teste passaria sem nada ter acontecido.
> 3. `0 or -1` em Python fez os nove zeros legítimos parecerem divergência.
>    O dado estava certo; o teste é que estava errado.
> 4. Quatro exibições foram relatadas como criadas lendo o retorno do próprio
>    `evaluate`, quando nenhuma existia — o botão OK procurado por
>    `name="BtnOK"` não existe naquela página.
>
> A regra: compare sempre com algo de fora do seu próprio caminho — a tela, o
> dado de origem, ou um número que o usuário já conhece de cor.

### 6. Exibições — feito, menos uma

Em `MP_Projetos`:

| Nome | Filtro | Linhas |
|---|---|---|
| Carteira ativa | `Status` diferente de CONCLUÍDO e CANCELADO, agrupada por `Unidade` | 54 |
| Atrasados | `DiasAtraso` maior que 0 **e** `Status` diferente de CONCLUÍDO e CANCELADO, ordem decrescente | 27 |
| Bloqueados | `Bloqueado` igual a Sim | — |
| Por etapa | ativos, agrupada por `EtapaAtual` | 54 |

Em `MP_Entregas`: **A conferir** — `SituacaoFisica` diferente de CONFERIDO.

> **Por que "Atrasados" precisa do filtro de Status.** Só `DiasAtraso > 0`
> devolve 50 linhas: 27 ativos atrasados e 23 já concluídos que estouraram o
> prazo em algum momento do passado. Os 23 são história, não fila de trabalho
> — e uma exibição de triagem que mistura as duas coisas deixa de ser
> varrível. O atraso dos concluídos continua guardado no item; o que muda é
> só quem aparece nesta exibição.

**`MP_Itens` → Aguardando entrega — pendente.** O filtro de exibição do
SharePoint compara coluna com valor literal, nunca coluna com coluna; o CAML
também não faz. Então `QtdRecebida < QtdComprada` não existe como filtro.

A saída é uma coluna calculada em `MP_Itens`:

```
Pendente = [QtdComprada] - [QtdRecebida]
```

e a exibição filtra `Pendente` maior que 0 — hoje, 9 linhas.

> **Aqui coluna calculada pode.** A regra "coluna calculada não recalcula com
> o tempo" não morde neste caso: `Pendente` não depende de `HOJE()`, depende
> de duas colunas do próprio item. Toda vez que o Fluxo B grava `QtdRecebida`
> por MERGE, o SharePoint recalcula `Pendente` na mesma escrita. É o oposto
> exato de `DiasNaEtapa`, que precisou virar fluxo justamente por depender da
> data de hoje.

### 7. Índices — feito

Aplicados em `MP_Projetos`: `Unidade`, `Status`, `Title`.

> **Pelo navegador ou por REST, o nome muda.** No editor de exibição do
> SharePoint você escolhe a coluna pelo rótulo, e `Unidade`, `Status`,
> `Bloqueado` e `EtapaAtual` aparecem assim mesmo. Se em vez disso você
> montar o CAML ou o `ViewFields` por REST, essas quatro voltam a ser
> `field_2`, `field_9`, `field_10` e `field_7` — são colunas que vieram da
> importação do Excel. As criadas à mão (`SLADias`, `DiasNaEtapa`,
> `DiasAtraso`, `ConsumoSLA`, `Situacao`) usam o próprio nome nos dois
> caminhos. Prefira o editor: exibição não grava dado, e o navegador
> resolve o nome sozinho.

> Acima de 5.000 itens, exibição filtrada por coluna não indexada para de
> abrir. Com 78 itens não muda nada hoje; muda quando mudar.

---

## Armadilhas do SharePoint que já custaram tempo

**Coluna calculada não recalcula com o tempo.** Um cálculo com `HOJE()` só é
refeito quando alguém edita o item. É por isso que `DiasNaEtapa` é um número
comum atualizado por fluxo, e não uma fórmula.

**Coluna calculada não lê coluna de pesquisa.** Por isso `SLADias` vive em
`MP_Projetos` como número, copiado da etapa pelo fluxo.

**O tipo Calculado não aparece no painel moderno de criar coluna.** Use
⚙ → Configurações da lista → Criar coluna. Marque "Adicionar à exibição padrão"
no rodapé, senão a coluna existe mas não aparece.

**As fórmulas deste site são em português com ponto e vírgula.** `SE`, não `IF`.

---

## Fórmulas das colunas calculadas, para referência

`DiasAtraso` — retorno Número:

```
=SE([SLADias]>0;MÁXIMO([DiasNaEtapa]-[SLADias];0);0)
```

`ConsumoSLA` — retorno Número, 2 casas:

```
=SE([SLADias]>0;[DiasNaEtapa]/[SLADias];0)
```

`Situacao` — retorno Linha única de texto:

```
=SE([Status]="CONCLUÍDO";"CONCLUÍDO";SE([Status]="CANCELADO";"CANCELADO";SE([Bloqueado]="Não";SE([SLADias]=0;"SEM SLA";SE([DiasNaEtapa]>[SLADias];"ATRASADO";SE([DiasNaEtapa]*10>=[SLADias]*9;"EM RISCO";SE([DiasNaEtapa]*10>=[SLADias]*7;"ATENÇÃO";"NO PRAZO"))));"BLOQUEADO")))
```

Todas as três já existem em `MP_Projetos`. Ficam aqui caso precise recriar.
