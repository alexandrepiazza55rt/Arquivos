# Leitor HTML — Monitoramento Patrimonial

Um único arquivo: `Sistema_Patrimonial.html`. Dois cliques e abre no Edge ou no
Chrome. Não instala nada, não pede senha, não sai para a internet.

## Como cada pessoa usa

1. Recebe o `Sistema_Patrimonial.html` e salva onde quiser (área de trabalho serve).
2. Abre o arquivo, clica em **Vincular a planilha** e escolhe a planilha
   **dentro da pasta do OneDrive sincronizada no PC** — normalmente
   *Este Computador → OneDrive → (pasta do setor)*.
3. Pronto. Nas próximas vezes ele já reabre a mesma planilha sozinho.

O botão **Recarregar dados** relê o arquivo do disco: é assim que a pessoa vê o
que os colegas lançaram, depois que o OneDrive sincronizou.

> Escolher uma cópia na área de trabalho em vez do arquivo do OneDrive faz a
> pessoa parar de enxergar o que os outros lançam. O aviso está na própria tela.

## Por que funciona sem nada instalado

Um `.xlsx` é um zip de arquivos XML. O navegador já sabe descompactar
(`DecompressionStream`) e já sabe ler XML (`DOMParser`), então o leitor não usa
nenhuma biblioteca externa — nem baixa nada de CDN. Isso foi verificado no
próprio navegador antes de escrever o leitor: em `file://` o Chromium é contexto
seguro e libera os seletores de arquivo; o que ele exige é apenas um clique do
usuário para abrir o seletor.

O vínculo com o arquivo é guardado no IndexedDB do navegador. É uma **referência**,
não uma cópia — o leitor sempre lê o arquivo real.

## O que ele mostra

Painel · Projetos (lista e detalhe com linha do tempo) · Itens e escopo ·
Compras SC/OC · Notas e entregas · Conferências · Consistência.

Mesmas colunas, mesmas regras e mesmo desenho do sistema em VBA. As colunas
calculadas por fórmula são lidas como estão: **quem calcula continua sendo a
planilha**, e qualquer ajuste de regra continua sendo feito nela.

## Limite desta versão: só leitura

Ela lê, não grava. Isso é deliberado, e o motivo importa para o próximo passo.

O navegador **consegue** gravar de volta no arquivo (`showSaveFilePicker` e
`createWritable` estão disponíveis, também verificado). O problema não é técnico,
é de concorrência: quando duas pessoas gravam o arquivo inteiro, o OneDrive não
mescla — ele cria uma cópia em conflito, e **as alterações de uma das duas sao
perdidas em silêncio**. Isso é diferente do Excel na web, que faz co-autoria de
verdade porque conversa com o servidor por um protocolo próprio de mesclagem.

Enquanto for só leitura, quantas pessoas quiserem podem usar ao mesmo tempo, sem
disputar o arquivo. Já resolve o gargalo de hoje.

## Como fazer a gravação com segurança, depois

O caminho que funciona dentro das suas restrições é **cada pessoa gravar só o seu
próprio arquivo**, nunca a planilha compartilhada:

- ao lançar, o leitor grava um arquivo pequeno na mesma pasta, com o nome da
  pessoa (`lancamentos_lucas.json`);
- o leitor de todo mundo lê a planilha **mais** todos esses arquivos e mostra o
  conjunto já somado;
- de tempos em tempos, uma pessoa consolida os lançamentos na planilha pelo
  Excel e limpa os arquivos.

Assim ninguém escreve por cima de ninguém, porque duas pessoas nunca tocam no
mesmo arquivo. É mais trabalho do que gravar direto, mas é o único jeito de não
perder lançamento.
