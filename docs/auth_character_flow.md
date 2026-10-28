# Wonderland Online - Authentication, Server Selection & Character Flow

## Overview
This document specifies the authentic 1:1 reconstruction of the Wonderland Online (WLRI) authentication, server selection, account management, and character selection/creation pipeline in Godot 4. The architecture is reverse-engineered directly from the original Borland Delphi 6 client (`login.exe` / `main.exe`), VCL form layouts, binary skin sheets (`menu/Skins/white/`, `menu/Skins/default/`), and protocol specifications.

---

## Architecture & Screen Pipeline

The login system implements a hierarchical state machine managed by `LoginScreen` (`res://scripts/ui/login_screen.gd`), supporting seamless switching between 9 distinct screens and modal dialogs:

```
[ServerSelect (Main Servers)]
             │ (Select Server Group)
             ▼
[ServerSelect (Channels & Ping Lights)]
             │ (Select Channel / OK)
             ▼
     [Login Dialog] ◄────────────────┐ (Back / Switch Account)
      │          ▲                   │
      │ (Login)  │ (Back)            │
      ▼          │                   │
[Character Select (4 Slots)] ────────┘
      │               ▲
      │ (Create Slot) │ (Cancel / Created)
      ▼               │
[Character Create Wizard (4 Steps)]
   Step 1: Role / Appearance (14 Playable Roles)
   Step 2: Element Selection (Earth, Water, Fire, Wind)
   Step 3: Stat Allocation (STR, CON, INT, WIS, AGI + 4 Bonus Pool)
   Step 4: Name & Confirmation Review
      │
      ▼ (Enter World)
[GameDatabase.active_character -> MapView (res://scenes/world/map_view.tscn)]
```

---

## 1. Screen Specifications

### 1. Main Servers List
- **Skin Asset**: `menu/Skins/white/Form_ServerList_1.bmp` (309x352).
- **Buttons**:
  - `BtnLogin`: Sliced from `menu/Skins/default/btn_logIn.bmp` (3 vertical states: normal, hover, pressed).
  - `BtnCancel`: Sliced from `menu/Skins/default/Btn_Cancel_1.bmp` (3 vertical states).
- **Data Source**: Parsed from `res://assets/SERVER.INI` via `ServerConfig.load_from_file()`. Handles bracketed group headers (e.g. `01[Local Server]1`).

### 2. Channels List & Signal Indicators
- **Skin Asset**: `menu/Skins/white/Form_Channel_1.bmp` (166x237).
- **Signal Lights**: Sliced from `menu/Skins/default/icon_serverSignal.bmp` (18x72 vertical sheet, 4 frames of 18x18):
  - Frame 0: Green (Smooth / Low Latency)
  - Frame 1: Yellow (Normal)
  - Frame 2: Orange (Busy)
  - Frame 3: Red (Crowded / Full)
- **Buttons**:
  - `BtnOk`: Sliced from `menu/Skins/default/btn_ok_1.bmp`.
  - `BtnPrev`: Sliced from `menu/Skins/default/Btn_Prev_1.bmp` (returns to Main Servers).

### 3. Login Dialog
- **Skin Asset**: `menu/Skins/white/Form_IdPassword_1.jpg` (259x352).
- **Form Fields**:
  - `Account`: LineEdit positioned at `(72, 86)` with custom flat stylebox matching the parchment texture.
  - `Password`: LineEdit positioned at `(72, 118)` with `secret = true`.
  - `Save Account`: CheckBox positioned at `(72, 146)` with custom check icon.
- **Buttons**:
  - `BtnLogin`: Sliced from `menu/Skins/default/Btn_Login_L.bmp`.
  - `BtnPrev`: Sliced from `menu/Skins/default/Btn_Prev_L.bmp`.
  - `BtnApply`: Sliced from `menu/Skins/default/Btn_applyID_1.bmp` (Registration link).
  - `BtnAbout`: Sliced from `menu/Skins/default/Btn_About_L.bmp`.
  - `BtnDropdown`: Triangular button at `(216, 88)` toggling the Saved Accounts popup.

### 4. Saved Accounts Dropdown
- **Skin Asset**: Floating popup panel with border `Color(0.3, 0.4, 0.5)` and parchment background.
- **Behavior**: Lists all persisted accounts stored in `user://saved_accounts.json`.
- **Interaction**: Clicking an account automatically fills the `Account` LineEdit, checks `Save Account`, and closes the popup.

