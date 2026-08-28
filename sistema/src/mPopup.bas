Attribute VB_Name = "mPopup"
Option Explicit
'==============================================================================
' mPopup  -  Seletor sobreposto (o "dropdown" do sistema)
'
' Desenha um painel centralizado por cima da tela atual, sem redesenhar nada.
' Ao escolher uma opcao, chama o procedimento informado passando o valor.
' Clicar fora fecha (apenas redesenha a tela).
'==============================================================================

Private Const MAX_COL As Long = 13

Public Sub Popup(ByVal titulo As String, ByVal opcoes As Variant, ByVal proc As String, _
                 Optional ByVal atual As String = "")
    Dim ws As Worksheet, n As Long, i As Long
    Dim cols As Long, porCol As Long, pw As Double, ph As Double, px As Double, py As Double

    Set ws = Canvas()
    If Not IsArray(opcoes) Then Exit Sub
    On Error Resume Next
    n = UBound(opcoes) - LBound(opcoes) + 1
    On Error GoTo 0
    If n = 0 Then Exit Sub

    ' listas muito longas: cai para digitacao
    If n > MAX_COL * 2 Then
        Dim r As Variant
        r = InputBox(titulo & vbCrLf & vbCrLf & "Digite o valor exatamente como esta cadastrado.", _
                     APP_NOME, atual)
        If StrPtr(r) = 0 Then Exit Sub
        Application.Run proc, CStr(r)
        Exit Sub
    End If

    If n > MAX_COL Then cols = 2 Else cols = 1
    porCol = -Int(-n / cols)

    pw = IIf(cols = 2, 620, 360)
    ph = 62 + porCol * 38 + 16

    px = (ViewW - pw) / 2
    py = (ViewH - ph) / 2
    If py < 40 Then py = 40

    ' fundo escurecido, clicavel para fechar
    Dim bd As Shape
    Set bd = Rect(ws, 0, 0, ViewW, ViewH, HX(&H0B0F14), 0, -1)
    bd.Fill.Transparency = 0.62
    bd.OnAction = ActProc("Recarregar")

    Card ws, px, py, pw, ph
    Lbl ws, px + 20, py + 16, pw - 60, 22, titulo, 11.5, clrText, True, 1
    IconBtn ws, px + pw - 40, py + 14, 26, IC_CLOSE, ActProc("Recarregar"), "ghost"
    HRule ws, px + 16, py + 50, pw - 32

    Dim colW As Double
    colW = (pw - 32 - IIf(cols = 2, 12, 0)) / cols

    For i = 0 To n - 1
        Dim c As Long, l As Long, ix As Double, iy As Double, v As String
        c = i \ porCol
        l = i Mod porCol
        ix = px + 16 + c * (colW + 12)
        iy = py + 62 + l * 38
        v = CStr(opcoes(LBound(opcoes) + i))

        If UCase$(v) = UCase$(atual) Then
            Rect ws, ix, iy, colW, 34, clrAccentSoft, 8, -1
            Lbl ws, ix + 12, iy, colW - 44, 34, v, 9.5, clrAccent, True, 1
            Icon ws, ix + colW - 30, iy, 20, IC_OK, clrAccent, 10
        Else
            Lbl ws, ix + 12, iy, colW - 24, 34, v, 9.5, clrText, False, 1
        End If
        HitArea ws, ix, iy, colW, 34, ActProc1(proc, v)
    Next i
End Sub

'==============================================================================
' Seletores usados pelos filtros
'==============================================================================
Public Sub AbrirFiltroUnidade()
    Dim u As Variant, lst() As String, i As Long, n As Long
    u = ListaUnidades()
    n = UBound(u) - LBound(u) + 1
    ReDim lst(1 To n + 1)
    lst(1) = "(TODAS AS UNIDADES)"
    For i = 0 To n - 1
        lst(i + 2) = CStr(u(LBound(u) + i))
    Next i
    Popup "Filtrar por unidade", lst, "AplicarFiltroUnidade", gFUnidade
End Sub

Public Sub AplicarFiltroUnidade(ByVal v As String)
    gFUnidade = v
    gPagina = 1
    On Error Resume Next
    Sh(SH_GRAF).Range("U1").Value = v   ' apenas informativo
    On Error GoTo 0
    Recarregar
End Sub

Public Sub AbrirFiltroSituacao()
    Popup "Filtrar por situação", _
          Array("(TODAS)", "NO PRAZO", "ATENÇÃO", "EM RISCO", "ATRASADO", "BLOQUEADO", _
                "SEM DATA DE ETAPA", "CONCLUÍDO"), _
          "AplicarFiltroSituacao", gFSituacao
End Sub

Public Sub AplicarFiltroSituacao(ByVal v As String)
    gFSituacao = v
    gPagina = 1
    Recarregar
End Sub
