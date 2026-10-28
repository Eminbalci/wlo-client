# Quest & Team Window Skin Alignment Specification

## Overview
This specification details visual alignment and layout fixes applied to the Quest (`form_taskview_1`) and Team (`form_team_2`) floating HUD windows in accordance with real client skins and reference captures.

## 1. Quest Window Layout & Text Overrun Parity
- **Source File:** `scripts/ui/hud/hud_window_manager.gd`
- **Skin Reference:** `assets/hud/form_taskview_1.png` (geometry 435x348)
- **Problem Statement:**
  Previously, quest titles in the left-hand listing were prepended with space indentation (`"      " + title`) on a fixed-width `Button`. When text was longer than ~18 characters, Godot truncated the text abruptly or clipped it into the scroll margin. Furthermore, the selection area slightly misaligned with the baked panel grooves.
- **Adjustments Applied:**
  - `QUEST_ROW_ORIGIN` adjusted from `Vector2(17, 53)` to `Vector2(14, 53)`.
  - `QUEST_ROW_SIZE` expanded from `Vector2(193, 22)` to `Vector2(202, 22)`.
  - `QUEST_DETAIL_POS` centered at `Vector2(220, 54)` with `QUEST_DETAIL_SIZE` of `Vector2(196, 238)`.
  - Added dedicated `TitleLabel` child on each row button at `Vector2(22, 0)` with `size = Vector2(178, 22)`, `TextServer.OVERRUN_TRIM_ELLIPSIS`, and size 10 font.
  - Set `row.tooltip_text` to the full quest title, allowing users to hover over clipped titles to see the complete text.
  - Button text set to empty (`row.text = ""`) so the internal label and completion checkmark control rendering cleanly without synthetic whitespace offsets.

## 2. Team Window Layout & Bar Overlap Resolution
- **Source File:** `scripts/ui/hud/team_window.gd`
- **Skin Reference:** `assets/hud/form_team_2.png` (geometry 371x539)
- **Problem Statement:**
  Party member cards previously positioned HP and SP bars at `Vector2(150.0, 8.0)` and `Vector2(150.0, 18.0)` with width 60px (spanning X=150..210). In the right portion of the card (starting at X=178), companion/party control buttons ("Battle", "Ride", "Dismiss") are situated. This caused graphical overlap where HP/SP bars were drawn under or through the buttons.
- **Adjustments Applied:**
  - `NameLabel` and `LevelLabel` width set to `68.0` px (X=52..120).
  - `LeaderBadge` placed at `Vector2(96.0, 17.0)` with size `24x14`.
  - `HpBar` and `SpBar` repositioned to `Vector2(122.0, 8.0)` and `Vector2(122.0, 18.0)` with width `50.0` px (spanning X=122..172).
  - Provides a clean 6px margin before any button controls at X=178, completely eliminating visual overlap.

## 3. Verification & Test Suite
- `tests/test_team_window_and_companions.gd`: 117 tests passed (100% pass rate).
- `tests/test_companion_ride_mode.gd`: 48 tests passed (100% pass rate).
- `tests/test_quest_dialogue_connection.gd`: 100% pass rate across 5 test scenarios.
