Attribute VB_Name = "scrPainel"
Option Explicit
'==============================================================================
' scrPainel  -  Tela inicial: visao geral do setor
'==============================================================================

Public Sub PainelRender()
    Dim ws As Worksheet, y As Double, x As Double, w As Double
    Set ws = Canvas()
    x = ContentX: w = ContentW

    y = RenderShell("Painel", "Visão geral do setor  ·  referência " & Format$(DataRefer, "dd/mm/yyyy"))

    ' filtro de unidade no canto do cabecalho
    Dim fu As String
    fu = IIf(gFUnidade = "(TODAS AS UNIDADES)", "Todas as unidades", gFUnidade)
    Rect ws, x + w - 220, 26, 220, 36, clrSurface, 8, clrBorder
    Icon ws, x + w - 212, 26, 18, IC_FILTER, clrMuted, 9.5, 36
    Lbl ws, x + w - 190, 26, 158, 36, fu, 9, clrText, False, 1
    Icon ws, x + w - 30, 26, 16, ChrW(&HE70D), clrMuted, 8, 36
    HitArea ws, x + w - 220, 26, 220, 36, ActProc("AbrirFiltroUnidade")

    '--- indicadores ---------------------------------------------------------
    Dim ativos As Long, prazo As Long, atras As Long, bloq As Long, concl As Long
    Dim aguardando As Long, conferir As Long, divergencias As Long
    ContarProjetos ativos, prazo, atras, bloq, concl
    ContarMaterial aguardando, conferir, divergencias

    Dim cw As Double, i As Long
    cw = (w - GAP * 4) / 5

    KpiCard ws, x + 0 * (cw + GAP), y, cw, 104, "Projetos ativos", CStr(ativos), _
            CStr(concl) & " concluídos no total", clrMuted, ActIr("projetos"), clrAccent
    KpiCard ws, x + 1 * (cw + GAP), y, cw, 104, "No prazo", CStr(prazo), _
            Pct(prazo, ativos) & " da carteira ativa", clrOk, ActIr("projetos"), clrOk
    KpiCard ws, x + 2 * (cw + GAP), y, cw, 104, "Atrasados", CStr(atras), _
            IIf(atras = 0, "nenhuma etapa estourada", "SLA de etapa estourado"), _
            IIf(atras = 0, clrMuted, clrDanger), ActIr("projetos"), clrDanger
    KpiCard ws, x + 3 * (cw + GAP), y, cw, 104, "Itens aguardando entrega", CStr(aguardando), _
            "sem recebimento registrado", clrMuted, ActIr("itens"), clrWarn
    KpiCard ws, x + 4 * (cw + GAP), y, cw, 104, "Pendências de conferência", CStr(conferir + divergencias), _
            CStr(conferir) & " notas · " & CStr(divergencias) & " divergências", _
            IIf(conferir + divergencias = 0, clrMuted, clrWarn), ActIr("conferencia"), clrInfo

    y = y + 104 + GAP

    '--- graficos ------------------------------------------------------------
    Dim gw As Double, gh As Double
    gh = 224
    gw = (w - GAP * 2) / 3

    CardSituacao ws, x, y, gw, gh
    CardEtapas ws, x + gw + GAP, y, gw, gh
    CardMaterial ws, x + (gw + GAP) * 2, y, gw, gh

    y = y + gh + GAP + 6

    '--- lista de atencao ----------------------------------------------------
    Lbl ws, x, y - 32, w * 0.6, 24, "Precisam de atenção", 12, clrText, True, 1
    Lbl ws, x + w - 130, y - 32, 130, 24, "Ver todos os projetos", 9, clrAccent, True, 3
    HitArea ws, x + w - 130, y - 32, 130, 24, ActIr("projetos")

    TabelaAtencao x, y, w
End Sub

Private Function Pct(ByVal a As Long, ByVal b As Long) As String
    If b = 0 Then Pct = "—" Else Pct = Format$(a / b, "0%")
End Function

'==============================================================================
' Agregacoes
'==============================================================================
Private Function PassaFiltro(ByVal unidade As String) As Boolean
    PassaFiltro = (gFUnidade = "(TODAS AS UNIDADES)" Or gFUnidade = "" Or unidade = gFUnidade)
End Function

Public Sub ContarProjetos(ByRef ativos As Long, ByRef prazo As Long, ByRef atras As Long, _
                          ByRef bloq As Long, ByRef concl As Long)
    Dim d As Variant, i As Long, n As Long, sit As String, st As String
    d = Bloco(SH_PROJ, PJ_CHAMADO, PJ_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, PJ_CHAMADO)) <> "" And PassaFiltro(SVal(d(i, PJ_UNID))) Then
            sit = UCase$(SVal(d(i, PJ_SITUACAO)))
            st = UCase$(SVal(d(i, PJ_STATUS)))
            If st = "CONCLUÍDO" Or st = "CANCELADO" Then
                concl = concl + 1
            Else
                ativos = ativos + 1
                Select Case True
                    Case InStr(sit, "ATRAS") > 0:  atras = atras + 1
                    Case InStr(sit, "BLOQUE") > 0: bloq = bloq + 1
                    Case InStr(sit, "PRAZO") > 0:  prazo = prazo + 1
                End Select
            End If
        End If
    Next i
