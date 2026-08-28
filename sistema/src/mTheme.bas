Attribute VB_Name = "mTheme"
Option Explicit
'==============================================================================
' mTheme  -  Design tokens do sistema (cores, tipografia, espacamentos, icones)
'
' Toda a identidade visual esta neste modulo. Mudar uma cor aqui muda o sistema
' inteiro. Nenhum outro modulo deve conter valores de cor "soltos".
'==============================================================================

'--- Tipografia ---------------------------------------------------------------
' Segoe UI e a familia padrao do Windows e a mais proxima da San Francisco.
' Se a empresa tiver "Inter" ou "Segoe UI Variable" instalada, basta trocar aqui.
Public Const FONT_UI       As String = "Segoe UI"
Public Const FONT_LIGHT    As String = "Segoe UI Light"
Public Const FONT_SEMI     As String = "Segoe UI Semibold"
Public Const FONT_ICON     As String = "Segoe MDL2 Assets"

'--- Metricas de layout (em pixels de projeto, convertidos por P()) -----------
Public Const SIDEBAR_W     As Double = 244
Public Const TOPBAR_H      As Double = 78
Public Const PAD           As Double = 28
Public Const GAP           As Double = 16
Public Const CARD_R        As Double = 12
Public Const ROW_H         As Double = 42
Public Const HEAD_H        As Double = 38

'--- Glifos (Segoe MDL2 Assets) ----------------------------------------------
Public Const IC_PAINEL     As String = ChrW(&HE80F)   ' casa
Public Const IC_PROJETOS   As String = ChrW(&HE8A5)   ' documento
Public Const IC_ITENS      As String = ChrW(&HE8EF)   ' caixa / itens
Public Const IC_COMPRAS    As String = ChrW(&HE7BF)   ' carrinho
Public Const IC_NOTAS      As String = ChrW(&HE8EC)   ' nota / entrega
Public Const IC_CONFER     As String = ChrW(&HE73E)   ' check
Public Const IC_CADASTRO   As String = ChrW(&HE713)   ' engrenagem
Public Const IC_CHECKUP    As String = ChrW(&HE7BA)   ' alerta
Public Const IC_BUSCA      As String = ChrW(&HE721)
Public Const IC_ADD        As String = ChrW(&HE710)
Public Const IC_EDIT       As String = ChrW(&HE70F)
Public Const IC_SAVE       As String = ChrW(&HE74E)
Public Const IC_DEL        As String = ChrW(&HE74D)
Public Const IC_REFRESH    As String = ChrW(&HE72C)
Public Const IC_FILTER     As String = ChrW(&HE71C)
Public Const IC_LEFT       As String = ChrW(&HE76B)
Public Const IC_RIGHT      As String = ChrW(&HE76C)
Public Const IC_CLOSE      As String = ChrW(&HE711)
Public Const IC_BACK       As String = ChrW(&HE72B)
Public Const IC_EXPORT     As String = ChrW(&HE896)
Public Const IC_OK         As String = ChrW(&HE73E)
Public Const IC_DOT        As String = ChrW(&HE915)

'==============================================================================
' Conversao de unidades
'==============================================================================
' O projeto e desenhado em pixels logicos (96 dpi). O Excel posiciona formas em
' pontos. P() e a unica ponte entre os dois mundos.
Public Function P(ByVal px As Double) As Double
    P = px * 0.75
End Function

Public Function PxFromPt(ByVal pt As Double) As Double
    PxFromPt = pt / 0.75
End Function

' Converte &HRRGGBB (ordem natural da web) para o Long BGR que o VBA espera.
Public Function HX(ByVal webColor As Long) As Long
    HX = RGB((webColor \ 65536) And 255, (webColor \ 256) And 255, webColor And 255)
End Function

'==============================================================================
' Paleta
'==============================================================================
Public Property Get clrCanvas() As Long:      clrCanvas = HX(&HF6F7F9):        End Property
Public Property Get clrSurface() As Long:     clrSurface = HX(&HFFFFFF):       End Property
Public Property Get clrSurfaceAlt() As Long:  clrSurfaceAlt = HX(&HFAFBFC):    End Property

Public Property Get clrSide() As Long:        clrSide = HX(&H10141B):          End Property
Public Property Get clrSideActive() As Long:  clrSideActive = HX(&H1E2632):    End Property
Public Property Get clrSideText() As Long:    clrSideText = HX(&H97A1B0):      End Property
Public Property Get clrSideTextOn() As Long:  clrSideTextOn = HX(&HFFFFFF):    End Property
Public Property Get clrSideDim() As Long:     clrSideDim = HX(&H5A6474):       End Property