### 5. Character Selection Screen
- **Skin Assets**:
  - Character Details Panel: `menu/Skins/white/Form_SelectRole_Info_R.bmp` (200x320).
  - Slot Bar: 4 interactive slot tabs (Slot 0, Slot 1, Slot 2, Slot 3).
- **Details Readout**:
  - Name, Role Name, Element (with colored icon), Level, Base Stats (STR, CON, INT, WIS, AGI), Calculated HP and SP.
- **Animated Preview**:
  - 14 playable role avatar frames loaded from `008.jma` via `ArchiveLoader.get_avatar_frames()`.
  - Dynamic 3.5s eye-blinking timer state machine (Frame 0: Open eyes -> Frame 1: Half-blink -> Frame 2: Closed -> Frame 0).
- **Action Buttons**:
  - `Enter World`: Enabled only when selecting an occupied slot.
  - `Create Character`: Enabled only when selecting an empty slot.
  - `Delete Character`: Opens confirmation modal requiring typing "DELETE" or confirming deletion.

### 6-9. Character Creation Wizard (4 Steps)
- **Step 1: Role & Appearance Selection**:
  - Grid of all 14 official playable roles:
    1. Nina (Female)
    2. Betty (Female)
    3. Rocco (Male)
    4. Vanessa (Female)
    5. Lique (Male)
    6. Daniel (Male)
    7. Sid (Male)
    8. Jessica (Female)
    9. Konnotsuroko (Female)
    10. Iris (Female)
    11. Maria (Female)
    12. More (Male)
    13. Kurogane (Male)
    14. Karin (Female)
  - Displays full avatar preview, role lore description, and initial stat allocations from `GameDatabase.get_role()`.

- **Step 2: Element Selection**:
  - Four elemental affinities:
    - **Earth**: Defense focus (+2 CON, +1 STR). Superior physical resilience and earth binding spells.
    - **Water**: Support and healing focus (+2 WIS, +1 CON, +1 INT). HP recovery and resurrection abilities.
    - **Fire**: Damage focus (+2 STR, +1 AGI). Extreme physical/magical burst damage.
    - **Wind**: Speed and evasion focus (+2 AGI, +1 STR). Highest initiative order in combat and evasion buffs.
  - Sourced icons: `res://assets/hud/icon_element_1.png` (Earth) through `icon_element_4.png` (Wind).

- **Step 3: Stat Allocation**:
  - 5 primary attributes: STR, CON, INT, WIS, AGI.
  - Pool of 4 allocatable bonus points (`TOTAL_BONUS_POINTS = 4`).
  - Interactive `[+]` and `[-]` buttons per attribute with clamping to available pool.
  - Live preview of final calculated attributes: `Base + Element Bonus + Allocated Bonus`.

- **Step 4: Character Name & Confirmation**:
  - Name input (1 to 14 characters, trimmed).
  - Validation: rejects whitespace-only or empty strings.
  - Review summary card displaying portrait, role name, element, stats, and target slot.

---

## 2. Component Class References & APIs

### `SavedAccountsManager` (`res://scripts/ui/auth/saved_accounts_manager.gd`)
- `save_account(account_name: String) -> bool`: Persists unique account name to `user://saved_accounts.json` and updates `last_used`.
- `get_saved_accounts() -> Array[String]`: Returns list of all stored accounts.
- `get_last_used_account() -> String`: Returns the most recently active account or empty string.
- `remove_account(account_name: String) -> bool`: Deletes an account entry from storage.
- `clear_all() -> void`: Wipes saved accounts file.

### `CharacterManager` (`res://scripts/ui/auth/character_manager.gd`)
- `get_characters(account_name: String) -> Dictionary`: Returns `{slot_index: character_dict}` for given account.
- `get_character_in_slot(slot_index: int, account_name: String) -> Dictionary`: Returns data dict or empty `{}`.
- `save_character(slot_index: int, char_data: Dictionary, account_name: String) -> bool`: Validates and saves character to `user://characters.json`.
- `delete_character(slot_index: int, account_name: String) -> bool`: Erases character in slot.
- `create_default_character(slot: int, role: int, name: String, elem: String, str: int, con: int, int_val: int, wis: int, agi: int) -> Dictionary`: Calculates derived HP (`con * 15 + 100`) and SP (`wis * 12 + 80`) and constructs normalized record.

