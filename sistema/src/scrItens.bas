Attribute VB_Name = "scrItens"
Option Explicit
'==============================================================================
' scrItens  -  Cadastro unico de itens e auditoria quantitativa do escopo
'==============================================================================

Public Sub ItensRender()
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim d As Variant, n As Long, i As Long, m As Long, idx() As Long, cap As Long

    Set ws = Canvas()
    x = ContentX: w = ContentW

    d = Bloco(SH_ESCOPO, ES_CHAMADO, ES_ULT)
    n = BlocoLinhas(d)

    y = RenderShell("Itens e escopo", "Cada item aparece uma única vez; as quantidades se acumulam por etapa")

    ' resumo do funil
    Dim prev As Double, comp As Double, receb As Double, inst As Double, desv As Long
    For i = 1 To n
        If SVal(d(i, ES_CHAMADO)) <> "" And PassaUnidade(SVal(d(i, ES_UNID))) Then
            prev = prev + NVal(d(i, ES_PREV))
            comp = comp + NVal(d(i, ES_COMP))
            receb = receb + NVal(d(i, ES_RECEB))
            inst = inst + NVal(d(i, ES_INST))
            If NVal(d(i, ES_DESVIO)) > 0 Then desv = desv + 1
        End If
    Next i

    Dim cw As Double
    cw = (w - GAP * 4) / 5
    KpiCard ws, x, y, cw, 96, "Itens no escopo", CStr(ContaItens(d, n)), "linhas de produto", clrMuted, "", clrAccent
    KpiCard ws, x + (cw + GAP), y, cw, 96, "Previsto", Format$(prev, "#,##0"), "quantidade planejada", clrMuted
    KpiCard ws, x + (cw + GAP) * 2, y, cw, 96, "Comprado", Format$(comp, "#,##0"), Pc(comp, prev) & " do previsto", clrInfo
    KpiCard ws, x + (cw + GAP) * 3, y, cw, 96, "Recebido", Format$(receb, "#,##0"), Pc(receb, comp) & " do comprado", clrAccent
    KpiCard ws, x + (cw + GAP) * 4, y, cw, 96, "Com desvio", CStr(desv), _
            IIf(desv = 0, "escopo consistente", "verifique as quantidades"), _
            IIf(desv = 0, clrMuted, clrDanger), ActIr("conferencia"), clrDanger
    y = y + 96 + GAP

    y = y + Toolbar(x, y, w, "Novo item", ActIr("item_form"), _
                    IIf(gFUnidade = "(TODAS AS UNIDADES)", "Todas as unidades", gFUnidade), _
                    ActProc("AbrirFiltroUnidade"))

    ReDim idx(1 To IIf(n = 0, 1, n))
    For i = 1 To n
        If SVal(d(i, ES_CHAMADO)) <> "" And PassaUnidade(SVal(d(i, ES_UNID))) Then
            If Casa(d(i, ES_CHAMADO), d(i, ES_COD), d(i, ES_DESC), d(i, ES_TIPO), d(i, ES_STATUS)) Then
                m = m + 1: idx(m) = i
            End If
        End If
    Next i

    GridBegin x, y, w
    GridCol "Chamado", 90, 1, "strong"
    GridCol "Código", 84
    GridCol "Descrição do produto", 0
    GridCol "Tipo", 108, 1, "dim"
    GridCol "Prev.", 58, 2
    GridCol "Solic.", 58, 2
    GridCol "Compr.", 58, 2
    GridCol "Receb.", 58, 2
    GridCol "Lib.", 58, 2
    GridCol "Inst.", 58, 2
    GridCol "VMS", 58, 2
    GridCol "Status quantitativo", 200, 1, "badge"
    GridCol "", 26, 3, "chevron"

    cap = GridCapacity(y)
    Dim de As Long, ate As Long, k As Long, q As Long
    de = (gPagina - 1) * cap + 1
    If de > m Then de = 1: gPagina = 1
    ate = de + cap - 1
    If ate > m Then ate = m
    q = ate - de + 1

    If q <= 0 Then
        GridDraw Empty, 0, Empty
        EmptyState ws, x, y + 40, w, 180, "Nenhum item encontrado", _
                   "Cadastre os produtos previstos para cada chamado."
        Exit Sub
    End If

    Dim lin() As Variant, ch() As String
    ReDim lin(1 To q, 1 To 13): ReDim ch(1 To q)
    For k = 1 To q
        i = idx(de + k - 1)
        lin(k, 1) = SVal(d(i, ES_CHAMADO))
        lin(k, 2) = SVal(d(i, ES_COD))
        lin(k, 3) = SVal(d(i, ES_DESC))
        lin(k, 4) = SVal(d(i, ES_TIPO))
        lin(k, 5) = FmtN(d(i, ES_PREV))
        lin(k, 6) = FmtN(d(i, ES_SOLIC))
        lin(k, 7) = FmtN(d(i, ES_COMP))
        lin(k, 8) = FmtN(d(i, ES_RECEB))
        lin(k, 9) = FmtN(d(i, ES_LIB))
        lin(k, 10) = FmtN(d(i, ES_INST))
        lin(k, 11) = FmtN(d(i, ES_VMS))
        lin(k, 12) = SVal(d(i, ES_STATUS))
        lin(k, 13) = ""
        ch(k) = CStr(i + FIRST_ROW - 1)
    Next k

    GridDraw lin, q, ch, "item_form"
    GridPager x, ViewH - 52, w, m, gPagina, cap
