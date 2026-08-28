Attribute VB_Name = "mUI"
Option Explicit
'==============================================================================
' mUI  -  Motor de renderizacao da interface
'
' Desenha a tela do sistema sobre a planilha SISTEMA usando formas (chrome:
' cartoes, botoes, badges) e celulas (tabelas, campos de digitacao).
' Toda forma criada aqui recebe o prefixo "ui_" e e removida a cada navegacao.
'==============================================================================

Public Const UI_SHEET As String = "SISTEMA"
Private Const PFX     As String = "ui_"

Private mSeq As Long

'==============================================================================
' Folha de trabalho / canvas
'==============================================================================
Public Function Canvas() As Worksheet
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(UI_SHEET)
    On Error GoTo 0
    If ws Is Nothing Then
        Set ws = ThisWorkbook.Worksheets.Add(Before:=ThisWorkbook.Worksheets(1))
        ws.Name = UI_SHEET
    End If
    Set Canvas = ws
End Function

' Largura util da area de conteudo, em pixels de projeto.
Public Function ViewW() As Double
    Dim w As Double
    w = PxFromPt(ActiveWindow.UsableWidth)
    If w < 900 Then w = 900
    ViewW = w
End Function

Public Function ViewH() As Double
    Dim h As Double
    h = PxFromPt(ActiveWindow.UsableHeight)
    If h < 520 Then h = 520
    ViewH = h
End Function

Public Function ContentX() As Double
    ContentX = SIDEBAR_W + PAD
End Function

Public Function ContentW() As Double
    ContentW = ViewW - SIDEBAR_W - PAD * 2
End Function

'==============================================================================
' Limpeza
'==============================================================================
Public Sub ClearUI(ws As Worksheet)
    Dim i As Long
    On Error Resume Next
    For i = ws.Shapes.Count To 1 Step -1
        If Left$(ws.Shapes(i).Name, Len(PFX)) = PFX Then ws.Shapes(i).Delete
    Next i
    On Error GoTo 0
End Sub

Private Function NextName() As String
    mSeq = mSeq + 1
    NextName = PFX & Format$(mSeq, "00000")
End Function

'==============================================================================
' Primitivas de forma
'==============================================================================
Public Function Rect(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                     ByVal w As Double, ByVal h As Double, ByVal fillClr As Long, _
                     Optional ByVal radius As Double = 0, _
                     Optional ByVal lineClr As Long = -1) As Shape
    Dim s As Shape, shp As Long
    If radius > 0 Then shp = msoShapeRoundedRectangle Else shp = msoShapeRectangle
    Set s = ws.Shapes.AddShape(shp, P(l), P(t), P(w), P(h))
    s.Name = NextName()
    If radius > 0 Then
        Dim mn As Double
        mn = w: If h < mn Then mn = h
        If mn <= 0 Then mn = 1
        On Error Resume Next
        s.Adjustments(1) = radius / mn
        On Error GoTo 0
    End If
    With s
        If fillClr < 0 Then
            .Fill.Visible = msoFalse
        Else
            .Fill.Visible = msoTrue
            .Fill.Solid
            .Fill.ForeColor.RGB = fillClr
            .Fill.Transparency = 0
        End If
        If lineClr < 0 Then
            .Line.Visible = msoFalse
        Else
            .Line.Visible = msoTrue
            .Line.ForeColor.RGB = lineClr
            .Line.Weight = 0.75
        End If
        .Shadow.Visible = msoFalse
        .TextFrame2.TextRange.Text = ""
        .TextFrame2.WordWrap = msoFalse
        .TextFrame2.AutoSize = msoAutoSizeNone
        ' Sem isto o Excel move e estica a forma quando a largura das colunas e
        ' a altura das linhas mudam — e a grade da tabela e montada depois do
        ' menu e dos cartoes. Toda forma do sistema tem posicao absoluta.
        .Placement = xlFreeFloating
    End With
    Set Rect = s
End Function

' Cartao branco padrao: fundo, borda fina, canto arredondado.
Public Function Card(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                     ByVal w As Double, ByVal h As Double) As Shape
    Set Card = Rect(ws, l, t, w, h, clrSurface, CARD_R, clrBorder)
End Function

