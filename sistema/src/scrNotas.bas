Attribute VB_Name = "scrNotas"
Option Explicit
'==============================================================================
' scrNotas  -  Notas fiscais, remessas e custodia
'
' E aqui que o setor lanca o recebimento. Cada linha de 07_Entregas e uma nota
' (ou remessa) de um item; as quantidades recebidas do item e a conferencia com
' a ordem de compra sao recalculadas pelas formulas da pasta.
'==============================================================================

'==============================================================================
' LISTA
'==============================================================================
Public Sub NotasRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long

    Set ws = Canvas()
    x = ContentX: w = ContentW

    d = Bloco(SH_ENT, EN_NF, EN_ULT)
    n = BlocoLinhas(d)

    y = RenderShell("Notas e entregas", "Lançamento de notas, remessas e guarda do material")

    ' resumo rapido
    Dim total As Long, pend As Long, div As Long, qtd As Double
    For i = 1 To n
        If SVal(d(i, EN_NF)) <> "" And PassaUnidade(SVal(d(i, EN_UNID))) Then
            total = total + 1
            qtd = qtd + NVal(d(i, EN_QTD))
            If UCase$(SVal(d(i, EN_SITFIS))) <> "CONFERIDO" Then pend = pend + 1
            If SVal(d(i, EN_CONF)) <> "" And UCase$(SVal(d(i, EN_CONF))) <> "OK" Then div = div + 1
        End If
    Next i

    Dim cw As Double
    cw = (w - GAP * 3) / 4
    KpiCard ws, x, y, cw, 96, "Notas lançadas", CStr(total), "no filtro atual", clrMuted, "", clrAccent
    KpiCard ws, x + cw + GAP, y, cw, 96, "Peças recebidas", Format$(qtd, "#,##0"), "soma das quantidades", clrMuted, "", clrInfo
    KpiCard ws, x + (cw + GAP) * 2, y, cw, 96, "Pendentes de conferência", CStr(pend), _
            IIf(pend = 0, "nada em aberto", "aguardando conferência física"), _
            IIf(pend = 0, clrMuted, clrWarn), ActIr("conferencia"), clrWarn
    KpiCard ws, x + (cw + GAP) * 3, y, cw, 96, "Divergências com a OC", CStr(div), _
            IIf(div = 0, "tudo bate com a OC", "recebido acima da ordem"), _
            IIf(div = 0, clrMuted, clrDanger), ActIr("conferencia"), clrDanger
    y = y + 96 + GAP

    y = y + Toolbar(x, y, w, "Lançar nota", ActProc("NovaNota"), _
                    IIf(gFUnidade = "(TODAS AS UNIDADES)", "Todas as unidades", gFUnidade), _
                    ActProc("AbrirFiltroUnidade"))

    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = n To 1 Step -1          ' mais recentes primeiro
        If SVal(d(i, EN_NF)) <> "" Then
            If PassaUnidade(SVal(d(i, EN_UNID))) Then
                If Casa(d(i, EN_NF), d(i, EN_CHAMADO), d(i, EN_DESC), d(i, EN_COD), _
                        d(i, EN_OC), d(i, EN_FORN), d(i, EN_CUSTODIA)) Then
                    m = m + 1
                    idx(m) = i
                End If
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "NF / Remessa", 112, 1, "strong"
    GridCol "Recebimento", 104, 2
    GridCol "Chamado", 88, 1, "dim"
    GridCol "Produto", 0
    GridCol "OC", 92, 2, "dim"
    GridCol "Qtd.", 62, 2
    GridCol "Unidade", 78, 2
    GridCol "Custódia", 150, 1, "dim"
    GridCol "Situação física", 156, 1, "badge"
    GridCol "Conferência", 150, 1, "badge"
    GridCol "", 28, 3, "chevron"

    cap = GridCapacity(y)
    Dim de As Long, ate As Long, k As Long, q As Long
    de = (gPagina - 1) * cap + 1
    If de > m Then de = 1: gPagina = 1
    ate = de + cap - 1
    If ate > m Then ate = m
    q = ate - de + 1

    If q <= 0 Then
        GridDraw Empty, 0, Empty
        EmptyState ws, x, y + 40, w, 180, "Nenhuma nota lançada", _
                   "Clique em ""Lançar nota"" para registrar o primeiro recebimento."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String
    ReDim lin(1 To q, 1 To 11): ReDim ch(1 To q)
    For k = 1 To q
        i = idx(de + k - 1)
        lin(k, 1) = SVal(d(i, EN_NF))
        lin(k, 2) = FmtD(d(i, EN_DATA))
        lin(k, 3) = SVal(d(i, EN_CHAMADO))
        lin(k, 4) = SVal(d(i, EN_DESC))
        lin(k, 5) = SVal(d(i, EN_OC))
        lin(k, 6) = FmtN(d(i, EN_QTD))
        lin(k, 7) = SVal(d(i, EN_UNID))
        lin(k, 8) = SVal(d(i, EN_CUSTODIA))
        lin(k, 9) = SVal(d(i, EN_SITFIS))
        lin(k, 10) = SVal(d(i, EN_CONF))
        lin(k, 11) = ""
        ch(k) = CStr(i + FIRST_ROW - 1)     ' linha real na aba 07_Entregas
    Next k

    GridDraw lin, q, ch, "nota_form"
    GridPager x, ViewH - 52, w, m, gPagina, cap
