Attribute VB_Name = "scrProjetos"
Option Explicit
'==============================================================================
' scrProjetos  -  Lista, detalhe e formulario dos projetos
'==============================================================================

'==============================================================================
' LISTA
'==============================================================================
Public Sub ProjetosRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim d As Variant, n As Long, i As Long, cap As Long
    Dim idx() As Long, m As Long

    Set ws = Canvas()
    x = ContentX: w = ContentW

    d = Bloco(SH_PROJ, PJ_CHAMADO, PJ_ULT)
    n = BlocoLinhas(d)

    y = RenderShell("Projetos", "Carteira completa do setor")

    y = y + Toolbar(x, y, w, "Novo projeto", ActIr("projeto_form"), _
                    IIf(gFUnidade = "(TODAS AS UNIDADES)", "Todas as unidades", gFUnidade), _
                    ActProc("AbrirFiltroUnidade"), _
                    IIf(gFSituacao = "(TODAS)", "Todas as situações", gFSituacao), _
                    ActProc("AbrirFiltroSituacao"))

    ' filtragem
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, PJ_CHAMADO)) <> "" Then
            If PassaUnidade(SVal(d(i, PJ_UNID))) And PassaSituacao(SVal(d(i, PJ_SITUACAO))) Then
                If Casa(d(i, PJ_CHAMADO), d(i, PJ_NOME), d(i, PJ_UNID), d(i, PJ_AREA), _
                        d(i, PJ_ETAPA), d(i, PJ_RESPDEM), d(i, PJ_OBJDESC)) Then
                    m = m + 1
                    idx(m) = i
                End If
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "Chamado", 96, 1, "strong"
    GridCol "Projeto", 0
    GridCol "Unidade", 82
    GridCol "Etapa atual", 200, 1, "dim"
    GridCol "Responsável", 130, 1, "dim"
    GridCol "Dias / SLA", 92, 2
    GridCol "Atraso", 72, 2
    GridCol "Situação", 126, 1, "badge"
    GridCol "", 28, 3, "chevron"

    cap = GridCapacity(y)
    gLinhas = cap

    Dim de As Long, ate As Long, k As Long, q As Long
    de = (gPagina - 1) * cap + 1
    If de > m Then de = 1: gPagina = 1
    ate = de + cap - 1
    If ate > m Then ate = m
    q = ate - de + 1

    If q <= 0 Then
        GridDraw Empty, 0, Empty
        EmptyState ws, x, y + 60, w, 200, "Nenhum projeto encontrado", _
                   "Ajuste a busca ou os filtros, ou cadastre um novo projeto."
        GridPager x, ViewH - 52, w, m, gPagina, cap
        Exit Sub
    End If

    Dim lin() As Variant, chaves() As String
    ReDim lin(1 To q, 1 To 9)
    ReDim chaves(1 To q)
    For k = 1 To q
        i = idx(de + k - 1)
        lin(k, 1) = SVal(d(i, PJ_CHAMADO))
        lin(k, 2) = SVal(d(i, PJ_NOME))
        lin(k, 3) = SVal(d(i, PJ_UNID))
        lin(k, 4) = SVal(d(i, PJ_ETAPA))
        lin(k, 5) = SVal(d(i, PJ_RESP))
        lin(k, 6) = FmtN(d(i, PJ_DIASETAPA)) & " / " & FmtN(d(i, PJ_SLA))
        lin(k, 7) = IIf(NVal(d(i, PJ_ATRASO)) > 0, "+" & FmtN(d(i, PJ_ATRASO)), "—")
        lin(k, 8) = SVal(d(i, PJ_SITUACAO))
        lin(k, 9) = ""
        chaves(k) = SVal(d(i, PJ_CHAMADO))
    Next k

    GridDraw lin, q, chaves, "projeto"
    GridPager x, ViewH - 52, w, m, gPagina, cap
End Sub

Public Function PassaUnidade(ByVal u As String) As Boolean
    PassaUnidade = (gFUnidade = "" Or gFUnidade = "(TODAS AS UNIDADES)" Or u = gFUnidade)