' Rotulo de texto. align: 1=esq 2=centro 3=dir
Public Function Lbl(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                    ByVal w As Double, ByVal h As Double, ByVal txt As String, _
                    ByVal size As Double, ByVal clr As Long, _
                    Optional ByVal bold As Boolean = False, _
                    Optional ByVal align As Long = 1, _
                    Optional ByVal fontName As String = FONT_UI, _
                    Optional ByVal wrap As Boolean = False, _
                    Optional ByVal spacing As Double = 0) As Shape
    Dim s As Shape
    Set s = Rect(ws, l, t, w, h, -1, 0, -1)
    With s.TextFrame2
        .MarginLeft = 0: .MarginRight = 0: .MarginTop = 0: .MarginBottom = 0
        .VerticalAnchor = msoAnchorMiddle
        .WordWrap = IIf(wrap, msoTrue, msoFalse)
        .TextRange.Text = txt
        With .TextRange.Font
            .Name = fontName
            .NameFarEast = fontName
            .Size = size
            .Bold = IIf(bold, msoTrue, msoFalse)
            .Fill.Visible = msoTrue
            .Fill.ForeColor.RGB = clr
            If spacing <> 0 Then .Spacing = spacing
        End With
        Select Case align
            Case 2: .TextRange.ParagraphFormat.Alignment = msoAlignCenter
            Case 3: .TextRange.ParagraphFormat.Alignment = msoAlignRight
            Case Else: .TextRange.ParagraphFormat.Alignment = msoAlignLeft
        End Select
    End With
    Set Lbl = s
End Function

' Icone da fonte Segoe MDL2 Assets.
Public Function Icon(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                     ByVal box As Double, ByVal glyph As String, ByVal clr As Long, _
                     Optional ByVal size As Double = 12, _
                     Optional ByVal alturaCaixa As Double = -1) As Shape
    If alturaCaixa < 0 Then alturaCaixa = box
    Set Icon = Lbl(ws, l, t, box, alturaCaixa, glyph, size, clr, False, 2, FONT_ICON)
End Function

' Area transparente clicavel sobre outros elementos.
Public Function HitArea(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                        ByVal w As Double, ByVal h As Double, ByVal action As String) As Shape
    Dim s As Shape
    Set s = Rect(ws, l, t, w, h, clrSurface, 0, -1)
    s.Fill.Transparency = 1
    s.OnAction = action
    Set HitArea = s
End Function

'==============================================================================
' Botoes
'==============================================================================
' kind: "primary" | "secondary" | "ghost" | "danger" | "dark"
Public Function Btn(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                    ByVal w As Double, ByVal h As Double, ByVal caption As String, _
                    ByVal action As String, Optional ByVal kind As String = "secondary", _
                    Optional ByVal glyph As String = "") As Shape
    Dim bg As Long, fg As Long, ln As Long, bx As Shape
    Select Case LCase$(kind)
        Case "primary": bg = clrAccent:  fg = HX(&HFFFFFF): ln = -1
        Case "danger":  bg = clrDanger:  fg = HX(&HFFFFFF): ln = -1
        Case "dark":    bg = clrText:    fg = HX(&HFFFFFF): ln = -1
        Case "ghost":   bg = -1:         fg = clrText2:     ln = -1
        Case Else:      bg = clrSurface: fg = clrText:      ln = clrBorderOn
    End Select

    Set bx = Rect(ws, l, t, w, h, bg, 8, ln)
    Dim tx As Double, tw As Double
    tx = l: tw = w
    If glyph <> "" Then
        Icon ws, l + 12, t, 16, glyph, fg, 11, h
        tx = l + 30: tw = w - 38
        Lbl ws, tx, t, tw, h, caption, 9.5, fg, True, 1
    Else
        Lbl ws, l, t, w, h, caption, 9.5, fg, True, 2
    End If
    HitArea ws, l, t, w, h, action
    Set Btn = bx
End Function

' Botao apenas de icone (quadrado).
Public Function IconBtn(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                        ByVal box As Double, ByVal glyph As String, ByVal action As String, _
                        Optional ByVal kind As String = "secondary") As Shape
    Dim bg As Long, fg As Long, ln As Long
    Select Case LCase$(kind)
        Case "primary": bg = clrAccent: fg = HX(&HFFFFFF): ln = -1
        Case "ghost":   bg = -1:        fg = clrText2:     ln = -1
        Case Else:      bg = clrSurface: fg = clrText2:    ln = clrBorderOn
    End Select
    Set IconBtn = Rect(ws, l, t, box, box, bg, 8, ln)
    Icon ws, l, t, box, glyph, fg, 11, box
    HitArea ws, l, t, box, box, action
End Function

'==============================================================================
' Badge (pilula de status)
'==============================================================================
Public Function Badge(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                      ByVal txt As String, ByVal kind As String, _
                      Optional ByVal minW As Double = 0) As Shape
    Dim bg As Long, fg As Long, w As Double, h As Double
    BadgeColors kind, bg, fg
    h = 22
    w = Len(txt) * 6.1 + 20
    If w < minW Then w = minW
    Rect ws, l, t, w, h, bg, 11, -1
    Set Badge = Lbl(ws, l, t, w, h, txt, 8.5, fg, True, 2)
End Function

' Badge centralizado dentro de uma faixa (para colunas de tabela).
Public Sub BadgeIn(ws As Worksheet, ByVal l As Double, ByVal t As Double, _
                   ByVal w As Double, ByVal h As Double, ByVal txt As String, ByVal kind As String)
    Dim bw As Double
    bw = Len(txt) * 6.1 + 20
    If bw > w Then bw = w
    Badge ws, l, t + (h - 22) / 2, txt, kind
