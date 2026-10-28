# System Window Options, Chat Colors, & Gameplay Flags Specification

## Overview
Wonderland Online features extensive system preferences in `SystemWindow` (`Form_System_2`), including audio sliders, 5 chat channel color pickers (Local, Whisper, Party, Guild, World), and gameplay toggle flags (PVP/PK, Join Battle, Trading, Zoom Mode, Party Invites).

This specification details the end-to-end synchronization between `SystemWindow`, `ChatDock`, `HUDChat`, `FightWindow`, `BattleManager`, and `TopActionBar`.

---

## 1. Dynamic Chat Channel Color Propagation

### Channel Key Mapping
`SystemWindow` emits `settings_changed(settings)` containing:
```gdscript
"chat_colors": {
    "local": Color(...),
    "whisper": Color(...),
    "party": Color(...),
    "guild": Color(...),
    "world": Color(...)
}
```
Both chat implementations (`HUDChat` and `ChatDock`) receive this dictionary via `apply_chat_colors(colors: Dictionary)`:
- Maps `"party"` and `"team"` to the team channel color.
- Converts `Color` objects or string hex codes to clean `#rrggbb` strings.
- Formats message output lines: `_format_line()` wraps the message in the channel's dynamic color tag: `[color=#rrggbb](World)Name:msg[/color]`.
- Dynamically restyles the `BtnChannel` button in `ChatDock` with the active channel's color.

---

## 2. Gameplay Option Synchronization

The `SystemWindow` options dictionary contains:
- `pvp_pk`: PK safety mode. When `false`, PK is forbidden (accidental clicks on other players do not initiate combat). When `true`, PVP is enabled.
- `trading`: Trade requests permission. When `false`, trade invitations are blocked.
- `party_invites`: Team invitations permission. When `false`, incoming party requests are blocked.
- `join_battle`: Join ongoing battle permission.

### PVP / PK Safety Lock Inversion
In `hud.gd` (`_on_system_settings_changed`):
- When `opts["pvp_pk"] == true`, PK is enabled, and `fight_window.set_pk_safety_lock(false)` unlocks PK safety.
- When `opts["pvp_pk"] == false`, PK is disabled, and `fight_window.set_pk_safety_lock(true)` enables PK safety protection.
- Synchronizes with `BattleManager.set_pk_safety_lock(...)`.

### Gameplay Permission Queries on HUD:
- `is_trading_allowed() -> bool`
- `is_party_invites_allowed() -> bool`
- `is_join_battle_allowed() -> bool`
- `is_pvp_allowed() -> bool`

### TopActionBar Action Guard:
When the user clicks the top action bar's "Trade" button:
- Checks `hud.is_trading_allowed()`.
- If disabled, outputs: `"Trading is currently disabled in System Settings."`
- If enabled, prompts: `"Select a target player to initiate trade."`

---

## 3. Verification & Test Coverage

Automated test suite `tests/test_system_window_options_and_chat_colors.gd`:
- `test_chat_dock_dynamic_colors()`: Verifies default World chat `#ffea33`, applies custom color objects (red/cyan), applies string hexes (#123456), and validates `_format_line` output.
- `test_hud_system_settings_sync()`: Verifies default permissions (trading, party, join battle enabled, PVP disabled), and simulates option changes.
- `test_pvp_and_combat_safety_sync()`: Verifies PK safety lock inversion (PVP enabled -> safety unlocked; PVP disabled -> safety locked).
- `test_gameplay_permission_flags()`: Verifies TopBar trade action under both permitted and blocked states.

**Execution Result:** 19/19 passed, 0 failures (100%).
