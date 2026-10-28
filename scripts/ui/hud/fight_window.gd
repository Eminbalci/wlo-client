class_name FightWindow
extends Control

## Sub-controller and view for Wonderland Online Combat Settings Window (FightWindow).
## Provides authentic 2000s MMORPG visual styling and runtime controls for:
## - Auto-Battle Toggle (automatically selects basic attack or priority skill during combat)
## - PK Safety Lock Toggle (disables or enables player-versus-player attack consent)
## - Battle Animation Speed (1.0x Normal, 1.5x Fast, 2.0x Hyper)
## - Auto-Flee HP Threshold (0%..30% threshold to automatically trigger Flee)
## - Restore Defaults Action (resets combat settings to authentic defaults)
##
## Settings persist to user://system_settings.json under the "combat" dictionary key
## and forward seamlessly to BattleManager and BattleView.

signal combat_settings_changed(settings: Dictionary)
signal auto_battle_toggled(enabled: bool)
signal pk_safety_toggled(enabled: bool)
signal battle_speed_changed(speed: float)
signal auto_flee_threshold_changed(threshold: int)
signal window_closed

const SETTINGS_FILE_PATH: String = "user://system_settings.json"
const WINDOW_WIDTH: float = 153.0
const WINDOW_HEIGHT: float = 115.0

const DEFAULT_AUTO_BATTLE: bool = false
const DEFAULT_PK_SAFETY: bool = true
const DEFAULT_BATTLE_SPEED: float = 1.0
const DEFAULT_AUTO_FLEE_THRESHOLD: int = 0

const SPEED_OPTIONS: Array[Dictionary] = [
	{"label": "1.0x Normal", "speed": 1.0},
	{"label": "1.5x Fast", "speed": 1.5},
	{"label": "2.0x Hyper", "speed": 2.0}
]

var _auto_battle: bool = DEFAULT_AUTO_BATTLE
var _pk_safety_lock: bool = DEFAULT_PK_SAFETY
var _battle_speed: float = DEFAULT_BATTLE_SPEED
var _auto_flee_threshold: int = DEFAULT_AUTO_FLEE_THRESHOLD

var _is_building: bool = false
var _is_updating_ui: bool = false
var _hud: Control = null
var _battle_manager: Node = null
var _battle_view: Node = null

# Node references
var backing_panel: Panel = null
var background: TextureRect = null
var title_label: Label = null
var close_button: Button = null

var auto_battle_check: CheckBox = null
var pk_safety_check: CheckBox = null

var speed_label: Label = null
var speed_option: OptionButton = null

var auto_flee_label: Label = null
var auto_flee_spinbox: SpinBox = null

func _init() -> void:
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	_build_ui_if_needed()

func _ready() -> void:
	_build_ui_if_needed()
	load_settings()
	find_and_link_battle_manager()

func setup(hud: Control = null) -> void:
	_hud = hud
	_build_ui_if_needed()
	load_settings()
	find_and_link_battle_manager()

