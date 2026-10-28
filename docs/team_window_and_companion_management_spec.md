# Team / Party Window & Companion Management Specification

## Executive Summary
This document specifies the reverse engineering, visual reconstruction, and functional architecture of the **Team / Party Window** (`Form_Team_2`, 371x539) and the **Companion / Pet Management Subsystem** in the Wonderland Online Godot 4 client (`wonderland-online-client`).

The subsystem incorporates authentic 2000s MMORPG bitmap skin assets sliced and defringed from the original game archives (`D:/GitHub/wlridecode/menu/Skins/white/` and `default/`), 4 party member slots with leader promotion and dismissal, active companion / pet management with Summon/Rest state transitions, and real-time overworld companion follower kinematics and overland map NPC suppression.

---

## 1. Window Geometry & Skin Asset Architecture

### 1.1 Geometry & Alignment
In the original 32-bit Borland Delphi client (`aLogin.exe`), the team window interface is rendered using `Form_Team_2.bmp` with pre-composed card slot backgrounds, tab headers, and action button sockets.

- **Window Dimensions:** Exactly `Vector2(371.0, 539.0)` (`WINDOW_WIDTH = 371.0`, `WINDOW_HEIGHT = 539.0`).
- **Scene File:** `scenes/ui/hud/team_window.tscn` and embedded under `FloatingWindows/TeamWindow` in `scenes/ui/hud.tscn`.
- **Script File:** `scripts/ui/hud/team_window.gd` (`TeamWindow` class inheriting `Control`).
- **Background Texture:** `res://assets/hud/form_team_2.png` (371x539 PNG).

### 1.2 Authentic 18x18 Close Button
- **Position:** `Vector2(341.0, 8.0)` (exact 12px right margin: `371 - (341 + 18) = 12px`, 8px top padding).
- **Size:** `Vector2(18.0, 18.0)`.
- **Textures:**
  - Normal: `res://assets/hud/btn_close_normal.png`
  - Hover: `res://assets/hud/btn_close_hover.png`
  - Pressed: `res://assets/hud/btn_close_pressed.png`
- **Text:** Strictly empty string `""` (no synthetic "X").
- **Cursor:** `Control.CURSOR_POINTING_HAND`.
- **Audio:** Invokes `AuthAudio.play_click()` on button down.

### 1.3 Asset Slicing & Chroma Defringing
All bitmap sources were extracted and processed with strict green chroma-key elimination (`RGB(0, 255, 0)`), background alpha masking, and 1-pixel morphological defringing to eliminate edge halos:
- `assets/hud/form_team_2.png`: Main dialog frame (371x539).
- `assets/hud/btn_leave_team_*.png`: 3-state textures for "Leave Team" (71x20) from `Btn_LeaveTeam_1.bmp`.
- `assets/hud/btn_dismiss_team_*.png`: 3-state textures for "Dismiss Member" (71x20) from `Btn_DismissTeam_1.bmp`.
- `assets/hud/btn_assign_leader_*.png`: 3-state textures for "Promote Leader" (71x20) from `Btn_AssignLeader_1.bmp`.
- `assets/hud/btn_assign_fight_*.png`: 3-state textures for "Fight" / Summon (43x20) from `Btn_AssignFight_1.bmp`.
- `assets/hud/btn_assign_rest_*.png`: 3-state textures for "Rest" / Recall (43x20) from `Btn_AssignRest_1.bmp`.
- `assets/hud/btn_team_tab_*.png`: 3-state textures for "Team" tab header (66x21) from `Btn_Team_1.bmp`.
- `assets/hud/org_leader_badge.png`: Authentic team leader badge (59x20) from `OrgLeader.bmp`.

---

## 2. 4 Party Member Slots Architecture

### 2.1 Layout Coordinates
The upper section of `Form_Team_2` provides 4 horizontal party member rows:
- **Card Bounds:** X = 26.0, Width = 314.0, Height = 33.0.
- **Y-Offsets:**
  - Slot 0 (Leader): `Y = 68.0`
  - Slot 1: `Y = 103.0`
  - Slot 2: `Y = 137.0`
  - Slot 3: `Y = 171.0`

### 2.2 Card Components
Each member row contains:
1. **Selection Highlight (`highlight`):** Semi-transparent golden accent (`Color(1.0, 0.85, 0.2, 0.22)`) bordered with `Color(1.0, 0.85, 0.2, 0.8)` indicating active slot focus.
2. **Avatar Bust (`bust`):** 30x30 texture aperture at `(3, 2)` displaying the character's bust portrait from `assets/character_select/head/` or `assets/avatars/`.
3. **Element Badge (`elem`):** 14x14 icon at `(36, 9)` displaying Earth, Water, Fire, or Wind elemental affinities from `assets/hud/status_dock/`.
4. **Name Label (`name`):** Positioned at `(54, 3)`, 11px font with 2px black outline (`Color(0, 0, 0, 1)`).
5. **Leader Badge (`leader`):** Positioned at `(150, 4)`, displaying `assets/hud/org_leader_badge.png` when `is_leader = true`.
6. **Level Label (`lvl`):** Positioned at `(54, 18)`, displaying `"Lv. %d"`.
7. **HP Bar & Readout (`hp_bar`, `hp_text`):** Miniature red progress bar (`Color(0.85, 0.15, 0.15, 1.0)`) at `(180, 5)` with text `"HP: %d/%d"`.
8. **SP Bar & Readout (`sp_bar`, `sp_text`):** Miniature blue progress bar (`Color(0.15, 0.45, 0.95, 1.0)`) at `(180, 18)` with text `"SP: %d/%d"`.
9. **Empty Placeholder (`empty`):** Displayed when a slot is vacant with text `"(Empty Slot)"` in subdued gray (`Color(0.6, 0.6, 0.6, 1.0)`).

