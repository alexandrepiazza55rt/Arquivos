Attribute VB_Name = "scrCheckup"
Option Explicit
'==============================================================================
' scrCheckup  -  Verificacoes de consistencia antes de apresentar os numeros
'==============================================================================

Public Sub CheckupRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim vs As Worksheet, r As Long, ult As Long
    Dim total As Long, comOcorrencia As Long

    Set ws = Canvas()
    x = ContentX: w = ContentW
    Set vs = Sh(SH_VERIF)

    y = RenderShell("Consistência", "Tudo precisa estar zerado antes de levar os números para a reunião")

    ult = vs.Cells(vs.Rows.Count, 1).End(xlUp).Row
    For r = FIRST_ROW To ult
        If SVal(vs.Cells(r, 1).Value) <> "" Then
            total = total + 1
            If NVal(vs.Cells(r, 2).Value) > 0 Then comOcorrencia = comOcorrencia + 1
        End If
    Next r

    ' cartao de resumo
    Dim ok As Boolean
    ok = (comOcorrencia = 0)
    Card ws, x, y, w, 96
    Rect ws, x + 24, y + 24, 48, 48, IIf(ok, clrOkSoft, clrDangerSoft), 12, -1
    Icon ws, x + 24, y + 24, 48, IIf(ok, IC_OK, IC_CHECKUP), IIf(ok, clrOk, clrDanger), 18
    Lbl ws, x + 88, y + 26, w - 300, 24, _
        IIf(ok, "Base consistente", CStr(comOcorrencia) & " verificação(ões) com ocorrência"), _
        14, clrText, True, 1
    Lbl ws, x + 88, y + 50, w - 300, 20, _
        IIf(ok, "As " & total & " verificações passaram. Os números podem ser apresentados.", _
                "Corrija os pontos abaixo antes de divulgar os indicadores."), 9.5, clrText2, False, 1
    Btn ws, x + w - 180, y + 29, 156, 38, "Recalcular tudo", ActProc("RecalcularTudo"), "secondary", IC_REFRESH

    y = y + 96 + GAP

    '--- lista das verificacoes ---------------------------------------------
    Dim cw As Double, cx As Double, cy As Double, col As Long, hcard As Double
    cw = (w - GAP) / 2
    hcard = 92
    col = 0
    cy = y

    For r = FIRST_ROW To ult
        If SVal(vs.Cells(r, 1).Value) <> "" Then
            If cy + hcard > ViewH - 20 Then Exit For
            cx = x + col * (cw + GAP)

            Dim oc As Long, bg As Long, fg As Long
            oc = CLng(NVal(vs.Cells(r, 2).Value))
            If oc = 0 Then bg = clrOkSoft: fg = clrOk Else bg = clrDangerSoft: fg = clrDanger

            Card ws, cx, cy, cw, hcard
            Rect ws, cx + 18, cy + 18, 34, 34, bg, 9, -1
            Lbl ws, cx + 18, cy + 18, 34, 34, CStr(oc), 12, fg, True, 2
            Lbl ws, cx + 64, cy + 18, cw - 84, 18, SVal(vs.Cells(r, 1).Value), 10, clrText, True, 1
            Lbl ws, cx + 64, cy + 38, cw - 84, 34, SVal(vs.Cells(r, 3).Value), 8.5, clrMuted, False, 1, FONT_UI, True

            col = col + 1
            If col > 1 Then col = 0: cy = cy + hcard + GAP
        End If
    Next r
End Sub

Public Sub RecalcularTudo()
    Application.StatusBar = "Recalculando..."
    Recalcular
    Application.StatusBar = False
    Aviso "Pasta recalculada.", "OK"
    Recarregar
End Sub