func _build_ui_if_needed() -> void:
	if _is_building:
		return
	_is_building = true

	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)

	# 1. Backing panel for crisp legibility and authentic border
	backing_panel = get_node_or_null("BackingPanel") as Panel
	if not backing_panel:
		backing_panel = Panel.new()
		backing_panel.name = "BackingPanel"
		add_child(backing_panel)
		move_child(backing_panel, 0)
	backing_panel.position = Vector2(0.0, 0.0)
	backing_panel.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	backing_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.95, 0.97, 1.0, 1.0)
	panel_sb.border_color = Color(0.48, 0.60, 0.82, 1.0)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(3)
	backing_panel.add_theme_stylebox_override("panel", panel_sb)

	# 2. Background TextureRect
	background = get_node_or_null("Background") as TextureRect
	if not background:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
		move_child(background, 1)
	background.position = Vector2(0.0, 0.0)
	background.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_PASS
	# form_fight_1.png is the HP/SP gauge art (BattleStatus_1), not a window skin, so the light
	# BackingPanel above is the window frame.
	background.texture = null

	# 3. Header Title Label
	title_label = get_node_or_null("TitleLabel") as Label
	if not title_label:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		add_child(title_label)
	title_label.position = Vector2(10.0, 5.0)
	title_label.size = Vector2(105.0, 18.0)
	title_label.text = "Combat Settings"
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", Color(0.30, 0.38, 0.62, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	title_label.add_theme_constant_override("outline_size", 0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 4. Authentic 18x18 Close Button at Vector2(123, 8)
	close_button = get_node_or_null("CloseButton") as Button
	if not close_button:
		close_button = Button.new()
		close_button.name = "CloseButton"
		add_child(close_button)
	close_button.position = Vector2(123.0, 8.0)
	close_button.size = Vector2(18.0, 18.0)
	close_button.custom_minimum_size = Vector2(18.0, 18.0)
	close_button.text = ""
	close_button.flat = true
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if ResourceLoader.exists("res://assets/hud/btn_close_normal.png"):
		var norm := StyleBoxTexture.new()
		norm.texture = load("res://assets/hud/btn_close_normal.png")
		close_button.add_theme_stylebox_override("normal", norm)
	if ResourceLoader.exists("res://assets/hud/btn_close_hover.png"):
		var hov := StyleBoxTexture.new()
		hov.texture = load("res://assets/hud/btn_close_hover.png")
		close_button.add_theme_stylebox_override("hover", hov)
	if ResourceLoader.exists("res://assets/hud/btn_close_pressed.png"):
		var prs := StyleBoxTexture.new()
		prs.texture = load("res://assets/hud/btn_close_pressed.png")
		close_button.add_theme_stylebox_override("pressed", prs)

	for conn in close_button.pressed.get_connections():
		close_button.pressed.disconnect(conn.callable)
	close_button.pressed.connect(close_window)

	# 5. Auto-Battle Toggle CheckBox
	auto_battle_check = get_node_or_null("AutoBattleCheck") as CheckBox
	if not auto_battle_check:
		auto_battle_check = CheckBox.new()
		auto_battle_check.name = "AutoBattleCheck"
		add_child(auto_battle_check)
	auto_battle_check.position = Vector2(8.0, 26.0)
	auto_battle_check.size = Vector2(137.0, 20.0)
	auto_battle_check.text = "Auto-Battle"
	auto_battle_check.tooltip_text = "Automatically execute actions for characters & companions during combat turns."
	auto_battle_check.button_pressed = _auto_battle
	auto_battle_check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	auto_battle_check.add_theme_font_size_override("font_size", 10)
	auto_battle_check.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
	auto_battle_check.add_theme_color_override("font_pressed_color", Color(0.20, 0.26, 0.44, 1.0))
	auto_battle_check.add_theme_color_override("font_hover_color", Color(0.20, 0.26, 0.44, 1.0))
	auto_battle_check.add_theme_color_override("font_hover_pressed_color", Color(0.20, 0.26, 0.44, 1.0))
	auto_battle_check.add_theme_color_override("font_focus_color", Color(0.20, 0.26, 0.44, 1.0))
	auto_battle_check.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	auto_battle_check.add_theme_constant_override("outline_size", 0)
	_apply_checkbox_icons(auto_battle_check)

	for conn in auto_battle_check.toggled.get_connections():
		auto_battle_check.toggled.disconnect(conn.callable)
	auto_battle_check.toggled.connect(func(pressed: bool) -> void:
		if not _is_updating_ui:
			set_auto_battle(pressed, true)
	)

	# 6. PK Safety Lock Toggle CheckBox
	pk_safety_check = get_node_or_null("PKSafetyCheck") as CheckBox
	if not pk_safety_check:
		pk_safety_check = CheckBox.new()
		pk_safety_check.name = "PKSafetyCheck"
		add_child(pk_safety_check)
	pk_safety_check.position = Vector2(8.0, 46.0)
	pk_safety_check.size = Vector2(137.0, 20.0)
	pk_safety_check.text = "PK Safety Lock"
	pk_safety_check.tooltip_text = "Prevents accidental or unauthorized player-versus-player attack consent."
	pk_safety_check.button_pressed = _pk_safety_lock
	pk_safety_check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pk_safety_check.add_theme_font_size_override("font_size", 10)
	pk_safety_check.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
	pk_safety_check.add_theme_color_override("font_pressed_color", Color(0.20, 0.26, 0.44, 1.0))
	pk_safety_check.add_theme_color_override("font_hover_color", Color(0.20, 0.26, 0.44, 1.0))
	pk_safety_check.add_theme_color_override("font_hover_pressed_color", Color(0.20, 0.26, 0.44, 1.0))
	pk_safety_check.add_theme_color_override("font_focus_color", Color(0.20, 0.26, 0.44, 1.0))
	pk_safety_check.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	pk_safety_check.add_theme_constant_override("outline_size", 0)
	_apply_checkbox_icons(pk_safety_check)

	for conn in pk_safety_check.toggled.get_connections():
		pk_safety_check.toggled.disconnect(conn.callable)
	pk_safety_check.toggled.connect(func(pressed: bool) -> void:
		if not _is_updating_ui:
			set_pk_safety_lock(pressed, true)
	)

	# 7. Battle Animation Speed (SpeedLabel & SpeedOption)
	speed_label = get_node_or_null("SpeedLabel") as Label
	if not speed_label:
		speed_label = Label.new()
		speed_label.name = "SpeedLabel"
		add_child(speed_label)
	speed_label.position = Vector2(8.0, 68.0)
	speed_label.size = Vector2(46.0, 18.0)
	speed_label.text = "Speed:"
	speed_label.add_theme_font_size_override("font_size", 10)
	speed_label.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
	speed_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	speed_label.add_theme_constant_override("outline_size", 0)
	speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	speed_option = get_node_or_null("SpeedOption") as OptionButton
	if not speed_option:
		speed_option = OptionButton.new()
		speed_option.name = "SpeedOption"
		add_child(speed_option)
	speed_option.position = Vector2(54.0, 67.0)
	speed_option.size = Vector2(91.0, 20.0)
	speed_option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	speed_option.add_theme_font_size_override("font_size", 9)

	var opt_sb := StyleBoxFlat.new()
	opt_sb.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	opt_sb.border_color = Color(0.48, 0.60, 0.82, 1.0)
	opt_sb.set_border_width_all(1)
	opt_sb.set_corner_radius_all(2)
	speed_option.add_theme_stylebox_override("normal", opt_sb)
	speed_option.add_theme_stylebox_override("hover", opt_sb)
	speed_option.add_theme_stylebox_override("pressed", opt_sb)
	speed_option.add_theme_stylebox_override("focus", opt_sb)
	speed_option.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))

	speed_option.clear()
	for i in range(SPEED_OPTIONS.size()):
		var opt: Dictionary = SPEED_OPTIONS[i]
		speed_option.add_item(String(opt.get("label", "")), i)

	_update_speed_option_selection()

	for conn in speed_option.item_selected.get_connections():
		speed_option.item_selected.disconnect(conn.callable)
	speed_option.item_selected.connect(func(idx: int) -> void:
		if idx >= 0 and idx < SPEED_OPTIONS.size():
			var spd: float = float(SPEED_OPTIONS[idx].get("speed", 1.0))
			set_battle_speed(spd, true)
	)

	# 8. Auto-Flee HP Threshold (AutoFleeLabel & AutoFleeSpinBox)
	auto_flee_label = get_node_or_null("AutoFleeLabel") as Label
	if not auto_flee_label:
		auto_flee_label = Label.new()
		auto_flee_label.name = "AutoFleeLabel"
		add_child(auto_flee_label)
	auto_flee_label.position = Vector2(8.0, 90.0)
	auto_flee_label.size = Vector2(66.0, 18.0)
	auto_flee_label.text = "Flee HP%:"
	auto_flee_label.add_theme_font_size_override("font_size", 10)
	auto_flee_label.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
	auto_flee_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	auto_flee_label.add_theme_constant_override("outline_size", 0)
	auto_flee_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	auto_flee_spinbox = get_node_or_null("AutoFleeSpinBox") as SpinBox
	if not auto_flee_spinbox:
		auto_flee_spinbox = SpinBox.new()
		auto_flee_spinbox.name = "AutoFleeSpinBox"
		add_child(auto_flee_spinbox)
	auto_flee_spinbox.position = Vector2(74.0, 88.0)
	auto_flee_spinbox.size = Vector2(71.0, 22.0)
	auto_flee_spinbox.min_value = 0.0
	auto_flee_spinbox.max_value = 30.0
	auto_flee_spinbox.step = 5.0
	auto_flee_spinbox.suffix = "%"
	auto_flee_spinbox.tooltip_text = "Automatically flee during auto-battle when HP falls below this percentage (0% = never flee)."
	auto_flee_spinbox.value = float(_auto_flee_threshold)
	auto_flee_spinbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var flee_edit := auto_flee_spinbox.get_line_edit()
	if flee_edit:
		flee_edit.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
		flee_edit.add_theme_color_override("font_uneditable_color", Color(0.20, 0.26, 0.44, 1.0))
		var flee_box := StyleBoxFlat.new()
		flee_box.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		flee_box.border_color = Color(0.48, 0.60, 0.82, 1.0)
		flee_box.set_border_width_all(1)
		flee_box.set_corner_radius_all(2)
		for state in ["normal", "focus", "read_only"]:
			flee_edit.add_theme_stylebox_override(state, flee_box)
		flee_edit.add_theme_font_size_override("font_size", 10)

	for conn in auto_flee_spinbox.value_changed.get_connections():
		auto_flee_spinbox.value_changed.disconnect(conn.callable)
	auto_flee_spinbox.value_changed.connect(func(val: float) -> void:
		set_auto_flee_threshold(int(val), true)
	)

	_is_building = false

