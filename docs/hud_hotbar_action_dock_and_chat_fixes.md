# Wonderland Online HUD Hotbar, Action Dock & Chat Fixes Specification

## 1. Overview
This document specifies the technical architecture and implementation for:
1. Right Hotbar Dock (`HUDHotbar`): 4-page paging mechanism, Drag & Drop item/skill binding, unobstructed F1..F8 baked-in artwork, and quick activation.
2. Bottom-Right Action Dock (`HUDActionDock`): Lifted vertical position (-78px to -10px) preventing screen edge clipping, restoration of authentic gold arch background (`ActionBackground`), and tooltip correction for `BtnQuest` to `"Compound [C]"`.
3. Chat Dock (`HUDChat`): Removal of ghosted/cropped screenshot artifacts from `panel_talk_form_left`, migration to authentic translucent dark parchment `StyleBoxFlat` with gold border.

---

## 2. Right Hotbar System (`HUDHotbar`)

### 2.1 Visual Artwork Parity
- Background texture: Authentic vertical quick bar `menu/Skins/white/Form_HotKey_V.bmp` (56x274) containing pre-rendered F1..F8 tabs on left (x=0..18).
- Redundant text labels (`KeyLabel`): Hidden (`visible = false`) while preserving property `text = "F%d"` for test suite compatibility, ensuring the baked-in F1..F8 artwork is displayed cleanly without duplicate text overlay.
- Action slot icons (`TextureRect`): Positioned at $(X=19, Y=1, W=24, H=24)$ inside `HotbarSlotButton` $(X=6, Y=28 + i \times 27, W=44, H=25)$.

### 2.2 4-Page Paging Architecture
- 4 Pages $\times$ 8 slots (32 quickslots total), indexed `0..3`.
- Bottom page controls container positioned at $(X=0, Y=246, W=56, H=26)$:
  - `BtnPagePrev`: Sliced from authentic `HotKeyPageUp_H.bmp` (`btn_hotbar_prev_*.png`, $14 \times 16$ at $X=6, Y=4$).
  - `PageDisplay` / `PageLabel`: Page icon sliced from `HotKeyPage_1.bmp` .. `4.bmp` or circled unicode numeral (`①`, `②`, `③`, `④`) at $(X=21, Y=4, W=14, H=16)$.
  - `BtnPageNext`: Sliced from authentic `HotKeyPageDn_H.bmp` (`btn_hotbar_next_*.png`, $14 \times 16$ at $X=36, Y=4$).
- Page cycling methods:
  - `prev_page()`: `set_page(posmod(_current_page - 1, 4))`
  - `next_page()`: `set_page(posmod(_current_page + 1, 4))`
  - Hotkey support: `KEY_PAGEUP` and `KEY_PAGEDOWN` mapped in `HUD._unhandled_input`.

### 2.3 Drag & Drop Binding
- Class: `HotbarSlotButton` (`scripts/ui/hotbar_slot_button.gd`) extending `Button`.
- Incoming drag data formats accepted:
  - `inventory`: `{"type": "inventory", "slot_index": int, "item": Dictionary, "icon_tex": Texture2D}`
  - `item`: `{"type": "item", "id": int, "name": String, "icon_tex": Texture2D}`
  - `skill`: `{"type": "skill", "id": int, "name": String, "icon_tex": Texture2D}`
  - `hotbar`: `{"type": "hotbar", "page": int, "slot_index": int, "entry": Dictionary}`
- Right-click clear: Clicking right mouse button on an assigned slot clears it and logs feedback to chat.
- Slot activation: Left click or pressing F1..F8 triggers `activate_slot(slot_index)`:
  - Consumable/Equip: Finds matching item in `inventory_ctrl` and invokes `use_or_equip_inventory_item`.
  - Skill: Invokes `use_skill(id)`.

---

## 3. Bottom Action Dock Enhancements (`HUDActionDock`)

### 3.1 Vertical Offset Adjustment
- Prior positioning: `offset_top = -68.0, offset_bottom = 0.0`. Large 51-54px circular buttons were clipped at the monitor bezel.
- New lifted positioning: `offset_top = -78.0, offset_bottom = -10.0` (lifted by 10px), providing a 10px safety margin above the viewport bottom.

### 3.2 Authentic Gold Arch Background
- Node: `BottomActionDock/ActionBackground` set to `visible = true`.
- Texture: Sliced authentic skin `menu/Skins/default/Btn_BackGround_2.bmp` (`assets/hud/btn_background_2.png`, $268 \times 37$) rendered behind `ButtonContainer`.

### 3.3 Compound Button Tooltip
- Node: `BottomActionDock/ButtonContainer/BtnQuest`
- Tooltip text updated from `"Quest Log & Alchemy [Q]"` to `"Compound [C]"` as requested.

---

## 4. Chat Dock Clean Parchment System (`HUDChat`)

### 4.1 Screenshot Artifact Elimination
- Node: `PanelTalkFormLeft` had dirty cropped screenshot texture with ghosted buttons and borders. Texture set to `null` and mouse filter passed, removing ghosted pixels while preserving interactive buttons `BtnMsgLock` and `BtnChatSwitch`.
- `ChatFrameNinePatch`: Disabled dirty screenshot texture in favor of authentic `StyleBoxFlat`.

### 4.2 Authentic Parchment StyleBoxFlat
- Panel background: `Color(0.03, 0.04, 0.07, 0.75)` (framed) or `0.52` (compact).
- Border: `Color(0.72, 0.58, 0.32, 0.85)` (1px solid gold/parchment frame).
- Margins: Left `46px` (clearing left control buttons), Top `6px`, Right `24px` (clearing resize toggle), Bottom `6px`.

---

## 5. Verification Test Evidence
Validated using headless Godot engine:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_game_resizable.gd
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_hotbar_slots.gd
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_hud_chat_and_status_features.gd
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_hud_hotbar_action_and_chat_fixes.gd
```
Result: 100% PASS with 0 errors across all resolutions and dock components.
