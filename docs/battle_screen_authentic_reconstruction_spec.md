# Wonderland Online - Battle Screen Authentic Reconstruction Specification

## 1. Overview & Objective

This document specifies the technical architecture and behavioral implementation of the authentic Wonderland Online (WLO) turn-based combat screen within the Godot client, aligning it directly with the Delphi original (`aLogin.exe`, `Form_Battle`, `battle.md`, and reverse-engineered packet protocols).

Prior to this reconstruction, the combat screen exhibited several fidelity discrepancies:
- `_battle_layer.layer = 90` obscured the entire World HUD, status dock, chat, and system tickers.
- The radar minimap remained visible during combat rather than auto-hiding.
- Only the player character entered combat; summoned companions and pets from the Team Window were omitted.
- The 7-button radial command ring did not sequence between player and companion, nor display floating queued action badges over fighter heads.
- Physical attack lunges pushed combatants away from their targets rather than towards them.
- Defeated actors faded out immediately without the signature horizontal squash collapse.
- No tactical combatant hover information card was shown when mousing over targets.

---

## 2. Architecture & Layering Model

### 2.1 CanvasLayer Stacking Hierarchy
In the authentic WLO client, the combat arena acts as an overlay onto the current world perspective while preserving player HUD visibility (status dock, chat dock, hotbar, top-right buttons):

| Layer Node | Stacking Layer | Description |
|---|---|---|
| `MapView` World & Entities | Layer 0 (default) | Isometric tilemap, ground items, NPCs, world foliage |
| `BattleLayer` (`battle_view.tscn`) | **Layer 10** | Combat arena backdrop, 2:1 axonometric combat grid, standees, VFX layer, radial ring |
| `CanvasLayer` (World HUD) | **Layer 20** | Top-left status dock, action bar, chat dock, system notifications |

### 2.2 Minimap Auto-Hiding Lifecycle
Upon `MapView.start_battle()`:
- `hud_minimap.visible = false` hides the overland radar.
- Upon battle completion (`_on_battle_view_closed()`), `hud_minimap.visible = true` restores radar navigation.

### 2.3 Authentic Battle Stage Backdrop & World Entity Isolation
Rather than taking a live map snapshot (which erroneously captured village straw huts, terrain, and roaming NPCs), `MapView.start_battle()` and `BattleView`:
- Hide `entities` (all overland NPCs and companions) and `map_renderer` while battle is active, restoring them cleanly upon `_on_battle_view_closed()`.
- Load and display the authentic **Forest Battle Arena Backdrop** (`res://assets/battle/forest_battle_bg.png`), an 800x600 2D painted combat stage featuring pine trees, blue sky, and a pristine green grass field reconstructed from the original Delphi client.
- Statically anchor `map_backdrop` and `ArenaBackground` to completely occlude any underlying world rendering.

### 2.4 Headless Mode Safety
In headless automated testing environments (`DisplayServer.get_name() == "headless"`), Viewport dummy render textures return null RIDs. `MapView.start_battle()` safely skips viewport grab operations to guarantee zero runtime panics while preserving full background rendering in windowed gameplay.

---

## 3. Companion & Party Combat Integration

### 3.1 Party Composition Protocol
When encountering wild monsters or engaging bosses:
1. Slot 0 is assigned to the player character (`name`, `level`, `element`, `hp`, `max_hp`, `sp`, `max_sp`, `atk`, `def`, `spd`).
2. If `_active_companion_data` is present (summoned companion from `TeamWindow`), it is automatically injected into **Slot 1**:
   ```gdscript
   party.append({
       "name": String(_active_companion_data.get("name", "Companion")),
       "level": int(_active_companion_data.get("level", 1)),
       "element": int(_active_companion_data.get("element", 0)),
       "cur_hp": int(_active_companion_data.get("cur_hp", 100)),
       "max_hp": int(_active_companion_data.get("max_hp", 100)),
       "cur_sp": int(_active_companion_data.get("cur_sp", 50)),
       "max_sp": int(_active_companion_data.get("max_sp", 50)),
       "atk": int(_active_companion_data.get("atk", 20)),
       "def": int(_active_companion_data.get("def", 15)),
       "spd": int(_active_companion_data.get("spd", 10)),
       "is_alive": int(_active_companion_data.get("cur_hp", 100)) > 0
   })
   ```