End Sub

'==============================================================================
' Elementos compostos
'==============================================================================
Public Sub HRule(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, _
                 Optional ByVal clr As Long = -2)
    If clr = -2 Then clr = clrBorder
    Rect ws, l, t, w, 1, clr, 0, -1
End Sub

' Barra de progresso fina (consumo de SLA, evolucao fisica...).
Public Sub Progress(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, _
                    ByVal pct As Double, ByVal clr As Long, Optional ByVal h As Double = 6)
    Dim fw As Double
    If pct < 0 Then pct = 0
    If pct > 1 Then pct = 1
    Rect ws, l, t, w, h, clrTrack, h / 2, -1
    fw = w * pct
    If fw > 0 Then
        If fw < h Then fw = h
        Rect ws, l, t, fw, h, clr, h / 2, -1
    End If
End Sub

' Cartao de indicador: rotulo pequeno, numero grande, nota de apoio.
Public Sub KpiCard(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, _
                   ByVal h As Double, ByVal titulo As String, ByVal valor As String, _
                   ByVal nota As String, ByVal notaClr As Long, _
                   Optional ByVal action As String = "", _
                   Optional ByVal accent As Long = -1)
    Card ws, l, t, w, h
    If accent >= 0 Then Rect ws, l, t + 14, 3, h - 28, accent, 2, -1
    Lbl ws, l + 20, t + 16, w - 40, 16, UCase$(titulo), 8, clrMuted, True, 1, FONT_UI, False, 0.6
    Lbl ws, l + 19, t + 32, w - 38, 40, valor, 24, clrText, False, 1, FONT_LIGHT
    Lbl ws, l + 20, t + h - 26, w - 40, 16, nota, 8.5, notaClr, False, 1
    If action <> "" Then HitArea ws, l, t, w, h, action
End Sub

' Cabecalho de secao dentro de um cartao.
Public Sub CardTitle(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, _
                     ByVal titulo As String, Optional ByVal sub_ As String = "")
    Lbl ws, l, t, w, 22, titulo, 11.5, clrText, True, 1
    If sub_ <> "" Then Lbl ws, l, t + 21, w, 16, sub_, 8.5, clrMuted, False, 1
End Sub

' Estado vazio elegante.
Public Sub EmptyState(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, _
                      ByVal h As Double, ByVal titulo As String, ByVal msg As String)
    Icon ws, l + w / 2 - 20, t + h / 2 - 56, 40, ChrW(&HE7C3), clrBorderOn, 22
    Lbl ws, l, t + h / 2 - 14, w, 20, titulo, 11, clrText2, True, 2
    Lbl ws, l, t + h / 2 + 6, w, 18, msg, 9, clrMuted, False, 2
End Sub

'==============================================================================
' Grade de celulas (tabelas e campos)
'==============================================================================
' Define a largura de uma coluna em pixels de projeto, por aproximacao iterativa
' (ColumnWidth e medido em caracteres, nao em pontos).
Public Sub SetColPx(ws As Worksheet, ByVal col As Long, ByVal px As Double)
    Dim alvo As Double, cw As Double, atual As Double, i As Long
    alvo = P(px)
    cw = px / 7#
    If cw < 0.08 Then cw = 0.08
    ws.Columns(col).ColumnWidth = cw
    For i = 1 To 8
        atual = ws.Columns(col).Width
        If atual <= 0 Then Exit For
        If Abs(atual - alvo) < 0.5 Then Exit For
        cw = cw * (alvo / atual)
        If cw < 0.05 Then cw = 0.05
        If cw > 250 Then cw = 250
        ws.Columns(col).ColumnWidth = cw
    Next i
End Sub

Public Sub SetRowPx(ws As Worksheet, ByVal r As Long, ByVal px As Double)
    ws.Rows(r).RowHeight = P(px)
End Sub

' Zera a grade antes de montar uma tela nova.
Public Sub ResetGrid(ws As Worksheet)
    Dim eventosAntes As Boolean
    eventosAntes = Application.EnableEvents
    Application.EnableEvents = False
    On Error Resume Next
    ws.Cells.Validation.Delete
    On Error GoTo 0
    With ws.Cells
        .ClearContents
        .ClearFormats
        .UnMerge
    End With
    ws.Cells.RowHeight = P(6)
    ws.Cells.ColumnWidth = 0.5
    ws.Cells.Font.Name = FONT_UI
    ws.Cells.Font.Size = 10
    ws.Cells.Font.Color = clrText
    ws.Cells.VerticalAlignment = xlCenter
    ws.Cells.Interior.Color = clrCanvas
    Application.EnableEvents = eventosAntes
End Sub