End Sub

Private Function ContaItens(ByVal d As Variant, ByVal n As Long) As Long
    Dim i As Long
    For i = 1 To n
        If SVal(d(i, ES_CHAMADO)) <> "" And PassaUnidade(SVal(d(i, ES_UNID))) Then ContaItens = ContaItens + 1
    Next i
End Function

Private Function Pc(ByVal a As Double, ByVal b As Double) As String
    If b = 0 Then Pc = "—" Else Pc = Format$(a / b, "0%")
End Function

'==============================================================================
' FORMULARIO DO ITEM
'==============================================================================
Public Sub ItemFormRender(ByVal ctx As String)
    Dim ws As Worksheet, x As Double, w As Double, y As Double
    Dim cad As Worksheet, r As Long, novo As Boolean

    Set ws = Canvas()
    x = ContentX: w = ContentW
    Set cad = Sh(SH_ITENS)

    r = 0
    If ctx <> "" Then
        If IsNumeric(ctx) Then
            r = CLng(ctx)
        Else
            r = FindRow(SH_ITENS, IT_ID, ctx)
        End If
    End If
    If r < FIRST_ROW Then r = 0
    novo = (r = 0)

    y = RenderShell(IIf(novo, "Novo item", "Editar item"), _
                    IIf(novo, "Um item por produto e por chamado", _
                              CelTxt(cad, r, IT_ID) & "  ·  " & CelTxt(cad, r, IT_DESC)), _
                    "itens")

    FormBegin x, y, w, 4
    FormCompacto

    FormSection "Item do projeto", "identificação do produto previsto no escopo"
    FormField "chamado", "Nº do chamado", CelTxt(cad, r, IT_CHAMADO), "texto"
    FormField "cod", "Código do produto", CelTxt(cad, r, IT_COD), "texto", , 1, _
              "descrição e tipo vêm do cadastro de produtos"
    FormField "qprev", "Qtd. prevista", CelNum(cad, r, IT_QPREV), "numero"
    FormField "descr", "Descrição", CelTxt(cad, r, IT_DESC), "leitura"

    FormSection "Solicitação de compra", "acompanhamento do fluxo de suprimentos"
    FormField "req", "Nº requisição", CelTxt(cad, r, IT_REQ), "texto"
    FormField "sc", "Nº SC", CelTxt(cad, r, IT_SC), "texto"
    FormField "qreq", "Qtd. requisitada", CelNum(cad, r, IT_QREQ), "numero"
    FormField "comprador", "Comprador", CelTxt(cad, r, IT_COMPRADOR), "texto"
    FormField "dtreq", "Data da requisição", CelData(cad, r, IT_DTREQ), "data"
    FormField "enviosup", "Envio ao suprimentos", CelData(cad, r, IT_ENVIOSUP), "data"

    FormSection "Ordem de compra", "dados do fornecedor e do prazo de entrega"
    FormField "oc", "Nº OC", CelTxt(cad, r, IT_OC), "texto"
    FormField "forn", "Fornecedor", CelTxt(cad, r, IT_FORN), "texto", , 2
    FormField "qcomp", "Qtd. comprada", CelNum(cad, r, IT_QCOMP), "numero"
    FormField "dtoc", "Data da OC", CelData(cad, r, IT_DTOC), "data"
    FormField "prevent", "Previsão de entrega", CelData(cad, r, IT_PREVENT), "data"

    FormSection "Evolução física", "o recebido é somado automaticamente pelas notas lançadas"
    FormField "qreceb", "Qtd. recebida", IIf(novo, "0", CelNum(cad, r, IT_QRECEB)), "leitura"
    FormField "qlib", "Qtd. liberada", CelNum(cad, r, IT_QLIB), "numero"
    FormField "qinst", "Qtd. instalada", CelNum(cad, r, IT_QINST), "numero"
    FormField "ips", "IPs disponibilizados", CelNum(cad, r, IT_IPS), "numero"
    FormField "qvms", "Qtd. incluída no VMS", CelNum(cad, r, IT_QVMS), "numero"

    FormFooter FormBottom() + 8, ActProc1("SalvarItem", CStr(r)), ActIr("itens"), _
               IIf(novo, "Cadastrar item", "Salvar alterações"), _
               IIf(novo, "", ActProc1("ExcluirItem", CStr(r)))
End Sub
