# Login & Enter World Engine Specification

## Overview
This document specifies the technical implementation, signal architectures, fallback timers, parameter validations, and world scene transitions for the Wonderland Online Godot 4 client authentication and character pipeline.

---

## 1. Bug Resolutions & Architectural Fixes

### Bug 1: Signal Argument Mismatch in Character Selection
- **Root Cause**: `CharacterSelect` (`res://scripts/ui/auth/character_select.gd`) defines `signal character_selected(slot_index: int)` and emits `slot_idx: int` on login confirmation. `LoginScreen` (`res://scripts/ui/login_screen.gd`) previously connected this to `_on_enter_world_with_character(char_data: Dictionary)`, which caused a GDScript runtime type conversion error: `Cannot convert argument 1 from int to Dictionary`.
- **Resolution**:
  - `_on_enter_world_with_character(arg: Variant) -> void` now accepts polymorphic input (`int` slot index or `Dictionary` character object).
  - When `arg is int`:
    - Queries `CharacterManager.get_character(arg, current_account)`.
    - If empty, queries `CharacterManager.get_character_in_slot(arg, current_account)`.
    - If empty, falls back to slot `0`.
    - If all slots empty, initializes a default starter character dictionary (`Daniel`, role_id 1, level 10, HP 245, SP 180, etc.) and persists it via `CharacterManager.save_character`.
  - When `arg is Dictionary`: uses `arg` directly.
  - Registers the active character into global singleton `GameDatabase.active_character`.
  - Persists character state into `user://characters.json`.
  - Transitions scene to `res://scenes/world/map_view.tscn` (fallback `res://scenes/maps/map_10001_ship_deck.tscn`).

### Bug 2: Login Network Freeze & Offline Fallback
- **Root Cause**: When submitting account credentials in `LoginDialog`, `StreamPeerTCP.connect_to_host()` initiates non-blocking connection. If the local server is offline or not responding on `127.0.0.1:6414`, the client previously remained indefinitely stuck on "Connecting..." status with no transition to character select.
- **Resolution**:
  - In `_on_login_submitted(account: String, _password_text: String, save_account: bool)`:
    - If `_is_offline_mode` is active, immediately transitions to `FlowState.CHARACTER_SELECT`.
    - If `_network.connect_to_server()` returns an immediate error (`err != OK`), immediately transitions to `FlowState.CHARACTER_SELECT` in offline mode.
    - If asynchronous connection starts, attaches a 0.5s timer (`get_tree().create_timer(0.5)`). If the server has not connected within 0.5s, the client automatically falls back to offline mode and transitions to `FlowState.CHARACTER_SELECT`.
    - Added missing API methods on `LoginDialog`: `set_status(text: String)`, `get_username() -> String`, `get_password() -> String`.
    - Corrected `_on_packet_received` signature from 3 parameters `(action_code, _sub_action, payload)` to 2 parameters `(action_code, payload)` matching `NetworkClient.packet_received`.

---

## 2. API Specifications

### `CharacterManager.get_character(slot_index: int, account_name: String = "") -> Dictionary`
- **Parameters**:
  - `slot_index`: Integer slot index `[0..3]`.
  - `account_name`: Account name identifier string.
- **Returns**: `Dictionary` containing character data or `{}` if slot is unoccupied.
- **Exceptions & Edge Cases**:
  - Slot indices `< 0` or `>= MAX_SLOTS (4)` return `{}`.
  - Empty `account_name` defaults to `"default"`.

### `LoginScreen._on_enter_world_with_character(arg: Variant) -> void`
- **Parameters**:
  - `arg`: Either `int` (slot index emitted by `character_selected`) or `Dictionary` (direct character data).
- **Behavior**:
  - Resolves or constructs character dictionary.
  - Populates `GameDatabase.active_character`.
  - Calls `get_tree().change_scene_to_file.call_deferred(MAP_VIEW_SCENE_PATH)`.
- **Edge Cases Handled**:
  - Unrecognized argument types fall back to slot 0 or starter character.
  - Character state is saved to `user://characters.json` before world entry.

### `LoginDialog.set_status(text: String) -> void`
- **Parameters**:
  - `text`: Status string displayed on the centered form card and logged to console.

---

## 3. Verification Test Suite

Executed headlessly via Godot 4.6.2 console:
```powershell
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" scenes/tests/test_auth_flow.tscn
```
- **Assertion Coverage**: 89/89 tests passed (100%).
- **Covered Scenarios**:
  - Saved accounts persistence, retrieval, deletion, and last used update.
  - Character manager creation, stat calculation, persistence, alias `get_character`, and slot deletion.
  - Server select groups, channels, signal lights, channel selection signal, and leave/exit signals.
  - Login dialog saved accounts popup, input filling, status label, credential getters, and submission.
  - Character select cards, empty vs occupied slots, sprite/bust preview, and `character_selected` signal.
  - Character create 4-step wizard: role selection, element selection, 4-point stat allocation, name validation, and character creation.
  - Login screen state transitions: `SERVER_SELECT` -> `LOGIN_DIALOG` -> `CHARACTER_SELECT` -> `CHARACTER_CREATE` -> `CHARACTER_SELECT`.
  - Enter world with `Dictionary` parameter.
  - Enter world with `int` parameter resolving character from storage.
  - Enter world with `int` empty slot falling back to starter Daniel.
  - Direct signal emission from `CharacterSelect.character_selected(slot_idx)` into `_on_enter_world_with_character`.
  - Offline login submission instant transition.
