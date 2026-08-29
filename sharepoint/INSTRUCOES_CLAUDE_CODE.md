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

Já existe, feito à mão:

| Lista | Itens | Situação |
|---|---|---|
| `MP_Produtos` | 26 | pronta, com badge JSON em TipoItem |
| `MP_ObjetosCusto` | 108 | pronta |
| `MP_EtapasSLA` | 12 | pronta |
| `MP_Projetos` | 78 | dados importados, colunas criadas, **valores vazios** |

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

> **Realce de linha, versão 2.** A primeira versão pintava também ATRASADO, e
> o rosa da linha engolia o rosa da pílula. Além disso ATRASADO são 24 de 78
> hoje: realçar um terço da lista não ajuda a varrer, vira ruído. A v2 realça
> só BLOQUEADO (vermelho) e EM RISCO (laranja) — o que é raro e exige ação.
> ATRASADO continua sinalizado pelo badge, sobre linha branca.

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
   - **Atualizar item** → `MP_Projetos`
     - `Id` = campo dinâmico `ID`
     - `Title` = campo dinâmico `Title` ← **obrigatório, ver aviso abaixo**
     - `SLADias` =
       `if(empty(body('Achar_etapa')),0,int(first(body('Achar_etapa'))?['SLADias']))`
     - `DiasNaEtapa` =
       `if(empty(item()?['InicioEtapa']),0,div(sub(ticks(utcNow()),ticks(item()?['InicioEtapa'])),864000000000))`

> **PERIGO.** Se o campo `Title` do "Atualizar item" ficar vazio, o fluxo
> **apaga o número do chamado dos 54 projetos ativos**. Confira antes de rodar.
> O `Title` é obrigatório no SharePoint; os demais campos podem ficar em branco
> sem apagar nada.

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

Exclusão de entrega **não dispara** este gatilho. Ou crie um segundo fluxo com
"Quando um item for excluído", ou combine com o usuário marcar como cancelada
em vez de excluir.

### 6. Exibições

Em `MP_Projetos`:

| Nome | Filtro |
|---|---|
| Carteira ativa | `Status` diferente de CONCLUÍDO e CANCELADO, agrupada por `Unidade` |
| Atrasados | `DiasAtraso` maior que 0, ordem decrescente |
| Bloqueados | `Bloqueado` igual a Sim |
| Por etapa | ativos, agrupada por `EtapaAtual` |

Em `MP_Entregas`: **A conferir** — `SituacaoFisica` diferente de CONFERIDO.
Em `MP_Itens`: **Aguardando entrega** — `QtdRecebida` menor que `QtdComprada`.

### 7. Índices

Em Configurações da lista → Colunas indexadas, indexe em `MP_Projetos`:
`Unidade`, `Status`, `Title`. Acima de 5.000 itens, exibição filtrada por
coluna não indexada para de abrir.

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
