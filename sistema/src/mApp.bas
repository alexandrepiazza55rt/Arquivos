Attribute VB_Name = "mApp"
Option Explicit
'==============================================================================
' mApp  -  Casca do sistema: inicializacao, barra lateral, cabecalho, roteador
'
' Ponto de entrada:  IniciarSistema
' Saida controlada:  SairSistema        (tambem em Ctrl+Shift+E)
'==============================================================================

'--- Estado da navegacao ------------------------------------------------------
Public gTela      As String   ' painel | projetos | projeto | itens | compras | notas | conferencia | cadastros | checkup
Public gCtx       As String   ' chave do registro aberto (chamado, id do item, nota)
Public gAba       As String   ' sub-aba dentro da tela
Public gPagina    As Long
Public gBusca     As String
Public gFUnidade  As String
Public gFSituacao As String
Public gToast     As String
Public gToastKind As String
Public gLinhas    As Long     ' linhas por pagina calculadas no ultimo render

'--- Estado do Excel antes de entrarmos --------------------------------------
Private oFormulaBar As Boolean, oStatusBar As Boolean, oGrid As Boolean
Private oHead As Boolean, oTabs As Boolean, oHScroll As Boolean, oVScroll As Boolean
Private oCaption As String
Private mAtivo As Boolean
Private mAbasOcultas As Boolean

Public Const APP_NOME As String = "Monitoramento Patrimonial"
Public Const APP_VER  As String = "1.0"

'==============================================================================
' Entrada e saida
'==============================================================================
Public Sub IniciarSistema()
    On Error GoTo Falhou

    If Not ChecarEstrutura() Then Exit Sub

    GuardarEstadoExcel
    AplicarChrome
    EsconderTelaInicial
    If PrefGet("ocultar_abas", "0") = "1" Then OcultarAbasDeDados True

    If gTela = "" Then gTela = "painel"
    If gFUnidade = "" Then gFUnidade = "(TODAS AS UNIDADES)"
    If gFSituacao = "" Then gFSituacao = "(TODAS)"
    gPagina = 1
    mAtivo = True

    Application.OnKey "^+E", "SairSistema"

    Ir gTela, gCtx
    Exit Sub

Falhou:
    RestaurarEstadoExcel
    MsgBox "Nao foi possivel abrir o sistema." & vbCrLf & vbCrLf & _
           Err.Description, vbExclamation, APP_NOME
End Sub

Public Sub SairSistema()
    On Error Resume Next
    Application.OnKey "^+E"
    mAtivo = False
    Dim ws As Worksheet
    Set ws = Canvas()
    ws.Unprotect
    ClearUI ws
    ws.ScrollArea = ""
    ResetGrid ws
    OcultarAbasDeDados False
    MostrarTelaInicial
    RestaurarEstadoExcel
    MsgBox "Sistema encerrado. Para voltar, use a aba SISTEMA e o botao ABRIR SISTEMA," & vbCrLf & _
           "ou execute a macro IniciarSistema.", vbInformation, APP_NOME
End Sub

Public Function SistemaAtivo() As Boolean
    SistemaAtivo = mAtivo
End Function

'==============================================================================
' Ambiente do Excel
'==============================================================================
Private Sub GuardarEstadoExcel()
    oFormulaBar = Application.DisplayFormulaBar
    oStatusBar = Application.DisplayStatusBar
    oCaption = Application.Caption
    On Error Resume Next
    oGrid = ActiveWindow.DisplayGridlines
    oHead = ActiveWindow.DisplayHeadings
    oTabs = ActiveWindow.DisplayWorkbookTabs
    oHScroll = ActiveWindow.DisplayHorizontalScrollBar
    oVScroll = ActiveWindow.DisplayVerticalScrollBar
    On Error GoTo 0
End Sub

Private Sub AplicarChrome()
    Application.ScreenUpdating = False
    Application.DisplayFormulaBar = False
    Application.DisplayStatusBar = False
    Application.Caption = APP_NOME
    On Error Resume Next
    ExecuteExcel4Macro "SHOW.TOOLBAR(""Ribbon"",False)"
    Canvas().Activate
    With ActiveWindow
        .DisplayGridlines = False
        .DisplayHeadings = False
        .DisplayWorkbookTabs = False
        .DisplayHorizontalScrollBar = False
        .DisplayVerticalScrollBar = False
        .Zoom = 100
    End With
    On Error GoTo 0
