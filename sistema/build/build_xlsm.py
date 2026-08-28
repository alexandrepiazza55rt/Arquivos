"""
Monta Sistema_Monitoramento.xlsm: a planilha original + o projeto VBA embutido.
"""
import os, re, sys, glob, struct, zipfile, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ovba

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(RAIZ, 'src')
XLSX = '/root/.claude/uploads/e664e0b2-7edb-5bd5-bde3-daeea5e8e87a/48a6d194-Painel_de_Projetos__VF.xlsx'
SAIDA = os.path.join(RAIZ, 'Sistema_Monitoramento.xlsm')

CP = 'cp1252'
PROJ_ID = '{5A1EB4D2-9C77-4B8E-A0F3-7E2C61B4D3A8}'

# ─── registros do fluxo "dir" ────────────────────────────────────────────────
def rec(rid, payload=b''):
    return struct.pack('<HI', rid, len(payload)) + payload

def mbcs(s):
    return s.encode(CP)

def utf16(s):
    return s.encode('utf-16-le')

REFS = [
    ('stdole',  r'*\G{00020430-0000-0000-C000-000000000046}#2.0#0#C:\Windows\SysWOW64\stdole2.tlb#OLE Automation'),
    ('Office',  r'*\G{2DF8D04C-5BFA-101B-BDE5-00AA0044DE52}#2.8#0#C:\Program Files\Common Files\Microsoft Shared\OFFICE16\MSO.DLL#Microsoft Office 16.0 Object Library'),
]

def build_dir(modules):
    d = b''
    d += rec(0x0001, struct.pack('<I', 1))                 # SysKind: Win32
    d += rec(0x0002, struct.pack('<I', 0x409))             # Lcid
    d += rec(0x0014, struct.pack('<I', 0x409))             # LcidInvoke
    d += rec(0x0003, struct.pack('<H', 1252))              # CodePage
    d += rec(0x0004, mbcs('VBAProject'))                   # Name
    d += rec(0x0005, b'') + rec(0x0040, b'')               # DocString
    d += rec(0x0006, b'') + rec(0x003D, b'')               # HelpFile
    d += rec(0x0007, struct.pack('<I', 0))                 # HelpContext
    d += rec(0x0008, struct.pack('<I', 0))                 # LibFlags
    d += struct.pack('<HIIH', 0x0009, 4, 0x00000001, 0x0000)   # Version
    d += rec(0x000C, b'') + rec(0x003C, b'')               # Constants

    for nome, libid in REFS:
        d += rec(0x0016, mbcs(nome)) + rec(0x003E, utf16(nome))
        lib = mbcs(libid)
        d += struct.pack('<HI', 0x000D, 4 + len(lib) + 4 + 2)
        d += struct.pack('<I', len(lib)) + lib + struct.pack('<IH', 0, 0)

    d += rec(0x000F, struct.pack('<H', len(modules)))      # Modules
    d += rec(0x0013, struct.pack('<H', 0xFFFF))            # Cookie

    for nome, _texto, tipo in modules:
        d += rec(0x0019, mbcs(nome))
        d += rec(0x0047, utf16(nome))
        d += rec(0x001A, mbcs(nome)) + rec(0x0032, utf16(nome))
        d += rec(0x001C, b'') + rec(0x0048, b'')
        d += rec(0x0031, struct.pack('<I', 0))             # offset do código
        d += rec(0x001E, struct.pack('<I', 0))             # HelpContext
        d += rec(0x002C, struct.pack('<H', 0xFFFF))        # Cookie
        d += rec(0x0021 if tipo == 'std' else 0x0022, b'')  # Type
        d += rec(0x002B, b'')                              # fim do módulo

    d += rec(0x0010, b'')                                  # fim
    return d


def build_project(modules):
    linhas = ['ID="%s"' % PROJ_ID]
    for nome, _t, tipo in modules:
        if tipo == 'doc':
            linhas.append('Document=%s/&H00000000' % nome)
        else:
            linhas.append('Module=%s' % nome)
    linhas += [
        'Name="VBAProject"',
        'HelpContextID="0"',
        'VersionCompatible32="393222000"',
        'CMG="1113D51F095E0D5E0D5E0D5E0D"',
        'DPB="ADAF2E7B2E7B2E"',
        'GC="F5F70D620E620E9D"',
        '',
        '[Host Extender Info]',
        '&H00000001={3832D640-CF90-11CF-8E43-00A0C911005A};VBE;&H00000000',
        '',
        '[Workspace]',
    ]
    for nome, _t, _tipo in modules:
        linhas.append('%s=0, 0, 0, 0, C' % nome)
    return ('\r\n'.join(linhas) + '\r\n').encode(CP)


def build_projectwm(modules):
    out = b''
    for nome, _t, _tipo in modules:
        out += mbcs(nome) + b'\x00' + utf16(nome) + b'\x00\x00'
    return out + b'\x00\x00'


