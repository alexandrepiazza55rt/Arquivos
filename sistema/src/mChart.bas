Attribute VB_Name = "mChart"
Option Explicit
'==============================================================================
' mChart  -  Graficos desenhados com formas
'
' Nao usamos objetos de grafico do Excel: eles trazem molduras, fontes e cores
' proprias que destoam do restante. Barras desenhadas dao controle total.
'==============================================================================

' Lista de barras horizontais: rotulo a esquerda, trilho, barra, valor a direita.
Public Sub BarList(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                   ByVal rotulos As Variant, ByVal valores As Variant, _
                   Optional ByVal cores As Variant, Optional ByVal maxItens As Long = 8, _
                   Optional ByVal larguraRotulo As Double = 150)
    Dim i As Long, n As Long, maxV As Double, yy As Double
    Dim trilhoX As Double, trilhoW As Double, clr As Long

    If Not IsArray(rotulos) Then Exit Sub
    On Error Resume Next
    n = UBound(rotulos) - LBound(rotulos) + 1
    On Error GoTo 0
    If n = 0 Then Exit Sub
    If n > maxItens Then n = maxItens

    For i = 0 To n - 1
        If NVal(valores(LBound(valores) + i)) > maxV Then maxV = NVal(valores(LBound(valores) + i))
    Next i
    If maxV <= 0 Then maxV = 1

    trilhoX = x + larguraRotulo
    trilhoW = w - larguraRotulo - 52

    yy = y
    For i = 0 To n - 1
        Dim v As Double, txt As String
        v = NVal(valores(LBound(valores) + i))
        txt = CStr(rotulos(LBound(rotulos) + i))
        If Len(txt) > 26 Then txt = Left$(txt, 24) & "…"

        Lbl ws, x, yy, larguraRotulo - 10, 20, txt, 9, clrText2, False, 1
        Rect ws, trilhoX, yy + 7, trilhoW, 8, clrTrack, 4, -1

        clr = clrAccent
        If IsArray(cores) Then
            On Error Resume Next
            clr = CLng(cores(LBound(cores) + i))
            On Error GoTo 0
        End If

        Dim bw As Double
        bw = trilhoW * (v / maxV)
        If v > 0 And bw < 8 Then bw = 8
        If bw > 0 Then Rect ws, trilhoX, yy + 7, bw, 8, clr, 4, -1

        Lbl ws, trilhoX + trilhoW + 8, yy, 44, 20, Format$(v, "#,##0"), 9.5, clrText, True, 3
        yy = yy + 26
    Next i
End Sub

' Barra unica dividida em segmentos + legenda embaixo.
Public Sub SegmentBar(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                      ByVal rotulos As Variant, ByVal valores As Variant, ByVal cores As Variant, _
                      Optional ByVal h As Double = 12)
    Dim i As Long, n As Long, total As Double, xx As Double, seg As Double
    On Error Resume Next
    n = UBound(valores) - LBound(valores) + 1
    On Error GoTo 0
    If n = 0 Then Exit Sub

    For i = 0 To n - 1
        total = total + NVal(valores(LBound(valores) + i))
    Next i

    Rect ws, x, y, w, h, clrTrack, h / 2, -1
    If total <= 0 Then Exit Sub

    xx = x
    For i = 0 To n - 1
        seg = w * (NVal(valores(LBound(valores) + i)) / total)
        If seg > 0.5 Then
            Rect ws, xx, y, seg, h, CLng(cores(LBound(cores) + i)), IIf(seg < h, seg / 2, h / 2), -1
        End If
        xx = xx + seg
    Next i

    ' legenda
    Dim ly As Double, lx As Double
    ly = y + h + 16
    lx = x
    For i = 0 To n - 1
        Dim t As String, lw As Double
        t = CStr(rotulos(LBound(rotulos) + i)) & "  " & Format$(NVal(valores(LBound(valores) + i)), "#,##0")
        lw = Len(t) * 5.9 + 26
        If lx + lw > x + w Then
            lx = x: ly = ly + 22
        End If
        Rect ws, lx, ly + 6, 8, 8, CLng(cores(LBound(cores) + i)), 4, -1
        Lbl ws, lx + 14, ly, lw - 14, 20, t, 8.5, clrText2, False, 1
        lx = lx + lw
    Next i
End Sub

' Medidor circular simplificado: arco em barra grossa com percentual no centro.
Public Sub Gauge(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                 ByVal pct As Double, ByVal titulo As String)
    Dim clr As Long
    If pct >= LimRisco Then
        clr = clrDanger
    ElseIf pct >= LimAtencao Then
        clr = clrWarn
    Else
        clr = clrOk
    End If
    Lbl ws, x, y, w * 0.6, 20, titulo, 9, clrText2, False, 1
    Lbl ws, x + w * 0.6, y, w * 0.4, 20, Format$(pct, "0%"), 10, clr, True, 3
    Progress ws, x, y + 24, w, pct, clr, 8
End Sub
