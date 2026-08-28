Attribute VB_Name = "mBits"
Option Explicit
'==============================================================================
' mBits  -  Pecas visuais reaproveitadas pelas telas de detalhe
'==============================================================================

' Faixa de abas internas (sublinhado no item ativo).
Public Sub TabStrip(ws As Worksheet, ByVal x As Double, ByVal y As Double, _
                    ByVal rotulos As Variant, ByVal chaves As Variant, _
                    ByVal ativa As String, ByVal tela As String, ByVal ctx As String)
    Dim i As Long, xx As Double, w As Double, ativo As Boolean, ch As String
    xx = x
    For i = LBound(rotulos) To UBound(rotulos)
        ch = CStr(chaves(i))
        ativo = (LCase$(ativa) = LCase$(ch)) Or (ativa = "" And i = LBound(rotulos))
        w = Len(CStr(rotulos(i))) * 6.6 + 24
        Lbl ws, xx, y, w, 32, CStr(rotulos(i)), 9.5, IIf(ativo, clrText, clrText2), ativo, 2
        If ativo Then Rect ws, xx, y + 31, w, 2, clrAccent, 1, -1
        HitArea ws, xx, y, w, 32, ActIr(tela, ctx, ch)
        xx = xx + w + 4
    Next i
    HRule ws, x, y + 32, ContentW
End Sub

' Par rotulo/valor empilhado, usado nos cartoes de detalhe.
Public Sub Campo(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                 ByVal rotulo As String, ByVal valor As String, _
                 Optional ByVal clr As Long = -1, Optional ByVal tamanho As Double = 10)
    If clr = -1 Then clr = clrText
    Lbl ws, x, y, w, 14, UCase$(rotulo), 7.5, clrMuted, True, 1
    If valor = "" Then valor = "—"
    Lbl ws, x, y + 15, w, 20, valor, tamanho, clr, False, 1
End Sub

' Linha do tempo vertical das etapas.
Public Sub Timeline(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                    ByVal etapas As Variant, ByVal datas As Variant, ByVal estados As Variant, _
                    ByVal notas As Variant, ByVal n As Long)
    Dim i As Long, yy As Double, clr As Long, passo As Double
    passo = 52
    yy = y
    For i = 1 To n
        Select Case UCase$(CStr(estados(i)))
            Case "CONCLUÍDA", "CONCLUIDA": clr = clrOk
            Case "EM ANDAMENTO":           clr = clrAccent
            Case "ATRASADA":               clr = clrDanger
            Case Else:                     clr = clrBorderOn
        End Select

        If i < n Then Rect ws, x + 6, yy + 20, 2, passo - 8, clrBorder, 0, -1
        Rect ws, x, yy + 12, 14, 14, clrSurface, 7, clr
        Rect ws, x + 4, yy + 16, 6, 6, clr, 3, -1

        Lbl ws, x + 28, yy + 6, w - 200, 18, CStr(etapas(i)), 9.5, clrText, True, 1
        Lbl ws, x + 28, yy + 23, w - 200, 16, CStr(notas(i)), 8.5, clrMuted, False, 1
        Lbl ws, x + w - 168, yy + 6, 168, 32, CStr(datas(i)), 8.5, clrText2, False, 3
        yy = yy + passo
    Next i
End Sub

' Bloco "numero grande + rotulo", em linha.
Public Sub MiniStat(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                    ByVal valor As String, ByVal rotulo As String, Optional ByVal clr As Long = -1)
    If clr = -1 Then clr = clrText
    Lbl ws, x, y, w, 34, valor, 18, clr, False, 1, FONT_LIGHT
    Lbl ws, x, y + 32, w, 16, UCase$(rotulo), 7.5, clrMuted, True, 1
End Sub

' Cabecalho de uma tela de detalhe: titulo grande, badges e acoes a direita.
Public Sub DetailHeader(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                        ByVal titulo As String, ByVal subtitulo As String, _
                        ByVal badge1 As String, ByVal badge2 As String)
    Dim bx As Double
    Lbl ws, x, y, w * 0.62, 28, titulo, 17, clrText, False, 1, FONT_LIGHT
    Lbl ws, x, y + 28, w * 0.62, 16, subtitulo, 9, clrMuted, False, 1
    bx = x
    If badge1 <> "" Then bx = bx + Len(badge1) * 6.1 + 28: Badge ws, x, y + 48, badge1, SituacaoKind(badge1)
    If badge2 <> "" Then Badge ws, bx, y + 48, badge2, SituacaoKind(badge2)
End Sub
