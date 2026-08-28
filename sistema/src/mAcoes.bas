Attribute VB_Name = "mAcoes"
Option Explicit
'==============================================================================
' mAcoes  -  Gravacao e regras de negocio
'
' Regra importante: o sistema NUNCA apaga linhas das abas de dados. As abas
' derivadas (02, 03, 05) referenciam a aba Cadastro linha a linha; excluir uma
' linha quebraria essas formulas. Excluir aqui significa limpar as colunas de
' entrada da linha, deixando-a livre para o proximo cadastro.
'==============================================================================

'==============================================================================
' PROJETOS
'==============================================================================
Public Sub SalvarProjeto(ByVal chamado As String)
    Dim ps As Worksheet, r As Long, novo As Boolean, ch As String
    On Error GoTo Falhou
    Set ps = Sh(SH_PROJ)

    ch = UCase$(Trim$(FormValor("chamado")))
    If ch = "" Then ch = chamado
    novo = (FindRow(SH_PROJ, PJ_CHAMADO, chamado) = 0)

    If ch = "" Then Aviso "Informe o número do chamado.", "ERRO": Recarregar: Exit Sub
    If FormValor("nome") = "" Then Aviso "Informe o nome do projeto.", "ERRO": Recarregar: Exit Sub
    If FormValor("unidade") = "" Then Aviso "Selecione a unidade.", "ERRO": Recarregar: Exit Sub
    If UCase$(FormValor("bloq")) = "SIM" And FormValor("motivo") = "" Then
        Aviso "Projeto bloqueado exige o motivo do bloqueio.", "ERRO": Recarregar: Exit Sub
    End If

    If novo Then
        If FindRow(SH_PROJ, PJ_CHAMADO, ch) > 0 Then
            Aviso "Já existe um projeto com o chamado " & ch & ".", "ERRO": Recarregar: Exit Sub
        End If
        r = FirstFreeRow(SH_PROJ, PJ_CHAMADO)
        EnsureFormulaRow SH_PROJ, r, PJ_ULT
    Else
        r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    End If

    Dim etapaAnterior As String
    etapaAnterior = SVal(ps.Cells(r, PJ_ETAPA).Value)

    Application.EnableEvents = False
    ps.Cells(r, PJ_CHAMADO).Value = ValorNumOuTexto(ch)
    ps.Cells(r, PJ_NOME).Value = UCase$(FormValor("nome"))
    ps.Cells(r, PJ_UNID).Value = FormValor("unidade")
    ps.Cells(r, PJ_AREA).Value = FormValor("area")
    ps.Cells(r, PJ_OBJCOD).Value = ValorNumOuTexto(FormValor("objcod"))
    ps.Cells(r, PJ_RESPDEM).Value = UCase$(FormValor("respdem"))
    GravarData ps.Cells(r, PJ_ABERTURA), FormData("abertura")
    ps.Cells(r, PJ_ETAPA).Value = FormValor("etapa")
    GravarData ps.Cells(r, PJ_INIETAPA), FormData("inietapa")
    ps.Cells(r, PJ_STATUS).Value = FormValor("status")
    ps.Cells(r, PJ_BLOQ).Value = IIf(UCase$(FormValor("bloq")) = "SIM", "SIM", "NÃO")
    ps.Cells(r, PJ_DIFIC).Value = FormValor("motivo")
    ps.Cells(r, PJ_PROXACAO).Value = UCase$(FormValor("proxacao"))
    Application.EnableEvents = True

    If novo Then
        AbrirHistorico ch, FormValor("etapa"), FormData("inietapa")
    ElseIf etapaAnterior <> FormValor("etapa") Then
        FecharHistorico ch, etapaAnterior, FormData("inietapa")
        AbrirHistorico ch, FormValor("etapa"), FormData("inietapa")
    End If

    Recalcular
    Aviso IIf(novo, "Projeto " & ch & " cadastrado.", "Projeto " & ch & " atualizado."), "OK"
    Ir "projeto", ch
    Exit Sub

