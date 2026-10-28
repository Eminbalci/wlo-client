# Wonderland Online - Turn-Based Battle System & Runtime View Specification

## 1. Overview
The **Turn-Based Battle System & Runtime View** implements the complete authentic in-game combat loop for the Wonderland Online Godot 4 client. It faithfully recreates the classic 4x2 Player vs 4x2 Enemy 2:1 axonometric combat field, the 7 authentic battle action buttons (`Btn_Battle_1.bmp` through `Btn_Battle_7.bmp`), the 20-second turn countdown timer (`BattleStatus_1.bmp`), SPD-descending turn queues, the 4-element cycle (+25% / -25%), animated overhead HP/SP status bars, floating combat text, capture/escape mechanics, and victory/defeat progression with loot tables.

- **Engine Coordinator Script:** `res://scripts/battle/battle_manager.gd`
- **Visual Presentation Script:** `res://scripts/battle/battle_view.gd`
- **Combat View Scene:** `res://scenes/battle/battle_view.tscn`
- **Automated Test Suite Script:** `res://tests/test_battle_view.gd`
- **Test Runner Scene:** `res://scenes/tests/test_battle_view.tscn`
- **Resolution:** 800x600 (WLO native resolution)

---

## 2. Architecture & Scene Hierarchy

```
BattleView (Control, 800x600, mouse_filter=STOP)
├── ArenaBackground (ColorRect, 800x600, deep midnight slate)
├── ArenaCanvas (Control, custom 2:1 axonometric drawing)
├── ActorsLayer (Control, container for 16 formation slot standees & overhead HUDs)
├── VFXLayer (Control, impact rings, flashes, particles)
├── FloatingTextLayer (Control, floating damage/heal/status text)
├── LogPanel (PanelContainer, parchment combat announcements)
│   └── LogLabel (Label)
├── StatusPanel (PanelContainer, styled via BattleStatus_1.bmp, 153x115)
│   └── StatusVBox: ActorNameLabel, TurnLabel, TimerLabel (28pt bold gold)
├── ActionButtonsBar (HBoxContainer, 220x84, pos=(560, 500))
│   ├── Btn_Battle_1 (TextureButton, Attack: normal/hover/pressed .bmp)
│   ├── Btn_Battle_2 (TextureButton, Defend: normal/hover/pressed .bmp)
│   ├── Btn_Battle_3 (TextureButton, Skill: normal/hover/pressed .bmp)
│   ├── Btn_Battle_4 (TextureButton, Item: normal/hover/pressed .bmp)
│   ├── Btn_Battle_5 (TextureButton, Catch: normal/hover/pressed .bmp)
│   ├── Btn_Battle_6 (TextureButton, Escape: normal/hover/pressed .bmp)
│   └── Btn_Battle_7 (TextureButton, Auto: normal/hover/pressed .bmp)
├── SkillSelectDialog (PanelContainer, Form_BattleSkill_1 parchment popup)
│   └── VBoxContainer: Title, ScrollContainer (SkillList), CancelButton
├── ItemSelectDialog (PanelContainer, consumable item popup)
│   └── VBoxContainer: Title, ScrollContainer (ItemList), CancelButton
└── VictoryDialog (PanelContainer, post-combat modal)
    └── VBoxContainer: VictoryTitleLabel, ExpRewardLabel, GoldRewardLabel, ItemsRewardLabel, VictoryOkButton
```

---

## 3. 2:1 Axonometric Battle Grid Geometry

### 3.1 Diamond Geometry & Projection
The combat field utilizes an authentic 2:1 axonometric isometric projection matching the classic Wonderland Online battle field layout:
- **Diamond Half-Width ($hw$):** `24.0 px` (Full width = `48.0 px`)
- **Diamond Half-Height ($hh$):** `12.0 px` (Full height = `24.0 px`)
- **Aspect Ratio:** $48.0 / 24.0 = 2.0$ (Strict 2:1 ratio)
- **Diamond Vertices:**
  - Top: $(cx, cy - hh)$
  - Right: $(cx + hw, cy)$
  - Bottom: $(cx, cy + hh)$
  - Left: $(cx - hw, cy)$

