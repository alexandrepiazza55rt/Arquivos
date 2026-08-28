"""
Gera xl/vbaProject.bin (MS-OVBA) dentro de um contêiner OLE (MS-CFB),
a partir de módulos VBA em texto.

Referências: [MS-CFB] Compound File Binary File Format
             [MS-OVBA] Office VBA File Format Structure
"""
import struct, math, io

# ─────────────────────────────────────────────────────────────────────────────
# Compressão do "Compressed Container" (MS-OVBA 2.4.1)
# ─────────────────────────────────────────────────────────────────────────────
def _copytoken_help(diff):
    bit_count = 4 if diff <= 16 else max(4, int(math.ceil(math.log(diff, 2))))
    bit_count = min(bit_count, 12)
    length_mask = 0xFFFF >> bit_count
    return bit_count, length_mask, length_mask + 3


def _compress_chunk(chunk):
    out = bytearray()
    idx = {}                       # hash de 3 bytes -> posições recentes
    i = 0
    n = len(chunk)
    while i < n:
        flag_pos = len(out)
        out.append(0)
        flags = 0
        for bit in range(8):
            if i >= n:
                break
            bit_count, length_mask, max_len = _copytoken_help(i)
            max_off = 1 << bit_count
            best_len, best_off = 0, 0
            if i >= 3 and n - i >= 3:
                key = chunk[i:i + 3]
                for j in reversed(idx.get(key, ())[-24:]):
                    off = i - j
                    if off > max_off:
                        break
                    l = 0
                    lim = min(max_len, n - i)
                    while l < lim and chunk[j + l] == chunk[i + l]:
                        l += 1
                    if l > best_len:
                        best_len, best_off = l, off
                        if l == max_len:
                            break
            if best_len >= 3:
                token = ((best_off - 1) << (16 - bit_count)) | (best_len - 3)
                out += struct.pack('<H', token)
                flags |= 1 << bit
                step = best_len
            else:
                out.append(chunk[i])
                step = 1
            for k in range(i, min(i + step, n - 2)):
                idx.setdefault(chunk[k:k + 3], []).append(k)
            i += step
        out[flag_pos] = flags
    return bytes(out)


def compress(data):
    out = bytearray(b'\x01')
    for start in range(0, len(data), 4096):
        window = data[start:start + 4096]
        comp = _compress_chunk(window)
        if len(comp) <= 4096:
            out += struct.pack('<H', 0xB000 | (len(comp) + 2 - 3)) + comp
        else:                                   # incompressível: bloco cru
            raw = window + b'\x00' * (4096 - len(window))
            out += struct.pack('<H', 0x3FFF) + raw
    return bytes(out)


def decompress(data):
    """Descompressor de referência, usado para conferir a compressão."""
    assert data[0] == 1, 'assinatura do contêiner inválida'
    out = bytearray()
    pos = 1
    while pos < len(data):
        header = struct.unpack('<H', data[pos:pos + 2])[0]
        size = (header & 0x0FFF) + 3
        compressed = bool(header & 0x8000)
        body = data[pos + 2: pos + size]
        pos += size
        if not compressed:
            out += body
            continue
        p = 0
        chunk_start = len(out)
        while p < len(body):
            flags = body[p]; p += 1
            for bit in range(8):
                if p >= len(body):
                    break
                if flags & (1 << bit):
                    token = struct.unpack('<H', body[p:p + 2])[0]; p += 2
                    diff = len(out) - chunk_start
                    bit_count, length_mask, _ = _copytoken_help(diff)
                    length = (token & length_mask) + 3
                    offset = (token >> (16 - bit_count)) + 1
                    src = len(out) - offset
                    for k in range(length):
                        out.append(out[src + k])
                else:
                    out.append(body[p]); p += 1
    return bytes(out)


# ─────────────────────────────────────────────────────────────────────────────
# Contêiner OLE / Compound File (MS-CFB), versão 3, setor de 512 bytes
# ─────────────────────────────────────────────────────────────────────────────
FREE, ENDOFCHAIN, FATSECT, DIFSECT, NOSTREAM = 0xFFFFFFFF, 0xFFFFFFFE, 0xFFFFFFFD, 0xFFFFFFFC, 0xFFFFFFFF
SECTOR, MINISECTOR, MINI_CUTOFF = 512, 64, 4096


class _Entry:
    __slots__ = ('name', 'kind', 'children', 'data', 'id',
                 'left', 'right', 'child', 'start', 'size')

    def __init__(self, name, kind, data=None):
        self.name, self.kind, self.data = name, kind, data
        self.children = []
        self.id = -1
        self.left = self.right = self.child = NOSTREAM
        self.start, self.size = ENDOFCHAIN, 0


def _cfb_order(name):
    """Ordem de comparação do CFB: primeiro o comprimento, depois maiúsculas."""
    return (len(name), name.upper())


def _build_tree(entries):
    """Monta uma árvore binária equilibrada; todos os nós pretos."""
    entries = sorted(entries, key=lambda e: _cfb_order(e.name))

    def rec(lo, hi):
        if lo > hi:
            return NOSTREAM
        mid = (lo + hi) // 2
        e = entries[mid]
        e.left = rec(lo, mid - 1)
        e.right = rec(mid + 1, hi)
        return e.id

    return rec(0, len(entries) - 1)


