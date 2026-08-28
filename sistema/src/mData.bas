Attribute VB_Name = "mData"
Option Explicit
'==============================================================================
' mData  -  Camada de acesso aos dados
'
' As abas de dados continuam sendo a fonte da verdade e continuam calculando por
' formula. Este modulo so le e escreve as COLUNAS DE ENTRADA; tudo que e
' calculado (SLA, situacao, conferencias, graficos) permanece a cargo das
' formulas que ja existem na pasta.
'==============================================================================

Public Const SH_PROJ   As String = "01_Projetos"
Public Const SH_ITENS  As String = "Cadastro"
Public Const SH_ESCOPO As String = "02_Escopo_Itens"
Public Const SH_SC     As String = "03_Compras_SC"
Public Const SH_OC     As String = "05_OC_Fornecedor"
Public Const SH_ENT    As String = "07_Entregas"
Public Const SH_HIST   As String = "08_Historico_Etapas"
Public Const SH_PARAM  As String = "09_Cadastros"
Public Const SH_VERIF  As String = "10_Verificacoes"
Public Const SH_GRAF   As String = "11_Base_Graficos"

Public Const HDR_ROW   As Long = 4
Public Const FIRST_ROW As Long = 5

'==============================================================================
' Acesso basico
'==============================================================================
Public Function Sh(ByVal nome As String) As Worksheet
    On Error Resume Next
    Set Sh = ThisWorkbook.Worksheets(nome)
    On Error GoTo 0
    If Sh Is Nothing Then
        Err.Raise vbObjectError + 513, "mData.Sh", _
                  "A aba '" & nome & "' nao foi encontrada nesta pasta de trabalho."
    End If
End Function

Public Function ShExists(ByVal nome As String) As Boolean
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(nome)
    On Error GoTo 0
    ShExists = Not ws Is Nothing
End Function

' Indice da coluna pelo texto do cabecalho (linha 4). 0 se nao existir.
Public Function ColOf(ByVal sheetName As String, ByVal header As String) As Long
    Dim ws As Worksheet, c As Long, h As String
    Set ws = Sh(sheetName)
    For c = 1 To 80
        h = UCase$(Trim$(CStr(ws.Cells(HDR_ROW, c).Value)))
        If h = UCase$(Trim$(header)) Then ColOf = c: Exit Function
    Next c
    ColOf = 0
End Function

' Ultima linha preenchida a partir de uma coluna-chave.
Public Function LastRow(ByVal sheetName As String, ByVal keyCol As Long) As Long
    Dim ws As Worksheet, r As Long
    Set ws = Sh(sheetName)
    r = ws.Cells(ws.Rows.Count, keyCol).End(xlUp).Row
    If r < FIRST_ROW Then r = FIRST_ROW - 1
    LastRow = r
End Function

' Primeira linha livre (a chave esta vazia).
Public Function FirstFreeRow(ByVal sheetName As String, ByVal keyCol As Long) As Long
    Dim ws As Worksheet, r As Long
    Set ws = Sh(sheetName)
    r = FIRST_ROW
    Do While Trim$(CStr(ws.Cells(r, keyCol).Value)) <> "" And r < 100000
        r = r + 1
    Loop
    FirstFreeRow = r
End Function

' Localiza a linha cujo valor da coluna-chave e igual a 'chave'.
Public Function FindRow(ByVal sheetName As String, ByVal keyCol As Long, ByVal chave As String) As Long
    Dim ws As Worksheet, r As Long, ult As Long
    If Trim$(chave) = "" Then FindRow = 0: Exit Function
    Set ws = Sh(sheetName)
    ult = LastRow(sheetName, keyCol)
    For r = FIRST_ROW To ult
        If Trim$(CStr(ws.Cells(r, keyCol).Value)) = Trim$(chave) Then FindRow = r: Exit Function
    Next r
    FindRow = 0
End Function

' Garante que a linha destino tenha as formulas das colunas calculadas.
' A pasta ja vem com formulas ate a linha ~152; alem disso, replicamos.
Public Sub EnsureFormulaRow(ByVal sheetName As String, ByVal r As Long, ByVal lastCol As Long)
    Dim ws As Worksheet, c As Long, origem As Long
    Set ws = Sh(sheetName)
    If r <= FIRST_ROW Then Exit Sub
    origem = r - 1
    For c = 1 To lastCol
        If ws.Cells(origem, c).HasFormula Then
            If Not ws.Cells(r, c).HasFormula Then
                ws.Cells(origem, c).Copy ws.Cells(r, c)
            End If
        End If
    Next c
    Application.CutCopyMode = False