End Function

Public Function PassaSituacao(ByVal s As String) As Boolean
    PassaSituacao = (gFSituacao = "" Or gFSituacao = "(TODAS)" Or UCase$(s) = UCase$(gFSituacao))
End Function

'==============================================================================
' DETALHE
'==============================================================================
Public Sub ProjetoRender(ByVal chamado As String)
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim r As Long, ps As Worksheet

    Set ws = Canvas()
    x = ContentX: w = ContentW
    Set ps = Sh(SH_PROJ)

    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    If r = 0 Then
        y = RenderShell("Projeto não encontrado", "", "projetos")
        EmptyState ws, x, y + 40, w, 200, "Chamado " & chamado & " não localizado", _
                   "Ele pode ter sido removido. Volte para a lista de projetos."
        Exit Sub
    End If

    Dim nome As String, unid As String, etapa As String, sit As String, status As String
    nome = SVal(ps.Cells(r, PJ_NOME).Value)
    unid = SVal(ps.Cells(r, PJ_UNID).Value)
    etapa = SVal(ps.Cells(r, PJ_ETAPA).Value)
    sit = SVal(ps.Cells(r, PJ_SITUACAO).Value)
    status = SVal(ps.Cells(r, PJ_STATUS).Value)

    y = RenderShell(nome, "Chamado " & chamado & "  ·  " & unid & "  ·  " & SVal(ps.Cells(r, PJ_AREA).Value), "projetos")

    ' acoes do cabecalho
    Btn ws, x + w - 150, 44, 150, 38, "Avançar etapa", ActProc1("AvancarEtapa", chamado), "primary", IC_RIGHT
    Btn ws, x + w - 150 - 116, 44, 106, 38, "Editar", ActIr("projeto_form", chamado), "secondary", IC_EDIT
    If UCase$(SVal(ps.Cells(r, PJ_BLOQ).Value)) = "SIM" Then
        Btn ws, x + w - 150 - 116 - 130, 44, 120, 38, "Desbloquear", ActProc1("AlternarBloqueio", chamado), "secondary"
    Else
        Btn ws, x + w - 150 - 116 - 130, 44, 120, 38, "Bloquear", ActProc1("AlternarBloqueio", chamado), "secondary"
    End If

    '--- cartoes -------------------------------------------------------------
    Dim cw As Double, ch As Double
    ch = 208
    cw = (w - GAP * 2) / 3

    ' 1) dados gerais
    Card ws, x, y, cw, ch
    CardTitle ws, x + 20, y + 18, cw - 40, "Dados do chamado"
    Campo ws, x + 20, y + 56, cw * 0.5 - 24, "Área demandante", SVal(ps.Cells(r, PJ_AREA).Value), clrText, 9.5
    Campo ws, x + cw * 0.5 + 4, y + 56, cw * 0.5 - 24, "Responsável", SVal(ps.Cells(r, PJ_RESPDEM).Value), clrText, 9.5
    Campo ws, x + 20, y + 100, cw - 40, "Objeto de custo", _
          SVal(ps.Cells(r, PJ_OBJCOD).Value) & "  ·  " & SVal(ps.Cells(r, PJ_OBJDESC).Value), clrText, 9
    Campo ws, x + 20, y + 144, cw * 0.5 - 24, "Abertura", FmtD(ps.Cells(r, PJ_ABERTURA).Value), clrText, 9.5
    Campo ws, x + cw * 0.5 + 4, y + 144, cw * 0.5 - 24, "Dias corridos", _
          FmtN(ps.Cells(r, PJ_DIASTOT).Value) & " de " & FmtN(SLATotal), clrText, 9.5

    ' 2) etapa atual
    Dim x2 As Double
    x2 = x + cw + GAP
    Card ws, x2, y, cw, ch
    CardTitle ws, x2 + 20, y + 18, cw - 40, "Etapa atual"
    Lbl ws, x2 + 20, y + 52, cw - 40, 22, etapa, 12, clrText, True, 1
    Lbl ws, x2 + 20, y + 72, cw - 40, 16, "responsável: " & SVal(ps.Cells(r, PJ_RESP).Value) & _
        "  ·  desde " & FmtD(ps.Cells(r, PJ_INIETAPA).Value), 8.5, clrMuted, False, 1

    Dim consumo As Double
    consumo = NVal(ps.Cells(r, PJ_CONSUMO).Value)
    Gauge ws, x2 + 20, y + 100, cw - 40, consumo, _
          "Consumo do SLA  ·  " & FmtN(ps.Cells(r, PJ_DIASETAPA).Value) & " de " & FmtN(ps.Cells(r, PJ_SLA).Value) & " dias"
    Campo ws, x2 + 20, y + 148, cw - 40, "Próxima ação", SVal(ps.Cells(r, PJ_PROXACAO).Value), clrText, 9

    ' 3) situacao e material
    Dim x3 As Double
    x3 = x + (cw + GAP) * 2
    Card ws, x3, y, cw, ch
    CardTitle ws, x3 + 20, y + 18, cw - 40, "Situação"
    Badge ws, x3 + 20, y + 48, sit, SituacaoKind(sit)
    Badge ws, x3 + 20 + Len(sit) * 6.1 + 28, y + 48, status, SituacaoKind(status)

    Dim mw As Double
    mw = (cw - 40) / 3
    MiniStat ws, x3 + 20, y + 84, mw, FmtN(ps.Cells(r, PJ_CAMPREV).Value), "câmeras previstas"
    MiniStat ws, x3 + 20 + mw, y + 84, mw, FmtN(ps.Cells(r, PJ_CAMRECEB).Value), "recebidas", clrAccent
    MiniStat ws, x3 + 20 + mw * 2, y + 84, mw, FmtN(ps.Cells(r, PJ_CAMINST).Value), "instaladas", clrOk
    Campo ws, x3 + 20, y + 144, cw - 40, "Motivo principal", SVal(ps.Cells(r, PJ_MOTIVO).Value), _
          IIf(NVal(ps.Cells(r, PJ_ATRASO).Value) > 0, clrDanger, clrText2), 9

    y = y + ch + GAP + 4

    '--- abas ----------------------------------------------------------------
    TabStrip ws, x, y, Array("Itens do projeto", "Histórico das etapas", "Entregas"), _
             Array("itens", "hist", "entregas"), gAba, "projeto", chamado
    y = y + 32 + GAP

    Select Case LCase$(gAba)
        Case "hist":     AbaHistorico chamado, x, y, w
        Case "entregas": AbaEntregas chamado, x, y, w
        Case Else:       AbaItens chamado, x, y, w
    End Select
