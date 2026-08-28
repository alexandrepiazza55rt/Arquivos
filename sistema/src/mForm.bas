Attribute VB_Name = "mForm"
Option Explicit
'==============================================================================
' mForm  -  Formularios de digitacao
'
' Os campos sao celulas desbloqueadas (com validacao, mascara e listas nativas
' do Excel) desenhadas dentro do layout do sistema. O mapa "chave do campo ->
' endereco da celula" fica gravado numa area escondida da propria folha, de modo
' que gravar o registro depois nunca depende de variaveis em memoria.
'==============================================================================

Private Const REG_COL_KEY  As Long = 40    ' AN
Private Const REG_COL_ADDR As Long = 41    ' AO
Private Const REG_LIN0     As Long = 1

Private fX As Double, fY As Double, fW As Double
Private fCols As Long, fPad As Double
Private fColW As Double, fGap As Double
Private fSlot As Long          ' proxima coluna livre da linha atual (0-based)
Private fLblH As Double, fInH As Double, fGapH As Double, fSecH As Double
Private fRowLbl As Long        ' linha de celula do rotulo atual
Private fCount As Long         ' quantos campos ja registrados

'==============================================================================
Public Sub FormBegin(ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                     Optional ByVal cols As Long = 2, Optional ByVal pad As Double = 24)
    Dim ws As Worksheet, j As Long
    Set ws = Canvas()

    fX = x: fY = y: fW = w: fCols = cols: fPad = pad
    fGap = 20
    fLblH = 18: fInH = 34: fGapH = 14: fSecH = 30
    fColW = (w - pad * 2 - fGap * (cols - 1)) / cols
    fSlot = 0
    fCount = 0
    fRowLbl = 2

    ' limpa o registro de campos
    ws.Range(ws.Cells(REG_LIN0, REG_COL_KEY), ws.Cells(REG_LIN0 + 80, REG_COL_ADDR)).ClearContents

    ' colunas: 1 = deslocamento; depois campo/intervalo alternados
    SetColPx ws, 1, x + pad
    For j = 1 To cols
        SetColPx ws, 1 + (j - 1) * 2 + 1, fColW
        If j < cols Then SetColPx ws, 1 + (j - 1) * 2 + 2, fGap
    Next j
    SetColPx ws, 1 + cols * 2, 40

    SetRowPx ws, 1, IIf(y < 1, 1, y)
End Sub

