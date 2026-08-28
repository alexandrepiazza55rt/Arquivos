Attribute VB_Name = "scrCadastros"
Option Explicit
'==============================================================================
' scrCadastros  -  Parametros, etapas, listas suspensas e produtos
'==============================================================================

Public Sub CadastrosRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Set ws = Canvas()
    x = ContentX: w = ContentW

    y = RenderShell("Cadastros", "A base de tudo: prazos, etapas, listas e produtos")

    TabStrip ws, x, y, Array("Parâmetros e etapas", "Listas do sistema", "Produtos"), _
             Array("param", "listas", "produtos"), IIf(gAba = "", "param", gAba), "cadastros", ""
    y = y + 32 + GAP

    Select Case LCase$(gAba)
        Case "listas":   AbaListas x, y, w
        Case "produtos": AbaProdutos x, y, w
        Case Else:       AbaParametros x, y, w
    End Select
End Sub

'==============================================================================
' Parametros gerais e SLA por etapa
'==============================================================================
Private Sub AbaParametros(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim ws As Worksheet, et As Variant, i As Long, n As Long
    Set ws = Canvas()

    FormBegin x, y, w, 4
    FormCompacto

    FormSection "Parâmetros gerais", "usados em todos os cálculos de prazo do sistema"
    FormField "dataref", "Data de referência", Format$(DataRefer, "dd/mm/yyyy"), "data", , 1, _
              "todos os dias corridos são contados até esta data"
    FormField "slatotal", "SLA total do projeto (dias)", CStr(SLATotal), "numero"
    FormField "limaten", "Limite de atenção", CStr(LimAtencao), "numero", , 1, "ex.: 0,7 = 70% do SLA"
    FormField "limrisco", "Limite de risco", CStr(LimRisco), "numero", , 1, "ex.: 0,9 = 90% do SLA"

    FormSection "SLA por etapa", "prazo padrão de cada etapa do fluxo, em dias corridos"
    et = ListaEtapas()
    n = UBound(et) - LBound(et) + 1
    For i = 1 To n
        FormField "sla" & i, CStr(et(LBound(et) + i - 1)), CStr(EtapaSLA(CStr(et(LBound(et) + i - 1)))), "numero"
    Next i

    FormFooter FormBottom() + 8, ActProc("SalvarParametros"), ActIr("cadastros"), "Salvar parâmetros"
End Sub

'==============================================================================
' Listas suspensas
'==============================================================================
Private Sub AbaListas(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim ws As Worksheet
    Set ws = Canvas()

    Dim cw As Double, ch As Double
    cw = (w - GAP * 3) / 4
    ch = (ViewH - y - 40 - GAP) / 2
    If ch < 190 Then ch = 190

    CardLista ws, x + 0 * (cw + GAP), y, cw, ch, "Unidades", "C", ListaUnidades()
    CardLista ws, x + 1 * (cw + GAP), y, cw, ch, "Responsáveis / áreas", "G", ListaResponsaveis()
    CardLista ws, x + 2 * (cw + GAP), y, cw, ch, "Status do projeto", "A", ListaStatus()
    CardLista ws, x + 3 * (cw + GAP), y, cw, ch, "Situação física", "K", ListaSitFisica()

    CardLista ws, x + 0 * (cw + GAP), y + ch + GAP, cw, ch, "Áreas demandantes", "E", ListaAreas()
    CardLista ws, x + 1 * (cw + GAP), y + ch + GAP, cw, ch, "Motivos de bloqueio", "I", ListaMotivos()
    CardLista ws, x + 2 * (cw + GAP), y + ch + GAP, cw, ch, "Local de custódia", "M", ListaCustodia()
    CardLista ws, x + 3 * (cw + GAP), y + ch + GAP, cw, ch, "Etapas do fluxo", "O", ListaEtapas()
End Sub

Private Sub CardLista(ws As Worksheet, ByVal x As Double, ByVal y As Double, ByVal w As Double, _
                      ByVal h As Double, ByVal titulo As String, ByVal coluna As String, _
                      ByVal itens As Variant)
    Dim i As Long, n As Long, yy As Double, cabe As Long
    Card ws, x, y, w, h
    Lbl ws, x + 18, y + 16, w - 60, 20, titulo, 10.5, clrText, True, 1

    On Error Resume Next
    n = UBound(itens) - LBound(itens) + 1
    On Error GoTo 0
    Lbl ws, x + 18, y + 34, w - 36, 14, CStr(n) & " itens", 8, clrMuted, False, 1

    IconBtn ws, x + w - 44, y + 14, 26, IC_ADD, ActProc1("AdicionarNaLista", coluna), "ghost"
    HRule ws, x + 18, y + 54, w - 36

    cabe = Int((h - 74) / 22)
    yy = y + 62
    For i = 0 To n - 1
        If i >= cabe Then
            Lbl ws, x + 18, yy, w - 36, 20, "+ " & CStr(n - cabe) & " outros…", 8.5, clrMuted, False, 1
            Exit For
        End If
        Lbl ws, x + 18, yy, w - 36, 20, Corta(CStr(itens(LBound(itens) + i)), 26), 9, clrText2, False, 1
        yy = yy + 22
    Next i
End Sub

'==============================================================================
' Produtos
'==============================================================================
Private Sub AbaProdutos(ByVal x As Double, ByVal y As Double, ByVal w As Double)
    Dim ws As Worksheet, ps As Worksheet, r As Long, ult As Long
    Dim m As Long, idx() As Long, cap As Long
    Set ws = Canvas()
    Set ps = Sh(SH_PARAM)

    y = y + Toolbar(x, y, w, "Novo produto", ActIr("produto_form"))

    ult = FIRST_ROW
    Do While Trim$(CStr(ps.Cells(ult, 22).Value)) <> "" And ult < 1200
        ult = ult + 1
    Loop
    ult = ult - 1

    ReDim idx(1 To 1200)
    For r = FIRST_ROW To ult
        If Casa(ps.Cells(r, 22).Value, ps.Cells(r, 23).Value, ps.Cells(r, 24).Value) Then
            m = m + 1: idx(m) = r
        End If
    Next r

    GridBegin x, y, w
    GridCol "Código", 120, 1, "strong"
    GridCol "Descrição do produto", 0
    GridCol "Tipo de item", 220, 1, "badge"
    GridCol "", 28, 3, "chevron"

    cap = GridCapacity(y)
    Dim de As Long, ate As Long, k As Long, q As Long
    de = (gPagina - 1) * cap + 1
    If de > m Then de = 1: gPagina = 1
    ate = de + cap - 1
    If ate > m Then ate = m
    q = ate - de + 1

    If q <= 0 Then
        GridDraw Empty, 0, Empty
        EmptyState ws, x, y + 40, w, 180, "Nenhum produto cadastrado", _
                   "Cadastre os códigos usados nos itens dos projetos."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String
    ReDim lin(1 To q, 1 To 4): ReDim ch(1 To q)
    For k = 1 To q
        r = idx(de + k - 1)
        lin(k, 1) = SVal(ps.Cells(r, 22).Value)
        lin(k, 2) = SVal(ps.Cells(r, 23).Value)
        lin(k, 3) = SVal(ps.Cells(r, 24).Value)
        lin(k, 4) = ""
        ch(k) = CStr(r)
    Next k
    GridDraw lin, q, ch, "produto_form"
    GridPager x, ViewH - 52, w, m, gPagina, cap
End Sub

'==============================================================================
' Formulario de produto
'==============================================================================
Public Sub ProdutoFormRender(ByVal ctx As String)
    Dim ws As Worksheet, ps As Worksheet, x As Double, w As Double, y As Double
    Dim r As Long, novo As Boolean
    Set ws = Canvas()
    Set ps = Sh(SH_PARAM)
    x = ContentX: w = ContentW

    If ctx <> "" And IsNumeric(ctx) Then r = CLng(ctx)
    novo = (r < FIRST_ROW)

    y = RenderShell(IIf(novo, "Novo produto", "Editar produto"), _
                    "O código é a chave usada pelos itens dos projetos", "cadastros")

    FormBegin x, y, w, 3
    FormSection "Produto", "código, descrição e classificação"
    FormField "cod", "Código do produto", IIf(novo, "", SVal(ps.Cells(r, 22).Value)), "texto"
    FormField "desc", "Descrição", IIf(novo, "", SVal(ps.Cells(r, 23).Value)), "texto", , 2
    FormField "tipo", "Tipo de item", IIf(novo, "", SVal(ps.Cells(r, 24).Value)), "lista", _
              Array("CÂMERA", "LICENÇA", "SOFTWARE", "SWITCH", "EQUIPAMENTO", "INTERFONE", _
                    "COLETOR FACIAL", "INFRAESTRUTURA", "SERVIÇO")

    FormFooter FormBottom() + 8, ActProc1("SalvarProduto", CStr(r)), ActIr("cadastros", "", "produtos"), _
               IIf(novo, "Cadastrar produto", "Salvar alterações")
End Sub