Public Property Get clrBorder() As Long:      clrBorder = HX(&HE7EAEE):        End Property
Public Property Get clrBorderOn() As Long:    clrBorderOn = HX(&HD5DBE3):      End Property

Public Property Get clrText() As Long:        clrText = HX(&H0F1722):          End Property
Public Property Get clrText2() As Long:       clrText2 = HX(&H5B6675):         End Property
Public Property Get clrMuted() As Long:       clrMuted = HX(&H97A1AF):         End Property

Public Property Get clrAccent() As Long:      clrAccent = HX(&H2F6BFF):        End Property
Public Property Get clrAccentDark() As Long:  clrAccentDark = HX(&H1F51CC):    End Property
Public Property Get clrAccentSoft() As Long:  clrAccentSoft = HX(&HEAF0FF):    End Property

Public Property Get clrOk() As Long:          clrOk = HX(&H12A150):            End Property
Public Property Get clrOkSoft() As Long:      clrOkSoft = HX(&HE6F6EE):        End Property
Public Property Get clrWarn() As Long:        clrWarn = HX(&HB4780A):          End Property
Public Property Get clrWarnSoft() As Long:    clrWarnSoft = HX(&HFCF3E0):      End Property
Public Property Get clrDanger() As Long:      clrDanger = HX(&HDC2B4B):        End Property
Public Property Get clrDangerSoft() As Long:  clrDangerSoft = HX(&HFCE9ED):    End Property
Public Property Get clrInfo() As Long:        clrInfo = HX(&H0B84C7):          End Property
Public Property Get clrInfoSoft() As Long:    clrInfoSoft = HX(&HE4F2FB):      End Property
Public Property Get clrNeutralSoft() As Long: clrNeutralSoft = HX(&HF0F2F5):   End Property
Public Property Get clrTrack() As Long:       clrTrack = HX(&HEDEFF3):         End Property

'==============================================================================
' Semantica: situacao do projeto / item -> cores do badge
'==============================================================================
Public Sub BadgeColors(ByVal kind As String, ByRef bg As Long, ByRef fg As Long)
    Select Case UCase$(Trim$(kind))
        Case "OK", "SUCESSO", "NO PRAZO", "CONCLUIDA", "CONCLUÍDA", "SIM", "CONFERIDO", "EM DIA COM A ETAPA"
            bg = clrOkSoft: fg = clrOk
        Case "ATENCAO", "ATENÇÃO", "AVISO", "PARCIAL", "PENDENTE DE CONFERÊNCIA", "PENDENTE DE CONFERENCIA"
            bg = clrWarnSoft: fg = clrWarn
        Case "EM RISCO", "RISCO"
            bg = clrWarnSoft: fg = clrDanger
        Case "ATRASADO", "ERRO", "DIVERGENTE", "NAO", "NÃO", "BLOQUEADO", "AVARIADO"
            bg = clrDangerSoft: fg = clrDanger
        Case "CONCLUIDO", "CONCLUÍDO", "INFO", "EM ANDAMENTO"
            bg = clrInfoSoft: fg = clrInfo
        Case "DESTAQUE", "ACCENT"
            bg = clrAccentSoft: fg = clrAccent
        Case Else
            bg = clrNeutralSoft: fg = clrText2
    End Select
End Sub

' Situacao textual -> chave de badge, tolerando variacoes de escrita.
Public Function SituacaoKind(ByVal s As String) As String
    Dim u As String
    u = UCase$(Trim$(s))
    If u = "" Then SituacaoKind = "NEUTRO": Exit Function
    If InStr(u, "ATRAS") > 0 Then SituacaoKind = "ATRASADO": Exit Function
    If InStr(u, "BLOQUE") > 0 Then SituacaoKind = "BLOQUEADO": Exit Function
    If InStr(u, "RISCO") > 0 Then SituacaoKind = "EM RISCO": Exit Function
    If InStr(u, "ATEN") > 0 Then SituacaoKind = "ATENÇÃO": Exit Function
    If InStr(u, "CONCLU") > 0 Then SituacaoKind = "CONCLUÍDO": Exit Function
    If InStr(u, "PRAZO") > 0 Then SituacaoKind = "NO PRAZO": Exit Function
    If InStr(u, "DIVERG") > 0 Then SituacaoKind = "DIVERGENTE": Exit Function
    If InStr(u, "PENDENT") > 0 Then SituacaoKind = "ATENÇÃO": Exit Function
    If InStr(u, "CANCEL") > 0 Then SituacaoKind = "NEUTRO": Exit Function
    SituacaoKind = u
End Function
