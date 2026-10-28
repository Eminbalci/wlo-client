# Technical Documentation: Game Database & Binary Decryption

## Overview
Reconstructs the proprietary binary record formats used by Chinesegamer's Delphi engine. The databases contain string obfuscation (in-place character reversals) and multi-tier numerical XOR and subtraction ciphers.

## Database Specifications

### 1. `Item.dat` (451 Bytes / 0x1C3 per Record, 7293 Records)
- **String Reversal**:
  - Name (offset 1..14): Length $L \in [2, 14]$ at `offset 0`, characters stored in `rec[15 - L .. 14]` in reverse order.
  - Description (offset 0x93..0x190): Length $D \in [0, 200]$ at `offset 0x92`, characters stored in `rec[0x191 - D .. 0x190]` in reverse order.
- **Numerical Decryption**:
  - `decode_byte(v) = ((v ^ 0x9a) - 9) & 0xff`
  - `decode_word(v) = ((v ^ 0xefc3) - 9) & 0xffff`
  - `decode_dword(v) = ((v ^ 0x0b80f4b4) - 9) & 0xffffffff`
- **Fields**:
  - Item Type: byte at offset 0x0F (`decode_byte`)
  - Item ID: uint16 at offset 0x10 (`decode_word`)
  - Small Icon ID: uint16 at offset 0x12 (`decode_word`)
  - Large Icon ID: uint16 at offset 0x14 (`decode_word`)
  - Equip Position / Wear Slot: byte at offset 0x2E (`decode_byte`)

### 2. `SceneData.dat` (131 Bytes / 0x83 per Record, 1172 Records)
- **Map ID Decryption**:
  - `decode_scene_id(w) = ((w ^ 0xea6c) - 9) & 0xffff`
  - Examples: `0xcd76` -> 10001 (Ship Deck), `0xcd70` -> 10003 (Newbie Island)
- **String Reversals**:
  - Scene Name: offset 8..28 reversed.
  - BGM Identifier: offset 31..38 reversed (e.g. `7000MGB` -> `BGM0007`).

### 3. `Npc.dat` (138 Bytes / 0x8A per Record, 4930 Records)
- Template ID: uint32 at offset 0.
- Name: 32 bytes at offset 4 (reversed).
- Level: byte at offset 36.

### 4. `Skill.dat` (148 Bytes / 0x94 per Record, 953 Records)
- **Numerical Decryption**:
  - `decode_byte(v) = ((v ^ 0xfd) - 4) & 0xff`
  - `decode_word(v) = ((v ^ 0x6ea0) - 4) & 0xffff`
  - `decode_dword(v) = ((v ^ 0x0bdedebf) - 4) & 0xffffffff`
- **Fields**:
  - Name Length: byte at offset 0 ($L \le 20$).
  - Name: bytes at offset `21 - L .. 20` (in-place reversed).
  - Category: byte at offset 21 (`decode_byte`).
  - Skill ID: uint16 at offset 22 (`decode_word`).
  - SP Cost: uint16 at offset 24 (`decode_word`).
  - Element: byte at offset 26 (`decode_byte`: 0=None, 1=Earth, 2=Water, 3=Fire, 4=Wind).
  - Skill Mechanism: uint16 at offset 27 (`decode_word`).
  - Action / Skill Type: byte at offset 29 (`decode_byte`: 1=Physical, 2=Magic, 4/7/14=Assist, 3/5/15=Status, 10/12/13=Special).
  - Rank / Tier: byte at offset 30 (`decode_byte`).
  - Target Scope: byte at offset 31 (`decode_byte`: 1=Single, 2=Row, 3/4=Column, 6/7=Cross, 8=All).
  - Multipliers: float64 IEEE 754 at offset 32 and 40.
  - Base Damage: uint16 at offset 49 (`decode_word`).
  - Description Length: byte at offset 66 ($D \le 30$).
  - Description: bytes at offset `97 - D .. 96` (in-place reversed).
  - Animation ID: uint16 at offset 100 (`decode_word`).

### 5. `SkillData.MBTM` (1,240,387 Bytes, 1829 Motion Timeline Sequences)
- **File Index Layout**:
  - Located at byte `file_size - 2 - (count * 10)`.
  - Total count: uint16 at byte `file_size - 2` (1829 records).
- **10-Byte Index Entry**:
  - `skill_id`: uint16 at offset 0.
  - `entry_offset`: uint32 at offset 2.
  - `entry_length`: uint32 at offset 6.
- Comprehensive technical documentation in [Skill Database & Combat Engine](file:///D:/Godot/WonderlandOnline/wonderland-online-client/docs/skill_database_and_combat_engine.md).
