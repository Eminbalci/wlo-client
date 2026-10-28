# Technical Documentation: Skill Database, MBTM Motion Timelines & Combat Engine

## 1. Overview
This document specifies the reverse-engineered binary structures, decryption mathematics, and Godot client integration for skills and battle animation sequences in Wonderland Online (Chinesegamer Borland Delphi 6 engine).
It details:
1. `data/Skill.dat` (141,044 bytes, 953 records of 148 bytes).
2. `data/SkillData.MBTM` (1,240,387 bytes, 1829 motion battle timeline animation sequences).
3. 14 authentic starter stunt skill assignments and loadouts for playable character roles.

---

## 2. Binary Architecture of `Skill.dat`

The database contains 953 records of 148 bytes (0x94) each. Record 0 acts as a sentinel/header, while records 1 through 952 represent 952 unique combat and utility skills.

### 2.1 Decryption Mathematics
Numerical values in `Skill.dat` are protected by a rolling XOR and subtraction cipher discovered in `aLogin.exe` at virtual address `0x49abe0`:
- **Byte Decryption**:
  $$\text{decode\_byte}(b) = ((b \oplus 0\text{xFD}) - 4) \ \& \ 0\text{xFF}$$
- **Word Decryption (uint16)**:
  $$\text{decode\_word}(w) = ((w \oplus 0\text{x6EA0}) - 4) \ \& \ 0\text{xFFFF}$$
- **Dword Decryption (uint32)**:
  $$\text{decode\_dword}(d) = ((d \oplus 0\text{x0BDEDEBF}) - 4) \ \& \ 0\text{xFFFFFFFF}$$

### 2.2 In-Place Reversed Strings
- **Skill Name (`offset 0..20`)**:
  - `offset 0`: Name character count $L \in [1, 20]$.
  - `offset 1..20`: Name characters stored right-aligned in reverse order ending at `offset 20`: `name[k] = rec[offset + 20 - k]` for $k \in [0, L-1]$.
- **Description (`offset 66..96`)**:
  - `offset 66`: Description character count $D \in [0, 30]$.
  - `offset 67..96`: Description characters stored right-aligned in reverse order ending at `offset 96`: `desc[k] = rec[offset + 96 - k]` for $k \in [0, D-1]$.

### 2.3 Record Offset Layout (148 Bytes)
| Offset | Size (Bytes) | Data Type | Field | Decryption / Interpretation |
|---|---|---|---|---|
| `0x00` | 1 | uint8 | Name Length $L$ | Plaintext byte ($0 < L \le 20$) |
| `0x01..0x14` | 20 | char[] | Name Raw Buffer | Right-aligned reversed characters |
| `0x15` (21) | 1 | uint8 | Category / Origin | `decode_byte` (0=Basic, 1..4=Elements, 7=Stunt, 9=Life, 10=Monster) |
| `0x16` (22) | 2 | uint16 | **Skill ID** | `decode_word` |
| `0x18` (24) | 2 | uint16 | **SP Cost** | `decode_word` (tested at `0x2a88b3` in `aLogin.exe`) |
| `0x1A` (26) | 1 | uint8 | **Element** | `decode_byte` (0=None, 1=Earth, 2=Water, 3=Fire, 4=Wind) |
| `0x1B` (27) | 2 | uint16 | Skill Mechanism | `decode_word` (1=Physical, 2=Magical, 3=Special, 4=Passive/Life) |
| `0x1D` (29) | 1 | uint8 | **Action Type** | `decode_byte` (1=PhysAtk, 2=MagAtk, 4=Shield, 7=Heal, 10=Def, 12=Flee, 13=Life) |
| `0x1E` (30) | 1 | uint8 | Skill Rank / Tier | `decode_byte` (Progression level within branch) |
| `0x1F` (31) | 1 | uint8 | **Target Scope** | `decode_byte` (1=Single, 2=Row, 3/4=Column, 6/7=Cross, 8=All) |
| `0x20` (32) | 8 | float64 | Multiplier 1 | Unencrypted IEEE 754 double precision float |
| `0x28` (40) | 8 | float64 | Multiplier 2 | Unencrypted IEEE 754 double precision float |
| `0x31` (49) | 2 | uint16 | **Base Damage** | `decode_word` (Primary power value) |
| `0x42` (66) | 1 | uint8 | Description Length $D$ | Plaintext byte ($0 \le D \le 30$) |
| `0x43..0x60` | 30 | char[] | Description Buffer | Right-aligned reversed characters |
| `0x64` (100) | 2 | uint16 | **Animation ID** | `decode_word` (Key into animation lookup) |