Falhou:
    Application.EnableEvents = True
    Aviso "Não foi possível salvar: " & Err.Description, "ERRO"
    Recarregar
End Sub

Public Sub ExcluirProjeto(ByVal chamado As String)
    Dim ps As Worksheet, r As Long, c As Variant
    If MsgBox("Remover o projeto " & chamado & " do controle?" & vbCrLf & vbCrLf & _
              "Os itens e as notas já lançadas continuam nas respectivas abas.", _
              vbYesNo + vbQuestion, APP_NOME) <> vbYes Then Exit Sub
    Set ps = Sh(SH_PROJ)
    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    If r = 0 Then Exit Sub
    Application.EnableEvents = False
    For Each c In Array(PJ_CHAMADO, PJ_NOME, PJ_UNID, PJ_AREA, PJ_OBJCOD, PJ_RESPDEM, PJ_ABERTURA, _
                        PJ_ETAPA, PJ_INIETAPA, PJ_STATUS, PJ_BLOQ, PJ_DIFIC, PJ_PROXACAO)
        ps.Cells(r, c).ClearContents
    Next c
    Application.EnableEvents = True
    Recalcular
    Aviso "Projeto " & chamado & " removido do controle.", "OK"
    Ir "projetos"
End Sub

'--- avanco de etapa ----------------------------------------------------------
Public Sub AvancarEtapa(ByVal chamado As String)
    Dim et As Variant, i As Long, n As Long, atual As String, sug As String
    Dim opc() As String, r As Long

    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    If r = 0 Then Exit Sub
    atual = SVal(Sh(SH_PROJ).Cells(r, PJ_ETAPA).Value)

    et = ListaEtapas()
    n = UBound(et) - LBound(et) + 1
    If n < 1 Then Aviso "Nenhuma etapa cadastrada em 09_Cadastros.", "ERRO": Recarregar: Exit Sub
    ReDim opc(1 To n + 1)
    For i = 1 To n
        opc(i) = CStr(et(LBound(et) + i - 1))
    Next i
    opc(n + 1) = "CONCLUIR O PROJETO"

    i = EtapaIndex(atual)
    If i > 0 And i < n Then sug = CStr(et(LBound(et) + i)) Else sug = "CONCLUIR O PROJETO"

    PrefSet "etapa_chamado", chamado
    Popup "Avançar o chamado " & chamado & " para:", opc, "MoverParaEtapa", sug
End Sub

Public Sub MoverParaEtapa(ByVal destino As String)
    Dim chamado As String, ps As Worksheet, r As Long, atual As String
    chamado = PrefGet("etapa_chamado")
    If chamado = "" Then Recarregar: Exit Sub

    Set ps = Sh(SH_PROJ)
    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    If r = 0 Then Recarregar: Exit Sub
    atual = SVal(ps.Cells(r, PJ_ETAPA).Value)

    Application.EnableEvents = False
    FecharHistorico chamado, atual, DataRefer

    If UCase$(destino) = "CONCLUIR O PROJETO" Then
        ps.Cells(r, PJ_STATUS).Value = "CONCLUÍDO"
        ps.Cells(r, PJ_BLOQ).Value = "NÃO"
        Application.EnableEvents = True
        Recalcular
        Aviso "Chamado " & chamado & " concluído.", "OK"
    Else
        ps.Cells(r, PJ_ETAPA).Value = destino
        ps.Cells(r, PJ_INIETAPA).Value = DataRefer
        ps.Cells(r, PJ_STATUS).Value = "EM ANDAMENTO"
        Application.EnableEvents = True
        AbrirHistorico chamado, destino, DataRefer
        Recalcular
        Aviso "Chamado " & chamado & " avançou para " & destino & ".", "OK"
    End If
    Ir "projeto", chamado
End Sub