### 2.3 Party Member Data Structure
```gdscript
var member_data: Dictionary = {
    "name": "Daniel",
    "role_id": 1,
    "level": 10,
    "element": "Fire",
    "hp": 245,
    "max_hp": 245,
    "sp": 180,
    "max_sp": 180,
    "is_leader": true
}
```

---

## 3. Party Actions & State Machine

### 3.1 Selection & Action Buttons
Located along the bottom edge of the window at `Y = 504.0`:
- **Leave Team (`btn_leave_team`):** Position `(26, 504)`, size `(71, 20)`. Always enabled.
- **Dismiss Member (`btn_dismiss_team`):** Position `(150, 504)`, size `(71, 20)`. Disabled by default; enabled only when an occupied non-leader slot (1..3) is selected.
- **Promote Leader (`btn_assign_leader`):** Position `(274, 504)`, size `(71, 20)`. Disabled by default; enabled only when an occupied non-leader slot (1..3) is selected.

### 3.2 State Transitions & Logic
1. **Selecting a Slot (`select_member_slot(slot_idx: int)`):**
   - Updates `selected_member_index`.
   - Displays highlight box on selected slot.
   - Enables `btn_dismiss_team` and `btn_assign_leader` if `slot_idx > 0` and slot is occupied.
   - Emits `member_selected(slot_idx, member_data)`.
2. **Promoting a Leader (`promote_leader(slot_idx: int)`):**
   - Swaps target slot data with Slot 0.
   - Assigns `is_leader = true` to new Slot 0 and `is_leader = false` to demoted member.
   - Re-renders member cards and updates button disabled states.
   - Emits `leader_promoted(slot_idx, new_leader_data)`.
3. **Dismissing a Member (`dismiss_selected_member()`):**
   - Removes selected member from `party_members` array.
   - Compacts slots 1..3 and sets remaining slots to empty state.
   - Disables `btn_dismiss_team` and `btn_assign_leader`.
   - Emits `member_dismissed(removed_index, removed_data)`.
4. **Leaving Team (`leave_team()`):**
   - Clears all remote party members, retaining only the local player in Slot 0.
   - Resets selection and disables dismiss/promote buttons.
   - Emits `team_left()`.

---

## 4. Companion & Pet Management Subsystem

### 4.1 Card Layout Coordinates
The lower section of `Form_Team_2` provides 3 vertical companion card rows:
- **Card Bounds:** X = 26.0, Width = 314.0, Height = 70.0.
- **Y-Offsets:**
  - Slot 0 (Active Companion): `Y = 262.0`
  - Slot 1 (Reserve Companion): `Y = 337.0`
  - Slot 2 (Reserve Companion): `Y = 412.0`

### 4.2 Companion Card Components
- **Portrait Aperture:** 70x70 pixel portrait frame on the left edge (`X = 0..70`).
- **Element Badge:** 16x16 icon at `(78, 8)` representing companion's affinity.
- **Name Label:** 12px font with 2px black outline at `(98, 8)`.
- **Level Label:** Positioned at `(98, 26)` displaying `"Lv. %d"`.
- **Status Badge:** Positioned at `(160, 26)` displaying `"Summoned"` in green (`Color(0.2, 0.85, 0.2)`) or `"Resting"` in orange (`Color(0.85, 0.65, 0.2)`).
- **HP / SP Bars:** Progress bars at `(78, 44)` and `(78, 56)` with detailed `"HP: %d/%d"` and `"SP: %d/%d"` numerical labels.
- **Summon / Rest Toggle Button:** Authentic bitmap button positioned at `(260, 24)`:
  - Displays `btn_assign_fight_*` when companion is currently resting (click to summon).
  - Displays `btn_assign_rest_*` when companion is currently summoned (click to recall/rest).

### 4.3 Default Companion Data
```gdscript
var default_companions: Array[Dictionary] = [
    {
        "id": 8090,
        "name": "Roca",
        "level": 12,
        "element": "Earth",
        "hp": 340,
        "max_hp": 340,
        "sp": 190,
        "max_sp": 190,
        "is_summoned": false,
        "model_jmp": "1221.jmp"
    },
    {
        "id": 14062,
        "name": "Kelang",
        "level": 15,
        "element": "Fire",
        "hp": 480,
        "max_hp": 480,
        "sp": 150,
        "max_sp": 150,
        "is_summoned": false,
        "model_jmp": "1203.jmp"
    },
    {
        "id": 14063,
        "name": "S. Monkey",
        "level": 8,
        "element": "Water",
        "hp": 210,
        "max_hp": 210,
        "sp": 120,
        "max_sp": 120,
        "is_summoned": false,
        "model_jmp": "1204.jmp"
    }
]
```