func _apply_checkbox_icons(cb: CheckBox) -> void:
	if not cb:
		return
	if ResourceLoader.exists("res://assets/hud/btn_checkbox_checked.png"):
		cb.add_theme_icon_override("checked", load("res://assets/hud/btn_checkbox_checked.png"))
	if ResourceLoader.exists("res://assets/hud/btn_checkbox_unchecked.png"):
		cb.add_theme_icon_override("unchecked", load("res://assets/hud/btn_checkbox_unchecked.png"))

func _update_speed_option_selection() -> void:
	if not speed_option:
		return
	var matched_idx: int = 0
	for i in range(SPEED_OPTIONS.size()):
		if is_equal_approx(float(SPEED_OPTIONS[i].get("speed", 1.0)), _battle_speed):
			matched_idx = i
			break
	if speed_option.selected != matched_idx:
		speed_option.selected = matched_idx

# ==================== CONTROL APIS ====================

func set_auto_battle(enabled: bool, save: bool = true) -> void:
	if _auto_battle == enabled and auto_battle_check and auto_battle_check.button_pressed == enabled:
		return
	_auto_battle = enabled
	if auto_battle_check and auto_battle_check.button_pressed != _auto_battle:
		_is_updating_ui = true
		auto_battle_check.button_pressed = _auto_battle
		_is_updating_ui = false
	
	if _battle_manager and _battle_manager.has_method("set_auto_battle"):
		if bool(_battle_manager.get("is_auto_battle")) != _auto_battle:
			_battle_manager.call("set_auto_battle", _auto_battle)

	auto_battle_toggled.emit(_auto_battle)
	if save:
		save_settings()