End Sub

Public Sub ContarMaterial(ByRef aguardando As Long, ByRef conferir As Long, ByRef divergencias As Long)
    Dim d As Variant, i As Long, n As Long

    d = Bloco(SH_ITENS, IT_CHAMADO, IT_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, IT_CHAMADO)) <> "" Then
            If PassaFiltro(UnidadeDoChamado(SVal(d(i, IT_CHAMADO)))) Then
                If NVal(d(i, IT_QRECEB)) < NVal(d(i, IT_QCOMP)) Then aguardando = aguardando + 1
            End If
        End If
    Next i

    d = Bloco(SH_ENT, EN_NF, EN_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, EN_NF)) <> "" Then
            If PassaFiltro(SVal(d(i, EN_UNID))) Then
                If UCase$(SVal(d(i, EN_SITFIS))) <> "CONFERIDO" Then conferir = conferir + 1
                If UCase$(SVal(d(i, EN_CONF))) <> "OK" And SVal(d(i, EN_CONF)) <> "" Then _
                    divergencias = divergencias + 1
            End If
        End If
    Next i
End Sub

Public Function UnidadeDoChamado(ByVal chamado As String) As String
    Dim r As Long
    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    If r > 0 Then UnidadeDoChamado = SVal(Sh(SH_PROJ).Cells(r, PJ_UNID).Value)
End Function

'==============================================================================
' Cartoes de grafico
'==============================================================================
Private Sub CardSituacao(ws As Worksheet, ByVal x As Double, ByVal y As Double, _
                         ByVal w As Double, ByVal h As Double)
    Dim d As Variant, i As Long, n As Long, sit As String
    Dim v(0 To 4) As Double, rot(0 To 4) As String, cor(0 To 4) As Long

    rot(0) = "No prazo": cor(0) = clrOk
    rot(1) = "Atenção": cor(1) = clrWarn
    rot(2) = "Atrasado": cor(2) = clrDanger
    rot(3) = "Bloqueado": cor(3) = HX(&H7C2D3E)
    rot(4) = "Concluído": cor(4) = clrInfo

    d = Bloco(SH_PROJ, PJ_CHAMADO, PJ_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, PJ_CHAMADO)) <> "" And PassaFiltro(SVal(d(i, PJ_UNID))) Then
            sit = UCase$(SVal(d(i, PJ_SITUACAO)))
            Select Case True
                Case InStr(sit, "CONCLU") > 0:  v(4) = v(4) + 1
                Case InStr(sit, "BLOQUE") > 0:  v(3) = v(3) + 1
                Case InStr(sit, "ATRAS") > 0:   v(2) = v(2) + 1
                Case InStr(sit, "ATEN") > 0 Or InStr(sit, "RISCO") > 0: v(1) = v(1) + 1
                Case InStr(sit, "PRAZO") > 0:   v(0) = v(0) + 1
            End Select
        End If
    Next i

    Card ws, x, y, w, h
    CardTitle ws, x + 20, y + 18, w - 40, "Situação da carteira", "distribuição dos projetos"
    SegmentBar ws, x + 20, y + 78, w - 40, rot, v, cor, 14
End Sub

Private Sub CardEtapas(ws As Worksheet, ByVal x As Double, ByVal y As Double, _
                       ByVal w As Double, ByVal h As Double)
    Dim et As Variant, d As Variant, i As Long, j As Long, n As Long
    Dim cont() As Double, rot() As String, nn As Long

    et = ListaEtapas()
    nn = UBound(et) - LBound(et) + 1
    If nn < 1 Then
        Card ws, x, y, w, h
        CardTitle ws, x + 20, y + 18, w - 40, "Onde estão parados", "nenhuma etapa cadastrada"
        Exit Sub
    End If
    ReDim cont(1 To nn): ReDim rot(1 To nn)
    For i = 1 To nn
        rot(i) = CStr(et(LBound(et) + i - 1))
    Next i

    d = Bloco(SH_PROJ, PJ_CHAMADO, PJ_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, PJ_CHAMADO)) <> "" And PassaFiltro(SVal(d(i, PJ_UNID))) Then
            If UCase$(SVal(d(i, PJ_STATUS))) <> "CONCLUÍDO" And UCase$(SVal(d(i, PJ_STATUS))) <> "CANCELADO" Then
                For j = 1 To nn
                    If UCase$(SVal(d(i, PJ_ETAPA))) = UCase$(rot(j)) Then cont(j) = cont(j) + 1: Exit For
                Next j
            End If
        End If
    Next i

    ' ordena decrescente (selecao simples: sao poucas etapas)
    Dim k As Long, tv As Double, ts As String
    For i = 1 To nn - 1
        For k = i + 1 To nn
            If cont(k) > cont(i) Then
                tv = cont(i): cont(i) = cont(k): cont(k) = tv
                ts = rot(i): rot(i) = rot(k): rot(k) = ts
            End If
        Next k
    Next i

    Card ws, x, y, w, h
    CardTitle ws, x + 20, y + 18, w - 40, "Onde estão parados", "projetos ativos por etapa"
    BarList ws, x + 20, y + 66, w - 40, rot, cont, , 5, w * 0.44
