# HUD Bottom Dock Buttons and Hotkeys Verification Specification

This document details the specifications, verification procedures, and signal handling for all 10 in-game bottom dock buttons and associated hotkeys in `HUD` (`[scripts/ui/hud.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd)`).

## Overview of Dock Buttons & Hotkeys

| # | Button Name | Hotkey | Target Window / Action | Signal / Verification |
|---|---|---|---|---|
| 1 | Item / Bag | `I` / `F1` | Inventory Window (CharacterWindow) | `toggle_character_status()` / `_use_or_equip_inventory_item()` |
| 2 | Status / Character | `S` / `F2` | Character / Stats Window (`char_window`) | `toggle_character_status()` |
| 3 | Skill | `K` / `F3` | Skills Window (`skill_window`) | `toggle_skill_window()` |
| 4 | Equip / Paperdoll | `E` / `F4` | Equipment / Paperdoll (`char_window`) | `toggle_character_status()` |
| 5 | Team / Party | `P` / `F5` | Party / Team Window (`team_window`) | `toggle_team_window()` |
| 6 | Guild | `G` / `F6` | Guild / Friends Window (`friends_window`) | `toggle_friends_window()` |
| 7 | Friend / Mail | `M` / `F7` | Messenger / Mailbox / Minimap (`minimap_dock`) | `_on_mailbox_pressed()` / `toggle_minimap()` |
| 8 | System / Options | `ESC` / `F8` | System Options / Settings (`system_window`) | `toggle_system_window()` |
| 9 | Help | - | Help / Guide overlay | `show_banner()` / chat system message |
| 10 | Logout / Exit | - | Confirmation prompt | `toggle_system_window()` / exit flow |

## Verification Procedures

1. **Click Handling**: All bottom action dock buttons (`BtnStatus`, `BtnSkill`, `BtnQuest`, `BtnTeam`, `BtnFriends`, `BtnSystem`) load authentic 3-state textures (`_normal.png`, `_hover.png`, `_pressed.png`) and correctly emit click signals.
2. **Window Visibility**: Toggling windows correctly sets `visible = true/false` and raises windows to front via `move_to_front()`.
3. **Audio Feedback**: Authentic UI click sounds are dispatched through `play_sfx()`.
