# Combat Settings & Auto-Battle Window (`FightWindow`) Specification

## 1. Executive Summary
This document specifies the architecture, visual styling, interactive controls, and backend integrations for the **Combat Settings & Auto-Battle Window** (`FightWindow`, 153x115) in the Wonderland Online Godot 4 client.

The Fight Window provides full user control over automated combat, PK security, battle animation pacing, and survival threshold routing:
1. **Auto-Battle Toggle:** Controls automatic tactical selection of elemental skills or basic attacks during player combat turns.
2. **PK Safety Lock:** Blocks accidental friendly fire or player-versus-player attack consent.
3. **Battle Animation Speed:** Configures combat tween and impact pacing across `1.0x (Normal)`, `1.5x (Fast)`, and `2.0x (Hyper)`.
4. **Auto-Flee HP Threshold:** Evaluates actor health during auto-battle turns to automatically register escape attempts (`ActionType.ESCAPE`) when health falls below safety margins (`0%..30%`).
5. **Persistence:** Saves and synchronizes combat configuration to `user://system_settings.json` under the `"combat"` dictionary key without overwriting audio or display configuration.

---

## 2. Visual & Architectural Design

### 2.1 Window Dimensions & Hierarchy
- **Width:** `153.0 px` (`WINDOW_WIDTH`)
- **Height:** `115.0 px` (`WINDOW_HEIGHT`)
- **Root Node:** `FightWindow` (`Control`, `scenes/ui/hud.tscn` under `FloatingWindows/FightWindow`).
- **Backing Panel:** `BackingPanel` (`Panel`, 153x115) with `Color(0.08, 0.10, 0.16, 0.95)` and beveled gold border `Color(0.65, 0.52, 0.32, 1.0)`.
- **Background Skin:** `Background` (`TextureRect`, 153x115) with `res://assets/hud/form_fight_1.png` decoded from authentic `menu/Skins/default/BattleStatus_1.bmp` with chroma-key defringing.
- **Close Button:** `CloseButton` (`Button`, 18x18 at `Vector2(123.0, 8.0)`), textured with `btn_close_normal.png`, `btn_close_hover.png`, `btn_close_pressed.png`.
- **Title Label:** `TitleLabel` (`Label` at `Vector2(10.0, 5.0)`), text `"Combat Settings"`, 10px font with 2px black outline (`Color(0,0,0,1)`).

### 2.2 Sliced Assets & Slices
| Asset File | Source Bitmap | Dimensions | Purpose |
|---|---|---|---|
| `assets/hud/form_fight_1.png` | `BattleStatus_1.bmp` | 153x115 | Window frame background |
| `assets/hud/btn_player_battle_setting.png` | `Btn_PlayerBattleSetting.bmp` | 87x63 | 3-state battle settings button (87x21 each) |
| `assets/hud/btn_player_battle_restore.png` | `Btn_PlayerBattleRestore.bmp` | 56x60 | 3-state restore defaults button (56x20 each) |
| `assets/hud/btn_assign_fight.png` | `Btn_AssignFight_1.bmp` | 43x60 | 3-state combat assignment button (43x20 each) |
| `assets/hud/btn_top_pk.png` | `Btn_TopPK_1.bmp` | 66x63 | 3-state top PK button (66x21 each) |
| `assets/hud/btn_checkbox_checked.png` | `btn_Check_1.bmp` | 16x16 | Checked checkbox state |
| `assets/hud/btn_checkbox_unchecked.png` | `btn_UnCheck_1.bmp` | 16x16 | Unchecked checkbox state |

---

## 3. Interactive Controls Specification

### 3.1 Auto-Battle Toggle CheckBox (`AutoBattleCheck`)
- **Position & Size:** `Vector2(8, 26)`, `Vector2(137, 20)`.
- **Default:** `false`.
- **Behavior:**
  - When checked, characters and recruited companions in `BattleView` automatically queue actions on turn start.
  - Forwarded to `BattleManager.set_auto_battle(enabled)`.
  - Bidirectionally synchronized with `BattleView` action bar button 7 (Auto).

### 3.2 PK Safety Lock CheckBox (`PKSafetyCheck`)
- **Position & Size:** `Vector2(8, 46)`, `Vector2(137, 20)`.
- **Default:** `true`.
- **Behavior:**
  - When enabled, `BattleManager.register_player_action` intercepts and blocks any aggressive action (`ATTACK` or offensive `SKILL`) targeted at friendly allies (`target_is_enemy: false`).
  - Assist / heal skills remain permitted.
  - When disabled, explicit player-versus-player attack consent is granted.

### 3.3 Battle Animation Speed Selector (`SpeedOption`)
- **Label:** `SpeedLabel` at `Vector2(8, 68)`, text `"Speed:"`.
- **Dropdown:** `SpeedOption` (`OptionButton` at `Vector2(54, 67)`, size `Vector2(91, 20)`).
- **Options:**
  - `0`: `"1.0x Normal"` -> `1.0` multiplier.
  - `1`: `"1.5x Fast"` -> `1.5` multiplier.
  - `2`: `"2.0x Hyper"` -> `2.0` multiplier.
- **Behavior:**
  - Sets `battle_speed_multiplier` in `BattleManager` and `BattleView`.
  - Scales all combat tweens (`caster lunges`, `damage flinches`, `floating combat text`, `skill VFX`) via `tween.set_speed_scale(multiplier)`.