Public Sub AlternarBloqueio(ByVal chamado As String)
    Dim ps As Worksheet, r As Long
    Set ps = Sh(SH_PROJ)
    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    If r = 0 Then Exit Sub

    If UCase$(SVal(ps.Cells(r, PJ_BLOQ).Value)) = "SIM" Then
        ps.Cells(r, PJ_BLOQ).Value = "NÃO"
        Recalcular
        Aviso "Bloqueio removido do chamado " & chamado & ".", "OK"
        Ir "projeto", chamado
    Else
        PrefSet "bloq_chamado", chamado
        Popup "Motivo do bloqueio do chamado " & chamado, ListaMotivos(), "ConfirmarBloqueio", _
              SVal(ps.Cells(r, PJ_DIFIC).Value)
    End If
End Sub

Public Sub ConfirmarBloqueio(ByVal motivo As String)
    Dim ps As Worksheet, r As Long, chamado As String
    chamado = PrefGet("bloq_chamado")
    Set ps = Sh(SH_PROJ)
    r = FindRow(SH_PROJ, PJ_CHAMADO, chamado)
    If r = 0 Then Recarregar: Exit Sub
    ps.Cells(r, PJ_BLOQ).Value = "SIM"
    ps.Cells(r, PJ_DIFIC).Value = motivo
    Recalcular
    Aviso "Chamado " & chamado & " bloqueado: " & motivo, "ATENÇÃO"
    Ir "projeto", chamado
End Sub

'--- historico ----------------------------------------------------------------
Private Sub AbrirHistorico(ByVal chamado As String, ByVal etapa As String, ByVal inicio As Variant)
    Dim hs As Worksheet, r As Long
    If chamado = "" Or etapa = "" Then Exit Sub
    Set hs = Sh(SH_HIST)
    r = FirstFreeRow(SH_HIST, HI_CHAMADO)
    EnsureFormulaRow SH_HIST, r, HI_ULT
    hs.Cells(r, HI_CHAMADO).Value = chamado
    hs.Cells(r, HI_ETAPA).Value = etapa
    If IsDate(inicio) Then hs.Cells(r, HI_INICIO).Value = CDate(inicio) Else hs.Cells(r, HI_INICIO).Value = DataRefer
End Sub

Private Sub FecharHistorico(ByVal chamado As String, ByVal etapa As String, ByVal fim As Variant)
    Dim hs As Worksheet, r As Long, ult As Long
    If chamado = "" Or etapa = "" Then Exit Sub
    Set hs = Sh(SH_HIST)
    ult = LastRow(SH_HIST, HI_CHAMADO)
    For r = ult To FIRST_ROW Step -1
        If SVal(hs.Cells(r, HI_CHAMADO).Value) = chamado And _
           UCase$(SVal(hs.Cells(r, HI_ETAPA).Value)) = UCase$(etapa) Then
            If Not IsDate(hs.Cells(r, HI_FIM).Value) Then
                If IsDate(fim) Then hs.Cells(r, HI_FIM).Value = CDate(fim) Else hs.Cells(r, HI_FIM).Value = DataRefer
                Exit Sub
            End If
        End If
    Next r
End Sub