func is_auto_battle() -> bool:
	return _auto_battle

func set_pk_safety_lock(enabled: bool, save: bool = true) -> void:
	if _pk_safety_lock == enabled and pk_safety_check and pk_safety_check.button_pressed == enabled:
		return
	_pk_safety_lock = enabled
	if pk_safety_check and pk_safety_check.button_pressed != _pk_safety_lock:
		_is_updating_ui = true
		pk_safety_check.button_pressed = _pk_safety_lock
		_is_updating_ui = false
	
	if _battle_manager and _battle_manager.has_method("set_pk_safety_lock"):
		_battle_manager.call("set_pk_safety_lock", _pk_safety_lock)

	pk_safety_toggled.emit(_pk_safety_lock)
	if save:
		save_settings()

func is_pk_safety_locked() -> bool:
	return _pk_safety_lock

func set_battle_speed(speed: float, save: bool = true) -> void:
	_battle_speed = maxf(speed, 0.1)
	_update_speed_option_selection()

	if _battle_manager and _battle_manager.has_method("set_battle_speed"):
		_battle_manager.call("set_battle_speed", _battle_speed)
	if _battle_view and _battle_view.has_method("set_battle_speed"):
		_battle_view.call("set_battle_speed", _battle_speed)

	battle_speed_changed.emit(_battle_speed)
	if save:
		save_settings()

func get_battle_speed() -> float:
	return _battle_speed

func set_auto_flee_threshold(val: int, save: bool = true) -> void:
	_auto_flee_threshold = clampi(val, 0, 30)
	if auto_flee_spinbox and int(auto_flee_spinbox.value) != _auto_flee_threshold:
		auto_flee_spinbox.value = float(_auto_flee_threshold)

	if _battle_manager and _battle_manager.has_method("set_auto_flee_hp_threshold"):
		_battle_manager.call("set_auto_flee_hp_threshold", _auto_flee_threshold)

	auto_flee_threshold_changed.emit(_auto_flee_threshold)
	if save:
		save_settings()

func get_auto_flee_threshold() -> int:
	return _auto_flee_threshold

func restore_defaults(save: bool = true) -> void:
	set_auto_battle(DEFAULT_AUTO_BATTLE, false)
	set_pk_safety_lock(DEFAULT_PK_SAFETY, false)
	set_battle_speed(DEFAULT_BATTLE_SPEED, false)
	set_auto_flee_threshold(DEFAULT_AUTO_FLEE_THRESHOLD, false)
	if save:
		save_settings()

func get_combat_settings() -> Dictionary:
	return {
		"auto_battle": _auto_battle,
		"pk_safety_lock": _pk_safety_lock,
		"battle_speed": _battle_speed,
		"auto_flee_threshold": _auto_flee_threshold
	}