End Sub

Public Sub NovaNota()
    RascunhoLimpar
    PrefSet "nota_linha", ""
    RascunhoGravar "data", Format$(DataRefer, "dd/mm/yyyy")
    RascunhoGravar "sitfis", "PENDENTE DE CONFERÊNCIA"
    Ir "nota_form", ""
End Sub

' Valor a exibir num campo: o rascunho tem prioridade sobre o que esta gravado,
' porque significa que o usuario saiu para escolher o item e voltou.
Private Function VN(ByVal chave As String, ByVal daPlanilha As String) As String
    If RascunhoAtivo Then VN = RascunhoValor(chave, daPlanilha) Else VN = daPlanilha
End Function

'==============================================================================
' FORMULARIO
'==============================================================================
Public Sub NotaFormRender(ByVal ctx As String)
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim es As Worksheet, r As Long, novo As Boolean
    Dim rotulo As String

    Set ws = Canvas()
    x = ContentX: w = ContentW
    Set es = Sh(SH_ENT)

    r = 0
    If ctx <> "" Then
        If InStr(ctx, "|") > 0 Then ctx = Mid$(ctx, InStr(ctx, "|") + 1)
        If IsNumeric(ctx) Then r = CLng(ctx)
    End If
    novo = (r < FIRST_ROW)
    PrefSet "nota_linha", IIf(novo, "", CStr(r))

    y = RenderShell(IIf(novo, "Lançar nota fiscal", "Editar lançamento"), _
                    IIf(novo, "Registre o recebimento de um item já comprado", _
                              "Nota " & SVal(es.Cells(r, EN_NF).Value)), "notas")

    ' item escolhido
    If novo Then
        rotulo = RascunhoValor("item")
    Else
        rotulo = VN("item", SVal(es.Cells(r, EN_ITEM).Value))
    End If

    '--- cartao do item ------------------------------------------------------
    Dim ih As Double
    ih = 132
    Card ws, x, y, w, ih
    CardTitle ws, x + 20, y + 16, w - 300, "Item recebido", "o restante do lançamento é conferido contra a ordem de compra"
    Btn ws, x + w - 180, y + 20, 160, 36, IIf(rotulo = "", "Selecionar item", "Trocar item"), _
        ActProc("AbrirSeletorItem"), IIf(rotulo = "", "primary", "secondary"), IC_BUSCA

    If rotulo = "" Then
        Lbl ws, x + 20, y + 66, w - 220, 40, "Nenhum item selecionado.", 11, clrMuted, False, 1
    Else
        Dim ri As Long, cad As Worksheet
        Set cad = Sh(SH_ITENS)
        ri = LinhaDoRotulo(rotulo)
        Lbl ws, x + 20, y + 62, w - 220, 22, SVal(cad.Cells(ri, IT_DESC).Value), 12, clrText, True, 1
        Dim comprado As Double, recebido As Double, saldo As Double
        comprado = NVal(cad.Cells(ri, IT_QCOMP).Value)
        recebido = NVal(cad.Cells(ri, IT_QRECEB).Value)
        saldo = comprado - recebido

        Dim sw As Double
        sw = (w - 40) / 6
        Campo ws, x + 20, y + 88, sw, "Chamado", SVal(cad.Cells(ri, IT_CHAMADO).Value), clrText, 9.5
        Campo ws, x + 20 + sw, y + 88, sw, "Código", SVal(cad.Cells(ri, IT_COD).Value), clrText, 9.5
        Campo ws, x + 20 + sw * 2, y + 88, sw, "Ordem de compra", SVal(cad.Cells(ri, IT_OC).Value), clrText, 9.5
        Campo ws, x + 20 + sw * 3, y + 88, sw * 1.4, "Fornecedor", Corta(SVal(cad.Cells(ri, IT_FORN).Value), 30), clrText, 9
        Campo ws, x + 20 + sw * 4.4, y + 88, sw * 0.8, "Comprado", Format$(comprado, "#,##0"), clrText, 9.5
        Campo ws, x + 20 + sw * 5.2, y + 88, sw * 0.8, "Saldo a receber", Format$(saldo, "#,##0"), _
              IIf(saldo <= 0, clrOk, clrWarn), 9.5
    End If

    y = y + ih + GAP

    '--- campos --------------------------------------------------------------
    FormBegin x, y, w, 4

    FormField "nf", "Nº da NF / remessa", VN("nf", IIf(novo, "", SVal(es.Cells(r, EN_NF).Value))), "texto"
    FormField "data", "Data de recebimento", _
              VN("data", IIf(novo, Format$(DataRefer, "dd/mm/yyyy"), FmtDEdit(es.Cells(r, EN_DATA).Value))), "data"
    FormField "qtd", "Quantidade recebida", _
              VN("qtd", IIf(novo, "", CStr(NVal(es.Cells(r, EN_QTD).Value)))), "numero"
    FormField "unid", "Unidade recebedora", _
              VN("unid", IIf(novo, "", SVal(es.Cells(r, EN_UNID).Value))), "lista", ListaUnidades()

    FormField "custodia", "Local de custódia", _
              VN("custodia", IIf(novo, "", SVal(es.Cells(r, EN_CUSTODIA).Value))), "lista", ListaCustodia()
    FormField "sitfis", "Situação física", _
              VN("sitfis", IIf(novo, "PENDENTE DE CONFERÊNCIA", SVal(es.Cells(r, EN_SITFIS).Value))), _
              "lista", ListaSitFisica()
    FormField "obs", "Observação", VN("obs", IIf(novo, "", SVal(es.Cells(r, EN_OBS).Value))), "texto", , 2

    FormListaDeIntervalo "unid", "=Lista_Unidades"
    FormListaDeIntervalo "custodia", "=Lista_Custodia"
    FormListaDeIntervalo "sitfis", "=Lista_SitFisica"

    FormFooter FormBottom() + 8, ActProc1("SalvarNota", CStr(r)), ActProc("CancelarNota"), _
               IIf(novo, "Lançar nota", "Salvar alterações"), _
               IIf(novo, "", ActProc1("ExcluirNota", CStr(r)))