'==============================================================================
' ITENS
'==============================================================================
Public Sub SalvarItem(ByVal linha As String)
    Dim cad As Worksheet, r As Long, novo As Boolean, ch As String, cod As String
    On Error GoTo Falhou
    Set cad = Sh(SH_ITENS)

    r = 0
    If IsNumeric(linha) Then r = CLng(linha)
    novo = (r < FIRST_ROW)

    ch = UCase$(Trim$(FormValor("chamado")))
    cod = Trim$(FormValor("cod"))

    If ch = "" Then Aviso "Informe o número do chamado.", "ERRO": Recarregar: Exit Sub
    If cod = "" Then Aviso "Informe o código do produto.", "ERRO": Recarregar: Exit Sub
    If FindRow(SH_PROJ, PJ_CHAMADO, ch) = 0 Then
        Aviso "O chamado " & ch & " não está cadastrado em Projetos.", "ERRO": Recarregar: Exit Sub
    End If
    If ProdutoDesc(cod) = "" Then
        Aviso "O produto " & cod & " não está no cadastro de produtos. Cadastre-o primeiro.", "ERRO"
        Recarregar: Exit Sub
    End If
    If novo Then
        If FindRow(SH_ITENS, IT_ID, ch & "-" & cod) > 0 Then
            Aviso "Este produto já existe no chamado " & ch & ". Edite o item existente.", "ERRO"
            Recarregar: Exit Sub
        End If
        r = FirstFreeRow(SH_ITENS, IT_CHAMADO)
        EnsureFormulaRow SH_ITENS, r, IT_ULT
    End If

    Application.EnableEvents = False
    cad.Cells(r, IT_CHAMADO).Value = ch
    cad.Cells(r, IT_COD).Value = ValorNumOuTexto(cod)
    cad.Cells(r, IT_QPREV).Value = FormNum("qprev")
    cad.Cells(r, IT_REQ).Value = ValorNumOuTexto(FormValor("req"))
    cad.Cells(r, IT_SC).Value = ValorNumOuTexto(FormValor("sc"))
    cad.Cells(r, IT_QREQ).Value = FormNum("qreq")
    GravarData cad.Cells(r, IT_DTREQ), FormData("dtreq")
    GravarData cad.Cells(r, IT_ENVIOSUP), FormData("enviosup")
    cad.Cells(r, IT_COMPRADOR).Value = UCase$(FormValor("comprador"))
    cad.Cells(r, IT_OC).Value = ValorNumOuTexto(FormValor("oc"))
    cad.Cells(r, IT_FORN).Value = UCase$(FormValor("forn"))
    GravarData cad.Cells(r, IT_DTOC), FormData("dtoc")
    GravarData cad.Cells(r, IT_PREVENT), FormData("prevent")
    cad.Cells(r, IT_QCOMP).Value = FormNum("qcomp")
    cad.Cells(r, IT_QLIB).Value = FormNum("qlib")
    cad.Cells(r, IT_QINST).Value = FormNum("qinst")
    cad.Cells(r, IT_IPS).Value = FormNum("ips")
    cad.Cells(r, IT_QVMS).Value = FormNum("qvms")
    Application.EnableEvents = True

    Recalcular

    Dim alerta As String
    If FormNum("qinst") > FormNum("qlib") Then alerta = "instalado maior que liberado"
    If FormNum("qlib") > NVal(cad.Cells(r, IT_QRECEB).Value) Then alerta = "liberado maior que recebido"
    If alerta <> "" Then
        Aviso "Item salvo, mas confira as quantidades: " & alerta & ".", "ATENÇÃO"
    Else
        Aviso IIf(novo, "Item cadastrado no chamado " & ch & ".", "Item atualizado."), "OK"
    End If
    Ir "itens"
    Exit Sub

Falhou:
    Application.EnableEvents = True
    Aviso "Não foi possível salvar o item: " & Err.Description, "ERRO"
    Recarregar
End Sub

Public Sub ExcluirItem(ByVal linha As String)
    Dim cad As Worksheet, r As Long, c As Variant
    If Not IsNumeric(linha) Then Exit Sub
    r = CLng(linha)
    Set cad = Sh(SH_ITENS)
    If MsgBox("Remover o item " & SVal(cad.Cells(r, IT_ID).Value) & " do escopo?", _
              vbYesNo + vbQuestion, APP_NOME) <> vbYes Then Exit Sub
    Application.EnableEvents = False
    For Each c In Array(IT_CHAMADO, IT_COD, IT_QPREV, IT_REQ, IT_SC, IT_QREQ, IT_DTREQ, IT_ENVIOSUP, _
                        IT_COMPRADOR, IT_OC, IT_FORN, IT_DTOC, IT_PREVENT, IT_QCOMP, IT_QLIB, _
                        IT_QINST, IT_IPS, IT_QVMS)
        cad.Cells(r, c).ClearContents
    Next c
    Application.EnableEvents = True
    Recalcular
    Aviso "Item removido do escopo.", "OK"
    Ir "itens"
