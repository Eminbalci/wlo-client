# Technical Documentation: Archive and Sprite Streaming Loader

## Overview
The `ArchiveLoader`, `WloArchiveReader`, and `JmaParser` components implement direct in-memory loading and streaming of proprietary Wonderland Online package archives (`.JMG`, `.BMg`, `.jma`, `.jmp`). In strict compliance with performance constraints, no loose image files are written to disk. All textures are deserialized directly into memory and uploaded to the GPU as `ImageTexture` objects.

## Components

### 1. `WloArchiveReader` (`res://scripts/core/wlo_archive_reader.gd`)
Parses `.JMG` (JPEG archives) and `.BMg` (Bitmap archives) found in `pic/` (e.g. `pic/map.JMG`, `pic/item.BMg`, `pic/JRole.JMg`).

#### Binary Layout:
- Header: 2 bytes `count` (uint16 little-endian).
- Directory Entries: 32 bytes each.
  - Byte 0: `name_len` (uint8)
  - Bytes 1..23: `name` (ASCII string, null-terminated)
  - Bytes 24..27: `offset` (uint32 little-endian)
  - Bytes 28..31: `size` (uint32 little-endian)

#### Methods:
- `static open_archive(file_path: String) -> WloArchiveReader`
  - Returns reader instance or `null` if file missing/invalid.
- `extract_bytes(file_name: String) -> PackedByteArray`
  - Parameters: `file_name` (case-insensitive name).
  - Returns: Raw payload buffer.
- `extract_texture(file_name: String) -> ImageTexture`
  - Direct conversion via `Image.load_jpg_from_buffer` or `Image.load_bmp_from_buffer`.
  - Returns GPU `ImageTexture` directly without disk IO.

---

### 2. `JmaParser` (`res://scripts/core/jma_parser.gd`)
Parses `.jma` containers and embedded `.jmp` 8-bit palette-indexed sprite animations.

#### Binary Layout:
- JMA Container Header (14 bytes):
  - Magic: `"ja"` (0x6a 0x61)
  - Total Size: uint32
  - Header Size: uint32 (`14 + file_count * 28`)
  - File Count: uint32
- JMA File Entry (28 bytes):
  - Name Len: uint8, Name: 19 bytes ASCII, Size: uint32, Offset: uint32
- JMP Animation Header (14 bytes):
  - Magic: `"jmxx"` (0x6a 0x6d 0x78 0x78)
  - Flag: uint16 (0x0003)
  - Data Offset: uint32
  - Frame Count: uint32
- Frame Entry (40 bytes each):
  - Bounds & Pivot: `pivot_x`, `pivot_y` (int16)
  - Frame Size & Offset: uint32
  - Width & Height: uint32
- 256-Color Palette (1024 bytes):
  - Located at `14 + frame_count * 40`.
  - Chroma Key: Index 0 or pure green `(0, 255, 0)` maps to `alpha = 0.0`.
- Stride:
  - Row padded to 4-byte boundary: `(width + 3) & ~3`.
  - Bottom-up scanlines converted to Godot `FORMAT_RGBA8`.
