Attribute VB_Name = "mGrid"
Option Explicit
'==============================================================================
' mGrid  -  Tabela de dados
'
' O texto das listas e escrito em CELULAS (rapido, alinhado, selecionavel) e os
' enfeites (badges, setas, area clicavel da linha) sao formas por cima.
' Visual: linhas brancas sobre o fundo da tela, separadas por fio de 1 px,
' cabecalho em maiusculas discretas. Sem molduras pesadas.
'==============================================================================

Private Const MAXC As Long = 14

Private gX As Double, gY As Double, gW As Double
Private gN As Long                       ' numero de colunas declaradas
Private gTit(1 To MAXC) As String
Private gLar(1 To MAXC) As Double
Private gAli(1 To MAXC) As Long          ' 1 esq, 2 centro, 3 dir
Private gKin(1 To MAXC) As String        ' text | badge | chevron | strong | dim
Private gFlex As Long                    ' coluna que absorve a sobra

'==============================================================================
' Definicao
'==============================================================================
Public Sub GridBegin(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    gX = x: gY = y: gW = w: gN = 0: gFlex = 0
End Sub

' larg = 0 marca a coluna flexivel (recebe o espaco que sobrar).
Public Sub GridCol(ByVal titulo As String, ByVal larg As Double, _
                   Optional ByVal align As Long = 1, Optional ByVal kind As String = "text")
    If gN >= MAXC Then Exit Sub
    gN = gN + 1
    gTit(gN) = titulo
    gLar(gN) = larg
    gAli(gN) = align
    gKin(gN) = kind
    If larg = 0 Then gFlex = gN
End Sub

' Quantas linhas cabem da posicao y ate o fim da janela (reservando o rodape).
Public Function GridCapacity(ByVal y As Double) As Long
    Dim disp As Double
    disp = ViewH - y - HEAD_H - 66
    GridCapacity = Int(disp / ROW_H)
    If GridCapacity < 3 Then GridCapacity = 3
    If GridCapacity > 40 Then GridCapacity = 40
End Function

'==============================================================================
' Desenho
'==============================================================================
' dados : matriz (1..n, 1..gN) com o texto ja formatado
' keys  : matriz (1..n) com a chave de cada linha (vazio = linha nao clicavel)
' tela  : tela de destino ao clicar na linha
Public Sub GridDraw(ByVal dados As Variant, ByVal n As Long, ByVal keys As Variant, _
                    Optional ByVal tela As String = "")
    Dim ws As Worksheet, i As Long, j As Long
    Dim soma As Double, sobra As Double
    Dim r1 As Long, rN As Long, c1 As Long, cN As Long

    Set ws = Canvas()
    If gN = 0 Then Exit Sub

    ' --- largura das colunas -------------------------------------------------
    For j = 1 To gN
        soma = soma + gLar(j)
    Next j
    sobra = gW - soma
    If gFlex > 0 And sobra > 0 Then gLar(gFlex) = gLar(gFlex) + sobra

    SetColPx ws, 1, gX
    For j = 1 To gN
        SetColPx ws, 1 + j, gLar(j)
    Next j
    SetColPx ws, 2 + gN, 24

    ' --- alturas -------------------------------------------------------------
    SetRowPx ws, 1, IIf(gY < 1, 1, gY)
    SetRowPx ws, 2, HEAD_H
    r1 = 3: rN = 3 + n - 1
    c1 = 2: cN = 1 + gN

    ' --- cabecalho -----------------------------------------------------------
    For j = 1 To gN
        With ws.Cells(2, 1 + j)
            .Value = UCase$(gTit(j))
            .Font.Name = FONT_UI
            .Font.Size = 7.5
            .Font.Bold = True
            .Font.Color = clrMuted
            .HorizontalAlignment = AliXL(gAli(j))
            .VerticalAlignment = xlCenter
            If gAli(j) <> 2 Then .IndentLevel = 1
        End With
    Next j
    With ws.Range(ws.Cells(2, c1), ws.Cells(2, cN)).Borders(xlEdgeBottom)
        .LineStyle = xlContinuous: .Weight = xlThin: .Color = clrBorderOn
    End With

    If n <= 0 Then Exit Sub

    ' --- corpo ---------------------------------------------------------------
    For i = r1 To rN
        SetRowPx ws, i, ROW_H
    Next i

    With ws.Range(ws.Cells(r1, c1), ws.Cells(rN, cN))
        .NumberFormat = "@"
        .Interior.Color = clrSurface
        .Font.Name = FONT_UI
        .Font.Size = 9.5
        .Font.Color = clrText
        .VerticalAlignment = xlCenter
        .WrapText = False
        With .Borders(xlInsideHorizontal)
            .LineStyle = xlContinuous: .Weight = xlHairline: .Color = clrBorder
        End With
        With .Borders(xlEdgeBottom)
            .LineStyle = xlContinuous: .Weight = xlHairline: .Color = clrBorder
        End With
    End With

    For j = 1 To gN
        With ws.Range(ws.Cells(r1, 1 + j), ws.Cells(rN, 1 + j))
            .HorizontalAlignment = AliXL(gAli(j))
            If gAli(j) <> 2 Then .IndentLevel = 1
            Select Case gKin(j)
                Case "strong": .Font.Bold = True
                Case "dim":    .Font.Color = clrText2: .Font.Size = 9
                Case "badge", "chevron": .Font.Color = clrSurface   ' o texto vira forma
            End Select
        End With
    Next j

    ' escrita em bloco
    Dim saida() As Variant
    ReDim saida(1 To n, 1 To gN)
    For i = 1 To n
        For j = 1 To gN
            If gKin(j) = "badge" Or gKin(j) = "chevron" Then
                saida(i, j) = ""
            Else
                saida(i, j) = CStr(dados(i, j))
            End If
        Next j
    Next i
    ws.Range(ws.Cells(r1, c1), ws.Cells(rN, cN)).Value = saida

    ' --- formas por cima -----------------------------------------------------
    Dim xAcc As Double, yLin As Double, chave As String
    For i = 1 To n
        yLin = gY + HEAD_H + (i - 1) * ROW_H
        xAcc = gX
        For j = 1 To gN
            Select Case gKin(j)
                Case "badge"
                    Dim txt As String
                    txt = CStr(dados(i, j))
                    If txt <> "" Then
                        Dim bl As Double, bw As Double
                        bw = Len(txt) * 6.1 + 20
                        Select Case gAli(j)
                            Case 2: bl = xAcc + (gLar(j) - bw) / 2
                            Case 3: bl = xAcc + gLar(j) - bw - 8
                            Case Else: bl = xAcc + 7
                        End Select
                        Badge ws, bl, yLin + (ROW_H - 22) / 2, txt, SituacaoKind(txt)
                    End If
                Case "chevron"
                    Icon ws, xAcc + gLar(j) - 26, yLin, ROW_H, IC_RIGHT, clrBorderOn, 9
            End Select
            xAcc = xAcc + gLar(j)
        Next j

        chave = ""
        On Error Resume Next
        chave = CStr(keys(i))
        On Error GoTo 0
        If chave <> "" And tela <> "" Then
            HitArea ws, gX, yLin, gW, ROW_H, ActIr(tela, chave)
        End If
    Next i
End Sub

Private Function AliXL(ByVal a As Long) As Long
    Select Case a
        Case 2: AliXL = xlCenter
        Case 3: AliXL = xlRight
        Case Else: AliXL = xlLeft
    End Select
End Function

'==============================================================================
' Rodape de paginacao
'==============================================================================
Public Sub GridPager(ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                     ByVal total As Long, ByVal pagina As Long, ByVal porPagina As Long)
    Dim ws As Worksheet, de As Long, ate As Long, paginas As Long
    Set ws = Canvas()
    If porPagina < 1 Then porPagina = 1
    paginas = -Int(-total / porPagina)
    If paginas < 1 Then paginas = 1
    de = (pagina - 1) * porPagina + 1
    ate = de + porPagina - 1
    If ate > total Then ate = total
    If total = 0 Then de = 0

    Lbl ws, x, y, w * 0.5, 30, "Mostrando " & de & "–" & ate & " de " & total & " registros", _
        8.5, clrMuted, False, 1

    Dim bx As Double
    bx = x + w - 190
    Lbl ws, bx, y, 92, 30, "Página " & pagina & " de " & paginas, 8.5, clrText2, False, 3
    If pagina > 1 Then
        IconBtn ws, bx + 104, y + 3, 26, IC_LEFT, ActProc("PaginaAnterior")
    Else
        Rect ws, bx + 104, y + 3, 26, 26, clrSurface, 8, clrBorder
        Icon ws, bx + 104, y + 3, 26, IC_LEFT, clrBorderOn, 9
    End If
    If pagina < paginas Then
        IconBtn ws, bx + 136, y + 3, 26, IC_RIGHT, ActProc("PaginaProxima")
    Else
        Rect ws, bx + 136, y + 3, 26, 26, clrSurface, 8, clrBorder
        Icon ws, bx + 136, y + 3, 26, IC_RIGHT, clrBorderOn, 9
    End If
End Sub

'==============================================================================
' Barra de ferramentas: busca + filtros + botao principal
'==============================================================================
' Desenha a caixa de busca ligada a uma celula de entrada (mesma folha).
' Devolve a altura ocupada.
Public Function Toolbar(ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                        Optional ByVal btnTexto As String = "", _
                        Optional ByVal btnAcao As String = "", _
                        Optional ByVal filtro1 As String = "", _
                        Optional ByVal acaoFiltro1 As String = "", _
                        Optional ByVal filtro2 As String = "", _
                        Optional ByVal acaoFiltro2 As String = "") As Double
    Dim ws As Worksheet, bx As Double
    Set ws = Canvas()

    ' busca
    Rect ws, x, y, 300, 36, clrSurface, 8, clrBorder
    Icon ws, x + 8, y, 20, IC_BUSCA, clrMuted, 10, 36
    If gBusca = "" Then
        Lbl ws, x + 32, y, 250, 36, "Buscar…", 9.5, clrMuted, False, 1
    Else
        Lbl ws, x + 32, y, 226, 36, gBusca, 9.5, clrText, False, 1
        IconBtn ws, x + 268, y + 6, 24, IC_CLOSE, ActProc("LimparBusca"), "ghost"
    End If
    HitArea ws, x, y, 262, 36, ActProc("DefinirBusca")

    bx = x + 300 + 10
    If filtro1 <> "" Then
        bx = bx + ChipFiltro(ws, bx, y, filtro1, acaoFiltro1) + 8
    End If
    If filtro2 <> "" Then
        bx = bx + ChipFiltro(ws, bx, y, filtro2, acaoFiltro2) + 8
    End If

    If btnTexto <> "" Then
        Dim bw As Double
        bw = Len(btnTexto) * 6.6 + 56
        Btn ws, x + w - bw, y, bw, 36, btnTexto, btnAcao, "primary", IC_ADD
    End If
    Toolbar = 36 + GAP
End Function

Private Function ChipFiltro(ws As Worksheet, ByVal x As Double, ByVal y As Double, _
                            ByVal texto As String, ByVal acao As String) As Double
    Dim w As Double
    w = Len(texto) * 6.3 + 48
    Rect ws, x, y, w, 36, clrSurface, 8, clrBorder
    Icon ws, x + 8, y, 18, IC_FILTER, clrMuted, 9.5, 36
    Lbl ws, x + 28, y, w - 48, 36, texto, 9, clrText, False, 1
    Icon ws, x + w - 22, y, 16, ChrW(&HE70D), clrMuted, 8, 36
    HitArea ws, x, y, w, 36, acao
    ChipFiltro = w
End Function

Public Sub DefinirBusca()
    Dim r As Variant
    r = InputBox("Buscar (numero do chamado, nome do projeto, produto, NF...):", APP_NOME, gBusca)
    If StrPtr(r) = 0 Then Exit Sub
    gBusca = Trim$(CStr(r))
    gPagina = 1
    Recarregar
End Sub

Public Sub LimparBusca()
    gBusca = ""
    gPagina = 1
    Recarregar
End Sub

' Casa o texto buscado com qualquer um dos campos informados.
Public Function Casa(ParamArray campos() As Variant) As Boolean
    Dim i As Long, alvo As String
    If gBusca = "" Then Casa = True: Exit Function
    alvo = UCase$(gBusca)
    For i = LBound(campos) To UBound(campos)
        If InStr(UCase$(CStr(campos(i) & "")), alvo) > 0 Then Casa = True: Exit Function
    Next i
End Function