End Sub

Public Sub RestaurarEstadoExcel()
    On Error Resume Next
    Application.DisplayFormulaBar = oFormulaBar
    Application.DisplayStatusBar = oStatusBar
    Application.Caption = oCaption
    ExecuteExcel4Macro "SHOW.TOOLBAR(""Ribbon"",True)"
    With ActiveWindow
        .DisplayGridlines = oGrid
        .DisplayHeadings = oHead
        .DisplayWorkbookTabs = True
        .DisplayHorizontalScrollBar = True
        .DisplayVerticalScrollBar = True
    End With
    Application.ScreenUpdating = True
    On Error GoTo 0
End Sub

Private Sub OcultarAbasDeDados(ByVal ocultar As Boolean)
    Dim ws As Worksheet
    On Error Resume Next
    For Each ws In ThisWorkbook.Worksheets
        If ws.Name <> UI_SHEET And ws.Name <> "_APP" Then
            ws.Visible = IIf(ocultar, xlSheetHidden, xlSheetVisible)
        End If
    Next ws
    mAbasOcultas = ocultar
    On Error GoTo 0
End Sub

Private Function ChecarEstrutura() As Boolean
    Dim faltando As String, n As Variant
    For Each n In Array(SH_PROJ, SH_ITENS, SH_ENT, SH_HIST, SH_PARAM)
        If Not ShExists(CStr(n)) Then faltando = faltando & vbCrLf & "  ·  " & n
    Next n
    If faltando <> "" Then
        MsgBox "Estas abas sao obrigatorias e nao foram encontradas:" & vbCrLf & faltando & _
               vbCrLf & vbCrLf & "Abra a pasta original do Painel de Projetos e importe o sistema nela.", _
               vbCritical, APP_NOME
        ChecarEstrutura = False
    Else
        ChecarEstrutura = True
    End If
End Function

'==============================================================================
' Roteador
'==============================================================================
Public Function ActIr(ByVal tela As String, Optional ByVal ctx As String = "", _
                      Optional ByVal aba As String = "") As String
    ActIr = "'Ir """ & Limpa(tela) & """,""" & Limpa(ctx) & """,""" & Limpa(aba) & """'"
End Function

Public Function ActProc(ByVal proc As String) As String
    ActProc = "'" & proc & "'"
End Function

Public Function ActProc1(ByVal proc As String, ByVal arg As String) As String
    ActProc1 = "'" & proc & " """ & Limpa(arg) & """'"
End Function

Public Function ActProc2(ByVal proc As String, ByVal a1 As String, ByVal a2 As String) As String
    ActProc2 = "'" & proc & " """ & Limpa(a1) & """,""" & Limpa(a2) & """'"
End Function

Private Function Limpa(ByVal s As String) As String
    Limpa = Replace(Replace(s, """", ""), "'", "")
End Function

Public Sub Ir(ByVal tela As String, Optional ByVal ctx As String = "", Optional ByVal aba As String = "")
    Dim ws As Worksheet
    On Error GoTo Falhou

    Application.ScreenUpdating = False
    Application.EnableEvents = False

    If tela <> gTela Or ctx <> gCtx Then gPagina = 1
    gTela = tela
    gCtx = ctx
    gAba = aba

    Set ws = Canvas()
    ws.Unprotect
    ws.ScrollArea = ""
    ClearUI ws
    ResetGrid ws

    Select Case LCase$(tela)
        Case "painel":      PainelRender
        Case "projetos":    ProjetosRender
        Case "projeto":     ProjetoRender ctx
        Case "projeto_form": ProjetoFormRender ctx
        Case "itens":       ItensRender
        Case "item_form":   ItemFormRender ctx
        Case "compras":     ComprasRender
        Case "notas":       NotasRender
        Case "nota_form":   NotaFormRender ctx
        Case "nota_item":   SeletorItemRender
        Case "conferencia": ConferenciaRender
        Case "cadastros":   CadastrosRender
        Case "produto_form": ProdutoFormRender ctx
        Case "checkup":     CheckupRender
        Case Else:          gTela = "painel": PainelRender
    End Select

    ws.Range("A1").Select
    ws.Protect Password:="", DrawingObjects:=False, Contents:=True, Scenarios:=False, _
               UserInterfaceOnly:=True, AllowFormattingCells:=True
    Application.EnableEvents = True
    Application.ScreenUpdating = True
    Exit Sub