### 4.4 Summon & Rest State Transitions
- **`toggle_companion_summon(companion_id: int = -1) -> bool`:**
  - If toggling active companion, flips `is_summoned` state.
  - If selecting a reserve companion, marks previously active companion as resting, designates target companion as active, and sets `is_summoned = true`.
  - Updates toggle button textures between `btn_assign_fight_*` and `btn_assign_rest_*`.
  - Updates status badge text between `"Summoned"` and `"Resting"`.
  - Emits:
    - `companion_toggled(companion_id, is_summoned)`
    - `companion_summoned(companion_id, companion_name)` (when summoned)
    - `companion_recalled(companion_id)` (when recalled)

---

## 5. MapView & Overland Follower Integration

### 5.1 Dynamic Follower Spawning & Trailing
When a companion is summoned (`is_summoned = true`), `MapView` dynamically instantiates an overland follower entity:
- **Spawner Method:** `MapView.spawn_companion_follower(companion_data: Dictionary) -> Node2D`.
- **Entity Instance:** Instance of `res://scripts/world/npc.gd` tagged with `name = "CompanionFollower"`, `npc_id = companion_data.id`, and `npc_name = companion_data.name`.
- **Initial Placement:** Placed exactly 48.0 pixels behind the player's current orientation vector:
  $$\vec{P}_{\text{follower}} = \vec{P}_{\text{player}} - \text{normalize}(\vec{V}_{\text{heading}}) \times 48.0$$
- **Tracking Hook:** In `_on_player_position_updated()`:
  - Invokes `update_companion_follower_position(player.world_position)`.
  - If distance between player and follower exceeds 48.0 pixels, smoothly glides the follower along the trailing vector.
  - Updates follower heading to face the player via `IsometricMath.get_heading(follower.world_position, player.world_position)`.
- **Despawning Method:** `MapView.despawn_companion_follower()`. Removes entity from scene tree, frees node, and clears `_companion_follower` reference.

### 5.2 Overland NPC Suppression
When a companion is recruited and registered in `MapView._party_companions`:
- `NpcStateEvaluator.should_npc_be_visible()` evaluates the NPC against `party_companions`.
- If the NPC represents a recruited companion already in the party, it is suppressed from overland map spawning to prevent duplicate entities from co-existing on the map.

### 5.3 Map Teleportation & Scene Transitions
- In `MapView._switch_map_entities(target_scene_id: int)`:
  - If an active companion was summoned (`_companion_follower != null`), MapView preserves `_active_companion_data`.
  - After loading the new map scene and placing the player at the spawn warp coordinates, `spawn_companion_follower(_active_companion_data)` is automatically re-invoked.

---

## 6. Public API Reference

### 6.1 `TeamWindow` (`scripts/ui/hud/team_window.gd`)
- `setup() -> void`: Initializes window geometry, textures, member cards, companion cards, and signal bindings.
- `set_player_data(data: Dictionary) -> void`: Updates Slot 0 (player/leader) stats (name, level, HP, SP, element).
- `add_party_member(member: Dictionary) -> bool`: Adds a remote member into the first vacant slot (1..3). Returns `false` if party is full.
- `select_member_slot(idx: int) -> void`: Sets active member selection and updates action button states.
- `promote_leader(slot_idx: int) -> bool`: Promotes member at `slot_idx` to Slot 0 leader.
- `dismiss_selected_member() -> bool`: Dismisses currently selected member (slots 1..3).
- `leave_team() -> void`: Disbands remote party members, retaining only local player.
- `set_companions(companions: Array[Dictionary]) -> void`: Populates companion slots with custom dataset.
- `toggle_companion_summon(target_id: int = -1) -> bool`: Toggles summon/rest state for active or specified companion.
- `is_companion_summoned() -> bool`: Returns `true` if active companion is currently summoned.
- `get_active_companion() -> Dictionary`: Returns active companion dictionary.

### 6.2 Signals
- `member_selected(slot_index: int, member_data: Dictionary)`
- `member_dismissed(slot_index: int, member_data: Dictionary)`
- `leader_promoted(slot_index: int, new_leader_data: Dictionary)`
- `team_left()`
- `companion_toggled(companion_id: int, is_summoned: bool)`
- `companion_summoned(companion_id: int, companion_name: String)`
- `companion_recalled(companion_id: int)`
- `window_closed()`

---

## 7. Verification & Automated Test Suite

### 7.1 Test Suite File
- `tests/test_team_window_and_companions.gd`

### 7.2 Execution Command
```bash
C:\Godot\godot_console.exe --headless -s tests/test_team_window_and_companions.gd
```

### 7.3 Results
- **Total Assertions:** 92
- **Passed:** 92
- **Failed:** 0
- **Exit Code:** 0