' Cria um campo. tipo: texto | numero | data | lista | leitura | area
' Devolve a chave (mesma que foi passada) por conveniencia.
Public Function FormField(ByVal chave As String, ByVal rotulo As String, ByVal valor As String, _
                          Optional ByVal tipo As String = "texto", _
                          Optional ByVal lista As Variant, _
                          Optional ByVal span As Long = 1, _
                          Optional ByVal ajuda As String = "") As String
    Dim ws As Worksheet, c1 As Long, c2 As Long, rgLbl As Range, rgIn As Range
    Set ws = Canvas()

    If fSlot + span > fCols Then NovaLinha
    If fRowLbl = 2 And fSlot = 0 Then PrepararLinha

    c1 = 1 + fSlot * 2 + 1
    c2 = c1 + (span - 1) * 2

    Set rgLbl = ws.Range(ws.Cells(fRowLbl, c1), ws.Cells(fRowLbl, c2))
    Set rgIn = ws.Range(ws.Cells(fRowLbl + 1, c1), ws.Cells(fRowLbl + 1, c2))
    If c2 > c1 Then
        rgLbl.Merge
        rgIn.Merge
    End If

    With rgLbl
        .Value = UCase$(rotulo)
        .Font.Name = FONT_UI
        .Font.Size = 7.5
        .Font.Bold = True
        .Font.Color = clrMuted
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlBottom
        .Interior.Color = clrSurface
    End With

    With rgIn
        .Interior.Color = IIf(tipo = "leitura", clrSurfaceAlt, clrSurface)
        .Font.Name = FONT_UI
        .Font.Size = 10
        .Font.Color = IIf(tipo = "leitura", clrText2, clrText)
        .HorizontalAlignment = xlLeft
        .VerticalAlignment = xlCenter
        .IndentLevel = 1
        .Locked = (tipo = "leitura")
        .Borders.LineStyle = xlContinuous
        .Borders.Weight = xlThin
        .Borders.Color = clrBorderOn
        Select Case tipo
            Case "numero":  .NumberFormat = "0.##"
            Case "data":    .NumberFormat = "dd/mm/yyyy"
            Case Else:      .NumberFormat = "@"
        End Select
        If valor <> "" Then
            If tipo = "data" And IsDate(valor) Then
                .Value = CDate(valor)
            ElseIf tipo = "numero" And IsNumeric(valor) Then
                .Value = CDbl(valor)
            Else
                .Value = valor
            End If
        Else
            .ClearContents
        End If
        If tipo = "lista" Then
            AplicarLista rgIn, lista
        End If
    End With

    If ajuda <> "" Then
        Lbl ws, fX + fPad + fSlot * (fColW + fGap), _
            fY + AlturaAteLinha(fRowLbl) + fLblH + fInH, _
            fColW * span + fGap * (span - 1), 14, ajuda, 8, clrMuted, False, 1
    End If

    fCount = fCount + 1
    ws.Cells(REG_LIN0 + fCount, REG_COL_KEY).Value = chave
    ws.Cells(REG_LIN0 + fCount, REG_COL_ADDR).Value = rgIn.Cells(1, 1).Address(False, False)

    fSlot = fSlot + span
    FormField = chave
End Function

Private Sub PrepararLinha()
    Dim ws As Worksheet
    Set ws = Canvas()
    SetRowPx ws, fRowLbl, fLblH
    SetRowPx ws, fRowLbl + 1, fInH
    SetRowPx ws, fRowLbl + 2, fGapH
    PintarFundoLinha
End Sub

' Reduz as alturas para caber formularios longos numa tela so.
' Deve ser chamado logo depois de FormBegin.
Public Sub FormCompacto()
    fLblH = 15: fInH = 30: fGapH = 9: fSecH = 24
    SetRowPx Canvas(), fRowLbl, fLblH
    SetRowPx Canvas(), fRowLbl + 1, fInH
    SetRowPx Canvas(), fRowLbl + 2, fGapH
End Sub

Private Sub NovaLinha()
    fRowLbl = fRowLbl + 3
    fSlot = 0
    PrepararLinha
End Sub

' Pinta o fundo branco do cartao atras da linha de campos.
Private Sub PintarFundoLinha()
    Dim ws As Worksheet
    Set ws = Canvas()
    ws.Range(ws.Cells(fRowLbl, 1), ws.Cells(fRowLbl + 2, 1 + fCols * 2)).Interior.Color = clrSurface
End Sub

Private Function AlturaAteLinha(ByVal r As Long) As Double
    Dim ws As Worksheet, i As Long, s As Double
    Set ws = Canvas()
    For i = 2 To r - 1
        s = s + PxFromPt(ws.Rows(i).RowHeight)
    Next i
    AlturaAteLinha = s
End Function

' Altura total ocupada pelo formulario, em px (para posicionar o rodape).
Public Function FormHeight() As Double
    Dim ws As Worksheet, i As Long, s As Double
    Set ws = Canvas()
    For i = 2 To fRowLbl + 2
        s = s + PxFromPt(ws.Rows(i).RowHeight)
    Next i
    FormHeight = s
End Function

Public Function FormBottom() As Double
    FormBottom = fY + FormHeight()
End Function