### 3.4 Auto-Flee HP Threshold Control (`AutoFleeSpinBox`)
- **Label:** `AutoFleeLabel` at `Vector2(8, 90)`, text `"Flee HP%:"`.
- **SpinBox:** `AutoFleeSpinBox` at `Vector2(74, 88)`, size `Vector2(71, 22)`.
- **Range:** `0.0 .. 30.0%`, step `5.0%`, suffix `"%"` (0% = disabled).
- **Behavior:**
  - During `BattleManager.auto_assign_player_actions()`, computes actor HP percentage:
    $$\text{HP}_{\%} = \frac{\text{Current HP}}{\max(\text{Max HP}, 1)} \times 100.0$$
  - If $\text{HP}_{\%} \le \text{threshold}$, automatically queues `ActionType.ESCAPE` instead of `ATTACK`/`SKILL`.

---

## 4. Technical API Reference (`FightWindow`)

### 4.1 Signals
- `combat_settings_changed(settings: Dictionary)`: Emitted upon configuration write.
- `auto_battle_toggled(enabled: bool)`: Emitted when auto-battle toggle state mutates.
- `pk_safety_toggled(enabled: bool)`: Emitted when PK safety state mutates.
- `battle_speed_changed(speed: float)`: Emitted when battle speed multiplier changes.
- `auto_flee_threshold_changed(threshold: int)`: Emitted when flee threshold changes.
- `window_closed()`: Emitted when the window closes.

### 4.2 Methods
| Method | Parameters | Return Type | Description |
|---|---|---|---|
| `setup` | `hud: Control = null` | `void` | Initializes UI, loads persistent settings, links `BattleManager`. |
| `set_auto_battle` | `enabled: bool, save: bool = true` | `void` | Mutates auto-battle state, updates checkbox, forwards to engine. |
| `is_auto_battle` | *None* | `bool` | Returns current auto-battle state. |
| `set_pk_safety_lock` | `enabled: bool, save: bool = true` | `void` | Mutates PK lock state, updates checkbox, forwards to engine. |
| `is_pk_safety_locked` | *None* | `bool` | Returns current PK safety lock state. |
| `set_battle_speed` | `speed: float, save: bool = true` | `void` | Mutates animation speed multiplier, updates dropdown selection. |
| `get_battle_speed` | *None* | `float` | Returns current battle speed multiplier. |
| `set_auto_flee_threshold` | `val: int, save: bool = true` | `void` | Sets auto-flee HP percentage threshold (0..30%). |
| `get_auto_flee_threshold` | *None* | `int` | Returns auto-flee HP percentage threshold. |
| `restore_defaults` | `save: bool = true` | `void` | Resets all combat settings to authentic factory defaults. |
| `get_combat_settings` | *None* | `Dictionary` | Returns dictionary of all 4 combat parameters. |
| `apply_combat_settings` | `settings: Dictionary, save: bool = false` | `void` | Applies dictionary of combat settings. |
| `save_settings` | *None* | `void` | Merges into `user://system_settings.json` under `"combat"`. |
| `load_settings` | *None* | `void` | Reads and applies `"combat"` settings from disk. |
| `set_battle_manager` | `bm: Node` | `void` | Binds BattleManager node and hooks bidirectional signals. |
| `set_battle_view` | `bv: Node` | `void` | Binds BattleView node for animation speed scaling. |
| `find_and_link_battle_manager` | *None* | `void` | Auto-discovers BattleManager and BattleView from scene tree. |
| `open_window` | *None* | `void` | Plays click SFX, refreshes settings, makes window visible. |
| `close_window` | *None* | `void` | Plays click SFX, hides window, emits `window_closed`. |
| `toggle_window` | *None* | `void` | Toggles window visibility between open and closed. |

---

## 5. Storage Persistence (`user://system_settings.json`)

Settings are stored under the `"combat"` key alongside global system settings:

```json
{
	"bgm_volume": 80,
	"bgm_muted": false,
	"sfx_volume": 80,
	"sfx_muted": false,
	"fullscreen": false,
	"combat": {
		"auto_battle": false,
		"pk_safety_lock": true,
		"battle_speed": 1.0,
		"auto_flee_threshold": 0
	}
}
```

- Safe non-destructive read/write guarantees that modifying combat parameters never alters audio levels or fullscreen states.

---

## 6. Verification & Automated Testing

The headless test suite `tests/test_fight_window_and_combat_settings.gd` verifies:
1. `_test_1_window_geometry_and_hierarchy`: Dimensions (153x115), close button position (123, 8), node presence.
2. `_test_2_interactive_controls_and_signals`: Getters, setters, and signals for all 4 controls.
3. `_test_3_json_persistence_and_merging`: JSON write and read verification with dictionary preservation.
4. `_test_4_battle_manager_forwarding_and_sync`: Bidirectional synchronization between `FightWindow` and `BattleManager`.
5. `_test_5_pk_safety_lock_behavior`: Aggressive action blocking when PK safety is enabled vs disabled.
6. `_test_6_auto_flee_threshold_behavior`: Automatic `ActionType.ESCAPE` assignment below HP threshold.
7. `_test_7_battle_view_speed_integration`: Battle speed multiplier propagation into `BattleView` and `BattleManager`.
8. `_test_8_window_open_close_toggling`: Visibility toggling, close button routing, and `window_closed` signal emission.