---

## 3. Binary Architecture of `SkillData.MBTM`

`SkillData.MBTM` (1,240,387 bytes) stores choreography and motion timeline data for turn-based combat animations.

### 3.1 File Structure
- **Index Table at End of File**:
  - Located at byte offset: `file_size - 2 - (count * 10)`.
  - The very last 2 bytes of the file contain `count: uint16` = **1829**.
  - Index table size: $1829 \times 10 = 18,290$ bytes.
- **10-Byte Index Record**:
  | Offset | Size (Bytes) | Data Type | Field |
  |---|---|---|---|
  | `0x00` | 2 | uint16 | `skill_id` |
  | `0x02` | 4 | uint32 | `entry_offset` (absolute byte offset in `SkillData.MBTM`) |
  | `0x06` | 4 | uint32 | `entry_length` (byte length of animation payload) |
- **Payload**:
  - Accessed directly via `file.seek(entry_offset)` and `file.get_buffer(entry_length)`.
  - Stores keyframed sequences, projectile sprites, timing delays, and sound triggers.

---

## 4. Playable Character Role Starter Stunt Assignments

Derived from the `aLogin.exe` role creation jump table at virtual address `0x49ef9a`:

| Role ID | Role Name | Innate Element | Starter Stunt Skill ID | Stunt Name | SP Cost | Base Damage | Animation ID | Target Scope | MBTM Payload (Bytes) |
|---|---|---|---|---|---|---|---|---|---|
| **1** | **Nina** | Fire | `15039` | Wine Flame | 9 | 40 | 60010 | Single | 648 |
| **2** | **Betty** | Wind | `12036` | Leap | 9 | 38 | 60005 | Single | 691 |
| **3** | **Rocco** | Earth | `11075` | Summon Dogs Groups | 18 | 50 | 60001 | Single | 792 |
| **4** | **Vanessa** | Water | `15042` | Recover Normal | 179 | 50 | 11055 | Single | 444 |
| **5** | **Lique** | Wind | `15041` | Love Wish | 10 | 24 | 60012 | Single | 392 |
| **6** | **Daniel** | Fire | `15038` | Overarm Stumble | 8 | 35 | 60009 | Single | 418 |
| **7** | **Sid** | Earth | `11076` | Combo x3 Attack | 9 | 38 | 60002 | Single | 757 |
| **8** | **Jessica** | Water | `15044` | Hagendis Attack | 41 | 93 | 12047 | Single | 443 |
| **9** | **Konnotsuroko** | Water | `15045` | Hagendis Beating | 67 | 139 | 12047 | Row | 443 |
| **10** | **Iris** | Water | `11078` | Bomber Attack (alias `12037`) | 20 | 90 | 60004 | Single | 660 |
| **11** | **Maria** | Water | `11077` | Cure 2 Players | 8 | 45 | 60003 | Row | 698 |
| **12** | **More** | Earth | `11183` | Deacon Attack | 7 | 28 | 60009 | Single | 851 |
| **13** | **Kurogane** | Fire | `11182` | Ghost Hammer | 9 | 38 | 10018 | Single | 676 |
| **14** | **Karin** | Fire | `15040` | Palm | 7 | 28 | 60011 | Single | 676 |

### 4.1 Starter Loadout Rule
All playable roles start with a standard 2-skill loadout:
1. **Basic Hand Attack (Skill `10001`)**: Physical, None element, 0 SP cost, Single target.
2. **Role Stunt Skill**: Unique character special attack from the table above.

---

## 5. Implementation Architecture in Godot

### 5.1 [`SkillDatabase`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/database/skill_database.gd)
- `class_name SkillDatabase extends RefCounted`.
- Maintains `_skills: Dictionary` (Skill ID $\to$ `SkillRecord`) and `_mbtm_entries: Dictionary` (Skill ID $\to$ `{"offset": int, "length": int}`).
- Decodes and exposes complete taxonomy of `Element`, `SkillType`, and `TargetScope`.

### 5.2 [`GameDatabase`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/database/game_database.gd) Integration
- Registered as autoload singleton coordinator `GameDatabase`.
- Automatically initializes `Skill.dat` and `SkillData.MBTM` during `load_all()`.
- Exposes accessors:
  - `get_skill(id: int) -> SkillRecord`
  - `get_starter_stunt_for_role(role_id: int) -> SkillRecord`
  - `get_starter_skills_for_role(role_id: int) -> Array[SkillRecord]`

### 5.3 Automated Verification Suite
- [`tests/test_skill_database.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_skill_database.gd) executes 9 test phases headlessly via `godot_console.exe --headless`.