Private Sub AplicarLista(rg As Range, ByVal lista As Variant)
    Dim s As String, i As Long
    If IsMissing(lista) Then Exit Sub
    If Not IsArray(lista) Then Exit Sub
    On Error Resume Next
    For i = LBound(lista) To UBound(lista)
        If Len(s) + Len(CStr(lista(i))) + 1 > 250 Then Exit For
        s = s & IIf(s = "", "", ",") & Replace(CStr(lista(i)), ",", " ")
    Next i
    On Error GoTo 0
    If s = "" Then Exit Sub
    With rg.Validation
        .Delete
        .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, Operator:=xlBetween, Formula1:=s
        .IgnoreBlank = True
        .InCellDropdown = True
        .ShowInput = False
        .ShowError = False
    End With
End Sub

' Listas longas nao cabem em Formula1; nesse caso apontamos para um intervalo.
Public Sub FormListaDeIntervalo(ByVal chave As String, ByVal formulaIntervalo As String)
    Dim ws As Worksheet, rg As Range
    Set ws = Canvas()
    Set rg = CelulaDoCampo(chave)
    If rg Is Nothing Then Exit Sub
    On Error Resume Next
    With rg.Validation
        .Delete
        .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, Operator:=xlBetween, Formula1:=formulaIntervalo
        .IgnoreBlank = True
        .InCellDropdown = True
        .ShowInput = False
        .ShowError = False
    End With
    On Error GoTo 0
End Sub

'==============================================================================
' Leitura dos valores digitados
'==============================================================================
Public Function CelulaDoCampo(ByVal chave As String) As Range
    Dim ws As Worksheet, i As Long
    Set ws = Canvas()
    For i = REG_LIN0 + 1 To REG_LIN0 + 80
        If Trim$(CStr(ws.Cells(i, REG_COL_KEY).Value)) = chave Then
            Set CelulaDoCampo = ws.Range(CStr(ws.Cells(i, REG_COL_ADDR).Value))
            Exit Function
        End If
    Next i
End Function

Public Function FormValor(ByVal chave As String) As String
    Dim rg As Range
    Set rg = CelulaDoCampo(chave)
    If rg Is Nothing Then Exit Function
    If IsDate(rg.Value) Then
        FormValor = Format$(rg.Value, "dd/mm/yyyy")
    Else
        FormValor = Trim$(CStr(rg.Value & ""))
    End If
End Function

Public Function FormNum(ByVal chave As String) As Double
    Dim rg As Range
    Set rg = CelulaDoCampo(chave)
    If rg Is Nothing Then Exit Function
    If IsNumeric(rg.Value) Then FormNum = CDbl(rg.Value)
End Function

Public Function FormData(ByVal chave As String) As Variant
    Dim rg As Range
    Set rg = CelulaDoCampo(chave)
    If rg Is Nothing Then Exit Function
    If IsDate(rg.Value) Then FormData = CDate(rg.Value) Else FormData = Empty
End Function

Public Function FormVazio(ByVal chave As String) As Boolean
    FormVazio = (FormValor(chave) = "")
End Function

'==============================================================================
' Rodape padrao do formulario
'==============================================================================
Public Sub FormFooter(ByVal y As Double, ByVal acaoSalvar As String, ByVal acaoCancelar As String, _
                      Optional ByVal textoSalvar As String = "Salvar", _
                      Optional ByVal acaoExcluir As String = "")
    Dim ws As Worksheet, x As Double, w As Double
    Set ws = Canvas()
    x = ContentX: w = ContentW
    ' nunca deixa os botoes fora da janela visivel
    If y + 62 > ViewH Then y = ViewH - 62
    HRule ws, x, y, w
    Btn ws, x + w - 132, y + 18, 132, 38, textoSalvar, acaoSalvar, "primary", IC_SAVE
    Btn ws, x + w - 132 - 110, y + 18, 100, 38, "Cancelar", acaoCancelar, "secondary"
    If acaoExcluir <> "" Then
        Btn ws, x, y + 18, 110, 38, "Excluir", acaoExcluir, "secondary", IC_DEL
    End If
End Sub

