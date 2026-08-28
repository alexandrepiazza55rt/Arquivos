Attribute VB_Name = "scrCompras"
Option Explicit
'==============================================================================
' scrCompras  -  Solicitacoes de compra e ordens de compra
'==============================================================================

Public Sub ComprasRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Set ws = Canvas()
    x = ContentX: w = ContentW

    y = RenderShell("Compras", "Solicitações no suprimentos e ordens junto ao fornecedor")

    Resumo ws, x, y, w
    y = y + 96 + GAP

    TabStrip ws, x, y, Array("Solicitações de compra", "Ordens de compra"), _
             Array("sc", "oc"), IIf(gAba = "", "sc", gAba), "compras", ""
    y = y + 32 + GAP

    y = y + Toolbar(x, y, w, , , _
                    IIf(gFUnidade = "(TODAS AS UNIDADES)", "Todas as unidades", gFUnidade), _
                    ActProc("AbrirFiltroUnidade"))

    If LCase$(gAba) = "oc" Then TabelaOC x, y, w Else TabelaSC x, y, w
End Sub

Private Sub Resumo(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long
    Dim scAbertas As Long, scAtras As Long, ocAbertas As Long, ocAtras As Long
    Dim saldoSemOC As Double, saldoPend As Double

    d = Bloco(SH_SC, SC_REQ, SC_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, SC_REQ)) <> "" And PassaUnidade(UnidadeDoChamado(SVal(d(i, SC_CHAMADO)))) Then
            If NVal(d(i, SC_SALDO)) > 0 Then scAbertas = scAbertas + 1
            saldoSemOC = saldoSemOC + NVal(d(i, SC_SALDO))
            If InStr(UCase$(SVal(d(i, SC_SIT))), "ATRAS") > 0 Then scAtras = scAtras + 1
        End If
    Next i

    d = Bloco(SH_OC, OC_NUM, OC_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, OC_NUM)) <> "" And PassaUnidade(UnidadeDoChamado(SVal(d(i, OC_CHAMADO)))) Then
            If NVal(d(i, OC_SALDO)) > 0 Then ocAbertas = ocAbertas + 1
            saldoPend = saldoPend + NVal(d(i, OC_SALDO))
            If InStr(UCase$(SVal(d(i, OC_SIT))), "ATRAS") > 0 Then ocAtras = ocAtras + 1
        End If
    Next i

    Dim cw As Double
    cw = (w - GAP * 3) / 4
    KpiCard ws, x, y, cw, 96, "SC sem OC completa", CStr(scAbertas), _
            Format$(saldoSemOC, "#,##0") & " peças sem ordem", clrMuted, ActIr("compras", "", "sc"), clrAccent
    KpiCard ws, x + cw + GAP, y, cw, 96, "SC atrasadas", CStr(scAtras), "SLA de suprimentos estourado", _
            IIf(scAtras = 0, clrMuted, clrDanger), ActIr("compras", "", "sc"), clrDanger
    KpiCard ws, x + (cw + GAP) * 2, y, cw, 96, "OC com saldo", CStr(ocAbertas), _
            Format$(saldoPend, "#,##0") & " peças a receber", clrMuted, ActIr("compras", "", "oc"), clrInfo
    KpiCard ws, x + (cw + GAP) * 3, y, cw, 96, "OC atrasadas", CStr(ocAtras), "prazo do fornecedor vencido", _
            IIf(ocAtras = 0, clrMuted, clrDanger), ActIr("compras", "", "oc"), clrWarn
End Sub