func apply_combat_settings(settings: Dictionary, save: bool = false) -> void:
	if settings.has("auto_battle"):
		set_auto_battle(bool(settings["auto_battle"]), false)
	if settings.has("pk_safety_lock"):
		set_pk_safety_lock(bool(settings["pk_safety_lock"]), false)
	if settings.has("battle_speed"):
		set_battle_speed(float(settings["battle_speed"]), false)
	if settings.has("auto_flee_threshold"):
		set_auto_flee_threshold(int(settings["auto_flee_threshold"]), false)
	
	if save:
		save_settings()

# ==================== SETTINGS PERSISTENCE ====================

func save_settings() -> void:
	var existing_data := {}
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		var r_file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
		if r_file:
			var txt := r_file.get_as_text()
			r_file.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary:
				existing_data = parsed

	existing_data["combat"] = get_combat_settings()

	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(existing_data, "\t"))
		file.close()
	combat_settings_changed.emit(existing_data["combat"])

func load_settings() -> void:
	var data := {}
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
		if file:
			var txt := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary and parsed.has("combat") and parsed["combat"] is Dictionary:
				data = parsed["combat"]

	_auto_battle = bool(data.get("auto_battle", DEFAULT_AUTO_BATTLE))
	_pk_safety_lock = bool(data.get("pk_safety_lock", DEFAULT_PK_SAFETY))
	_battle_speed = float(data.get("battle_speed", DEFAULT_BATTLE_SPEED))
	_auto_flee_threshold = int(data.get("auto_flee_threshold", DEFAULT_AUTO_FLEE_THRESHOLD))

	# Apply to UI controls and connected engines without re-saving
	set_auto_battle(_auto_battle, false)
	set_pk_safety_lock(_pk_safety_lock, false)
	set_battle_speed(_battle_speed, false)
	set_auto_flee_threshold(_auto_flee_threshold, false)

# ==================== BATTLE MANAGER / VIEW BINDINGS ====================

func set_battle_manager(bm: Node) -> void:
	if _battle_manager == bm:
		return
	_battle_manager = bm
	if _battle_manager:
		# Synchronize settings to battle manager
		if _battle_manager.has_method("apply_combat_settings"):
			_battle_manager.call("apply_combat_settings", get_combat_settings())
		else:
			if _battle_manager.has_method("set_auto_battle"):
				_battle_manager.call("set_auto_battle", _auto_battle)
			if _battle_manager.has_method("set_pk_safety_lock"):
				_battle_manager.call("set_pk_safety_lock", _pk_safety_lock)
			if _battle_manager.has_method("set_battle_speed"):
				_battle_manager.call("set_battle_speed", _battle_speed)
			if _battle_manager.has_method("set_auto_flee_hp_threshold"):
				_battle_manager.call("set_auto_flee_hp_threshold", _auto_flee_threshold)
		
		# Connect to auto_battle_changed if emitted externally (e.g. from BattleView UI)
		if _battle_manager.has_signal("auto_battle_changed"):
			var on_bm_auto := func(enabled: bool) -> void:
				if _auto_battle != enabled:
					set_auto_battle(enabled, true)
			if not _battle_manager.is_connected("auto_battle_changed", on_bm_auto):
				_battle_manager.connect("auto_battle_changed", on_bm_auto)

func set_battle_view(bv: Node) -> void:
	_battle_view = bv
	if _battle_view and _battle_view.has_method("set_battle_speed"):
		_battle_view.call("set_battle_speed", _battle_speed)

func find_and_link_battle_manager() -> void:
	if _battle_manager:
		return
	if is_inside_tree() and get_tree() and get_tree().root:
		var bm := get_tree().root.find_child("BattleManager", true, false)
		if bm:
			set_battle_manager(bm)
		var bv := get_tree().root.find_child("BattleView", true, false)
		if bv:
			set_battle_view(bv)

# ==================== WINDOW CONTROL ACTIONS ====================

func open_window() -> void:
	_play_click_sfx()
	load_settings()
	find_and_link_battle_manager()
	visible = true

func close_window() -> void:
	_play_click_sfx()
	visible = false
	window_closed.emit()

func toggle_window() -> void:
	if visible:
		close_window()
	else:
		open_window()

func _play_click_sfx() -> void:
	if ResourceLoader.exists("res://scripts/ui/auth/auth_audio.gd"):
		var auth_audio = load("res://scripts/ui/auth/auth_audio.gd")
		if auth_audio and auth_audio.has_method("play_click"):
			auth_audio.play_click()