'==============================================================================
' Rascunho
'
' Quando o usuario sai do formulario para escolher um item numa lista maior, o
' que ja foi digitado e guardado na folha de apoio _APP (que nao e redesenhada)
' e devolvido quando o formulario volta a ser montado.
'==============================================================================
Public Sub RascunhoSalvar()
    Dim ws As Worksheet, sy As Worksheet, i As Long, n As Long, chave As String
    Set ws = Canvas()
    Set sy = SysSheet()
    RascunhoLimpar
    For i = REG_LIN0 + 1 To REG_LIN0 + 80
        chave = Trim$(CStr(ws.Cells(i, REG_COL_KEY).Value))
        If chave = "" Then Exit For
        n = n + 1
        sy.Cells(n, 1).Value = chave
        sy.Cells(n, 2).Value = FormValor(chave)
    Next i
End Sub

Public Sub RascunhoGravar(ByVal chave As String, ByVal valor As String)
    Dim sy As Worksheet, i As Long
    Set sy = SysSheet()
    For i = 1 To 80
        If Trim$(CStr(sy.Cells(i, 1).Value)) = chave Then
            sy.Cells(i, 2).Value = valor
            Exit Sub
        End If
        If Trim$(CStr(sy.Cells(i, 1).Value)) = "" Then
            sy.Cells(i, 1).Value = chave
            sy.Cells(i, 2).Value = valor
            Exit Sub
        End If
    Next i
End Sub

Public Function RascunhoValor(ByVal chave As String, Optional ByVal padrao As String = "") As String
    Dim sy As Worksheet, i As Long
    Set sy = SysSheet()
    For i = 1 To 80
        If Trim$(CStr(sy.Cells(i, 1).Value)) = chave Then
            RascunhoValor = Trim$(CStr(sy.Cells(i, 2).Value & ""))
            Exit Function
        End If
    Next i
    RascunhoValor = padrao
End Function

Public Function RascunhoAtivo() As Boolean
    RascunhoAtivo = (Trim$(CStr(SysSheet().Cells(1, 1).Value)) <> "")
End Function

Public Sub RascunhoLimpar()
    Dim sy As Worksheet
    Set sy = SysSheet()
    sy.Range(sy.Cells(1, 1), sy.Cells(80, 2)).ClearContents
End Sub

'==============================================================================
' Titulo de secao dentro do formulario
'==============================================================================
Public Sub FormSection(ByVal titulo As String, Optional ByVal descricao As String = "")
    Dim ws As Worksheet, yy As Double
    Set ws = Canvas()

    If fCount > 0 Then
        fRowLbl = fRowLbl + 3
        fSlot = 0
    End If

    SetRowPx ws, fRowLbl, fSecH
    SetRowPx ws, fRowLbl + 1, 20
    SetRowPx ws, fRowLbl + 2, 4
    ws.Range(ws.Cells(fRowLbl, 1), ws.Cells(fRowLbl + 2, 1 + fCols * 2)).Interior.Color = clrSurface

    yy = fY + AlturaAteLinhaPub(fRowLbl)
    Lbl ws, fX + fPad, yy + 6, fW - fPad * 2, 18, titulo, 10.5, clrText, True, 1
    If descricao <> "" Then
        Lbl ws, fX + fPad, yy + fSecH - 2, fW - fPad * 2, 16, descricao, 8.5, clrMuted, False, 1
    End If
    HRule ws, fX + fPad, yy + fSecH + 20, fW - fPad * 2

    fRowLbl = fRowLbl + 3
    fSlot = 0
    SetRowPx ws, fRowLbl, fLblH
    SetRowPx ws, fRowLbl + 1, fInH
    SetRowPx ws, fRowLbl + 2, fGapH
    ws.Range(ws.Cells(fRowLbl, 1), ws.Cells(fRowLbl + 2, 1 + fCols * 2)).Interior.Color = clrSurface
End Sub

Public Function AlturaAteLinhaPub(ByVal r As Long) As Double
    AlturaAteLinhaPub = AlturaAteLinha(r)
End Function
