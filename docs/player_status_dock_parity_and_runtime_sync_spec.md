# Player Status Dock Parity, Level, HP/SP & Dynamic Runtime Synchronization Specification

## Overview
This specification details the architecture, node hierarchy, authentic texture defaults, and dynamic runtime synchronization for the Wonderland Online HUD **PlayerStatusDock** (`241x116`). It resolves the visual discrepancy where default character name, level, HP/SP readouts, and avatar bust did not match the authentic player character (defaulting to starter role Daniel, Role 6), and establishes full two-way runtime synchronization between `PlayerEntity`, `MapView`, and `HUD`.

---

## 1. Problem Diagnosis & Root Causes

### 1.1 Hardcoded Static Scene Defaults
In `scenes/ui/hud.tscn`, static node properties were pre-populated with mismatched values:
- `NameLabel.text` was hardcoded to `"Betty"`.
- `HpLabel.text` was hardcoded to `"HP   320/320"` with `HpBar.max_value = 320.0` and `value = 320.0`.
- `SpLabel.text` was hardcoded to `"SP   150/150"` with `SpBar.max_value = 150.0` and `value = 150.0`.
- `AvatarRect.texture` had no default assigned, rendering an empty dark gray square backplate (`AvatarBg`) until script execution.
- `ElementIcon.texture` had no default texture assigned.

### 1.2 Lack of Dynamic Property Setters on PlayerEntity
In `scripts/world/player.gd`:
- `character_name` was an `@export` string without a property setter, leaving the overhead `nameplate` label un-synchronized when modified at runtime.
- Stat variables (`level`, `hp`, `max_hp`, `sp`, `max_sp`, `exp_percent`, `role_id`) lacked reactive change signals or setters, causing stat updates during gameplay to not propagate automatically to the HUD.

### 1.3 Sub-Controller Binding & Type Hardening
In `scripts/ui/hud/hud_player_status.gd`:
- `set_player_stats` had a strict `p_exp: int` signature, discarding floating-point `exp_percent` values passed from `PlayerEntity` or character configs.
- Sub-controller node references lacked an automatic fallback retrieval mechanism if called prior to explicit `setup` execution.
- Missing node bindings for `ElementIcon`, `HpChannelUnder`, and `SpChannelUnder` in `hud.gd` sub-controller dictionary.

---

## 2. Technical Implementation & Architecture

### 2.1 Scene Hierarchy & Default Parity (`scenes/ui/hud.tscn`)
The default properties for `PlayerStatusDock` now reflect starter character **Daniel** (Role 6, Fire Element):
- `ext_resource` added for `res://assets/hud/avatar_role_6_0.png` (`uid="uid://4hff8w7tnac5"`).
- `ext_resource` added for `res://assets/hud/icon_element_3.png` (`uid="uid://dhoq4og41yatp"`).
- `AvatarRect.texture`: Configured with `ExtResource("4_avatar_role_6_0")`.
- `ElementIcon.texture`: Configured with `ExtResource("5_icon_element_3")`.
- `NameLabel.text`: `"Daniel"`.
- `LevelLabel.text`: `"LV 10"`.
- `HpLabel.text`: `"HP   245/245"`.
- `SpLabel.text`: `"SP   180/180"`.
- `HpBar.max_value = 245.0`, `HpBar.value = 245.0`.
- `SpBar.max_value = 180.0`, `SpBar.value = 180.0`.

### 2.2 Reactive PlayerEntity Signaling (`scripts/world/player.gd`)
Added reactive signal and property setters:
```gdscript
signal stats_changed(stat_dict: Dictionary)

@export var character_name: String = "Daniel":
	set(val):
		character_name = val
		if _nameplate or has_node("Nameplate"):
			nameplate.text = val
		_emit_stats_changed()

@export var role_id: int = 6:
	set(val):
		role_id = val
		_emit_stats_changed()

@export var level: int = 10:
	set(val):
		level = val
		_emit_stats_changed()

@export var hp: int = 245:
	set(val):
		hp = val
		_emit_stats_changed()

@export var max_hp: int = 245:
	set(val):
		max_hp = val
		_emit_stats_changed()

@export var sp: int = 180:
	set(val):
		sp = val
		_emit_stats_changed()

@export var max_sp: int = 180:
	set(val):
		max_sp = val
		_emit_stats_changed()

@export var exp_percent: float = 45.0:
	set(val):
		exp_percent = val
		_emit_stats_changed()

func _emit_stats_changed() -> void:
	stats_changed.emit({
		"name": character_name,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"sp": sp,
		"max_sp": max_sp,
		"exp_percent": exp_percent,
		"role_id": role_id
	})
```