End Sub

Private Sub AbaItens(ByVal chamado As String, ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long
    d = Bloco(SH_ESCOPO, ES_CHAMADO, ES_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, ES_CHAMADO)) = chamado Then m = m + 1: idx(m) = i
    Next i

    GridBegin x, y, w
    GridCol "Código", 90, 1, "strong"
    GridCol "Descrição do produto", 0
    GridCol "Tipo", 116, 1, "dim"
    GridCol "Prev.", 62, 2
    GridCol "Compr.", 62, 2
    GridCol "Receb.", 62, 2
    GridCol "Lib.", 62, 2
    GridCol "Inst.", 62, 2
    GridCol "VMS", 62, 2
    GridCol "Status quantitativo", 190, 1, "badge"

    cap = GridCapacity(y)
    If m > cap Then m = cap
    If m = 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 20, w, 150, "Sem itens neste chamado", _
                   "Cadastre os itens na tela Itens e escopo."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String, k As Long
    ReDim lin(1 To m, 1 To 10): ReDim ch(1 To m)
    For k = 1 To m
        i = idx(k)
        lin(k, 1) = SVal(d(i, ES_COD))
        lin(k, 2) = SVal(d(i, ES_DESC))
        lin(k, 3) = SVal(d(i, ES_TIPO))
        lin(k, 4) = FmtN(d(i, ES_PREV))
        lin(k, 5) = FmtN(d(i, ES_COMP))
        lin(k, 6) = FmtN(d(i, ES_RECEB))
        lin(k, 7) = FmtN(d(i, ES_LIB))
        lin(k, 8) = FmtN(d(i, ES_INST))
        lin(k, 9) = FmtN(d(i, ES_VMS))
        lin(k, 10) = SVal(d(i, ES_STATUS))
        ch(k) = chamado & "-" & SVal(d(i, ES_COD))
    Next k
    GridDraw lin, m, ch, "item_form"
