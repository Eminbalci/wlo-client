# Authentication and Character Flow Buttons Verification Specification

This document provides complete technical specifications, signal paths, state transitions, and verification test results for all buttons across the Authentication and Character Creation flow in Wonderland Online client.

## Overview

The auth flow comprises four major components and managers, fully verified headlessly via [`test_auth_flow.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tests/test_auth_flow.gd) (81/81 assertions passing).

---

## 1. ServerSelect Component [`server_select.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/auth/server_select.gd)

- **Server Group Buttons / List (`MainServerList`)**:
  - **Action**: Parses `SERVER.INI`, populates server groups (e.g. Aries, Taurus, Local Server).
  - **Signal / Transition**: Clicking or activating a group switches view mode to `CHANNELS` (`ViewMode.CHANNELS`), showing subservers/channels for the selected group.
- **Channel / Subserver Buttons / List (`ChannelList`)**:
  - **Action**: Lists available channels with status ping indicator lights (`icon_signal_0.png` to `icon_signal_3.png`).
  - **Signal / Transition**: Selecting a channel sets `selected_server_entry`.
- **Enter / Next Button (`BtnNext`)**:
  - **Action**: Confirms the currently selected server/channel.
  - **Signal Emitted**: `channel_selected(server_entry)` carrying the chosen `ServerConfig.ServerEntry`.
- **Back / Leave Button (`BtnLeave`)**:
  - **Action**: In channel view, returns to main server list (`show_main_servers()`). In main server view, requests exit/leave.
  - **Signals Emitted**: `leave_requested()` and `exit_requested()`.

---

## 2. LoginDialog Component [`login_dialog.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/auth/login_dialog.gd)

- **Login Button (`BtnLogin`)**:
  - **Action**: Validates username and password inputs, saves account if checkbox is selected.
  - **Signal Emitted**: `login_submitted(username, password, save_account_bool)`.
- **Cancel / Back Button (`BtnCancel`)**:
  - **Signal Emitted**: `canceled()` and `back_requested()`.
- **Saved Accounts Triangle Button / Dropdown Toggle**:
  - **Action**: Toggles visibility of `SavedAccountsPopup` populated via [`SavedAccountsManager`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/auth/saved_accounts_manager.gd). Selecting an item populates the username input field.
- **Save Account Checkbox**:
  - **Action**: Toggles persistent storage state in `user://saved_accounts.cfg`.

---

## 3. CharacterSelect Component [`character_select.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/auth/character_select.gd)

- **CardSlot 0 & CardSlot 1 Buttons**:
  - **`BtnCreateChar`**: Visible on empty slots; emits `create_requested(slot_index)`.
  - **`BtnLogin` (Enter World)**: Visible on occupied slots; emits `character_selected(slot_index)`. Disabled when slot is empty.
  - **`BtnDelChar` (Delete)**: Deletes character from slot via [`CharacterManager`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/auth/character_manager.gd) and refreshes slots.
  - **`BtnArrowLeft` / `BtnArrowRight`**: Rotates character 3D/sprite preview orientation index (0-7).
- **Previous / Back Button (`BtnPrev`)**:
  - **Signal Emitted**: `back_requested()`.

---

## 4. CharacterCreate (4-Step Wizard) [`character_create.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/auth/character_create.gd)

- **Step 1 (Role Selection)**:
  - **Role List / Click & Prev/Next buttons**: Selects starting role ID (1-14, e.g. Role 6 / Daniel), displays role name and portrait bust.
- **Step 2 (Element Selection)**:
  - **4 Element Buttons (Earth, Water, Fire, Wind)**: Assigns elemental affinity, updates element description and icon.
- **Step 3 (Stat Allocation)**:
  - **Stat +/- Buttons (STR, CON, INT, WIS, AGI)**: Allocates bonus points from a 4-point pool with real-time validation and `Reset` button support.
- **Step 4 (Name & Confirmation)**:
  - **Name LineEdit**: Validates non-empty character name.
  - **Create Character Confirmation Button (`BtnConfirm` / `BtnCreate`)**: Persists new character via `CharacterManager` and emits `character_created(character_data)`.

---

## Verification Test Execution

Run the headless verification suite via Godot console:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_auth_flow.tscn
```
- **Total Assertions**: 81
- **Status**: 81/81 Passed (100%)