Private Sub TabelaSC(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long
    d = Bloco(SH_SC, SC_REQ, SC_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, SC_REQ)) <> "" And PassaUnidade(UnidadeDoChamado(SVal(d(i, SC_CHAMADO)))) Then
            If Casa(d(i, SC_REQ), d(i, SC_NUM), d(i, SC_CHAMADO), d(i, SC_COD), d(i, SC_DESC), d(i, SC_COMPRADOR)) Then
                m = m + 1: idx(m) = i
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "Requisição", 104, 1, "strong"
    GridCol "SC", 96
    GridCol "Chamado", 88, 1, "dim"
    GridCol "Descrição", 0
    GridCol "Qtd.", 58, 2
    GridCol "Com OC", 66, 2
    GridCol "Saldo", 62, 2
    GridCol "Comprador", 112, 1, "dim"
    GridCol "Dias / SLA", 92, 2
    GridCol "Situação da compra", 210, 1, "badge"

    cap = GridCapacity(y)
    Dim de As Long, ate As Long, k As Long, q As Long
    de = (gPagina - 1) * cap + 1
    If de > m Then de = 1: gPagina = 1
    ate = de + cap - 1
    If ate > m Then ate = m
    q = ate - de + 1
    If q <= 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 40, w, 170, "Nenhuma solicitação", _
                   "As SCs aparecem aqui assim que forem informadas no item."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String
    ReDim lin(1 To q, 1 To 10): ReDim ch(1 To q)
    For k = 1 To q
        i = idx(de + k - 1)
        lin(k, 1) = SVal(d(i, SC_REQ))
        lin(k, 2) = SVal(d(i, SC_NUM))
        lin(k, 3) = SVal(d(i, SC_CHAMADO))
        lin(k, 4) = SVal(d(i, SC_DESC))
        lin(k, 5) = FmtN(d(i, SC_QTD))
        lin(k, 6) = FmtN(d(i, SC_QOC))
        lin(k, 7) = FmtN(d(i, SC_SALDO))
        lin(k, 8) = SVal(d(i, SC_COMPRADOR))
        lin(k, 9) = FmtN(d(i, SC_DIAS)) & " / " & FmtN(d(i, SC_SLA))
        lin(k, 10) = SVal(d(i, SC_SIT))
        ch(k) = SVal(d(i, SC_CHAMADO))
    Next k
    GridDraw lin, q, ch, "projeto"
    GridPager x, ViewH - 52, w, m, gPagina, cap
End Sub

Private Sub TabelaOC(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long
    d = Bloco(SH_OC, OC_NUM, OC_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, OC_NUM)) <> "" And PassaUnidade(UnidadeDoChamado(SVal(d(i, OC_CHAMADO)))) Then
            If Casa(d(i, OC_NUM), d(i, OC_SC), d(i, OC_CHAMADO), d(i, OC_DESC), d(i, OC_FORN)) Then
                m = m + 1: idx(m) = i
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "OC", 100, 1, "strong"
    GridCol "Chamado", 88, 1, "dim"
    GridCol "Descrição", 0
    GridCol "Fornecedor", 220, 1, "dim"
    GridCol "Emissão", 92, 2
    GridCol "Previsão", 92, 2
    GridCol "Compr.", 62, 2
    GridCol "Receb.", 62, 2
    GridCol "Saldo", 60, 2
    GridCol "Dias / SLA", 92, 2
    GridCol "Situação da entrega", 200, 1, "badge"

    cap = GridCapacity(y)
    Dim de As Long, ate As Long, k As Long, q As Long
    de = (gPagina - 1) * cap + 1
    If de > m Then de = 1: gPagina = 1
    ate = de + cap - 1
    If ate > m Then ate = m
    q = ate - de + 1
    If q <= 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 40, w, 170, "Nenhuma ordem de compra", _
                   "As OCs aparecem aqui assim que forem informadas no item."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String
    ReDim lin(1 To q, 1 To 11): ReDim ch(1 To q)
    For k = 1 To q
        i = idx(de + k - 1)
        lin(k, 1) = SVal(d(i, OC_NUM))
        lin(k, 2) = SVal(d(i, OC_CHAMADO))
        lin(k, 3) = SVal(d(i, OC_DESC))
        lin(k, 4) = Corta(SVal(d(i, OC_FORN)), 30)
        lin(k, 5) = FmtD(d(i, OC_DATA))
        lin(k, 6) = FmtD(d(i, OC_PREV))
        lin(k, 7) = FmtN(d(i, OC_QCOMP))
        lin(k, 8) = FmtN(d(i, OC_QRECEB))
        lin(k, 9) = FmtN(d(i, OC_SALDO))
        lin(k, 10) = FmtN(d(i, OC_DIAS)) & " / " & FmtN(d(i, OC_SLA))
        lin(k, 11) = SVal(d(i, OC_SIT))
        ch(k) = SVal(d(i, OC_CHAMADO))
    Next k
    GridDraw lin, q, ch, "projeto"
    GridPager x, ViewH - 52, w, m, gPagina, cap
End Sub