### 3.2 8 Player Slots vs 8 Enemy Slots Coordinates (Centered in 800x600)
Both sides possess 8 formation slots partitioned into 4 Front-row slots (`0..3`) and 4 Back-row slots (`4..7`):
- **Player Party (Facing North-East):**
  - Front Row (`0..3`): Starts at $(210, 260)$, stepping along vector $(+44, +22)$ per column.
  - Back Row (`4..7`): Starts at $(166, 290)$ (offset behind Front row), stepping along vector $(+44, +22)$.
- **Enemy Troop (Facing South-West):**
  - Front Row (`0..3`): Starts at $(450, 220)$, stepping along vector $(+44, +22)$ per column.
  - Back Row (`4..7`): Starts at $(494, 190)$ (offset behind Front row), stepping along vector $(+44, +22)$.
- **Neutral Boundary Line:** A subtle visual line separating player and enemy zones from $(385, 150)$ to $(455, 370)$.

### 3.3 Mouse Point-in-Polygon Collision
The view supports interactive clicking and hovering on both player and enemy grid slots. Given screen coordinate $P = (px, py)$ and diamond center $(cx, cy)$:
$$\frac{|px - cx|}{hw} + \frac{|py - cy|}{hh} \le 1.08$$
Points satisfying the inequality are resolved to their corresponding `(is_enemy: bool, slot: int)` index.

---

## 4. 7 Authentic Battle Action Buttons

Configured in `ActionButtonsBar` at coordinates $(X=560, Y=500)$ with size $220\times 84\text{ px}$:

| Button | Action Enum | Skin Assets (`res://assets/menu/Skins/default/`) | Description |
|---|---|---|---|
| `Btn_Battle_1` | `ATTACK` (`0`) | `Btn_Battle_1.bmp`, `_1.bmp` (hover), `_2.bmp` (pressed) | Normal physical attack against target enemy |
| `Btn_Battle_2` | `DEFEND` (`1`) | `Btn_Battle_2.bmp`, `_1.bmp`, `_2.bmp` | Defensive guard (reduces incoming damage by 50%) |
| `Btn_Battle_3` | `SKILL` (`2`) | `Btn_Battle_3.bmp`, `_1.bmp`, `_2.bmp` | Opens Stunt/Magic skill list (`SkillSelectDialog`) |
| `Btn_Battle_4` | `ITEM` (`3`) | `Btn_Battle_4.bmp`, `_1.bmp`, `_2.bmp` | Opens consumable inventory item list (`ItemSelectDialog`) |
| `Btn_Battle_5` | `CATCH` (`4`) | `Btn_Battle_5.bmp`, `_1.bmp`, `_2.bmp` | Attempts to capture monster as a loyal pet |
| `Btn_Battle_6` | `ESCAPE` (`5`) | `Btn_Battle_6.bmp`, `_1.bmp`, `_2.bmp` | Attempts to flee from the battle based on Agility/SPD |
| `Btn_Battle_7` | `AUTO` (`6`) | `Btn_Battle_7.bmp`, `_1.bmp`, `_2.bmp` | Toggles automatic turn resolution |

---

## 5. Turn Order Queue & SPD Sorting

Combat turn execution snapshots all active participants across Player (`0..7`) and Enemy (`0..7`) grids:
1. **Primary Sort Key:** Actor `spd` value descending. Highest speed acts first.
2. **Deterministic Tie-Breaker 1:** When actor SPDs are equal, Player actors take precedence over Enemy actors (consistent with `Wlo.pserver.core` pipeline).
3. **Deterministic Tie-Breaker 2:** Lower slot index takes precedence.

---

## 6. Combat Damage Formulas & 4-Element Wheel

### 6.1 4-Element Cycle (+25% / -25%)
- Cycle: **Earth (1) $\to$ Water (2) $\to$ Fire (3) $\to$ Wind (4) $\to$ Earth (1)**
- Elemental Advantage: $+25\%$ bonus multiplier ($1.25\times$).
- Elemental Disadvantage: $-25\%$ penalty multiplier ($0.75\times$).
- Neutral / None (`0`): $1.0\times$.

### 6.2 Physical & Magical Damage
- **Physical Damage (Attack & Physical Skills):**
  $$\text{Raw} = \text{BaseDamage} + (\text{UserATK} \times \text{Mult}_1) - (\text{TargetDEF} \times 0.6) + (\text{UserATK} \times \text{Mult}_2)$$
- **Magical Damage (Magic Skills):**
  $$\text{Raw} = \text{BaseDamage} + (\text{UserMATK} \times \text{Mult}_1) - (\text{TargetMDEF} \times 0.6) + (\text{UserMATK} \times \text{Mult}_2)$$