End Sub

'==============================================================================
' NOTAS / ENTREGAS
'==============================================================================
Public Sub SalvarNota(ByVal linha As String)
    Dim es As Worksheet, cad As Worksheet, r As Long, novo As Boolean
    Dim rotulo As String, ri As Long, qtd As Double, saldo As Double
    On Error GoTo Falhou
    Set es = Sh(SH_ENT)
    Set cad = Sh(SH_ITENS)

    r = 0
    If IsNumeric(linha) Then r = CLng(linha)
    novo = (r < FIRST_ROW)

    If novo Then rotulo = RascunhoValor("item") Else rotulo = SVal(es.Cells(r, EN_ITEM).Value)

    If rotulo = "" Then Aviso "Selecione o item que está sendo recebido.", "ERRO": Recarregar: Exit Sub
    If FormValor("nf") = "" Then Aviso "Informe o número da NF ou da remessa.", "ERRO": Recarregar: Exit Sub
    If Not IsDate(FormData("data")) Then Aviso "Informe a data de recebimento.", "ERRO": Recarregar: Exit Sub
    qtd = FormNum("qtd")
    If qtd <= 0 Then Aviso "A quantidade recebida deve ser maior que zero.", "ERRO": Recarregar: Exit Sub
    If FormValor("unid") = "" Then Aviso "Informe a unidade recebedora.", "ERRO": Recarregar: Exit Sub
    If FormValor("custodia") = "" Then Aviso "Informe onde o material ficará em custódia.", "ERRO": Recarregar: Exit Sub

    ri = LinhaDoRotulo(rotulo)
    saldo = NVal(cad.Cells(ri, IT_QCOMP).Value) - NVal(cad.Cells(ri, IT_QRECEB).Value)
    If Not novo Then saldo = saldo + NVal(es.Cells(r, EN_QTD).Value)

    If qtd > saldo Then
        If MsgBox("A quantidade informada (" & Format$(qtd, "#,##0") & ") passa do saldo da ordem de compra (" & _
                  Format$(saldo, "#,##0") & ")." & vbCrLf & vbCrLf & _
                  "Lançar assim mesmo? A nota ficará marcada como divergente.", _
                  vbYesNo + vbExclamation, APP_NOME) <> vbYes Then
            Recarregar: Exit Sub
        End If
    End If

    If novo Then
        r = FirstFreeRow(SH_ENT, EN_NF)
        EnsureFormulaRow SH_ENT, r, EN_ULT
    End If

    Application.EnableEvents = False
    es.Cells(r, EN_NF).Value = ValorNumOuTexto(FormValor("nf"))
    es.Cells(r, EN_ITEM).Value = rotulo
    es.Cells(r, EN_DATA).Value = FormData("data")
    es.Cells(r, EN_QTD).Value = qtd
    es.Cells(r, EN_UNID).Value = FormValor("unid")
    es.Cells(r, EN_CUSTODIA).Value = FormValor("custodia")
    es.Cells(r, EN_SITFIS).Value = IIf(FormValor("sitfis") = "", "PENDENTE DE CONFERÊNCIA", FormValor("sitfis"))
    es.Cells(r, EN_OBS).Value = FormValor("obs")
    Application.EnableEvents = True

    RascunhoLimpar
    Recalcular

    If UCase$(SVal(es.Cells(r, EN_CONF).Value)) <> "OK" Then
        Aviso "Nota lançada com divergência: " & SVal(es.Cells(r, EN_CONF).Value) & ".", "ATENÇÃO"
    Else
        Aviso "Nota " & FormValor("nf") & " lançada. Saldo do item atualizado.", "OK"
    End If
    Ir "notas"
    Exit Sub

