# Como abrir

## O caminho normal: só abrir o arquivo

Baixe **`Sistema_Monitoramento.xlsm`** e dê dois cliques.

1. O Excel mostra uma faixa amarela de segurança no topo → clique em **Habilitar conteúdo**.
2. O sistema abre sozinho.

É isso. O arquivo já traz a sua planilha inteira (os 78 projetos, os itens, as
notas, as fórmulas) mais o sistema embutido. **Nenhum dado foi alterado.**

A faixa amarela aparece uma vez por pessoa, por arquivo — é o Excel perguntando
se você confia nas macros. Para compartilhar com a equipe, mande o `.xlsm`
normalmente; cada pessoa vai ver a faixa na primeira abertura.

> Guarde uma cópia da sua planilha original antes de começar a lançar coisas no
> sistema. Não porque exista risco conhecido, mas porque é a primeira semana de
> uso de uma ferramenta nova.

**`Ctrl` + `Shift` + `E`** devolve o Excel ao estado normal a qualquer momento.

---

## Se o Excel reclamar do arquivo

O `.xlsm` foi montado fora do Excel, então existe a chance de ele recusar. Se
aparecer *"encontramos um problema com algum conteúdo"* ou se as macros não
carregarem, use o caminho abaixo — ele parte da sua planilha original e é o
procedimento padrão, sem nenhuma surpresa. Leva uns 10 minutos, uma vez só.

Me avise se isso acontecer, com o texto da mensagem: dá para corrigir.

---

# Instalação manual (plano B)

## Antes de começar

Use a sua planilha `Painel_de_Projetos__VF.xlsx`. **Nenhum dado é apagado** — o
sistema é uma camada de tela por cima das abas que você já tem. As fórmulas
continuam sendo as suas.

Faça uma cópia de segurança do arquivo antes de começar.

---

## Passo 1 — Salvar como .xlsm

1. Abra `Painel_de_Projetos__VF.xlsx`.
2. **Arquivo → Salvar como**.
3. Em "Tipo", escolha **Pasta de Trabalho Habilitada para Macro do Excel (\*.xlsm)**.
4. Salve, por exemplo, como `Sistema_Monitoramento.xlsm`.

Sem esse passo o Excel apaga as macros ao fechar.

---

## Passo 2 — Abrir o editor de macros

Pressione **Alt + F11**. Abre o *Editor do Visual Basic*.

No painel da esquerda, confira que o projeto selecionado é
`VBAProject (Sistema_Monitoramento.xlsm)`.

---

## Passo 3 — Importar os módulos

Existem dois caminhos. Tente o **A**; se a empresa bloquear, use o **B**.

### Caminho A — automático (1 minuto)

1. **Arquivo → Importar Arquivo…** e escolha apenas `_INSTALAR.bas`.
2. Volte para o Excel, pressione **Alt + F8**, escolha `ImportarModulos` e clique
   em *Executar*.
3. Aponte para a pasta `src` (a que contém todos os arquivos `.bas`).
4. Pronto: todos os módulos e o código de abertura automática são instalados.

> Se aparecer a mensagem "o Excel não permitiu o acesso ao projeto do VBA", vá em
> **Arquivo → Opções → Central de Confiabilidade → Configurações da Central de
> Confiabilidade → Configurações de Macro** e marque **"Confiar no acesso ao
> modelo de objeto de projeto do VBA"**. Se a TI não liberar, use o caminho B.

### Caminho B — manual (5 minutos)

No editor do VBA, **Arquivo → Importar Arquivo…** e repita para cada um dos
arquivos abaixo (a ordem não importa):

```
mTheme.bas      mUI.bas        mGrid.bas       mForm.bas
mPopup.bas      mBits.bas      mChart.bas      mCols.bas
mData.bas       mApp.bas       mAcoes.bas      mInstalar.bas
scrPainel.bas   scrProjetos.bas  scrItens.bas   scrCompras.bas
scrNotas.bas    scrConferencia.bas  scrCadastros.bas  scrCheckup.bas
```

(`_INSTALAR.bas` não precisa ser importado neste caminho.)

Depois, no painel da esquerda, dê **duplo clique em `EstaPasta_de_trabalho`** e
cole dentro dele o conteúdo do arquivo **`ThisWorkbook.txt`**.

---

## Passo 4 — Rodar a instalação

1. Volte para o Excel (**Alt + F11** de novo).
2. **Alt + F8** → escolha `InstalarSistema` → *Executar*.

Isso cria a aba `SISTEMA` (a tela do sistema) e a aba interna de apoio.

---

## Passo 5 — Salvar e testar

1. **Ctrl + S**.
2. Feche o arquivo e abra de novo.
3. Se aparecer a faixa amarela de segurança, clique em **Habilitar conteúdo**.

O sistema abre sozinho.

---

## Compartilhando com a equipe

Mande o `.xlsm` normalmente (e-mail, SharePoint, rede). Na primeira vez que cada
pessoa abrir, o Excel mostra a faixa amarela pedindo para habilitar as macros —
isso é normal e acontece uma única vez por pessoa, por arquivo.

Para evitar a faixa amarela de vez, peça à TI para colocar a pasta de rede onde o
arquivo fica como **Local Confiável** (Central de Confiabilidade → Locais
Confiáveis).

> **Importante sobre uso simultâneo:** um arquivo `.xlsm` não pode ser editado por
> duas pessoas ao mesmo tempo. Quem abrir depois entra em modo somente leitura e
> consegue consultar, mas não lançar. Se o setor precisar lançar em paralelo, veja
> a seção "Limites conhecidos" no `README.md`.

---

## Se algo der errado

| Situação | O que fazer |
|---|---|
| A tela ficou sem faixa de opções e o sistema travou | **Ctrl + Shift + E** devolve o Excel ao normal |
| Abriu no Excel normal, sem o sistema | **Alt + F8** → `IniciarSistema` |
| Quer ver as abas de dados | Clique em **Sair do sistema**, no rodapé do menu lateral |
| Mensagem "a aba X não foi encontrada" | Alguma aba foi renomeada; os nomes esperados estão no `README.md` |