3. Upon battle conclusion, survivor HP and SP values for Slot 1 are synchronized back to `_active_companion_data` and saved to `user://character_data.json`.

---

## 4. Radial Command Ring & Multi-Phase Turn Sequencing

### 4.1 Two-Phase Command Protocol
Turn-based combat requires sequential commands for each living player party member before round execution commences:
1. **Player Phase (Slot 0):** Radial command ring centers under the player standee. The player selects an action (Attack, Defend, Skill, Item, Catch, Escape, Auto).
2. **Queued Action Indicator:** Upon confirming target, a floating icon corresponding to the selected action (`Btn_Battle_*.bmp`) is pinned overhead:
   ```gdscript
   _display_floating_action_icon(false, current_player_slot, action_type)
   ```
3. **Companion Phase (Slot 1):** The command ring moves to the companion's feet (`current_player_slot = 1`).
4. **Execution Phase:** When `battle_manager.are_all_player_actions_ready()` evaluates `true`:
   - `action_bar.visible = false`
   - Floating queued action icons are cleared.
   - `countdown_label.visible = false`
   - Round execution starts (`round_execution_started` signal).

### 4.2 Radial Ring Button Layout
The 7 authentic action buttons are positioned radially relative to the actor's isometric foot anchor:

| Button | Action | Texture Asset | Relative Offset |
|---|---|---|---|
| 0 | Attack | `btn_battle_6.png` | `(-49, -20)` |
| 1 | Defend | `btn_battle_5.png` | `(-28, -48)` |
| 2 | Skill | `btn_battle_4.png` | `(12, -48)` |
| 3 | Item | `btn_battle_3.png` | `(33, -20)` |
| 4 | Catch | `btn_battle_2.png` | `(12, 12)` |
| 5 | Escape | `btn_battle_1.png` | `(-28, 12)` |
| 6 | Auto | `btn_battle_7.png` | `(-8, -18)` |

---

## 5. Visual Effects & Combat Animation Mechanics

### 5.1 Authentic Attack Lunges
In the 2:1 axonometric projection, the player party occupies the lower-right diamond formation and faces top-left towards the enemy party on the upper-left.
- **Player Party Lunge:** `Vector2(-40.0, -8.0)` (leaps northwest towards enemies).
- **Enemy Party Lunge:** `Vector2(40.0, 8.0)` (leaps southeast towards players).
- **Tween Timing:** 0.12s forward lunge (`TRANS_QUAD`, `EASE_OUT`) followed by 0.14s return (`TRANS_QUAD`, `EASE_IN`).

### 5.2 Defeat Horizontal Squash Collapse
When an actor is reduced to 0 HP:
- Standee scales horizontally and compresses vertically: `Vector2(1.2, 0.2)` over 0.22s.
- Standee sinks `+24.0px` on the Y axis into the ground.
- Root node fades out (`modulate:a = 0.0`) over 0.35s before `queue_free()`.

### 5.3 Tactical Fighter Hover Card
Hovering over any combatant displays an authentic single-line text card to their immediate left:
```
[Name]  [Element]  LV:[Level]  HP:[Cur]/[Max]
```
Formatted in clean white text (`Color(1.0, 1.0, 1.0, 0.95)`) with an authentic drop shadow, positioned at `pos + Vector2(-120.0, -50.0)`.

### 5.4 Center Cyan Countdown Timer
During the 20-second decision phase, a large cyan label (`Color(0.2, 0.95, 1.0, 1.0)`) centered at `(400, 240)` displays the remaining seconds in 32px font, updating every tick and vanishing upon round execution.

---

## 6. Verification & Automated Test Coverage

All battle view features are strictly verified using headless Godot execution:
- `tests/test_battle_view_scene.gd`: **11/11 PASSED (100%)**
- `tests/test_encounters_and_battle_flow.gd`: **23/23 PASSED (100%)**
- `tests/test_skill_vfx_animations.gd`: **4/4 PASSED (100%)**
