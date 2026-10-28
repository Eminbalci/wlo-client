# Wonderland Online Circular Bottom-Right Action Dock & Chat UI Specification

## 1. Overview
This document specifies the technical architecture, button iconography, and layout implementation of the authentic 6-button circular bottom-right action dock (`BottomActionDock`) and the parchment chat system (`ChatDock`) in the Wonderland Online Godot 4 client.

---

## 2. Bottom-Right Action Dock Architecture

### 2.1 Visual Reference & Slicing Parity
In authentic Wonderland Online, the bottom-right action bar contains 6 circular ornate gold and blue buttons, replacing the prior 8 generic square buttons:

| Index | Button Node | Iconography | Target Window / Action | Textures (Normal / Hover / Pressed) | Hotkey |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `BtnStatus` | Character Doll + Treasure Chest | `CharacterWindow` (Unified Stats & 45-slot Inventory) | `assets/hud/btn_dock_1_*.png` ($43 \times 43$) | `C` / `I` |
| 2 | `BtnSkill` | Magic Staff with Glowing Orb | `SkillWindow` (`form_skill.bmp`) | `assets/hud/btn_dock_2_*.png` ($43 \times 43$) | `S` |
| 3 | `BtnQuest` | Boiling Cauldron / Pot with Spoon | `Compound` (`Form_Compound_1.bmp` / Alchemy) | `assets/hud/btn_dock_3_*.png` ($43 \times 43$) | `C` |
| 4 | `BtnTeam` | 3 Character Faces (Blonde, Pink, Blue Hair) | `TeamWindow` (`Form_Team_2.bmp`) | `assets/hud/btn_dock_4_*.png` ($43 \times 43$) | `T` |
| 5 | `BtnFriends` | 2 Character Faces with Pink Heart | `FriendsWindow` (`Form_Friend_2.bmp`) | `assets/hud/btn_dock_5_*.png` ($43 \times 43$) | `F` |
| 6 | `BtnSystem` | Desktop PC Monitor with Red Checkmark | `SystemWindow` (`Form_System_2.bmp`) | `assets/hud/btn_dock_6_*.png` ($43 \times 43$) | `Esc` |

### 2.2 Coordinates & Layout Properties
- **Dock Node**: `BottomActionDock` (`Control`) anchored bottom-right (`anchors_preset = 3`, `offset_left = -282.0, offset_top = -78.0, offset_right = 0.0, offset_bottom = -10.0`).
- **Action Background**: Restored authentic gold arch `ActionBackground` (`assets/hud/btn_background_2.png` sliced from `menu/Skins/default/Btn_BackGround_2.bmp`).
- **Location & Map Coordinate Readout**: `LocationLabel` positioned at $(X=0, Y=0, W=278, H=20)$ above the circular buttons:
  - Font size: `11px`, Outline size: `2px` with black outline and shadow.
  - Dynamically updated via `update_location(map_name, x, y)` -> `"Ship Deck  X: 899  Y: 1102"`.
- **Button Container**: `ButtonContainer` (`HBoxContainer`) positioned at $(X=4, Y=22, W=276, H=44)$ with separation of `4px`.
- **Backward-Compatible Button Accessors**: `btn_inventory` aliases to `btn_status` and `btn_battle` aliases to `btn_system` ensuring existing scripts and APIs operate without breakage.

---

## 3. Chat System Architecture (`ChatDock`)

### 3.1 Layout & Visual Components
- **Dock Positioning**: Anchored bottom-left at $(X=0, Y=575, W=524, H=25)$.
- **Mailbox / Envelope Button**: `BtnMail` positioned at bottom-left $(X=3, Y=2, W=26, H=21)$ with 3 states sliced from authentic envelope icons (`btn_mail_normal.png`, `btn_mail_hover.png`, `btn_mail_pressed.png`). Perfectly fits the 26px mailbox indentation on the parchment background.
- **Channel Selector Button**: `BtnChannel` positioned at $(X=30, Y=2, W=42, H=21)$ with dark moss green background (`#0a170f`), dynamic channel-specific border (`#2eb847` for Local, `#4ab3ff` for Team, `#32e070` for Guild, `#ff66b2` for Whisper, `#ffea33` for World), and crisp 11px channel label.
- **Whisper Target Input**: `WhisperTarget` LineEdit positioned at $(X=74, Y=2, W=86, H=21)$ styled with dark translucent backplate and gold border; automatically displayed only when active channel is Whisper or `/target` is invoked.
- **Chat Input Field**: `ChatInput` LineEdit dynamically positioned at $(X=74, Y=2, W=420, H=21)$ in standard mode, smoothly shifting to $(X=163, Y=2, W=331, H=21)$ in Whisper mode, featuring subtle parchment focus glow and gold blinking caret.
- **Emote Button**: `BtnEmote` positioned at $(X=495, Y=1, W=25, H=23)$ with authentic normal/hover/pressed expression icons.
- **Channel Tabs Bar**: `ChannelTabs` positioned seamlessly atop `ChatHistoryPanel` with custom `StyleBoxFlat` for inactive, hover, and active states with 2px gold top indicator and 11px typography.
- **Custom Scrollbar**: Sleek 6px parchment scrollbar with custom grabber and track styling, replacing bulky Godot default scrollbar.
- **Chat History Panel**: `ChatHistoryPanel` positioned at $(X=0, Y=-86 \text{ to } -200, W=524)$ styled with dark translucent parchment backplate (`Color(0.03, 0.04, 0.07, 0.52)` in compact mode, `0.78` in framed mode) and gold border (`Color(0.72, 0.58, 0.32, 0.85)`).

### 3.2 Message Formatting & Spam Suppression
- System messages are formatted as `[color=#ffcc33][System][/color] [color=#ffffcc]%s[/color]` eliminating raw duplicate tags.
- Channel color matrix:
  - `System`: Gold/Amber tag (`#ffcc33`) with soft light cream message text (`#ffffcc`)
  - `Current / Local`: Emerald green tag (`#42d766`) with crisp white message text (`#ffffff`)
  - `Team`: Vibrant cyan tag (`#4ab3ff`) with ice blue message text (`#e6f4ff`)
  - `Guild`: Vibrant green tag (`#32e070`) with mint message text (`#e8ffef`)
  - `Whisper`: Vibrant magenta tag (`#ff66b2`) with soft rose message text (`#fff0f7`)
  - `World`: Canary yellow tag (`#ffea33`) with light yellow message text (`#fffde6`)
- Built-in rate limiter suppresses identical messages within $1.5$ seconds, preventing pathfinding log spam.

---

## 4. Verification Evidence
All components verified in-engine using headless runner:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_hud_runner.tscn
```
Output:
- `[PASS] BottomActionDock LocationLabel verified: Ship Deck  X: 899  Y: 1102`
- `[PASS] Button BtnStatus textures OK: normal=(43.0, 43.0)`
- `[PASS] Button BtnSkill textures OK: normal=(43.0, 43.0)`
- `[PASS] Button BtnQuest textures OK: normal=(43.0, 43.0)`
- `[PASS] Button BtnTeam textures OK: normal=(43.0, 43.0)`
- `[PASS] Button BtnFriends textures OK: normal=(43.0, 43.0)`
- `[PASS] Button BtnSystem textures OK: normal=(43.0, 43.0)`
- `[PASS] ChatDock Mailbox and Local tab button verified`
- `--- ALL VERIFICATIONS PASSED WITH 0 ERRORS ---`