End Sub

Private Sub CardMaterial(ws As Worksheet, ByVal x As Double, ByVal y As Double, _
                         ByVal w As Double, ByVal h As Double)
    Dim d As Variant, i As Long, n As Long
    Dim prev As Double, comp As Double, receb As Double, lib As Double, inst As Double, vms As Double

    d = Bloco(SH_ESCOPO, ES_CHAMADO, ES_ULT)
    n = BlocoLinhas(d)
    For i = 1 To n
        If SVal(d(i, ES_CHAMADO)) <> "" And PassaFiltro(SVal(d(i, ES_UNID))) Then
            prev = prev + NVal(d(i, ES_PREV))
            comp = comp + NVal(d(i, ES_COMP))
            receb = receb + NVal(d(i, ES_RECEB))
            lib = lib + NVal(d(i, ES_LIB))
            inst = inst + NVal(d(i, ES_INST))
            vms = vms + NVal(d(i, ES_VMS))
        End If
    Next i

    Card ws, x, y, w, h
    CardTitle ws, x + 20, y + 18, w - 40, "Funil do material", "quantidades acumuladas"
    BarList ws, x + 20, y + 66, w - 40, _
            Array("Previsto", "Comprado", "Recebido", "Liberado", "Instalado", "No VMS"), _
            Array(prev, comp, receb, lib, inst, vms), _
            Array(clrBorderOn, clrInfo, clrAccent, HX(&H6D5BD9), clrOk, HX(&H0E9384)), 6, w * 0.34
End Sub

'==============================================================================
' Lista dos projetos criticos
'==============================================================================
Private Sub TabelaAtencao(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, i As Long, n As Long, cap As Long
    Dim lin() As Variant, chaves() As String, k As Long

    d = Bloco(SH_PROJ, PJ_CHAMADO, PJ_ULT)
    n = BlocoLinhas(d)

    GridBegin x, y, w
    GridCol "Chamado", 96, 1, "strong"
    GridCol "Projeto", 0
    GridCol "Unidade", 88
    GridCol "Etapa atual", 210, 1, "dim"
    GridCol "Dias na etapa", 96, 2
    GridCol "Atraso", 78, 2
    GridCol "Situação", 128, 1, "badge"
    GridCol "", 30, 3, "chevron"

    cap = GridCapacity(y)
    If n = 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 40, w, 160, "Nenhum projeto cadastrado", _
                   "Use a tela Projetos para incluir o primeiro chamado."
        Exit Sub
    End If

    ' ordena por dias de atraso (decrescente) apenas entre os ativos filtrados
    Dim idx() As Long, atr() As Double, m As Long
    ReDim idx(1 To n): ReDim atr(1 To n)
    For i = 1 To n
        If SVal(d(i, PJ_CHAMADO)) <> "" And PassaFiltro(SVal(d(i, PJ_UNID))) Then
            If UCase$(SVal(d(i, PJ_STATUS))) <> "CONCLUÍDO" And UCase$(SVal(d(i, PJ_STATUS))) <> "CANCELADO" Then
                m = m + 1
                idx(m) = i
                atr(m) = NVal(d(i, PJ_ATRASO))
            End If
        End If
    Next i

    Dim a As Long, b As Long, tl As Long, td As Double
    For a = 1 To m - 1
        For b = a + 1 To m
            If atr(b) > atr(a) Then
                td = atr(a): atr(a) = atr(b): atr(b) = td
                tl = idx(a): idx(a) = idx(b): idx(b) = tl
            End If
        Next b
    Next a

    If m > cap Then m = cap
    If m = 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 40, w, 160, "Tudo em dia", _
                   "Nenhum projeto ativo na unidade selecionada."
        Exit Sub
    End If

    ReDim lin(1 To m, 1 To 8)
    ReDim chaves(1 To m)
    For k = 1 To m
        i = idx(k)
        lin(k, 1) = SVal(d(i, PJ_CHAMADO))
        lin(k, 2) = SVal(d(i, PJ_NOME))
        lin(k, 3) = SVal(d(i, PJ_UNID))
        lin(k, 4) = SVal(d(i, PJ_ETAPA))
        lin(k, 5) = FmtN(d(i, PJ_DIASETAPA)) & " / " & FmtN(d(i, PJ_SLA))
        lin(k, 6) = IIf(NVal(d(i, PJ_ATRASO)) > 0, "+" & FmtN(d(i, PJ_ATRASO)), "—")
        lin(k, 7) = SVal(d(i, PJ_SITUACAO))
        lin(k, 8) = ""
        chaves(k) = SVal(d(i, PJ_CHAMADO))
    Next k

    GridDraw lin, m, chaves, "projeto"
End Sub