Falhou:
    Application.EnableEvents = True
    Aviso "Não foi possível lançar a nota: " & Err.Description, "ERRO"
    Recarregar
End Sub

Public Sub ExcluirNota(ByVal linha As String)
    Dim es As Worksheet, r As Long, c As Variant
    If Not IsNumeric(linha) Then Exit Sub
    r = CLng(linha)
    Set es = Sh(SH_ENT)
    If MsgBox("Estornar o lançamento da nota " & SVal(es.Cells(r, EN_NF).Value) & "?" & vbCrLf & _
              "A quantidade recebida do item volta ao saldo anterior.", _
              vbYesNo + vbQuestion, APP_NOME) <> vbYes Then Exit Sub
    Application.EnableEvents = False
    For Each c In Array(EN_NF, EN_ITEM, EN_DATA, EN_QTD, EN_UNID, EN_CUSTODIA, EN_SITFIS, EN_OBS)
        es.Cells(r, c).ClearContents
    Next c
    Application.EnableEvents = True
    RascunhoLimpar
    Recalcular
    Aviso "Lançamento estornado.", "OK"
    Ir "notas"
End Sub

Public Sub ConferirNota(ByVal linha As String)
    Dim es As Worksheet, r As Long
    If Not IsNumeric(linha) Then Exit Sub
    r = CLng(linha)
    Set es = Sh(SH_ENT)
    es.Cells(r, EN_SITFIS).Value = "CONFERIDO"
    Recalcular
    Aviso "Nota " & SVal(es.Cells(r, EN_NF).Value) & " marcada como conferida.", "OK"
    Recarregar
End Sub

'==============================================================================
' CADASTROS
'==============================================================================
Public Sub SalvarParametros()
    Dim ps As Worksheet, et As Variant, i As Long, n As Long
    On Error GoTo Falhou
    Set ps = Sh(SH_PARAM)

    If IsDate(FormData("dataref")) Then ps.Range("T8").Value = FormData("dataref")
    If FormNum("slatotal") > 0 Then ps.Range("T5").Value = FormNum("slatotal")
    If FormNum("limaten") > 0 Then ps.Range("T6").Value = FormNum("limaten")
    If FormNum("limrisco") > 0 Then ps.Range("T7").Value = FormNum("limrisco")

    et = ListaEtapas()
    n = UBound(et) - LBound(et) + 1
    If n > 0 Then
        For i = 1 To n
            ps.Cells(FIRST_ROW + i - 1, 17).Value = FormNum("sla" & i)
        Next i
        ps.Range("Q18").Value = Application.WorksheetFunction.Sum( _
            ps.Range(ps.Cells(FIRST_ROW, 17), ps.Cells(FIRST_ROW + n - 1, 17)))
    End If

    Recalcular
    Aviso "Parâmetros atualizados.", "OK"
    Ir "cadastros", "", "param"
    Exit Sub
Falhou:
    Aviso "Não foi possível salvar os parâmetros: " & Err.Description, "ERRO"
    Recarregar
End Sub

Public Sub SalvarProduto(ByVal linha As String)
    Dim ps As Worksheet, r As Long, novo As Boolean, cod As String
    Set ps = Sh(SH_PARAM)
    r = 0
    If IsNumeric(linha) Then r = CLng(linha)
    novo = (r < FIRST_ROW)

    cod = Trim$(FormValor("cod"))
    If cod = "" Then Aviso "Informe o código do produto.", "ERRO": Recarregar: Exit Sub
    If FormValor("desc") = "" Then Aviso "Informe a descrição do produto.", "ERRO": Recarregar: Exit Sub

    If novo Then
        r = FIRST_ROW
        Do While Trim$(CStr(ps.Cells(r, 22).Value)) <> "" And r < 1200
            If Trim$(CStr(ps.Cells(r, 22).Value)) = cod Then
                Aviso "O código " & cod & " já está cadastrado.", "ERRO": Recarregar: Exit Sub
            End If
            r = r + 1
        Loop
    End If

    ps.Cells(r, 22).Value = ValorNumOuTexto(cod)
    ps.Cells(r, 23).Value = UCase$(FormValor("desc"))
    ps.Cells(r, 24).Value = UCase$(FormValor("tipo"))

    Recalcular
    Aviso IIf(novo, "Produto cadastrado.", "Produto atualizado."), "OK"
    Ir "cadastros", "", "produtos"