# ─── módulos ─────────────────────────────────────────────────────────────────
CABECALHO_DOC = (
    'Attribute VB_Name = "ThisWorkbook"\r\n'
    'Attribute VB_Base = "0{00020819-0000-0000-C000-000000000046}"\r\n'
    'Attribute VB_GlobalNameSpace = False\r\n'
    'Attribute VB_Creatable = False\r\n'
    'Attribute VB_PredeclaredId = True\r\n'
    'Attribute VB_Exposed = True\r\n'
    'Attribute VB_TemplateDerived = False\r\n'
    'Attribute VB_Customizable = True\r\n'
)

def carregar_modulos():
    mods = []
    # ThisWorkbook: só as rotinas, sem os comentários de instrução do .txt
    tw = open(os.path.join(SRC, 'ThisWorkbook.txt'), encoding='utf-8').read()
    tw = tw[tw.index('Option Explicit'):]
    mods.append(('ThisWorkbook', CABECALHO_DOC + tw.replace('\r\n', '\n').replace('\n', '\r\n'), 'doc'))

    for caminho in sorted(glob.glob(os.path.join(SRC, '*.bas'))):
        base = os.path.basename(caminho)
        if base == '_INSTALAR.bas':
            continue
        texto = open(caminho, encoding='utf-8').read()
        m = re.match(r'Attribute VB_Name = "([^"]+)"', texto)
        assert m, base
        mods.append((m.group(1), texto.replace('\r\n', '\n').replace('\n', '\r\n'), 'std'))
    return mods


def build_vbaproject(modules):
    filhos_vba = [
        ovba.stream('_VBA_PROJECT', b'\xCC\x61\xB2\x00\x00\x00\x00'),
        ovba.stream('dir', ovba.compress(build_dir(modules))),
    ]
    for nome, texto, _tipo in modules:
        filhos_vba.append(ovba.stream(nome, ovba.compress(texto.encode(CP))))

    raiz = [
        ovba.storage('VBA', filhos_vba),
        ovba.stream('PROJECT', build_project(modules)),
        ovba.stream('PROJECTwm', build_projectwm(modules)),
    ]
    return ovba.build_cfb(raiz)


# ─── empacotamento ───────────────────────────────────────────────────────────
def montar():
    modules = carregar_modulos()
    bin_vba = build_vbaproject(modules)

    origem = zipfile.ZipFile(XLSX)
    nomes = origem.namelist()

    ct = origem.read('[Content_Types].xml').decode('utf-8')
    ct = ct.replace(
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"',
        'ContentType="application/vnd.ms-excel.sheet.macroEnabled.main+xml"')
    if 'Extension="bin"' not in ct:
        ct = ct.replace('<Default Extension="rels"',
                        '<Default Extension="bin" ContentType="application/vnd.ms-office.vbaProject"/><Default Extension="rels"', 1)

    rels = origem.read('xl/_rels/workbook.xml.rels').decode('utf-8')
    rid = 'rIdVBA1'
    rels = rels.replace('</Relationships>',
        '<Relationship Id="%s" Type="http://schemas.microsoft.com/office/2006/relationships/vbaProject" '
        'Target="vbaProject.bin"/></Relationships>' % rid)

    wb = origem.read('xl/workbook.xml').decode('utf-8')
    if '<workbookPr' in wb:
        wb = re.sub(r'<workbookPr([^>]*?)/>', lambda m: '<workbookPr%s codeName="ThisWorkbook"/>' % m.group(1)
                    if 'codeName' not in m.group(1) else m.group(0), wb, count=1)
    else:
        wb = wb.replace('<fileVersion', '<workbookPr codeName="ThisWorkbook"/><fileVersion', 1)
        if 'codeName="ThisWorkbook"' not in wb:
            wb = re.sub(r'(<workbook\b[^>]*>)', r'\1<workbookPr codeName="ThisWorkbook"/>', wb, count=1)
    assert 'codeName="ThisWorkbook"' in wb, 'não consegui marcar o codeName da pasta'

    if os.path.exists(SAIDA):
        os.remove(SAIDA)
    destino = zipfile.ZipFile(SAIDA, 'w', zipfile.ZIP_DEFLATED)
    for nome in nomes:
        if nome == '[Content_Types].xml':
            destino.writestr(nome, ct)
        elif nome == 'xl/_rels/workbook.xml.rels':
            destino.writestr(nome, rels)
        elif nome == 'xl/workbook.xml':
            destino.writestr(nome, wb)
        else:
            destino.writestr(origem.getinfo(nome), origem.read(nome))
    destino.writestr('xl/vbaProject.bin', bin_vba)
    destino.close()
    origem.close()
    return SAIDA, modules, len(bin_vba)


if __name__ == '__main__':
    caminho, mods, tam = montar()
    print('gerado:', caminho)
    print('modulos:', len(mods), '| vbaProject.bin:', tam, 'bytes')