End Sub

Private Sub AbaHistorico(ByVal chamado As String, ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long
    d = Bloco(SH_HIST, HI_CHAMADO, HI_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, HI_CHAMADO)) = chamado Then m = m + 1: idx(m) = i
    Next i

    If m = 0 Then
        EmptyState Canvas(), x, y, w, 180, "Sem histórico registrado", _
                   "O histórico é criado automaticamente ao avançar as etapas."
        Exit Sub
    End If

    Dim maxN As Long
    maxN = Int((ViewH - y - 40) / 52)
    If m > maxN Then m = maxN

    Dim et() As String, dt() As String, es() As String, nt() As String, k As Long
    ReDim et(1 To m): ReDim dt(1 To m): ReDim es(1 To m): ReDim nt(1 To m)
    For k = 1 To m
        i = idx(k)
        et(k) = SVal(d(i, HI_ETAPA))
        dt(k) = FmtD(d(i, HI_INICIO)) & IIf(IsDate(d(i, HI_FIM)), "  " & ChrW(&H2192) & "  " & FmtD(d(i, HI_FIM)), "  " & ChrW(&H2192) & "  em curso")
        es(k) = SVal(d(i, HI_SIT))
        nt(k) = SVal(d(i, HI_RESP)) & "  ·  " & FmtN(d(i, HI_DIAS)) & " dias" & _
                IIf(NVal(d(i, HI_ATRASO)) > 0, "  ·  " & FmtN(d(i, HI_ATRASO)) & " dias de atraso", "") & _
                "  ·  SLA " & FmtN(d(i, HI_SLA))
        If UCase$(es(k)) = "EM ANDAMENTO" And NVal(d(i, HI_ATRASO)) > 0 Then es(k) = "ATRASADA"
    Next k

    Card Canvas(), x, y, w, m * 52 + 32
    Timeline Canvas(), x + 24, y + 12, w - 48, et, dt, es, nt, m
End Sub

Private Sub AbaEntregas(ByVal chamado As String, ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long
    d = Bloco(SH_ENT, EN_NF, EN_ULT)
    n = BlocoLinhas(d)
    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, EN_CHAMADO)) = chamado Then m = m + 1: idx(m) = i
    Next i

    GridBegin x, y, w
    GridCol "NF / Remessa", 118, 1, "strong"
    GridCol "Produto", 0
    GridCol "Recebimento", 110, 2
    GridCol "Qtd.", 66, 2
    GridCol "Unidade", 86, 2
    GridCol "Custódia", 168, 1, "dim"
    GridCol "Situação física", 168, 1, "badge"
    GridCol "Conferência", 168, 1, "badge"

    cap = GridCapacity(y)
    If m > cap Then m = cap
    If m = 0 Then
        GridDraw Empty, 0, Empty
        EmptyState Canvas(), x, y + 20, w, 150, "Nenhuma nota lançada", _
                   "Use a tela Notas e entregas para registrar o recebimento."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String, k As Long
    ReDim lin(1 To m, 1 To 8): ReDim ch(1 To m)
    For k = 1 To m
        i = idx(k)
        lin(k, 1) = SVal(d(i, EN_NF))
        lin(k, 2) = SVal(d(i, EN_DESC))
        lin(k, 3) = FmtD(d(i, EN_DATA))
        lin(k, 4) = FmtN(d(i, EN_QTD))
        lin(k, 5) = SVal(d(i, EN_UNID))
        lin(k, 6) = SVal(d(i, EN_CUSTODIA))
        lin(k, 7) = SVal(d(i, EN_SITFIS))
        lin(k, 8) = SVal(d(i, EN_CONF))
        ch(k) = SVal(d(i, EN_NF)) & "|" & CStr(idx(k) + FIRST_ROW - 1)
    Next k
    GridDraw lin, m, ch, "nota_form"
