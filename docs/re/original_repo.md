# The original game folder `D:\GitHub\WLRI` (read it before re-deriving anything)

Earlier sessions (other agents) already reverse engineered a lot. Everything below is **observed/decoded by them**; check before trusting.

- `docs/` (105 specs): `wlo_network_protocol_and_packet_dictionary.md` (framing + opcode table, 25 struct layouts: walk, chat, warp, NPC talk,
  pickup, login, char create, item use `AC 23:96`, battle prepare `AC 11:250`, battle spawn `AC 11:5` ...), `network_manager.md`, `battle_system_and_runtime_view_spec.md`,
  `kelan_combat_and_leveling_spec.md` (private-server numbers: EXP 30/70/130/210 per level, +2 STR/+1 CON per level, damage `ATK*2.0 - DEF*1.2`),
  `skill_database_and_combat_engine.md`, `original_client_data_structures.md`, `item_*` specs, `delphi_*` (launcher DFMs only: not in-game UI).
- `data/`: `Item.dat`, `Npc.dat`, `Skill.dat`, `Talk.dat`, `SceneData.dat`, `Compound.dat`/`Compound2.Dat` (alchemy recipes), `Mark.dat`, `Lbd.dat`, `Eve.emg`,
  `Ground.MMG`, `Wem.MMG`, `SkillData.MBTM`, `Formula.dat`, `PlayerTitleData.txt`, `ServerDataBase.db`, and JSON exports (`all_maps.json`, `all_npcs.json`, `all_scenes.json`).
- `extracted_resources/`: stock Delphi VCL bitmaps (not game art). `pic/`, `menu/Skins/{default,white}`, `jma/`, `cursor/`, `sound/` hold the game art.
- Many `scratch_*.py` / `find_*.py` / `inspect_*.py` helper scripts live in the folder root (formats of the dat files are readable from them).

## data/Formula.dat (407 bytes, decoded here)
Layout: 1 byte count (2), then little-endian doubles starting at offset 1, then a small int table. Values (index: value):
```
0-4   2.0 1.4 1.0 0.6 1.75     5-9   2.0 1.0 0.6 2.0 1.4     10-14 1.0 0.2 2.2 2.0 1.0
15-19 0.2 1.8 1.6 1.0 0.5      20-24 2.0 1.0 1.0 1.0 1.0     25-29 1.0 1.0 1.6 0.7 30.0
30-34 3.1 1.0 2.0 0.35 2.0     35-39 1.0 3.2 0.3 2.0 3.0     40-44 0.09 0.01 1.0 5.0 3.0
```
These look like element-advantage / damage multipliers and tuning constants (not yet tied to code: find the reader in aLogin.exe by searching for "Formula.dat").
Godot currently uses its own multipliers (`battle_manager.gd`); replace them once the semantics are confirmed.

## Image archives and how they were decoded (all formats verified on the real files)
Extractor: `scratchpad` script `wlri_extract.py` (port of `scripts/core/wlo_archive_reader.gd` and `scripts/core/jma_parser.gd`).
Output (one PNG per image, outside the repo): `D:\Godot\WonderlandOnline\original_assets\{bmg,jma,loose}\` with `manifest.csv` per group.

| Source | Format | Count |
|--------|--------|-------|
| `pic/*.BMg`, `pic/*.JMg`, `pic/*.JMG` | u16 count, 32-byte entries: u8 name_len, 23-byte name, u32 offset, u32 size. Payload BMP (8/24/32 bit) or JPG | 15,699 BMP + 439 JPG (in 28 archives) |
| `jma/*.jma` | `ja` magic, u32 count at byte 10, 28-byte entries from byte 14: u8 name_len, 19-byte name, u32 size, u32 offset | 6,178 `.jmp` (sprite sets) |
| `jma/*.jmp` (inside jma) | `jm`, frame count u32 at byte 10, 40-byte frame entries from 14 (name, bounds, pivot, size, offset, width, height), then 256-colour BGRA palette, then 8-bit indexed rows padded to 4 bytes | frames per jmp = frame count |
| `jma/*.Jxa` | `jx` magic, same header as the jma, total = header + index; not needed (the jma carries the same index) | - |
| `menu/**/*.bmp`, `pic/*.bmp`, `images/*.jpg|gif`, `pic/*.jpg` | loose files | see manifest |

Chroma: pure green (0,255,0) is transparent in BMP; sprite palette index 0 and green are transparent.
Note: the jmp frame "bpp" field is 1 (not 8); it is not a bit depth, do not check it.