End Sub

'==============================================================================
' Conversores tolerantes
'==============================================================================
Public Function SVal(ByVal v As Variant) As String
    If IsError(v) Then SVal = "" Else SVal = Trim$(CStr(v & ""))
End Function

Public Function NVal(ByVal v As Variant) As Double
    On Error Resume Next
    If IsError(v) Then NVal = 0: Exit Function
    If IsNumeric(v) Then NVal = CDbl(v) Else NVal = 0
    On Error GoTo 0
End Function

Public Function DVal(ByVal v As Variant) As Variant
    On Error Resume Next
    If IsError(v) Then DVal = Empty: Exit Function
    If IsDate(v) Then DVal = CDate(v) Else DVal = Empty
    On Error GoTo 0
End Function

Public Function FmtD(ByVal v As Variant) As String
    If IsDate(v) Then FmtD = Format$(CDate(v), "dd/mm/yyyy") Else FmtD = "—"
End Function

Public Function FmtN(ByVal v As Variant) As String
    If IsNumeric(v) Then FmtN = Format$(CDbl(v), "#,##0") Else FmtN = "—"
End Function

'==============================================================================
' Listas de apoio (abas de cadastro)
'==============================================================================
' Le uma coluna de 09_Cadastros a partir da linha 5 ate a primeira celula vazia.
Public Function ListaCol(ByVal col As String, Optional ByVal maxItens As Long = 400) As Variant
    Dim ws As Worksheet, r As Long, out() As String, n As Long
    Set ws = Sh(SH_PARAM)
    ReDim out(1 To maxItens)
    r = FIRST_ROW
    Do While r < FIRST_ROW + maxItens
        If Trim$(CStr(ws.Range(col & r).Value)) = "" Then Exit Do
        n = n + 1
        out(n) = Trim$(CStr(ws.Range(col & r).Value))
        r = r + 1
    Loop
    If n = 0 Then
        ListaCol = Array()
    Else
        ReDim Preserve out(1 To n)
        ListaCol = out
    End If
End Function

Public Function ListaStatus() As Variant:        ListaStatus = ListaCol("A"):        End Function
Public Function ListaUnidades() As Variant:      ListaUnidades = ListaCol("C"):      End Function
Public Function ListaAreas() As Variant:         ListaAreas = ListaCol("E"):         End Function
Public Function ListaResponsaveis() As Variant:  ListaResponsaveis = ListaCol("G"):  End Function
Public Function ListaMotivos() As Variant:       ListaMotivos = ListaCol("I"):       End Function
Public Function ListaSitFisica() As Variant:     ListaSitFisica = ListaCol("K"):     End Function
Public Function ListaCustodia() As Variant:      ListaCustodia = ListaCol("M"):      End Function
Public Function ListaEtapas() As Variant:        ListaEtapas = ListaCol("O"):        End Function

' SLA e responsavel padrao de uma etapa.
Public Function EtapaSLA(ByVal etapa As String) As Double
    Dim ws As Worksheet, r As Long
    Set ws = Sh(SH_PARAM)
    For r = FIRST_ROW To FIRST_ROW + 40
        If Trim$(CStr(ws.Range("O" & r).Value)) = "" Then Exit For
        If UCase$(Trim$(CStr(ws.Range("O" & r).Value))) = UCase$(Trim$(etapa)) Then
            EtapaSLA = NVal(ws.Range("Q" & r).Value): Exit Function
        End If
    Next r
End Function

Public Function EtapaResp(ByVal etapa As String) As String
    Dim ws As Worksheet, r As Long
    Set ws = Sh(SH_PARAM)
    For r = FIRST_ROW To FIRST_ROW + 40
        If Trim$(CStr(ws.Range("O" & r).Value)) = "" Then Exit For
        If UCase$(Trim$(CStr(ws.Range("O" & r).Value))) = UCase$(Trim$(etapa)) Then
            EtapaResp = SVal(ws.Range("P" & r).Value): Exit Function
        End If
    Next r
End Function

Public Function EtapaIndex(ByVal etapa As String) As Long
    Dim et As Variant, i As Long
    et = ListaEtapas()
    If Not IsArray(et) Then Exit Function
    On Error Resume Next
    For i = LBound(et) To UBound(et)
        If UCase$(Trim$(et(i))) = UCase$(Trim$(etapa)) Then EtapaIndex = i: Exit Function
    Next i
    On Error GoTo 0
End Function

