# Technical Specification: Combat Engine, Responsive Battle View & Combat UI

## 1. Architectural Overview
This specification details the modernized, responsive Turn-Based Battle View and Combat UI architecture for the Wonderland Online client in Godot 4.

The subsystem comprises:
- **`CombatEngine` (`res://scripts/battle/combat_engine.gd`)**: Logic coordinator extending `BattleManager`, implementing dynamic initiative timelines, 4-element cycle advantage badges, evasion rates, status effect tracking, and candidate target filtering.
- **`CombatMenu` (`res://scripts/battle/combat_menu.gd` & `res://scenes/battle/combat_menu.tscn`)**: Responsive command menu supporting `DOCKED_BOTTOM_RIGHT` and `CONTEXTUAL_ANCHOR` modes, authentic audio feedback (`wav0151.wav`), keyboard shortcuts (`A`, `D`, `S`, `I`, `C`, `E`, `U`), and rich tooltip hover cards.
- **`TurnTimelineDock` (`res://scripts/battle/turn_timeline_dock.gd`)**: Horizontal initiative dock rendering active rounds, combatant stat mini-cards in SPD-descending order, active actor glowing border highlights, and tooltips.
- **`FloatingCombatText` (`res://scripts/battle/floating_combat_text.gd`)**: High-performance floating combat text (FCT) system handling normal damage, critical hits, health restoration, misses, and elemental relationship badges with scale-punch and cubic elevation fade-out.
- **`BattleView` (`res://scripts/battle/battle_view.gd` & `res://scenes/battle/battle_view.tscn`)**: Responsive visual arena integrating the 2:1 axonometric field centering, target reticle cursor tracking, overhead HUD progress bars, and modal progression dialogs.

---

## 2. Component Specifications

### 2.1 CombatEngine (`scripts/battle/combat_engine.gd`)
Inherits from: `BattleManager`

#### Methods:
1. `get_initiative_timeline(active_slot: int = -1, active_is_enemy: bool = false) -> Array[Dictionary]`
   - **Parameters:**
     - `active_slot: int`: Slot index of the currently acting entity.
     - `active_is_enemy: bool`: Side of the active entity.
   - **Returns:** Sorted array of participant dictionaries in descending SPD order. Player entities take precedence on equal speed. Lower slot index acts as deterministic second tie-breaker.
   - **Participant Dictionary Keys:** `id`, `name`, `level`, `slot`, `is_enemy`, `spd`, `hp`, `max_hp`, `sp`, `max_sp`, `element`, `element_name`, `element_color`, `is_boss`, `is_defending`, `role_id`, `is_active`.

2. `get_element_relation(user_elem: int, target_elem: int) -> Dictionary`
   - **Parameters:** `user_elem: int`, `target_elem: int` (0: None, 1: Earth, 2: Water, 3: Fire, 4: Wind).
   - **Returns:** `{ "multiplier": float, "relation": int, "badge_text": String }`.
   - **Multipliers:**
     - Advantage: `1.25x` (Earth > Water > Fire > Wind > Earth).
     - Disadvantage: `0.75x` (Earth < Wind < Fire < Water < Earth).
     - Neutral / None: `1.0x`.

3. `calculate_evasion_rate(attacker_spd: int, target_spd: int) -> float`
   - **Formula:** `clampf((target_spd - attacker_spd) * 0.015, 0.0, 0.25)`
   - **Returns:** Probability of evasion between 0% and 25%.

4. `calculate_detailed_attack(attacker: Dictionary, target: Dictionary, action: Dictionary) -> Dictionary`
   - **Returns:** Breakdown dictionary `{ "damage": int, "is_miss": bool, "is_critical": bool, "is_guarded": bool, "element_multiplier": float, "element_relation": int, "badge_text": String }`.
   - **Guarded:** Incoming damage multiplied by `0.5x`.
   - **Critical:** Base damage multiplied by `1.5x` (10% base chance or disabled in deterministic mode).
   - **Minimum Damage:** Enforced at `1`.

5. `get_valid_targets(is_enemy_caster: bool, action_type: int, skill_data: Dictionary = {}) -> Array[Dictionary]`
   - Filters candidate targets based on offensive vs assistive mechanics:
     - Attack (`0`) & Catch (`4`): Living opposing entities.
     - Item (`3`): Living friendly entities.
     - Skill (`2`): Living opposing entities for offensive skills, living allies for assist/healing skills (`base_damage < 0`).

