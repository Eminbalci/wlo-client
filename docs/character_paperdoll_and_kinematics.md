# Character Paper-Doll, Kinematics, and HUD Architecture

## 1. Overview
This document specifies the technical implementation of the authentic Wonderland Online character paper-doll composite system, 14 playable character role definitions reverse-engineered from original binaries, 8-directional counter-clockwise kinematics, standing idle breathing cycles, hardware animated cursor, and status/character UI layouts.

## 2. Playable Character Role Registry (Roles 1 to 14)

Reverse-engineered from `aLogin.exe` starting item tables at `0x4a32c0`, role bitmap arrays at `0x220b88`, and PServer character databases (`wlo.pserver.core.dll` / `database.py`).

| Role ID | Character Name | Gender / Body Type | Body Archive & JMP | Hair Archive & JMP | Starter Outfit (Clothes / Shoes / Head) | Element | Primary Stunt Skill | Authentic Base Stats |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | Nina | Small Female (Body 2) | `003.jma:3000.jmp` | `003h.jma:3100.jmp` | Small Dress (21002), Baby Shoes (24002), Star Headdress (22003) | Fire | 15039 Wine Flame | STR: 8, CON: 9, INT: 10, WIS: 9, AGI: 8 |
| **2** | **Betty** | Small Female (Body 2) | `003.jma:3000.jmp` | `003h.jma:3101.jmp` | Harness Pants (21003), Pink Shoes (24003), Feather Head (22001) | Wind | 12036 Leap | STR: 10, CON: 10, INT: 6, WIS: 6, AGI: 18 |
| **3** | Rocco | Small Male (Body 1) | `002.jma:2000.jmp` | `002h.jma:2100.jmp` | Boy's Suit (21001), Moppet's Shoes (24001), Lovely Headdress (22004) | Earth | 11075 Summon Dogs | STR: 10, CON: 10, INT: 8, WIS: 8, AGI: 10 |
| **4** | Vanessa | Big Female (Body 4) | `005.jma:5000.jmp` | `005h.jma:5102.jmp` | Uniform (21008), Student's Shoes (24008), Flower Headdress (22002) | Water | 15042 | STR: 7, CON: 8, INT: 12, WIS: 12, AGI: 9 |
| **5** | Lique | Big Female (Body 4) | `005.jma:5000.jmp` | `005h.jma:5101.jmp` | Racing Suit (21007), Racing Shoes (24007), Gloves (23002) | Wind | 15041 | STR: 11, CON: 9, INT: 7, WIS: 7, AGI: 14 |
| **6** | **Daniel** | Big Male (Body 3) | `004.jma:4000.jmp` | `004h.jma:4100.jmp` | Dust Coat (21004), Gentleman's Shoes (24004) | Fire | 15038 Shoulder Throw | STR: 14, CON: 12, INT: 6, WIS: 5, AGI: 11 |
| **7** | Sid | Big Male (Body 3) | `004.jma:4000.jmp` | `004h.jma:4101.jmp` | Jeans (21005), Leisure Shoes (24005) | Earth | 11076 Combo x3 | STR: 13, CON: 11, INT: 6, WIS: 6, AGI: 12 |
| **8** | Jessica | Big Female (Body 4) | `005.jma:5000.jmp` | `005h.jma:5104.jmp` | Violinists Suit (21010), High-Heeled Shoes (24010), Violin (10003) | Water | 15044 | STR: 8, CON: 8, INT: 14, WIS: 13, AGI: 8 |
| **9** | Konnotsuroko | Big Female (Body 4) | `005.jma:5000.jmp` | `005h.jma:5105.jmp` | Kimono (21013), Wooden Shoes (24013) | Water | 15045 | STR: 9, CON: 9, INT: 11, WIS: 11, AGI: 10 |
| **10** | Iris | Big Female (Body 4) | `005.jma:5000.jmp` | `005h.jma:5100.jmp` | Sailor's Suit (21006), White Boots (24006), Sailor's Hat (22005) | Water | 12037 | STR: 8, CON: 8, INT: 12, WIS: 12, AGI: 10 |
| **11** | Maria | Big Female (Body 4) | `005.jma:5000.jmp` | `005h.jma:5106.jmp` | Nurse Clothes (21011), White Leather (24011), Nurse's Hat (22006) | Water | 11077 Cure 2 Players | STR: 7, CON: 8, INT: 13, WIS: 14, AGI: 8 |
| **12** | More | Big Male (Body 3) | `004.jma:4000.jmp` | `004h.jma:4102.jmp` | Bartender Uniform (21012), Great Pumps (24012) | Earth | 11183 Deacon Attack | STR: 12, CON: 11, INT: 8, WIS: 8, AGI: 10 |
| **13** | Kurogane | Big Male (Body 3) | `004.jma:4000.jmp` | `004h.jma:4103.jmp` | Craftsman's Clothes (21014), Craftsman Shoes (24014), Headscarf (22009) | Fire | 11182 Ghost Hammer | STR: 15, CON: 13, INT: 5, WIS: 5, AGI: 9 |
| **14** | Karin | Big Female (Body 4) | `005.jma:5000.jmp` | `005h.jma:5107.jmp` | Uniform (21015), Leather Shoes (24015), Band (22008) | Fire | 15040 Palm | STR: 11, CON: 10, INT: 7, WIS: 7, AGI: 13 |

