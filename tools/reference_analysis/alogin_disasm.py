"""Disassembles one function of the original aLogin.exe (x86, capstone) without Ghidra.

Usage: python alogin_disasm.py <virtual_address_hex> [max_instructions]
Example: python alogin_disasm.py 0x2de1d4 200

The function is read from its start address until the first `ret` after a 0xC3 / 0xC2 that is
followed by another `55 8B EC` prologue, or until max_instructions. The result is assembly, not C.
"""
import sys

import pefile
from capstone import CS_ARCH_X86, CS_MODE_32, Cs

EXE = r"D:\GitHub\WLRI\aLogin.exe"


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return
    va = int(sys.argv[1], 16)
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 200
    pe = pefile.PE(EXE, fast_load=True)
    image_base = pe.OPTIONAL_HEADER.ImageBase
    rva = va - image_base
    code = None
    for s in pe.sections:
        start = s.VirtualAddress
        end = start + max(s.Misc_VirtualSize, s.SizeOfRawData)
        if start <= rva < end:
            raw = pe.__data__[s.PointerToRawData:s.PointerToRawData + s.SizeOfRawData]
            code = raw[rva - start:]
            break
    if code is None:
        print("address is outside every section")
        return
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    count = 0
    for ins in md.disasm(code, va):
        print(f"{ins.address:08x}  {ins.bytes.hex():<24} {ins.mnemonic} {ins.op_str}")
        count += 1
        if count >= limit:
            break


if __name__ == "__main__":
    main()
