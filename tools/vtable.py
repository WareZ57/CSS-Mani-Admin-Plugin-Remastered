"""vtable.py <lib.so> <vtable symbol> [regex]: prints index -> function of a vtable (Itanium ABI, 32 or 64-bit ELF).

    python3 tools/vtable.py cstrike/bin/linux64/server_srv.so _ZTV9CCSPlayer 'GiveNamedItem|Teleport'

Needs pyelftools (pip install pyelftools).
"""
import re
import struct
import sys

from elftools.elf.elffile import ELFFile
from elftools.elf.relocation import RelocationSection
from elftools.elf.sections import SymbolTableSection


def load(path):
    elf = ELFFile(open(path, 'rb'))
    syms = {}
    by_addr = {}
    for sec in elf.iter_sections():
        if isinstance(sec, SymbolTableSection):
            for s in sec.iter_symbols():
                if s.name and s['st_value']:
                    syms.setdefault(s.name, (s['st_value'], s['st_size']))
                    by_addr.setdefault(s['st_value'], s.name)
    # relocated vtable slots: symbol name (32-bit and R_X86_64_64), or target address (R_X86_64_RELATIVE)
    relocs = {}
    for sec in elf.iter_sections():
        if isinstance(sec, RelocationSection):
            symtab = elf.get_section(sec['sh_link'])
            for r in sec.iter_relocations():
                sym = symtab.get_symbol(r['r_info_sym']) if r['r_info_sym'] else None
                if sym is not None and sym.name:
                    relocs[r['r_offset']] = sym.name
                elif r.is_RELA():
                    relocs[r['r_offset']] = by_addr.get(r['r_addend'], hex(r['r_addend']))
    return elf, syms, by_addr, relocs


def read(elf, addr, size):
    for seg in elf.iter_segments():
        if seg['p_type'] == 'PT_LOAD' and seg['p_vaddr'] <= addr < seg['p_vaddr'] + seg['p_filesz']:
            elf.stream.seek(addr - seg['p_vaddr'] + seg['p_offset'])
            return elf.stream.read(size)
    return b'\0' * size


def vtable(path, name):
    elf, syms, by_addr, relocs = load(path)
    ptr = elf.elfclass // 8
    addr, size = syms[name]
    out = []
    for i in range(2, size // ptr):         # skip offset-to-top and typeinfo
        a = addr + i * ptr
        if a in relocs:
            out.append(relocs[a])
        else:
            v = struct.unpack('<Q' if ptr == 8 else '<I', read(elf, a, ptr))[0]
            out.append(by_addr.get(v, hex(v)))
    return out


if __name__ == '__main__':
    entries = vtable(sys.argv[1], sys.argv[2])
    pat = re.compile(sys.argv[3]) if len(sys.argv) > 3 else None
    for i, n in enumerate(entries):
        if not pat or pat.search(n):
            print(i, n)
