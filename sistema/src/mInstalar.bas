Attribute VB_Name = "mInstalar"
Option Explicit
'==============================================================================
' mInstalar  -  Preparacao da pasta e tela de abertura
'
' Rode InstalarSistema UMA VEZ depois de importar os modulos. Ela cria a folha
' SISTEMA, a folha de apoio _APP e desenha a tela de abertura que fica gravada
' no arquivo (e o que aparece quando as macros ainda nao foram habilitadas).
'==============================================================================

Private Const HOME As String = "home_"

' Executada em toda abertura: cria o que faltar, sem incomodar o usuario.
' Na primeira vez ela e a propria instalacao; nas seguintes nao faz nada.
Public Sub GarantirInstalacao()
    Dim ws As Worksheet, i As Long, temHome As Boolean
    On Error Resume Next

    Set ws = Canvas()
    SysSheet

    If ws.Index <> 1 Then ws.Move Before:=ThisWorkbook.Worksheets(1)

    For i = 1 To ws.Shapes.Count
        If Left$(ws.Shapes(i).Name, Len(HOME)) = HOME Then temHome = True: Exit For
    Next i
    If Not temHome Then
        ws.Unprotect
        ResetGrid ws
        DesenharTelaInicial
    End If

    If Application.Calculation <> xlCalculationAutomatic Then
        Application.Calculation = xlCalculationAutomatic
    End If
    On Error GoTo 0
End Sub

Public Sub InstalarSistema()
    Dim ws As Worksheet

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationAutomatic

    Set ws = Canvas()
    ws.Move Before:=ThisWorkbook.Worksheets(1)
    SysSheet

    ws.Unprotect
    ClearUI ws
    ResetGrid ws
    DesenharTelaInicial
    ws.Activate
    ws.Range("A1").Select

    Application.ScreenUpdating = True

    MsgBox "Sistema instalado nesta pasta." & vbCrLf & vbCrLf & _
           "1. Salve o arquivo como Pasta de Trabalho Habilitada para Macro (.xlsm)." & vbCrLf & _
           "2. Feche e abra novamente: o sistema passa a abrir sozinho." & vbCrLf & vbCrLf & _
           "Para abrir agora, clique em ABRIR SISTEMA.", vbInformation, APP_NOME
End Sub

'==============================================================================
' Tela de abertura (permanente, gravada no arquivo)
'==============================================================================
Public Sub DesenharTelaInicial()
    Dim ws As Worksheet, i As Long
    Dim cx As Double, cy As Double, cw As Double, chh As Double
    Set ws = Canvas()

    ' remove versoes anteriores
    On Error Resume Next
    For i = ws.Shapes.Count To 1 Step -1
        If Left$(ws.Shapes(i).Name, Len(HOME)) = HOME Then ws.Shapes(i).Delete
    Next i
    On Error GoTo 0

    cw = 620: chh = 340
    cx = (1280 - cw) / 2
    cy = 120

    HomeRect ws, 0, 0, 1600, 900, clrCanvas, 0
    HomeCard ws, cx, cy, cw, chh

    HomeRect ws, cx + 48, cy + 48, 52, 52, clrAccent, 14
    HomeLbl ws, cx + 48, cy + 48, 52, 52, ChrW(&HE72E), 20, HX(&HFFFFFF), False, 2, FONT_ICON

    HomeLbl ws, cx + 116, cy + 46, cw - 160, 36, "Monitoramento Patrimonial", 20, clrText, False, 1, FONT_LIGHT
    HomeLbl ws, cx + 116, cy + 80, cw - 160, 22, "Controle de projetos, compras, entregas e conferências", 10, clrMuted, False, 1

    HomeRect ws, cx + 48, cy + 128, cw - 96, 1, clrBorder, 0

    HomeLbl ws, cx + 48, cy + 150, cw - 96, 22, _
        "Este arquivo abre um sistema completo dentro do Excel.", 11, clrText, False, 1
    HomeLbl ws, cx + 48, cy + 174, cw - 96, 40, _
        "Se a faixa amarela de segurança aparecer no topo, clique em " & _
        "“Habilitar conteúdo” e depois no botão abaixo.", 9.5, clrText2, False, 1, FONT_UI, True

    ' botao principal
    HomeRect ws, cx + 48, cy + 236, 210, 48, clrAccent, 10
    HomeLbl ws, cx + 48, cy + 236, 210, 48, "ABRIR SISTEMA", 11, HX(&HFFFFFF), True, 2
    Dim hit As Shape
    Set hit = ws.Shapes.AddShape(msoShapeRectangle, P(cx + 48), P(cy + 236), P(210), P(48))
    hit.Name = HOME & "btn"
    hit.Fill.Visible = msoTrue
    hit.Fill.ForeColor.RGB = clrAccent
    hit.Fill.Transparency = 1
    hit.Line.Visible = msoFalse
    hit.Shadow.Visible = msoFalse
    hit.OnAction = "IniciarSistema"

    HomeLbl ws, cx + 276, cy + 236, cw - 324, 48, _
        "Ctrl+Shift+E devolve o Excel ao modo normal a qualquer momento.", 9, clrMuted, False, 1, FONT_UI, True

    HomeLbl ws, cx, cy + chh + 20, cw, 20, APP_NOME & "  ·  versão " & APP_VER, 8.5, clrMuted, False, 2
