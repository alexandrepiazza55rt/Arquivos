# Sistema de Monitoramento Patrimonial

Sistema de gestão do setor rodando dentro do Excel, com interface desenhada para
não parecer VBA: menu lateral fixo, cartões, tabelas com fio fino, badges de
status e tipografia Segoe UI — a família do Windows mais próxima da San Francisco.

Instalação: veja **[INSTALACAO.md](INSTALACAO.md)**.

---

## O que o sistema faz

| Tela | Para que serve |
|---|---|
| **Painel** | Visão geral: projetos ativos, no prazo, atrasados, itens aguardando entrega, pendências de conferência, situação da carteira, onde os projetos estão parados, funil do material e a lista dos casos críticos |
| **Projetos** | Carteira completa com busca e filtros. Ao abrir um chamado: dados, etapa atual com consumo de SLA, quantitativos, itens, histórico das etapas em linha do tempo e entregas |
| **Itens e escopo** | Cadastro único de itens com a auditoria quantitativa (previsto → solicitado → comprado → recebido → liberado → instalado → IP → VMS) |
| **Compras** | Solicitações de compra e ordens de compra, com SLA de suprimentos e do fornecedor |
| **Notas e entregas** | Lançamento de nota fiscal / remessa, custódia e situação física. Valida a quantidade contra o saldo da ordem de compra |
| **Conferências** | Notas a conferir, divergências com a OC e desvios de escopo, com ação de conferir direto na lista |
| **Cadastros** | Parâmetros de prazo, SLA por etapa, listas suspensas e cadastro de produtos |
| **Consistência** | As verificações da aba `10_Verificacoes` em forma de painel: tudo precisa estar zerado antes de apresentar os números |

### Ações que gravam

- Cadastrar e editar projeto, com validação de chamado duplicado e de motivo
  obrigatório quando o projeto está bloqueado
- **Avançar etapa**: fecha a etapa atual no histórico, abre a próxima e ajusta a
  data de início — em um clique
- Bloquear / desbloquear com motivo padronizado
- Cadastrar e editar itens, solicitações e ordens de compra
- **Lançar nota**: escolhe o item numa lista buscável, sugere a quantidade pelo
  saldo da OC, avisa quando o recebimento passa do comprado
- Estornar lançamento, marcar nota como conferida
- Ajustar parâmetros, SLA por etapa, listas e produtos

---

## Como foi construído

### A regra principal

**As suas fórmulas continuam mandando.** O sistema só escreve nas colunas de
entrada; SLA, situação, dias de atraso, conferência com a OC, base dos gráficos e
verificações continuam sendo calculados pelas fórmulas que já estavam na pasta.
Isso significa que qualquer ajuste de regra continua sendo feito na planilha, sem
mexer em código.

### Por que não tem formulário do VBA

`UserForm` é o que dá a cara datada ao VBA: controles cinza, fontes fixas, cantos
duros. Aqui não existe nenhum. A tela é desenhada na aba `SISTEMA`:

- **Formas** (retângulos arredondados sem contorno nem sombra) para o menu, os
  cartões, os botões e os badges
- **Células** para as tabelas e os campos de digitação — escrita em bloco, então
  a lista de 600 linhas aparece instantaneamente
- **Áreas transparentes** por cima das linhas, que tornam a linha inteira clicável

O Excel some: faixa de opções, barra de fórmulas, grade, cabeçalhos de linha e
coluna e as guias das abas ficam ocultos enquanto o sistema está aberto, e voltam
ao normal quando você sai.

### Sem rolagem

Nada de barra de rolagem no meio da tela. As listas são paginadas e o número de
linhas por página é calculado a partir do tamanho real da janela — quem tem
monitor maior vê mais linhas.

### Módulos

| Arquivo | Papel |
|---|---|
| `mTheme.bas` | Cores, fontes, medidas e ícones. **Toda a identidade visual está aqui** |
| `mUI.bas` | Motor de desenho: cartões, botões, badges, barras de progresso, indicadores |
| `mGrid.bas` | Tabelas, paginação e barra de busca/filtros |
| `mForm.bas` | Formulários: campos, seções, rascunho e rodapé |
| `mPopup.bas` | O "dropdown" do sistema: painel sobreposto de seleção |
| `mChart.bas` | Gráficos desenhados com formas (barras e segmentos) |
| `mBits.bas` | Abas internas, linha do tempo, pares rótulo/valor |
| `mCols.bas` | Número de cada coluna das abas de dados |
| `mData.bas` | Leitura e escrita nas abas, listas de apoio, parâmetros |
| `mAcoes.bas` | Regras de negócio e gravação |
| `mApp.bas` | Menu lateral, cabeçalho, roteador de telas, entrada e saída |
| `mInstalar.bas` | Preparação da pasta e tela de abertura |
| `scr*.bas` | Uma tela cada |