def build_cfb(root_children):
    """root_children: lista de _Entry (streams e storages) na raiz."""
    root = _Entry('Root Entry', 5)
    root.children = root_children

    # numeração em largura, raiz primeiro
    ordered, queue = [root], [root]
    while queue:
        node = queue.pop(0)
        for c in node.children:
            ordered.append(c)
            queue.append(c)
    for i, e in enumerate(ordered):
        e.id = i

    for e in ordered:
        if e.children:
            e.child = _build_tree(e.children)

    # separa streams grandes e pequenos
    big, small = [], []
    for e in ordered:
        if e.kind == 2:
            (small if len(e.data) < MINI_CUTOFF else big).append(e)

    # mini stream
    mini_bytes, mini_fat = bytearray(), []
    for e in small:
        e.start = len(mini_bytes) // MINISECTOR
        e.size = len(e.data)
        blob = e.data + b'\x00' * (-len(e.data) % MINISECTOR)
        first = len(mini_bytes) // MINISECTOR
        count = len(blob) // MINISECTOR
        for k in range(count):
            mini_fat.append(first + k + 1 if k < count - 1 else ENDOFCHAIN)
        mini_bytes += blob

    # alocação dos setores normais
    sectors = []                      # lista de blocos de 512 bytes
    fat = []                          # entrada FAT por setor

    def alloc(blob):
        blob = blob + b'\x00' * (-len(blob) % SECTOR)
        first = len(sectors)
        count = len(blob) // SECTOR
        for k in range(count):
            sectors.append(blob[k * SECTOR:(k + 1) * SECTOR])
            fat.append(first + k + 1 if k < count - 1 else ENDOFCHAIN)
        return first, count

    for e in big:
        e.start, _ = alloc(e.data)
        e.size = len(e.data)

    mini_start = ENDOFCHAIN
    if mini_bytes:
        mini_start, _ = alloc(bytes(mini_bytes))
    root.start, root.size = mini_start, len(mini_bytes)

    minifat_start, minifat_count = ENDOFCHAIN, 0
    if mini_fat:
        per = SECTOR // 4
        mini_fat += [FREE] * (-len(mini_fat) % per)
        minifat_start, minifat_count = alloc(struct.pack('<%dI' % len(mini_fat), *mini_fat))

    # diretório
    def dir_entry(e):
        nm = e.name.encode('utf-16-le')[:62]
        buf = nm + b'\x00' * (64 - len(nm))
        return (buf + struct.pack('<HBBIII', len(nm) + 2, e.kind, 1, e.left, e.right, e.child)
                + b'\x00' * 16                      # CLSID
                + struct.pack('<I', 0)              # state
                + b'\x00' * 16                      # tempos
                + struct.pack('<III', e.start, e.size, 0))

    dir_blob = b''.join(dir_entry(e) for e in ordered)
    per_sec = SECTOR // 128
    pad = (-len(ordered)) % per_sec
    dir_blob += (b'\x00' * 64 + struct.pack('<HBBIII', 0, 0, 1, NOSTREAM, NOSTREAM, NOSTREAM)
                 + b'\x00' * 16 + struct.pack('<I', 0) + b'\x00' * 16
                 + struct.pack('<III', 0, 0, 0)) * pad
    dir_start, _ = alloc(dir_blob)

    # FAT (e DIFAT, se necessário) — resolvido por iteração até estabilizar
    per = SECTOR // 4
    n_fat = 1
    while True:
        total = len(sectors) + n_fat
        n_difat = max(0, -(-(max(0, n_fat - 109)) // (per - 1)))
        total += n_difat
        need = -(-total // per)
        if need <= n_fat:
            break
        n_fat = need

    fat_sectors = list(range(len(sectors), len(sectors) + n_fat))
    difat_sectors = list(range(len(sectors) + n_fat, len(sectors) + n_fat + n_difat))
    full_fat = fat + [FATSECT] * n_fat + [DIFSECT] * n_difat
    full_fat += [FREE] * (n_fat * per - len(full_fat))
    fat_blob = struct.pack('<%dI' % len(full_fat), *full_fat)

    out = [None] * (len(sectors) + n_fat + n_difat)
    for i, s in enumerate(sectors):
        out[i] = s
    for k, sec in enumerate(fat_sectors):
        out[sec] = fat_blob[k * SECTOR:(k + 1) * SECTOR]

    difat_head = fat_sectors[:109] + [FREE] * max(0, 109 - len(fat_sectors))
    first_difat = ENDOFCHAIN
    if n_difat:
        first_difat = difat_sectors[0]
        rest = fat_sectors[109:]
        for k, sec in enumerate(difat_sectors):
            part = rest[k * (per - 1):(k + 1) * (per - 1)]
            part += [FREE] * (per - 1 - len(part))
            nxt = difat_sectors[k + 1] if k + 1 < n_difat else ENDOFCHAIN
            out[sec] = struct.pack('<%dI' % per, *(part + [nxt]))

    header = (b'\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1' + b'\x00' * 16
              + struct.pack('<HHHHHH', 0x003E, 0x0003, 0xFFFE, 9, 6, 0)
              + struct.pack('<III', 0, 0, n_fat)
              + struct.pack('<III', dir_start, 0, MINI_CUTOFF)
              + struct.pack('<III', minifat_start, minifat_count, first_difat)
              + struct.pack('<I', n_difat)
              + struct.pack('<109I', *difat_head))
    assert len(header) == 512, len(header)
    return header + b''.join(out)


def stream(name, data):
    return _Entry(name, 2, data)


def storage(name, children):
    e = _Entry(name, 1)
    e.children = children
    return e