- **Defensive Mitigation:**
  If the target is currently defending (`is_defending == true`), total incoming damage is halved ($\text{Damage} \times 0.5$).
- **Critical Strike:**
  $10\%$ base chance for a critical strike ($1.5\times$ damage multiplier).
- **Minimum Damage:**
  Damage is clamped to a minimum of $1$ point.

### 6.3 Healing / Assist Skills
- Base negative damage is converted to health restoration:
  $$\text{HealAmount} = |\text{BaseDamage}| + (\text{UserMATK} \times 0.6)$$

---

## 7. Capture & Escape Mechanics

### 7.1 Pet Capture Formula
- Boss actors are immune to capture (`target.is_boss == true`).
- Standard monsters use HP percentage and level variance:
  $$\text{CatchChance} = \text{clamp}(0.70 - (\text{HP}_{\%} \times 0.45) + ((\text{UserLevel} - \text{TargetLevel}) \times 0.03), 0.10, 0.95)$$

### 7.2 Escape Formula
- Probability is governed by the difference between player SPD and enemy average SPD:
  $$\text{EscapeChance} = \text{clamp}(0.60 + ((\text{PlayerSPD} - \text{EnemyAvgSPD}) \times 0.03), 0.20, 0.95)$$

---

## 8. Overhead Status HUD & Floating Combat Popups

### 8.1 Overhead Status HUD
Every occupied slot displays:
- Name and Level label (`"Nina Lv.10"`).
- Element color badge.
- Smooth `ProgressBar` for HP ($80\times 6\text{ px}$, green fill).
- Smooth `ProgressBar` for SP ($80\times 4\text{ px}$, cyan fill).

### 8.2 Floating Combat Popups
- Normal Damage: Bold red text (`"-45"`), floats $-32\text{ px}$ upward over $0.75\text{s}$ with cubic fade-out.
- Critical Damage: Bright yellow/gold text (`"CRIT! -142"`).
- Healing: Emerald green text (`"+80"`).
- Hit Impact FX: Struck standee flashes white/red and executes a 3-frame micro-shake.

---

## 9. Victory / Defeat Screen & Loot Tables

When all enemies are defeated, `VictoryDialog` is displayed:
- Total EXP earned: $\sum (\text{EnemyLevel} \times 20 + (100 \text{ if Boss else } 0))$
- Total Gold earned: $\sum (\text{EnemyLevel} \times 12 + (60 \text{ if Boss else } 0))$
- Dropped Items: Rolled against the encounter loot drop table with quantity ranges.
- Clicking "OK" emits `victory_confirmed` and `view_closed` to seamlessly return control to `MapView` or caller scene.

---

## 10. Automated Test Suite & Headless Verification

Headless execution commands:
```powershell
# Battle View Suite:
C:\Godot\godot_console.exe --headless -s tests/test_battle_view.gd
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_battle_view.tscn

# Combat Engine & Responsive UI Suite:
C:\Godot\godot_console.exe --headless -s scripts/tests/test_battle_engine.gd
```

### Verification Results:
- `_test_instantiation_and_layout`: 800x600 resolution and sub-controllers validated.
- `_test_axonometric_grid_geometry`: 2:1 aspect ratio ($48\times 24$ px), 4-vertex diamond geometry, and point containment validated.
- `_test_7_battle_buttons_and_textures`: 7 TextureButtons bound to authentic BMP skins validated.
- `_test_battle_initialization_and_presets`: "Kelan Slimes Troop", slot normalizations, and overhead HUD widgets validated.
- `_test_turn_timer_countdown`: 20-second timer countdown, visual label, and expiration turn advance validated.
- `_test_element_wheel_and_damage_formulas`: +25% advantage, -25% penalty, and 50% defense mitigation validated.
- `_test_turn_order_spd_sorting`: Descending SPD sort and player-first deterministic tie-breaking validated.
- `_test_action_execution_and_popups`: Attack execution, HP depletion, and floating popup labels validated.
- `_test_catch_and_escape_mechanics`: Pet capture formula, boss immunity, and flee mechanics validated.
- `_test_victory_rewards_and_loot_drops`: Victory state, reward sums, loot rolling, and dialog interaction validated.
- `_test_defeat_and_cleanup`: Defeat modal, party wipe state, and cleanup validated.
- **Pass Rate:** 100% (11/11 tests passing without errors).
