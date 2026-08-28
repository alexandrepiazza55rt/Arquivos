Attribute VB_Name = "_INSTALAR"
Option Explicit
'==============================================================================
' _INSTALAR  -  Importa os demais modulos automaticamente
'
' Use este atalho se a opcao "Confiar no acesso ao modelo de objeto do projeto
' do VBA" estiver liberada (Arquivo > Opcoes > Central de Confiabilidade >
' Configuracoes da Central de Confiabilidade > Configuracoes de Macro).
'
' Se nao estiver, ignore este modulo e importe os arquivos .bas um a um
' (Arquivo > Importar Arquivo, no editor do VBA). O resultado e o mesmo.
'==============================================================================

Private Const CODIGO_THISWORKBOOK As String = _
    "Private Sub Workbook_Open()" & vbCrLf & _
    "    On Error Resume Next" & vbCrLf & _
    "    IniciarSistema" & vbCrLf & _
    "End Sub" & vbCrLf & vbCrLf & _
    "Private Sub Workbook_BeforeSave(ByVal SaveAsUI As Boolean, Cancel As Boolean)" & vbCrLf & _
    "    On Error Resume Next" & vbCrLf & _
    "    If SistemaAtivo Then PrepararParaSalvar" & vbCrLf & _
    "End Sub" & vbCrLf & vbCrLf & _
    "Private Sub Workbook_AfterSave(ByVal Success As Boolean)" & vbCrLf & _
    "    On Error Resume Next" & vbCrLf & _
    "    If SistemaAtivo Then Recarregar" & vbCrLf & _
    "End Sub" & vbCrLf & vbCrLf & _
    "Private Sub Workbook_BeforeClose(Cancel As Boolean)" & vbCrLf & _
    "    On Error Resume Next" & vbCrLf & _
    "    If SistemaAtivo Then PrepararParaSalvar" & vbCrLf & _
    "    RestaurarEstadoExcel" & vbCrLf & _
    "End Sub" & vbCrLf & vbCrLf & _
    "Private Sub Workbook_Deactivate()" & vbCrLf & _
    "    On Error Resume Next" & vbCrLf & _
    "    If SistemaAtivo Then RestaurarEstadoExcel" & vbCrLf & _
    "End Sub" & vbCrLf & vbCrLf & _
    "Private Sub Workbook_Activate()" & vbCrLf & _
    "    On Error Resume Next" & vbCrLf & _
    "    If SistemaAtivo Then Recarregar" & vbCrLf & _
    "End Sub"

Public Sub ImportarModulos()
    Dim pasta As String, arq As String, n As Long, ja As Long
    Dim vbp As Object, comp As Object

    On Error GoTo SemAcesso
    Set vbp = ThisWorkbook.VBProject
    On Error GoTo 0

    pasta = EscolherPasta()
    If pasta = "" Then Exit Sub
    If Right$(pasta, 1) <> "\" Then pasta = pasta & "\"

    arq = Dir(pasta & "*.bas")
    Do While arq <> ""
        If LCase$(arq) <> "_instalar.bas" Then
            Dim nome As String
            nome = Left$(arq, InStrRev(arq, ".") - 1)
            On Error Resume Next
            vbp.VBComponents.Remove vbp.VBComponents(nome)
            On Error GoTo 0
            vbp.VBComponents.Import pasta & arq
            n = n + 1
        End If
        arq = Dir
    Loop

    If n = 0 Then
        MsgBox "Nenhum arquivo .bas encontrado em:" & vbCrLf & pasta, vbExclamation, "Instalação"
        Exit Sub
    End If

    ' codigo do objeto EstaPasta_de_trabalho
    Dim cm As Object
    Set cm = vbp.VBComponents(ThisWorkbook.CodeName).CodeModule
    If InStr(cm.Lines(1, cm.CountOfLines), "Workbook_Open") = 0 Then
        cm.AddFromString CODIGO_THISWORKBOOK
    Else
        ja = 1
    End If

    MsgBox n & " módulo(s) importado(s) com sucesso." & vbCrLf & vbCrLf & _
           IIf(ja = 1, "O código de abertura automática já existia e foi mantido." & vbCrLf & vbCrLf, "") & _
           "Agora execute a macro InstalarSistema e depois salve o arquivo como .xlsm.", _
           vbInformation, "Instalação"
    Exit Sub

SemAcesso:
    MsgBox "O Excel não permitiu o acesso ao projeto do VBA." & vbCrLf & vbCrLf & _
           "Marque a opção:" & vbCrLf & _
           "Arquivo > Opções > Central de Confiabilidade > Configurações da Central de " & _
           "Confiabilidade > Configurações de Macro >" & vbCrLf & _
           """Confiar no acesso ao modelo de objeto de projeto do VBA""" & vbCrLf & vbCrLf & _
           "Se a empresa não liberar essa opção, importe os arquivos .bas manualmente " & _
           "(no editor do VBA: Arquivo > Importar Arquivo).", vbExclamation, "Instalação"
End Sub

Private Function EscolherPasta() As String
    Dim fd As Object
    On Error Resume Next
    Set fd = Application.FileDialog(4)   ' msoFileDialogFolderPicker
    On Error GoTo 0
    If fd Is Nothing Then
        EscolherPasta = InputBox("Caminho da pasta com os arquivos .bas:", "Instalação")
        Exit Function
    End If
    fd.Title = "Selecione a pasta com os arquivos .bas do sistema"
    If fd.Show = -1 Then EscolherPasta = fd.SelectedItems(1)
End Function