### `ServerSelect` (`res://scripts/ui/auth/server_select.gd`)
- Signals:
  - `channel_selected(server: RefCounted)`: Emitted with active `ServerConfig.ServerEntry`.
  - `exit_requested()`: Emitted on cancel.
- Methods:
  - `show_main_servers() -> void`: Activates Main Server list mode.
  - `show_channels(group: ServerConfig.ServerGroup) -> void`: Populates and displays channels with signal lights.

### `LoginDialog` (`res://scripts/ui/auth/login_dialog.gd`)
- Signals:
  - `login_submitted(account: String, password_text: String, save_account: bool)`: Emitted when login button pressed or enter key hit.
  - `prev_pressed()`: Emitted to return to Server Select.
- Methods:
  - `set_server_info(group_name: String, channel_name: String) -> void`: Updates header banner.
  - `set_status(msg: String) -> void`: Updates status footer label.

### `CharacterSelect` (`res://scripts/ui/auth/character_select.gd`)
- Signals:
  - `character_selected(character_data: Dictionary)`: Emitted on Enter World.
  - `create_requested(slot_index: int)`: Emitted on Create Character.
  - `back_requested()`: Emitted to return to Login Dialog.
- Methods:
  - `select_slot(slot_index: int) -> void`: Updates UI to target slot.
  - `refresh_characters() -> void`: Re-queries `CharacterManager` and refreshes slot tabs.

### `CharacterCreate` (`res://scripts/ui/auth/character_create.gd`)
- Signals:
  - `character_created(char_data: Dictionary)`: Emitted after character created and persisted.
  - `cancelled()`: Emitted on wizard cancel.
- Methods:
  - `start_wizard(slot_index: int) -> void`: Resets wizard state to Step 1 for target slot.
  - `goto_step(step_idx: int) -> void`: Steps through 1..4.
  - `select_role(role_id: int) -> void`: Sets active role 1..14.
  - `select_element(elem_name: String) -> void`: Sets Earth, Water, Fire, Wind.
  - `_modify_stat(stat_key: String, delta_val: int) -> void`: Adds or removes points from stat pool.

---

## 3. Network Protocol & Wire Handshake

1. **Connection**: Connects to `current_server.host:current_server.port` via TCP stream (`NetworkClient`).
2. **Client Version Handshake**:
   - `ActionCode`: `1`, `SubAction`: `1`.
   - Payload: `pack_u16(1000)` (Client Version 1.000).
3. **Authentication Request**:
   - `ActionCode`: `63`, `SubAction`: `4`.
   - Payload: `pack_u16(1000)` + `pack_string(account)` + `pack_string(password)`.
4. **Authentication Response**:
   - `ActionCode`: `2` or `63`.
   - Payload byte 0: `1` = OK (proceed to Character Select), `0` = Invalid Credentials.
5. **Offline Fallback**:
   - Pressing `F1` or clicking `Offline Mode` bypasses the socket connection, seeding sample characters and proceeding directly to local character select and world map.

---

## 4. Verification Suite

The entire authentication, server selection, account management, and character creation/selection pipeline is covered by the headless test runner:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_auth_flow.tscn
```

### Test Coverage Summary (79/79 Assertions Passed)
- **SavedAccountsManager**: Account persistence, deduplication, retrieval, last-used tracking, removal.
- **CharacterManager**: 4 slots persistence, stat calculation, attribute mapping, deletion.
- **ServerSelect**: `SERVER.INI` parsing, group display, channel listing, ping light atlas generation, signal dispatch.
- **LoginDialog**: Server text display, triangle button popup toggle, account selection, credentials validation, submission signal.
- **CharacterSelect**: Slot selection, occupied vs empty slot button states, animated eye-blinking preview, Enter World signal.
- **CharacterCreate Wizard**: 4-step wizard transitions, 14 roles selection, 4 elements affinity stat calculation, 4 points bonus allocation/clamping, name validation, character creation signal.
- **LoginScreen State Machine**: Full lifecycle flow from Server Select -> Channel Select -> Login -> Character Select -> Character Create -> Enter World -> `GameDatabase.active_character` handoff.