### 2.1 Role Identity Resolution: Betty vs Daniel
In the original WLO client:
- **Role 2 is Betty** (`Btn_RolePic_2.bmp`): A young orphan circus acrobat with blonde hair, dressed in playful Harness Pants (`21003`) and Pink Shoes (`24003`). Agility specialist with high starting AGI (18) and Wind element.
- **Role 6 is Daniel** (`Btn_RolePic_6.bmp`): An adult male dressed in a long trench Dust Coat (`21004`) and Gentleman's Shoes (`24004`). Strength/combat specialist with high starting STR (14) and Fire element.

## 3. Character Paper-Doll Architecture

### 3.1 Layer Decomposition and Blending Hierarchy
In Wonderland Online, character sprites are dynamically composited using per-frame coordinate pivots `(pivot_x, pivot_y)` across 6 discrete layers:
- **Layer 0: Base Body (Skin / Undergarments)** — **Immutable Base Layer**. Always rendered first. Sourced from `GameDatabase.get_role(role_id)`. For Betty: `003.jma:3000.jmp`. For Daniel: `004.jma:4000.jmp`. The base nude mesh is NEVER destroyed or replaced by equipment slots.
- **Layer 1: Hair** — Sourced from the character's designated hair JMP (e.g. `003h.jma:3101.jmp` for Betty) or custom hairstyle.
- **Layer 2: Clothes / Torso Armor** — Sourced from `equip_layers["clothes"]` or the HUD `"body"` socket. Rendered on top of the base body. If unequipped (`""` or empty), this layer is omitted and the base undergarments remain visible.
- **Layer 3: Shoes / Footwear** — Sourced from `equip_layers["shoes"]`. Rendered on top of feet. If unequipped, bare feet of the base body remain visible.
- **Layer 4: Headgear / Cap** — Sourced from `equip_layers["cap"]` / `"head"`. Rendered on top of hair.
- **Layer 5: Weapon / Hand** — Sourced from `equip_layers["weapon"]`. Rendered on top of hands.

### 3.2 Root-Cause Analysis: Equipment Invisibility Fix
Previously, the composite pipeline erroneously treated the HUD `"body"` equipment socket as the base skin model:
1. When clothes were equipped, `body_pair` was overwritten by clothes JMA/JMP, bypassing the base skin model entirely (causing floating clothes with missing body parts).
2. When clothes were unequipped, `_resolve_equip_layer` returned `["", ""]`, which caused `body_anim` to evaluate to `null`. Line 414 then returned an empty array `[]` of textures, instantly turning the entire character invisible.

**Architectural Fix in `archive_loader.gd`**:
- Layer 0 (`body_jma:body_jmp`) is decoupled from equipment and strictly bound to the role's native skin mesh (`GameDatabase.get_role(role_id).body_jmp`).
- The `"body"` equipment socket is mapped to Layer 2 (Clothes).
- When clothes or shoes are unequipped, their respective layer animations are skipped, while the base body (Layer 0) and hair (Layer 1) continue rendering without interruption.
- Cache keys explicitly mark empty slots as `"none"` (e.g. `2:003.jma:3000.jmp:none:none:...`) to eliminate cache collisions between naked and clothed states.

