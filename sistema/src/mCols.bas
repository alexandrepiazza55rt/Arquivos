Attribute VB_Name = "mCols"
Option Explicit
'==============================================================================
' mCols  -  Numeros das colunas das abas de dados
'
' Mantido separado para que qualquer mudanca de layout das abas seja resolvida
' num unico lugar. Colunas marcadas com (f) sao calculadas por formula e nunca
' devem ser escritas pelo sistema.
'==============================================================================

'--- 01_Projetos --------------------------------------------------------------
Public Const PJ_CHAMADO   As Long = 1
Public Const PJ_NOME      As Long = 2
Public Const PJ_UNID      As Long = 3
Public Const PJ_AREA      As Long = 4
Public Const PJ_OBJCOD    As Long = 5
Public Const PJ_OBJDESC   As Long = 6    ' (f)
Public Const PJ_RESPDEM   As Long = 7
Public Const PJ_ABERTURA  As Long = 8
Public Const PJ_ETAPA     As Long = 9
Public Const PJ_RESP      As Long = 10   ' (f)
Public Const PJ_INIETAPA  As Long = 11
Public Const PJ_STATUS    As Long = 12
Public Const PJ_BLOQ      As Long = 13
Public Const PJ_DIFIC     As Long = 14
Public Const PJ_PROXACAO  As Long = 15
Public Const PJ_SLA       As Long = 16   ' (f)
Public Const PJ_DIASETAPA As Long = 17   ' (f)
Public Const PJ_CONSUMO   As Long = 18   ' (f)
Public Const PJ_DIASTOT   As Long = 19   ' (f)
Public Const PJ_ATRASO    As Long = 20   ' (f)
Public Const PJ_SITUACAO  As Long = 21   ' (f)
Public Const PJ_MOTIVO    As Long = 22   ' (f)
Public Const PJ_CAMPREV   As Long = 23   ' (f)
Public Const PJ_CAMRECEB  As Long = 24   ' (f)
Public Const PJ_CAMINST   As Long = 25   ' (f)
Public Const PJ_LICNEC    As Long = 26   ' (f)
Public Const PJ_LICRECEB  As Long = 27   ' (f)
Public Const PJ_DESVIOS   As Long = 28   ' (f)
Public Const PJ_DIVINST   As Long = 29   ' (f)
Public Const PJ_ULT       As Long = 32

'--- Cadastro (itens) ---------------------------------------------------------
Public Const IT_ID        As Long = 1    ' (f)
Public Const IT_CHAMADO   As Long = 2
Public Const IT_COD       As Long = 3
Public Const IT_DESC      As Long = 4    ' (f)
Public Const IT_TIPO      As Long = 5    ' (f)
Public Const IT_QPREV     As Long = 6
Public Const IT_REQ       As Long = 7
Public Const IT_SC        As Long = 8
Public Const IT_QREQ      As Long = 9
Public Const IT_DTREQ     As Long = 10
Public Const IT_ENVIOSUP  As Long = 11
Public Const IT_COMPRADOR As Long = 12
Public Const IT_OC        As Long = 13
Public Const IT_FORN      As Long = 14
Public Const IT_DTOC      As Long = 15
Public Const IT_PREVENT   As Long = 16
Public Const IT_QCOMP     As Long = 17
Public Const IT_QLIB      As Long = 18
Public Const IT_QINST     As Long = 19
Public Const IT_IPS       As Long = 20
Public Const IT_QVMS      As Long = 21
Public Const IT_QRECEB    As Long = 22   ' (f)
Public Const IT_SIT       As Long = 23   ' (f)
Public Const IT_ROTULO    As Long = 24   ' (f)
Public Const IT_ULT       As Long = 24