End Sub

' Acrescenta um valor ao fim de uma das listas de 09_Cadastros e amplia o
' intervalo nomeado correspondente, para que as validacoes enxerguem o novo item.
Public Sub AdicionarNaLista(ByVal coluna As String)
    Dim ps As Worksheet, r As Long, v As Variant, nome As String
    Set ps = Sh(SH_PARAM)

    v = InputBox("Novo valor para a lista:", APP_NOME)
    If StrPtr(v) = 0 Then Exit Sub
    If Trim$(CStr(v)) = "" Then Exit Sub

    r = FIRST_ROW
    Do While Trim$(CStr(ps.Range(coluna & r).Value)) <> "" And r < 900
        r = r + 1
    Loop
    ps.Range(coluna & r).Value = UCase$(Trim$(CStr(v)))

    If UCase$(coluna) = "O" Then
        Dim resp As Variant, sla As Variant
        resp = InputBox("Responsável padrão desta etapa:", APP_NOME, "MONITORAMENTO")
        sla = InputBox("SLA da etapa, em dias:", APP_NOME, "10")
        ps.Range("P" & r).Value = UCase$(Trim$(CStr(resp)))
        If IsNumeric(sla) Then ps.Range("Q" & r).Value = CDbl(sla)
        RedefinirNome "Lista_Etapas", "O", r
        RedefinirNome "Etapa_Resp", "P", r
        RedefinirNome "Etapa_SLA", "Q", r
    Else
        nome = NomeDaLista(coluna)
        If nome <> "" Then RedefinirNome nome, coluna, r
    End If

    Recalcular
    Aviso "Valor incluído na lista.", "OK"
    Recarregar
End Sub

Private Function NomeDaLista(ByVal coluna As String) As String
    Select Case UCase$(coluna)
        Case "A": NomeDaLista = "Lista_Status"
        Case "C": NomeDaLista = "Lista_Unidades"
        Case "E": NomeDaLista = "Lista_Areas"
        Case "G": NomeDaLista = "Lista_Responsaveis"
        Case "I": NomeDaLista = "Lista_Motivos"
        Case "K": NomeDaLista = "Lista_SitFisica"
        Case "M": NomeDaLista = "Lista_Custodia"
    End Select
End Function

Private Sub RedefinirNome(ByVal nome As String, ByVal coluna As String, ByVal ultimaLinha As Long)
    On Error Resume Next
    ThisWorkbook.Names(nome).Delete
    ThisWorkbook.Names.Add Name:=nome, _
        RefersTo:="='" & SH_PARAM & "'!$" & coluna & "$" & FIRST_ROW & ":$" & coluna & "$" & ultimaLinha
    On Error GoTo 0
End Sub

'==============================================================================
' Auxiliares de gravacao
'==============================================================================
Private Sub GravarData(rg As Range, ByVal v As Variant)
    If IsDate(v) Then rg.Value = CDate(v) Else rg.ClearContents
End Sub

' Numeros de chamado, SC, OC e NF sao gravados como numero quando possivel,
' porque as formulas da pasta comparam com os valores originais.
Private Function ValorNumOuTexto(ByVal s As String) As Variant
    s = Trim$(s)
    If s = "" Then
        ValorNumOuTexto = ""
    ElseIf IsNumeric(s) And Len(s) < 15 And InStr(s, ",") = 0 And InStr(s, ".") = 0 Then
        ValorNumOuTexto = CDbl(s)
    Else
        ValorNumOuTexto = UCase$(s)
    End If
End Function