Falhou:
    Application.EnableEvents = True
    Application.ScreenUpdating = True
    MsgBox "Ocorreu um erro ao montar a tela '" & tela & "'." & vbCrLf & vbCrLf & _
           Err.Description & vbCrLf & vbCrLf & _
           "Use Ctrl+Shift+E para devolver o Excel ao estado normal.", vbExclamation, APP_NOME
End Sub

Public Sub Recarregar()
    Ir gTela, gCtx, gAba
End Sub

Public Sub VoltarTela()
    Select Case gTela
        Case "projeto", "projeto_form": Ir "projetos"
        Case "item_form": Ir "itens"
        Case "nota_form", "nota_item": Ir "notas"
        Case "produto_form": Ir "cadastros", "", "produtos"
        Case "painel": ' ja esta na raiz
        Case Else: Ir "painel"
    End Select
End Sub

Public Sub PaginaAnterior()
    If gPagina > 1 Then gPagina = gPagina - 1
    Ir gTela, gCtx, gAba
End Sub

Public Sub PaginaProxima()
    gPagina = gPagina + 1
    Ir gTela, gCtx, gAba
End Sub

'==============================================================================
' Mensagens (faixa discreta no topo do conteudo, no lugar de caixas de dialogo)
'==============================================================================
Public Sub Aviso(ByVal msg As String, Optional ByVal kind As String = "OK")
    gToast = msg
    gToastKind = kind
End Sub

'==============================================================================
' Casca visual
'==============================================================================
' Desenha barra lateral + cabecalho. Devolve o Y (px) onde o conteudo comeca.
Public Function RenderShell(ByVal titulo As String, Optional ByVal subtitulo As String = "", _
                            Optional ByVal voltarPara As String = "", _
                            Optional ByVal voltarCtx As String = "") As Double
    Dim ws As Worksheet, y As Double
    Set ws = Canvas()

    Sidebar ws

    Dim cx As Double, cw As Double
    cx = ContentX: cw = ContentW

    ' cabecalho
    If voltarPara <> "" Then
        Icon ws, cx - 4, 26, 20, IC_BACK, clrText2, 11
        Lbl ws, cx + 18, 26, 120, 20, "Voltar", 9, clrText2, False, 1
        HitArea ws, cx - 6, 24, 90, 24, ActIr(voltarPara, voltarCtx)
        Lbl ws, cx, 44, cw * 0.6, 34, titulo, 19, clrText, False, 1, FONT_LIGHT
        If subtitulo <> "" Then Lbl ws, cx, 74, cw * 0.6, 16, subtitulo, 9, clrMuted, False, 1
        y = 104
    Else
        Lbl ws, cx, 22, cw * 0.6, 34, titulo, 21, clrText, False, 1, FONT_LIGHT
        If subtitulo <> "" Then Lbl ws, cx, 52, cw * 0.6, 16, subtitulo, 9, clrMuted, False, 1
        y = 84
    End If

    ' faixa de mensagem
    If gToast <> "" Then
        Dim bg As Long, fg As Long
        BadgeColors gToastKind, bg, fg
        Rect ws, cx, y, cw, 38, bg, 8, -1
        Icon ws, cx + 10, y, 20, IIf(gToastKind = "ERRO" Or gToastKind = "ATRASADO", IC_CHECKUP, IC_OK), fg, 11, 38
        Lbl ws, cx + 36, y, cw - 60, 38, gToast, 9.5, fg, False, 1
        IconBtn ws, cx + cw - 32, y + 7, 24, IC_CLOSE, ActProc("FecharAviso"), "ghost"
        y = y + 38 + GAP
        gToast = ""
    End If

    RenderShell = y
End Function

Public Sub FecharAviso()
    gToast = ""
    Recarregar
End Sub