6. `apply_status_effect(is_enemy: bool, slot: int, status_name: String, duration_turns: int, potency: int = 0) -> bool`
   - Records status effect on target.
7. `process_round_end_statuses() -> Array[Dictionary]`
   - Applies damage ticks (e.g., Poison), decrements remaining turn duration, and frees expired status effects.

---

### 2.2 CombatMenu (`scripts/battle/combat_menu.gd`)
Inherits from: `Control`

#### Dual-Mode Responsive Layout:
- **`DOCKED_BOTTOM_RIGHT` (Default)**:
  - Anchors: `PRESET_BOTTOM_RIGHT` (`anchor_left = 1.0, anchor_top = 1.0, anchor_right = 1.0, anchor_bottom = 1.0`).
  - Offsets: `(-240, -100, -20, -16)`.
  - Guarantees 100% compatibility with resizability suite.
- **`CONTEXTUAL_ANCHOR`**:
  - Positions menu offset from the current acting player's isometric slot screen coordinate (`+24, -70`).
  - Viewport boundary clamping (`VIEWPORT_PADDING = 16.0`) prevents any clipping off-screen on arbitrary resolutions.

#### Authentic SFX & Shortcuts:
- Button sound: Plays `res://assets/sound/wav0151.wav` on mouse hover and button trigger.
- Hotkey triggers:
  - `Btn_Battle_1`: Attack (`A`, `1`)
  - `Btn_Battle_2`: Defend (`D`, `2`)
  - `Btn_Battle_3`: Skill (`S`, `3`)
  - `Btn_Battle_4`: Item (`I`, `4`)
  - `Btn_Battle_5`: Catch (`C`, `5`)
  - `Btn_Battle_6`: Escape (`E`, `6`)
  - `Btn_Battle_7`: Auto (`U`, `7`, `Space`)
- Tooltip hover card: Floating parchment card with title, shortcut tag `[Key]`, and detailed mechanic description.

---

### 2.3 TurnTimelineDock (`scripts/battle/turn_timeline_dock.gd`)
Inherits from: `PanelContainer`

#### Visual Structure:
- Anchors: `PRESET_CENTER_TOP` (`anchor_left = 0.5, anchor_right = 0.5, offset_left = -280, offset_right = 280, offset_top = 44, offset_bottom = 90`).
- Left Pill: Displays `TURN [N] \n INIT`.
- Horizontal scroll of combatant cards:
  - Ally tint: Dark navy blue background, cyan border.
  - Enemy tint: Dark crimson background, red border.
  - Active actor: Radiant gold pulsing border (`Color(1.0, 0.85, 0.25, 1.0)`), `#Rank` badge, element color rectangle, and `ACT` label.
  - Hover tooltip displaying full HP/SP bars, element name, and SPD value.

---

### 2.4 FloatingCombatText (`scripts/battle/floating_combat_text.gd`)
Inherits from: `Control`

#### Visual States:
- `PopupType.DAMAGE`: Crimson/Orange (`#FF5238`), 16pt, upward cubic drift $-36\text{ px}$.
- `PopupType.CRITICAL`: Radiant Gold (`#FFE02E`), 20pt, initial scale punch $1.35\times \to 1.0\times$, upward cubic drift $-42\text{ px}$.
- `PopupType.HEAL`: Emerald Green (`#38F266`), 16pt, upward cubic drift $-36\text{ px}$.
- `PopupType.MISS`: Cyan Silver (`#A6D9FF`), 16pt.
- `BadgeLabel`: Optional badge pill attached to numbers (e.g. `+25% [FIRE > WIND]`).
- Fade-out: Cubic ease-in opacity fade over $0.85\text{s}$ before auto `queue_free()`.

---

## 3. Verification & Test Commands

### 3.1 Headless Suite Execution Commands
```powershell
# Run Combat Engine & Responsive UI Test Suite (10/10 PASS):
C:\Godot\godot_console.exe --headless -s scripts/tests/test_battle_engine.gd

# Run Battle View & Sub-Controller Test Suite (11/11 PASS):
C:\Godot\godot_console.exe --headless -s tests/test_battle_view.gd

# Run Battle View Scene Runner:
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_battle_view.tscn

# Run Dynamic Resizability Suite across 8 resolutions:
C:\Godot\godot_console.exe --headless -s tests/test_game_resizable.gd
```