'==============================================================================
' Parametros
'==============================================================================
Public Function DataRefer() As Date
    Dim v As Variant
    v = Sh(SH_PARAM).Range("T8").Value
    If IsDate(v) Then DataRefer = CDate(v) Else DataRefer = Date
End Function

Public Sub SetDataRefer(ByVal d As Date)
    Sh(SH_PARAM).Range("T8").Value = d
End Sub

Public Function SLATotal() As Double
    SLATotal = NVal(Sh(SH_PARAM).Range("T5").Value)
End Function

Public Function LimAtencao() As Double
    LimAtencao = NVal(Sh(SH_PARAM).Range("T6").Value)
    If LimAtencao <= 0 Then LimAtencao = 0.7
End Function

Public Function LimRisco() As Double
    LimRisco = NVal(Sh(SH_PARAM).Range("T7").Value)
    If LimRisco <= 0 Then LimRisco = 0.9
End Function

'==============================================================================
' Produtos
'==============================================================================
Public Function ProdutoDesc(ByVal codigo As String) As String
    Dim ws As Worksheet, r As Long
    Set ws = Sh(SH_PARAM)
    For r = FIRST_ROW To 900
        If Trim$(CStr(ws.Range("V" & r).Value)) = "" Then Exit For
        If Trim$(CStr(ws.Range("V" & r).Value)) = Trim$(codigo) Then
            ProdutoDesc = SVal(ws.Range("W" & r).Value): Exit Function
        End If
    Next r
End Function

Public Function ProdutosArray() As Variant
    Dim ws As Worksheet, r As Long, out() As String, n As Long
    Set ws = Sh(SH_PARAM)
    ReDim out(1 To 900)
    For r = FIRST_ROW To 900
        If Trim$(CStr(ws.Range("V" & r).Value)) = "" Then Exit For
        n = n + 1
        out(n) = SVal(ws.Range("V" & r).Value) & "  ·  " & SVal(ws.Range("W" & r).Value)
    Next r
    If n = 0 Then ProdutosArray = Array() Else ReDim Preserve out(1 To n): ProdutosArray = out
End Function

'==============================================================================
' Leitura em bloco (para renderizar listas rapidamente)
'==============================================================================
' Devolve o intervalo de dados de uma aba como matriz (1..n, 1..lastCol).
Public Function Bloco(ByVal sheetName As String, ByVal keyCol As Long, ByVal lastCol As Long) As Variant
    Dim ws As Worksheet, ult As Long
    Set ws = Sh(sheetName)
    ult = LastRow(sheetName, keyCol)
    If ult < FIRST_ROW Then
        Bloco = Empty
    Else
        Bloco = ws.Range(ws.Cells(FIRST_ROW, 1), ws.Cells(ult, lastCol)).Value
    End If
End Function

Public Function BlocoLinhas(ByVal v As Variant) As Long
    If IsEmpty(v) Then BlocoLinhas = 0 Else BlocoLinhas = UBound(v, 1)
End Function

'==============================================================================
' Recalculo
'==============================================================================
Public Sub Recalcular()
    Application.CalculateFullRebuild
End Sub

'==============================================================================
' Folha de apoio interna (_APP)
'
' Guarda o rascunho dos formularios e as preferencias do sistema. Fica sempre
' muito oculta: nao aparece nem na lista de reexibir abas.
'==============================================================================
Public Function SysSheet() As Worksheet
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets("_APP")
    On Error GoTo 0
    If ws Is Nothing Then
        Application.EnableEvents = False
        Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        ws.Name = "_APP"
        Application.EnableEvents = True
    End If
    ws.Visible = xlSheetVeryHidden
    Set SysSheet = ws
End Function

' Preferencias simples (chave -> valor), gravadas nas colunas D/E de _APP.
Public Sub PrefSet(ByVal chave As String, ByVal valor As String)
    Dim sy As Worksheet, i As Long
    Set sy = SysSheet()
    For i = 1 To 60
        If Trim$(CStr(sy.Cells(i, 4).Value)) = chave Or Trim$(CStr(sy.Cells(i, 4).Value)) = "" Then
            sy.Cells(i, 4).Value = chave
            sy.Cells(i, 5).Value = valor
            Exit Sub
        End If
    Next i
End Sub

Public Function PrefGet(ByVal chave As String, Optional ByVal padrao As String = "") As String
    Dim sy As Worksheet, i As Long
    Set sy = SysSheet()
    For i = 1 To 60
        If Trim$(CStr(sy.Cells(i, 4).Value)) = chave Then
            PrefGet = Trim$(CStr(sy.Cells(i, 5).Value & ""))
            Exit Function
        End If
    Next i
    PrefGet = padrao
End Function