End Sub

'==============================================================================
' FORMULARIO
'==============================================================================
Public Sub ProjetoFormRender(ByVal chamado As String)
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim r As Long, ps As Worksheet, novo As Boolean

    Set ws = Canvas()
    x = ContentX: w = ContentW
    Set ps = Sh(SH_PROJ)

    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    novo = (r = 0)

    y = RenderShell(IIf(novo, "Novo projeto", "Editar projeto"), _
                    IIf(novo, "Cadastre o chamado e a etapa em que ele se encontra", _
                              "Chamado " & chamado), "projetos")

    FormBegin x, y, w, 3

    FormField "chamado", "Nº do chamado", IIf(novo, "", SVal(ps.Cells(r, PJ_CHAMADO).Value)), _
              IIf(novo, "texto", "leitura")
    FormField "nome", "Nome do projeto", IIf(novo, "", SVal(ps.Cells(r, PJ_NOME).Value)), "texto", , 2

    FormField "unidade", "Unidade", IIf(novo, "", SVal(ps.Cells(r, PJ_UNID).Value)), "lista", ListaUnidades()
    FormField "area", "Área demandante", IIf(novo, "", SVal(ps.Cells(r, PJ_AREA).Value)), "lista", ListaAreas()
    FormField "respdem", "Responsável demandante", IIf(novo, "", SVal(ps.Cells(r, PJ_RESPDEM).Value)), "texto"

    FormField "objcod", "Código do objeto de custo", IIf(novo, "", SVal(ps.Cells(r, PJ_OBJCOD).Value)), "texto", , 1, _
              "a descrição é preenchida automaticamente pelo cadastro"
    FormField "abertura", "Data de abertura", IIf(novo, Format$(Date, "dd/mm/yyyy"), FmtDEdit(ps.Cells(r, PJ_ABERTURA).Value)), "data"
    FormField "status", "Status informado", IIf(novo, "EM ANDAMENTO", SVal(ps.Cells(r, PJ_STATUS).Value)), "lista", ListaStatus()

    FormField "etapa", "Etapa atual", IIf(novo, "ELABORAÇÃO DO PROJETO", SVal(ps.Cells(r, PJ_ETAPA).Value)), "lista", ListaEtapas()
    FormField "inietapa", "Início da etapa", IIf(novo, Format$(Date, "dd/mm/yyyy"), FmtDEdit(ps.Cells(r, PJ_INIETAPA).Value)), "data"
    FormField "bloq", "Bloqueado?", IIf(novo, "NÃO", SVal(ps.Cells(r, PJ_BLOQ).Value)), "lista", Array("NÃO", "SIM")

    FormField "motivo", "Dificuldade encontrada", IIf(novo, "", SVal(ps.Cells(r, PJ_DIFIC).Value)), "lista", ListaMotivos(), 1, _
              "obrigatório quando o projeto está bloqueado"
    FormField "proxacao", "Próxima ação", IIf(novo, "", SVal(ps.Cells(r, PJ_PROXACAO).Value)), "texto", , 2

    FormListaDeIntervalo "unidade", "=Lista_Unidades"
    FormListaDeIntervalo "area", "=Lista_Areas"
    FormListaDeIntervalo "status", "=Lista_Status"
    FormListaDeIntervalo "etapa", "=Lista_Etapas"
    FormListaDeIntervalo "motivo", "=Lista_Motivos"

    FormFooter FormBottom() + 8, ActProc1("SalvarProjeto", chamado), _
               IIf(novo, ActIr("projetos"), ActIr("projeto", chamado)), _
               IIf(novo, "Cadastrar projeto", "Salvar alterações"), _
               IIf(novo, "", ActProc1("ExcluirProjeto", chamado))
End Sub

Public Function FmtDEdit(ByVal v As Variant) As String
    If IsDate(v) Then FmtDEdit = Format$(CDate(v), "dd/mm/yyyy") Else FmtDEdit = ""
End Function