'--- Barra lateral ------------------------------------------------------------
Private Sub Sidebar(ws As Worksheet)
    Dim h As Double, y As Double
    h = ViewH

    Rect ws, 0, 0, SIDEBAR_W, h, clrSide, 0, -1

    ' marca
    Rect ws, 24, 26, 34, 34, clrAccent, 9, -1
    Lbl ws, 24, 26, 34, 34, ChrW(&HE72E), 13, HX(&HFFFFFF), False, 2, FONT_ICON
    Lbl ws, 68, 26, 160, 18, "Monitoramento", 11.5, clrSideTextOn, True, 1
    Lbl ws, 68, 44, 160, 14, "Controle de projetos", 8, clrSideDim, False, 1

    y = 92
    Lbl ws, 24, y, 200, 14, "ACOMPANHAMENTO", 7.5, clrSideDim, True, 1, FONT_UI, False, 0.8
    y = y + 22
    y = NavItem(ws, y, IC_PAINEL, "Painel", "painel")
    y = NavItem(ws, y, IC_PROJETOS, "Projetos", "projetos")
    y = NavItem(ws, y, IC_ITENS, "Itens e escopo", "itens")

    y = y + 14
    Lbl ws, 24, y, 200, 14, "OPERAÇÃO", 7.5, clrSideDim, True, 1, FONT_UI, False, 0.8
    y = y + 22
    y = NavItem(ws, y, IC_COMPRAS, "Compras (SC / OC)", "compras")
    y = NavItem(ws, y, IC_NOTAS, "Notas e entregas", "notas")
    y = NavItem(ws, y, IC_CONFER, "Conferências", "conferencia")

    y = y + 14
    Lbl ws, 24, y, 200, 14, "CONFIGURAÇÃO", 7.5, clrSideDim, True, 1, FONT_UI, False, 0.8
    y = y + 22
    y = NavItem(ws, y, IC_CADASTRO, "Cadastros", "cadastros")
    y = NavItem(ws, y, IC_CHECKUP, "Consistência", "checkup")

    ' rodape
    Dim by As Double
    by = h - 116
    Rect ws, 20, by, SIDEBAR_W - 40, 1, HX(&H262E3A), 0, -1
    Lbl ws, 24, by + 12, 200, 14, "DATA DE REFERÊNCIA", 7.5, clrSideDim, True, 1
    Lbl ws, 24, by + 28, 130, 16, Format$(DataRefer, "dd/mm/yyyy"), 10, clrSideTextOn, False, 1
    Lbl ws, 150, by + 28, 74, 16, "atualizar", 8.5, clrAccent, True, 3
    HitArea ws, 146, by + 26, 78, 20, ActProc("AtualizarDataRef")

    Icon ws, 22, by + 60, 20, ChrW(&HE7E8), clrSideDim, 11, 20
    Lbl ws, 46, by + 60, 180, 20, "Sair do sistema", 9.5, clrSideDim, False, 1
    HitArea ws, 20, by + 58, SIDEBAR_W - 40, 24, ActProc("SairSistema")
End Sub

Private Function NavItem(ws As Worksheet, ByVal y As Double, ByVal glyph As String, _
                         ByVal texto As String, ByVal destino As String) As Double
    Dim ativo As Boolean, fg As Long
    ativo = (LCase$(gTela) = destino) Or _
            (destino = "projetos" And (gTela = "projeto" Or gTela = "projeto_form")) Or _
            (destino = "itens" And gTela = "item_form") Or _
            (destino = "notas" And gTela = "nota_form")

    If ativo Then
        Rect ws, 14, y, SIDEBAR_W - 28, 38, clrSideActive, 8, -1
        Rect ws, 14, y + 9, 3, 20, clrAccent, 2, -1
        fg = clrSideTextOn
    Else
        fg = clrSideText
    End If
    Icon ws, 26, y, 20, glyph, fg, 11.5, 38
    Lbl ws, 52, y, SIDEBAR_W - 70, 38, texto, 9.5, fg, ativo, 1
    HitArea ws, 14, y, SIDEBAR_W - 28, 38, ActIr(destino)
    NavItem = y + 42
End Function

'==============================================================================
' Acoes globais
'==============================================================================
Public Sub AtualizarDataRef()
    Dim r As Variant
    r = InputBox("Data de referencia usada em todos os calculos de prazo:", _
                 APP_NOME, Format$(DataRefer, "dd/mm/yyyy"))
    If Trim$(CStr(r)) = "" Then Exit Sub
    If Not IsDate(r) Then
        Aviso "Data invalida. Use o formato dd/mm/aaaa.", "ERRO"
    Else
        SetDataRefer CDate(r)
        Recalcular
        Aviso "Data de referencia atualizada para " & Format$(CDate(r), "dd/mm/yyyy") & ".", "OK"
    End If
    Recarregar
End Sub

Public Sub HojeComoDataRef()
    SetDataRefer Date
    Recalcular
    Aviso "Data de referencia ajustada para hoje.", "OK"
    Recarregar
End Sub