### 3.3 Compositing Pipeline (`ArchiveLoader.get_player_composite_frames`)
- Method: `get_player_composite_frames(role_id: int, equip_layers: Dictionary = {}) -> Array[ImageTexture]`
- Dimensions: 128x128 RGBA8 transparent canvas per frame.
- Frame Count: Exactly 64 total frames:
  - Walk Cycle: Frames 0..31 (4 frames per heading x 8 headings)
  - Standing Idle Breathing Cycle: Frames 32..63 (4 frames per heading x 8 headings)
- Blending: Each layer image is placed onto the canvas at `Vector2i(pivot_x, pivot_y)` using `Image.blend_rect()`.
- Caching: Composited textures are cached in RAM dictionary `_composite_cache[cache_key]`.

## 4. 8-Directional Kinematics & Animation Indexing

### 4.1 Counter-Clockwise Heading Order
WLO animation frame banks follow counter-clockwise angular order:
- `NORTH = 0` (angle -90 deg / 270 deg)
- `NORTH_WEST = 1` (angle -135 deg / 225 deg)
- `WEST = 2` (angle 180 deg / -180 deg)
- `SOUTH_WEST = 3` (angle 135 deg)
- `SOUTH = 4` (angle 90 deg)
- `SOUTH_EAST = 5` (angle 45 deg)
- `EAST = 6` (angle 0 deg)
- `NORTH_EAST = 7` (angle -45 deg / 315 deg)

### 4.2 Motion States
- Walk State (`is_moving = true`):
  - Frame Index: `heading * 4 + sub_idx` (sub_idx runs at 8 FPS)
- Standing State (`is_moving = false`):
  - Frame Index: `32 + heading * 4 + sub_idx` (sub_idx runs at 4 FPS breathing rate)
- Input Constraints:
  - Movement inputs are restricted strictly to keyboard arrow keys (`KEY_UP`, `KEY_DOWN`, `KEY_LEFT`, `KEY_RIGHT`) and mouse left-click pathfinding.

## 5. UI Layout Specifications

### 5.1 PlayerStatusDock (`main_Status_1.bmp`, 241x116)
- Avatar Portrait:
  - Sourced from `menu/Skins/default/Btn_RolePic_2.bmp` for Betty (Role 2).
  - Region: `Rect2(25, 0, 92, 92)` framing Betty's bust inside the circular gold aperture at `(15, 40, 69, 69)`.
- HP / SP / EXP Bars:
  - HP Bar: `(102, 23)`, Size: `(126, 12)`, Crimson red fill `Color(0.88, 0.15, 0.15, 1.0)`, centered text `"320 / 320"`.
  - SP Bar: `(102, 41)`, Size: `(112, 12)`, Vibrant cobalt blue fill `Color(0.15, 0.45, 0.95, 1.0)`, centered text `"150 / 150"`.
  - EXP Bar: `(86, 59)`, Size: `(99, 8)`, Amber gold fill `Color(0.95, 0.80, 0.10, 1.0)`, centered text `"45%"`.

### 5.2 CharacterWindow (`Form_RoleStatus_1.bmp`, 386x461)
- Paper Doll TextureRect:
  - Position: `(37, 133)`, Size: `128x128`.
  - Texture: Betty's composite standing South frame 48.
- Stats Alignment:
  - Left Combat Stats:
    - ATK (Y=338): 34 (Base 26 + Iron Sword 8)
    - DEF (Y=354): 28 (Base 25 + Harness Pants 2 + Pink Shoes 1)
    - MATK (Y=370): 15
    - MDEF (Y=386): 14
    - SPD (Y=402): 22 (Base 21 + Pink Shoes 1)
  - Right Grid Attributes:
    - Name: "Betty", Level: "10", Element: "Wind"
    - HP: "320 / 320", SP: "150 / 150", EXP: "4500 / 10000"
    - STR: 10, CON: 10, INT: 6, WIS: 6, AGI: 18, Free Points: 0

## 6. Automated Verification

Run full automated headless test covering authentic character role mapping and equip/unequip visibility:
```powershell
C:\Godot\godot_console.exe --path D:\Godot\WonderlandOnline\wonderland-online-client --headless -s tests/test_equipment_visibility.gd
```
