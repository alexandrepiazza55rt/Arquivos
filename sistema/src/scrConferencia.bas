Attribute VB_Name = "scrConferencia"
Option Explicit
'==============================================================================
' scrConferencia  -  Tudo que esta pendente de conferencia ou divergente
'==============================================================================

Public Sub ConferenciaRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Set ws = Canvas()
    x = ContentX: w = ContentW

    y = RenderShell("Conferências", "Notas a conferir, divergências com a OC e desvios de escopo")

    TabStrip ws, x, y, Array("Notas a conferir", "Divergências com a OC", "Desvios de escopo"), _
             Array("conferir", "divoc", "desvio"), IIf(gAba = "", "conferir", gAba), "conferencia", ""
    y = y + 32 + GAP

    y = y + Toolbar(x, y, w, , , _
                    IIf(gFUnidade = "(TODAS AS UNIDADES)", "Todas as unidades", gFUnidade), _
                    ActProc("AbrirFiltroUnidade"))

    Select Case LCase$(gAba)
        Case "divoc":  TabelaDivergencias x, y, w
        Case "desvio": TabelaDesvios x, y, w
        Case Else:     TabelaConferir x, y, w
    End Select
End Sub

'--- notas com situacao fisica diferente de CONFERIDO -------------------------
Private Sub TabelaConferir(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long
    d = Bloco(SH_ENT, EN_NF, EN_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = n To 1 Step -1
        If SVal(d(i, EN_NF)) <> "" And PassaUnidade(SVal(d(i, EN_UNID))) Then
            If UCase$(SVal(d(i, EN_SITFIS))) <> "CONFERIDO" Then
                If Casa(d(i, EN_NF), d(i, EN_CHAMADO), d(i, EN_DESC), d(i, EN_FORN)) Then
                    m = m + 1: idx(m) = i
                End If
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "NF / Remessa", 116, 1, "strong"
    GridCol "Recebimento", 104, 2
    GridCol "Chamado", 88, 1, "dim"
    GridCol "Produto", 0
    GridCol "Qtd.", 62, 2
    GridCol "Custódia", 160, 1, "dim"
    GridCol "Situação física", 168, 1, "badge"
    GridCol "", 116, 2

    cap = GridCapacity(y)
    If m > cap Then m = cap
    If m = 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 40, w, 180, "Nada pendente de conferência", _
                   "Todas as notas lançadas já foram conferidas fisicamente."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String, k As Long
    ReDim lin(1 To m, 1 To 8): ReDim ch(1 To m)
    For k = 1 To m
        i = idx(k)
        lin(k, 1) = SVal(d(i, EN_NF))
        lin(k, 2) = FmtD(d(i, EN_DATA))
        lin(k, 3) = SVal(d(i, EN_CHAMADO))
        lin(k, 4) = SVal(d(i, EN_DESC))
        lin(k, 5) = FmtN(d(i, EN_QTD))
        lin(k, 6) = SVal(d(i, EN_CUSTODIA))
        lin(k, 7) = SVal(d(i, EN_SITFIS))
        lin(k, 8) = ""
        ch(k) = CStr(i + FIRST_ROW - 1)
    Next k
    GridDraw lin, m, ch, "nota_form"

    ' botao de conferir em cada linha, por cima da ultima coluna
    Dim yy As Double, bx As Double
    bx = x + w - 112
    For k = 1 To m
        yy = y + HEAD_H + (k - 1) * ROW_H
        Btn Canvas(), bx, yy + 6, 104, 30, "Conferir", ActProc1("ConferirNota", ch(k)), "secondary", IC_OK
    Next k
End Sub

'--- notas em que o recebido supera a ordem de compra -------------------------
Private Sub TabelaDivergencias(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long
    d = Bloco(SH_ENT, EN_NF, EN_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = n To 1 Step -1
        If SVal(d(i, EN_NF)) <> "" And PassaUnidade(SVal(d(i, EN_UNID))) Then
            If SVal(d(i, EN_CONF)) <> "" And UCase$(SVal(d(i, EN_CONF))) <> "OK" Then
                m = m + 1: idx(m) = i
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "NF / Remessa", 116, 1, "strong"
    GridCol "Chamado", 92, 1, "dim"
    GridCol "Produto", 0
    GridCol "OC", 96, 2, "dim"
    GridCol "Qtd. recebida", 106, 2
    GridCol "Fornecedor", 220, 1, "dim"
    GridCol "Conferência com a OC", 230, 1, "badge"

    cap = GridCapacity(y)
    If m > cap Then m = cap
    If m = 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 40, w, 180, "Nenhuma divergência", _
                   "As quantidades recebidas batem com as ordens de compra."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String, k As Long
    ReDim lin(1 To m, 1 To 7): ReDim ch(1 To m)
    For k = 1 To m
        i = idx(k)
        lin(k, 1) = SVal(d(i, EN_NF))
        lin(k, 2) = SVal(d(i, EN_CHAMADO))
        lin(k, 3) = SVal(d(i, EN_DESC))
        lin(k, 4) = SVal(d(i, EN_OC))
        lin(k, 5) = FmtN(d(i, EN_QTD))
        lin(k, 6) = Corta(SVal(d(i, EN_FORN)), 30)
        lin(k, 7) = SVal(d(i, EN_CONF))
        ch(k) = CStr(i + FIRST_ROW - 1)
    Next k
    GridDraw lin, m, ch, "nota_form"
End Sub

'--- itens com desvio quantitativo entre etapas -------------------------------
Private Sub TabelaDesvios(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long
    d = Bloco(SH_ESCOPO, ES_CHAMADO, ES_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, ES_CHAMADO)) <> "" And PassaUnidade(SVal(d(i, ES_UNID))) Then
            If NVal(d(i, ES_DESVIO)) > 0 Then m = m + 1: idx(m) = i
        End If
    Next i

    GridBegin x, y, w
    GridCol "Chamado", 92, 1, "strong"
    GridCol "Código", 84
    GridCol "Descrição do produto", 0
    GridCol "Prev.", 58, 2
    GridCol "Solic.", 58, 2
    GridCol "Compr.", 58, 2
    GridCol "Receb.", 58, 2
    GridCol "Lib.", 58, 2
    GridCol "Inst.", 58, 2
    GridCol "Saldo até o VMS", 116, 2
    GridCol "Status quantitativo", 210, 1, "badge"

    cap = GridCapacity(y)
    If m > cap Then m = cap
    If m = 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 40, w, 180, "Escopo consistente", _
                   "Nenhum item apresenta desvio entre as etapas."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String, k As Long
    ReDim lin(1 To m, 1 To 11): ReDim ch(1 To m)
    For k = 1 To m
        i = idx(k)
        lin(k, 1) = SVal(d(i, ES_CHAMADO))
        lin(k, 2) = SVal(d(i, ES_COD))
        lin(k, 3) = SVal(d(i, ES_DESC))
        lin(k, 4) = FmtN(d(i, ES_PREV))
        lin(k, 5) = FmtN(d(i, ES_SOLIC))
        lin(k, 6) = FmtN(d(i, ES_COMP))
        lin(k, 7) = FmtN(d(i, ES_RECEB))
        lin(k, 8) = FmtN(d(i, ES_LIB))
        lin(k, 9) = FmtN(d(i, ES_INST))
        lin(k, 10) = FmtN(d(i, ES_SALDO))
        lin(k, 11) = SVal(d(i, ES_STATUS))
        ch(k) = SVal(d(i, ES_CHAMADO))
    Next k
    GridDraw lin, m, ch, "projeto"
End Sub