---

## Personalizando

### Trocar a cor de destaque

`mTheme.bas`, uma linha:

```vba
Public Property Get clrAccent() As Long:      clrAccent = HX(&H2F6BFF):        End Property
```

Troque `&H2F6BFF` por qualquer cor em hexadecimal (o mesmo formato da web).
O sistema inteiro acompanha.

### Trocar a fonte

Também em `mTheme.bas`:

```vba
Public Const FONT_UI    As String = "Segoe UI"
Public Const FONT_LIGHT As String = "Segoe UI Light"
```

Se a empresa tiver **Inter** ou **Segoe UI Variable** instalada, troque aqui e o
resultado fica ainda mais próximo de um sistema web.

### Menu claro em vez de escuro

Em `mTheme.bas`, mude `clrSide` para `&HFFFFFF`, `clrSideText` para `&H5B6675` e
`clrSideTextOn` para `&H0F1722`.

### Ícones

Os ícones vêm da fonte **Segoe MDL2 Assets**, presente em todo Windows 10/11. Os
códigos estão no topo de `mTheme.bas` (`IC_PAINEL`, `IC_NOTAS`, …). Se algum
desenho não for o que você esperava, troque o código do glifo — o aplicativo
*Mapa de Caracteres* do Windows mostra todos.

---

## Abas de dados esperadas

O sistema procura estas abas pelo nome. **Não renomeie.**

`01_Projetos` · `Cadastro` · `02_Escopo_Itens` · `03_Compras_SC` ·
`05_OC_Fornecedor` · `07_Entregas` · `08_Historico_Etapas` · `09_Cadastros` ·
`10_Verificacoes` · `11_Base_Graficos`

Em todas elas o cabeçalho está na **linha 4** e os dados começam na **linha 5**.
Se você inserir ou reordenar colunas, ajuste `mCols.bas`.

Duas abas são criadas pelo sistema: `SISTEMA` (a tela) e `_APP` (apoio interno,
sempre oculta).

---

## Limites conhecidos

**Exclusão não apaga linhas.** As abas `02`, `03` e `05` referenciam a aba
`Cadastro` linha a linha; apagar uma linha quebraria essas fórmulas. Excluir, no
sistema, limpa as colunas de entrada e deixa a linha livre para o próximo
cadastro. Na prática o efeito é o mesmo, mas a linha em branco continua existindo
no meio da aba.

**Fórmulas prontas até a linha ~152.** A pasta original já traz as fórmulas
preenchidas até ali. Ao passar disso, o sistema copia as fórmulas da linha
anterior automaticamente — mas vale conferir a primeira vez que acontecer.

**Uma pessoa por vez.** É a limitação do formato `.xlsm`, não do sistema. Se o
setor precisar lançar em paralelo, os caminhos possíveis dentro do que a empresa
permite são:
- dividir por unidade, um arquivo por unidade, consolidando periodicamente;
- hospedar a pasta no SharePoint/OneDrive **sem** macros para consulta, mantendo o
  `.xlsm` como ferramenta de lançamento;
- pedir à TI uma lista do SharePoint ou um Power App, que aceitam uso simultâneo.

**Windows apenas.** O Excel para Mac não tem a fonte de ícones nem os mesmos
recursos de janela. No Excel Online as macros não rodam.

**Ctrl + Shift + E** devolve o Excel ao estado normal a qualquer momento — é a
saída de emergência se alguma tela travar.

---

## Próximos passos sugeridos

O foco de hoje foi projetos, notas e conferências. A base já está pronta para
crescer:

1. **Relatórios e exportação** — gerar uma visão filtrada em nova pasta ou PDF
2. **Registro de quem fez o quê** — carimbar usuário e data em cada gravação
3. **Anexos** — vincular o PDF da nota fiscal ao lançamento
4. **Alertas** — destaque automático para OC vencida e etapa estourada
5. **Fechamento mensal** — congelar os indicadores do mês para comparação