### 2.3 Resilient Sub-Controller & Binding Fallbacks (`scripts/ui/hud/hud_player_status.gd`)
- Implemented `_ensure_node_bindings()` to guarantee valid node references across all status dock elements (`status_dock`, `status_bg`, `avatar_bg`, `avatar_rect`, `name_label`, `level_label`, `hp_label`, `hp_bar`, `sp_label`, `sp_bar`, `exp_label`, `exp_bar`, `element_icon`, `hp_channel_under`, `sp_channel_under`, `gold_label`).
- Expanded `set_player_stats` parameter signature to `p_exp: Variant` with automatic handling for float percentages and integer ratios:
```gdscript
func set_player_stats(p_name: String, p_lvl: int, p_hp: int, p_max_hp: int, p_sp: int, p_max_sp: int, p_exp: Variant, p_max_exp: int = 100) -> void:
	_ensure_node_bindings()
	if name_label: name_label.text = p_name
	if level_label: level_label.text = "LV %d" % p_lvl
	if hp_label: hp_label.text = "HP   %d/%d" % [p_hp, p_max_hp]
	if hp_bar:
		hp_bar.max_value = p_max_hp
		hp_bar.value = p_hp
	if sp_label: sp_label.text = "SP   %d/%d" % [p_sp, p_max_sp]
	if sp_bar:
		sp_bar.max_value = p_max_sp
		sp_bar.value = p_sp
	
	var exp_pct: float = 0.0
	if p_exp is float:
		exp_pct = float(p_exp)
	elif p_max_exp > 0:
		exp_pct = (float(p_exp) / float(p_max_exp)) * 100.0
	
	if exp_label: exp_label.text = "%d%%" % int(exp_pct)
	if exp_bar:
		exp_bar.max_value = 100.0
		exp_bar.value = exp_pct
```

### 2.4 HUD Coordinator & MapView Two-Way Synchronization (`scripts/ui/hud.gd` & `scripts/map/map_view.gd`)
- In `hud.gd`, declared `@onready var element_icon`, `@onready var hp_channel_under`, and `@onready var sp_channel_under` and forwarded them in `_init_sub_controllers()`.
- Updated `hud.player` setter to automatically connect `player.stats_changed` and execute immediate synchronization via `_sync_player_stats_from_player()`.
- In `map_view.gd`, connected `player.stats_changed` to `_on_player_stats_changed` to ensure dynamic HUD stat updates whenever gameplay mechanics mutate player stats.

---

## 3. Function Signatures & Data Contracts

### 3.1 `HUDPlayerStatus.set_player_stats`
- **Parameters**:
  - `p_name: String`: Character name displayed in `NameLabel`.
  - `p_lvl: int`: Character level displayed in `LevelLabel` as `"LV %d"`.
  - `p_hp: int`: Current health points.
  - `p_max_hp: int`: Maximum health points.
  - `p_sp: int`: Current spirit points.
  - `p_max_sp: int`: Maximum spirit points.
  - `p_exp: Variant`: EXP points (`int`) or percentage progress (`float`).
  - `p_max_exp: int = 100`: Maximum EXP threshold for integer calculation.
- **Return Type**: `void`
- **Side Effects**: Mutates label texts and progress bar min/max/current values.

### 3.2 `HUDPlayerStatus.set_player_role`
- **Parameters**:
  - `role_id: int`: Role ID (1..14).
- **Return Type**: `void`
- **Behavior**: Clears existing avatar frames, loads 2 blinking frames from `ArchiveLoader` or fallback PNGs, initializes idle texture on `AvatarRect`, and queries `GameDatabase` to assign authentic element icon badge.

---

## 4. Verification & Automated Test Coverage

The implementation is verified via comprehensive headless tests:
- `tests/test_player_status_parity.gd`: Validates HUD default node texts and textures, `PlayerEntity` setters and `nameplate` update, `stats_changed` signal emission, `hud.player` auto-synchronization, and dynamic runtime stat modification.
- `tests/test_animated_status_dock_avatar.gd`: Validates 14 role busts from `008.jma`, 3-layer chroma mask order, blinking state machine, role switching, and HP/SP progress bar proportional fill.
- `tests/test_animated_avatar.gd`: Validates asset directory visibility, 14 role blinking differentials, and idle/blinking loop transitions.
- `tests/test_hud_chat_and_status_features.gd`: Validates element badge dynamic mapping and chat dock controls.
- `tests/test_hud_hotbar_action_and_chat_fixes.gd`: Validates hotbar pagination, bottom action dock geometry, and chat parchment background.