End Sub

Public Sub EsconderTelaInicial()
    AlternarHome False
End Sub

Public Sub MostrarTelaInicial()
    AlternarHome True
End Sub

Private Sub AlternarHome(ByVal visivel As Boolean)
    Dim ws As Worksheet, i As Long
    Set ws = Canvas()
    On Error Resume Next
    For i = 1 To ws.Shapes.Count
        If Left$(ws.Shapes(i).Name, Len(HOME)) = HOME Then
            ws.Shapes(i).Visible = IIf(visivel, msoTrue, msoFalse)
        End If
    Next i
    On Error GoTo 0
End Sub

' Chamado antes de salvar: o arquivo e gravado sempre na tela de abertura.
Public Sub PrepararParaSalvar()
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = Canvas()
    ws.Unprotect
    ClearUI ws
    ResetGrid ws
    MostrarTelaInicial
    On Error GoTo 0
End Sub

'==============================================================================
' Primitivas com prefixo proprio (nao sao apagadas pelo ClearUI)
'==============================================================================
Private Function HomeRect(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, _
                          ByVal h As Double, ByVal fillClr As Long, ByVal radius As Double) As Shape
    Dim s As Shape, tipo As Long
    If radius > 0 Then tipo = msoShapeRoundedRectangle Else tipo = msoShapeRectangle
    Set s = ws.Shapes.AddShape(tipo, P(l), P(t), P(w), P(h))
    s.Name = HOME & ws.Shapes.Count
    If radius > 0 Then
        Dim mn As Double
        mn = w: If h < mn Then mn = h
        On Error Resume Next
        s.Adjustments(1) = radius / mn
        On Error GoTo 0
    End If
    s.Fill.Visible = msoTrue
    s.Fill.Solid
    s.Fill.ForeColor.RGB = fillClr
    s.Line.Visible = msoFalse
    s.Shadow.Visible = msoFalse
    s.TextFrame2.TextRange.Text = ""
    Set HomeRect = s
End Function

Private Sub HomeCard(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, ByVal h As Double)
    Dim s As Shape
    Set s = HomeRect(ws, l, t, w, h, clrSurface, 16)
    s.Line.Visible = msoTrue
    s.Line.ForeColor.RGB = clrBorder
    s.Line.Weight = 0.75
End Sub

Private Sub HomeLbl(ws As Worksheet, ByVal l As Double, ByVal t As Double, ByVal w As Double, _
                    ByVal h As Double, ByVal txt As String, ByVal size As Double, ByVal clr As Long, _
                    Optional ByVal bold As Boolean = False, Optional ByVal align As Long = 1, _
                    Optional ByVal fonte As String = FONT_UI, Optional ByVal wrap As Boolean = False)
    Dim s As Shape
    Set s = ws.Shapes.AddShape(msoShapeRectangle, P(l), P(t), P(w), P(h))
    s.Name = HOME & "t" & ws.Shapes.Count
    s.Fill.Visible = msoFalse
    s.Line.Visible = msoFalse
    s.Shadow.Visible = msoFalse
    With s.TextFrame2
        .MarginLeft = 0: .MarginRight = 0: .MarginTop = 0: .MarginBottom = 0
        .VerticalAnchor = msoAnchorMiddle
        .WordWrap = IIf(wrap, msoTrue, msoFalse)
        .TextRange.Text = txt
        With .TextRange.Font
            .Name = fonte
            .NameFarEast = fonte
            .Size = size
            .Bold = IIf(bold, msoTrue, msoFalse)
            .Fill.Visible = msoTrue
            .Fill.ForeColor.RGB = clr
        End With
        Select Case align
            Case 2: .TextRange.ParagraphFormat.Alignment = msoAlignCenter
            Case 3: .TextRange.ParagraphFormat.Alignment = msoAlignRight
            Case Else: .TextRange.ParagraphFormat.Alignment = msoAlignLeft
        End Select
    End With
End Sub