'--- 02_Escopo_Itens ----------------------------------------------------------
Public Const ES_CHAMADO   As Long = 1
Public Const ES_COD       As Long = 2
Public Const ES_DESC      As Long = 3
Public Const ES_TIPO      As Long = 4
Public Const ES_PREV      As Long = 5
Public Const ES_SOLIC     As Long = 6
Public Const ES_COMP      As Long = 7
Public Const ES_RECEB     As Long = 8
Public Const ES_LIB       As Long = 9
Public Const ES_INST      As Long = 10
Public Const ES_IP        As Long = 11
Public Const ES_VMS       As Long = 12
Public Const ES_STATUS    As Long = 20
Public Const ES_SALDO     As Long = 21
Public Const ES_UNID      As Long = 22
Public Const ES_DESVIO    As Long = 25
Public Const ES_ULT       As Long = 25

'--- 03_Compras_SC ------------------------------------------------------------
Public Const SC_REQ       As Long = 1
Public Const SC_NUM       As Long = 2
Public Const SC_CHAMADO   As Long = 3
Public Const SC_COD       As Long = 4
Public Const SC_DESC      As Long = 5
Public Const SC_QTD       As Long = 6
Public Const SC_DTREQ     As Long = 7
Public Const SC_ENVIO     As Long = 8
Public Const SC_COMPRADOR As Long = 9
Public Const SC_QOC       As Long = 10
Public Const SC_SALDO     As Long = 11
Public Const SC_DTOC      As Long = 12
Public Const SC_DIAS      As Long = 13
Public Const SC_SLA       As Long = 14
Public Const SC_SIT       As Long = 15
Public Const SC_ULT       As Long = 15

'--- 05_OC_Fornecedor ---------------------------------------------------------
Public Const OC_NUM       As Long = 1
Public Const OC_SC        As Long = 2
Public Const OC_CHAMADO   As Long = 3
Public Const OC_COD       As Long = 4
Public Const OC_DESC      As Long = 5
Public Const OC_FORN      As Long = 6
Public Const OC_DATA      As Long = 7
Public Const OC_PREV      As Long = 8
Public Const OC_QCOMP     As Long = 9
Public Const OC_QRECEB    As Long = 10
Public Const OC_SALDO     As Long = 11
Public Const OC_ULTRECEB  As Long = 12
Public Const OC_DIAS      As Long = 13
Public Const OC_SLA       As Long = 14
Public Const OC_SIT       As Long = 15
Public Const OC_ULT       As Long = 15

'--- 07_Entregas --------------------------------------------------------------
Public Const EN_NF        As Long = 1
Public Const EN_ITEM      As Long = 2
Public Const EN_IDITEM    As Long = 3    ' (f)
Public Const EN_OC        As Long = 4    ' (f)
Public Const EN_SC        As Long = 5    ' (f)
Public Const EN_CHAMADO   As Long = 6    ' (f)
Public Const EN_COD       As Long = 7    ' (f)
Public Const EN_DESC      As Long = 8    ' (f)
Public Const EN_DATA      As Long = 9
Public Const EN_QTD       As Long = 10
Public Const EN_UNID      As Long = 11
Public Const EN_CUSTODIA  As Long = 12
Public Const EN_SITFIS    As Long = 13
Public Const EN_OBS       As Long = 14
Public Const EN_FORN      As Long = 15   ' (f)
Public Const EN_CONF      As Long = 16   ' (f)
Public Const EN_ULT       As Long = 16

'--- 08_Historico_Etapas ------------------------------------------------------
Public Const HI_CHAMADO   As Long = 1
Public Const HI_ETAPA     As Long = 2
Public Const HI_RESP      As Long = 3    ' (f)
Public Const HI_INICIO    As Long = 4
Public Const HI_FIM       As Long = 5
Public Const HI_SLA       As Long = 6    ' (f)
Public Const HI_DIAS      As Long = 7    ' (f)
Public Const HI_ATENDIDO  As Long = 8    ' (f)
Public Const HI_ATRASO    As Long = 9    ' (f)
Public Const HI_SIT       As Long = 10   ' (f)
Public Const HI_UNID      As Long = 11   ' (f)
Public Const HI_PROJ      As Long = 12   ' (f)
Public Const HI_ULT       As Long = 12