End Sub

Public Sub CancelarNota()
    RascunhoLimpar
    Ir "notas"
End Sub

Public Function Corta(ByVal s As String, ByVal n As Long) As String
    If Len(s) > n Then Corta = Left$(s, n - 1) & "…" Else Corta = s
End Function

' Linha da aba Cadastro correspondente ao rotulo de lancamento.
Public Function LinhaDoRotulo(ByVal rotulo As String) As Long
    LinhaDoRotulo = FindRow(SH_ITENS, IT_ROTULO, rotulo)
    If LinhaDoRotulo = 0 Then LinhaDoRotulo = FIRST_ROW
End Function

'==============================================================================
' SELETOR DE ITEM
'==============================================================================
Public Sub AbrirSeletorItem()
    RascunhoSalvar
    gBusca = ""
    Ir "nota_item"
End Sub

Public Sub SeletorItemRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long

    Set ws = Canvas()
    x = ContentX: w = ContentW

    d = Bloco(SH_ITENS, IT_CHAMADO, IT_ULT)
    n = BlocoLinhas(d)

    y = RenderShell("Selecionar item", "Escolha o item da ordem de compra que está sendo recebido", _
                    "nota_form", PrefGet("nota_linha"))
    y = y + Toolbar(x, y, w)

    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, IT_CHAMADO)) <> "" Then
            If Casa(d(i, IT_CHAMADO), d(i, IT_COD), d(i, IT_DESC), d(i, IT_OC), d(i, IT_SC), d(i, IT_FORN)) Then
                m = m + 1
                idx(m) = i
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "Chamado", 92, 1, "strong"
    GridCol "Código", 84
    GridCol "Descrição do produto", 0
    GridCol "OC", 92, 2, "dim"
    GridCol "Fornecedor", 200, 1, "dim"
    GridCol "Comprado", 84, 2
    GridCol "Recebido", 84, 2
    GridCol "Situação do item", 210, 1, "badge"

    cap = GridCapacity(y)
    Dim de As Long, ate As Long, k As Long, q As Long
    de = (gPagina - 1) * cap + 1
    If de > m Then de = 1: gPagina = 1
    ate = de + cap - 1
    If ate > m Then ate = m
    q = ate - de + 1

    If q <= 0 Then
        GridDraw Empty, 0, Empty
        EmptyState ws, x, y + 40, w, 180, "Nenhum item encontrado", _
                   "Cadastre o item e a ordem de compra na tela Itens e escopo."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String
    ReDim lin(1 To q, 1 To 8): ReDim ch(1 To q)
    For k = 1 To q
        i = idx(de + k - 1)
        lin(k, 1) = SVal(d(i, IT_CHAMADO))
        lin(k, 2) = SVal(d(i, IT_COD))
        lin(k, 3) = SVal(d(i, IT_DESC))
        lin(k, 4) = SVal(d(i, IT_OC))
        lin(k, 5) = Corta(SVal(d(i, IT_FORN)), 28)
        lin(k, 6) = FmtN(d(i, IT_QCOMP))
        lin(k, 7) = FmtN(d(i, IT_QRECEB))
        lin(k, 8) = SVal(d(i, IT_SIT))
        ch(k) = CStr(i + FIRST_ROW - 1)
    Next k

    GridDraw lin, q, ch, ""
    ' cada linha escolhe o item em vez de navegar
    Dim yy As Double
    For k = 1 To q
        yy = y + HEAD_H + (k - 1) * ROW_H
        HitArea ws, x, yy, w, ROW_H, ActProc1("EscolherItem", ch(k))
    Next k

    GridPager x, ViewH - 52, w, m, gPagina, cap
End Sub

Public Sub EscolherItem(ByVal linha As String)
    Dim cad As Worksheet, r As Long
    Set cad = Sh(SH_ITENS)
    r = CLng(linha)
    RascunhoGravar "item", SVal(cad.Cells(r, IT_ROTULO).Value)
    If RascunhoValor("unid") = "" Then
        RascunhoGravar "unid", UnidadeDoChamado(SVal(cad.Cells(r, IT_CHAMADO).Value))
    End If
    If RascunhoValor("qtd") = "" Then
        Dim saldo As Double
        saldo = NVal(cad.Cells(r, IT_QCOMP).Value) - NVal(cad.Cells(r, IT_QRECEB).Value)
        If saldo > 0 Then RascunhoGravar "qtd", CStr(saldo)
    End If
    gBusca = ""
    Ir "nota_form", PrefGet("nota_linha")
End Sub
