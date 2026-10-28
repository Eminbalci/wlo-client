# Wonderland Online HUD & Bottom Action Dock Specification

## Overview
This document specifies the technical implementation, asset mapping, and coordinate architecture of the Bottom Action Dock and Floating Delphi VCL Windows in the Godot 4.6 Wonderland Online client (`D:\Godot\WonderlandOnline\wonderland-online-client`).

## Architecture & Layout

### 1. Bottom Action Dock (280x35)
- **Anchoring**: `Bottom-Right` at `(800, 600)`, `anchors_preset = 3` (bottom-right: `anchor_left = 1.0, anchor_top = 1.0, anchor_right = 1.0, anchor_bottom = 1.0`), position `offset_left = -280.0, offset_top = -35.0, offset_right = 0.0, offset_bottom = 0.0` ($X=520..800, Y=565..600$).
- **Complementary Docking**: Connects seamlessly with Chat Dock ($X=0..521, Y=575..600$), creating a continuous bottom bar spanning the entire $800$px screen width.
- **Background Texture**: `menu/Skins/default/Btn_BackGround_1.bmp` ($380 \times 35$ metallic bar).
- **Buttons (8 Total)**:
  - Sliced dynamically at runtime into `AtlasTexture` normal, hover, and pressed states (height $H/3$).
  - 100% in-memory streaming through `ArchiveLoader.get_ui_texture()`. Zero loose files written to disk.

| Index | Button Node | Texture File | Slice Size | Window Mapping | Hotkey |
|-------|-------------|--------------|------------|----------------|--------|
| 1 | `BtnStatus` | `menu/Skins/default/Btn_1.bmp` | $37 \times 33$ | `CharacterWindow` (`Form_RoleStatus_1.bmp`, $386 \times 461$) | `C` |
| 2 | `BtnInventory` | `menu/Skins/default/Btn_2.bmp` | $37 \times 34$ | `InventoryWindow` (`Form_ThingGrid5x5_1.bmp`, $209 \times 287$) | `I` |
| 3 | `BtnSkill` | `menu/Skins/default/Btn_3.bmp` | $37 \times 33$ | `SkillWindow` (`form_skill.bmp`, $290 \times 459$) | `S` |
| 4 | `BtnTeam` | `menu/Skins/default/Btn_4.bmp` | $36 \times 33$ | `TeamWindow` (`Form_Team_2.bmp`, $371 \times 539$) | `T` |
| 5 | `BtnQuest` | `menu/Skins/default/Btn_5.bmp` | $36 \times 33$ | `QuestWindow` (`form_taskview_1.bmp`, $432 \times 367$) | `Q` |
| 6 | `BtnFriends` | `menu/Skins/default/Btn_6.bmp` | $38 \times 33$ | `FriendsWindow` (`Form_Friend_2.bmp`, $356 \times 493$) | `F` |
| 7 | `BtnBattle` | `menu/Skins/default/Btn_7.bmp` | $37 \times 34$ | `FightWindow` (`BattleStatus_1.bmp`, $153 \times 115$) | `P` |
| 8 | `BtnSystem` | `menu/Skins/default/Btn_8.bmp` | $36 \times 33$ | `SystemWindow` (`Form_System_2.bmp`, $388 \times 451$) | `Esc` |

### 2. Player Status Dock ($241 \times 116$)
- **Texture**: `menu/Skins/white/main_Status_1.bmp`
- **Avatar Socket**: $X=14..74, Y=45..105$ (circular frame centered at $X=44, Y=75$).
- **Bar Coordinates & Heights**:
  - Name: $X=95..170, Y=16..32$
  - Level: $X=170..228, Y=16..32$
  - EXP Bar: $X=95..225, Y=63..68$ (5px, Gold `#EBB81F`, zero content margin)
  - HP Bar: $X=95..225, Y=87..92$ (5px, Red `#D92E2E`, zero content margin)
  - SP Bar: $X=95..225, Y=110..115$ (5px, Blue `#2E73F2`, zero content margin)

### 2.1 Right Hotbar Dock ($56 \times 274$)
- **Texture**: `menu/Skins/white/Form_HotKey_V.bmp`
- **Anchoring**: `Top-Right` at $X=744..800, Y=163..437$, seated below the Minimap and cleanly above the Bottom Action Dock.
- **Slots**: 8 vertical slots (F1..F8) with 27px stride, key indicator on left tab, 24x24 authentic item icon on right.

### 3. Click-to-Move Coordinate Transform
- Screen click unhandled event coordinates must be inverted against the viewport canvas transform to eliminate camera panning deviation:
  ```gdscript
  var canvas_coord: Vector2 = get_canvas_transform().affine_inverse() * event.position
  var world_coord: Vector2 = IsometricMath.screen_to_world(canvas_coord)
  ```
- Tested round-trip precision error: `0.0px`.

### 4. Eve.emg Authentic NPC Coordinates (Map 10001)
- Captain Robinson (`npc_id = 7`): `Vector2(1720, 906)`
- Crew Member (`npc_id = 4`): `Vector2(1470, 444)`
- Lookout Sailor (`npc_id = 6`): `Vector2(1363, 1261)`
- Dynamic feet grounding offset: `Vector2(0, -frame_height / 2.0)`.
