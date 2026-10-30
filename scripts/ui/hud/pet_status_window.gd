class_name PetStatusWindow
extends Control

## Form_PetStatus: the small Rest / Battle / Ride popup the real client opens next to a pet row of
## the team window (Form_Team_2). Decoded from aLogin.exe (see docs/re/pet_status_window.md):
## - constructor 0x327a20: skin Form_PetStatus (white skin set, 49x65) and three TSe_FixedButton
##   children: Btn_AssignRest_1 at (3,3), Btn_AssignFight_1 at (3,22), Btn_AssignRide_1 at (3,42),
##   each 43x20 (sheet height / 3). Hints "Rest", "Battle", "Ride". Button tag 1..3.
## - OnClick 0x327d9c: writes 0 / 1 / 2 into the team form's pet-mode byte array (+0xd20 + slot),
##   calls 0x291828 (slot 1..4) and hides the popup. Refusals: "Can't replace, pet in training",
##   "Can't mount".
## - placement 0x327f50: Left = team.Left + 247 - 3, Top = team.Top + 77 - Height + (slot - 1) * 34.

signal window_closed
## mode: MODE_REST / MODE_BATTLE / MODE_RIDE; slot is 1-based like the original (+0x131).
signal pet_mode_selected(slot: int, mode: int, pet: Dictionary)
signal action_refused(message: String)

const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")

const WINDOW_WIDTH: float = 49.0
const WINDOW_HEIGHT: float = 65.0
const MODE_REST: int = 0
const MODE_BATTLE: int = 1
const MODE_RIDE: int = 2
const BUTTON_SIZE: Vector2 = Vector2(43, 20)
## [mode, skin prefix in assets/hud, position, hint] in the order the constructor creates them.
const BUTTON_SPECS: Array = [
	[MODE_REST, "btn_assign_rest", Vector2(3, 3), "Rest"],
	[MODE_BATTLE, "btn_assign_fight", Vector2(3, 22), "Battle"],
	[MODE_RIDE, "btn_assign_ride", Vector2(3, 42), "Ride"],
]
## Offset of the popup from the team window origin (0x327f50).
const ANCHOR_X: float = 244.0
const ANCHOR_Y: float = 77.0
const ROW_PITCH: float = 34.0
const MSG_IN_TRAINING: String = "Can't replace, pet in training"
const MSG_CANT_MOUNT: String = "Can't mount"
## Team-window action names for each mode (TeamWindow._on_pet_row_button).
const TEAM_ACTIONS: Array[String] = ["dismiss", "battle", "ride"]

var background: TextureRect = null
var mode_buttons: Dictionary = {} # mode (int) -> Button
var current_slot: int = 1
var current_pet: Dictionary = {}
var in_training: bool = false
var mount_blocked: bool = false
var _built: bool = false


func _init() -> void:
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = size


func _ready() -> void:
	_build_ui_if_needed()


func _build_ui_if_needed() -> void:
	if _built:
		return
	_built = true
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	background = get_node_or_null("Background") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
	background.position = Vector2.ZERO
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_PASS
	if background.texture == null:
		background.texture = _tex("assets/hud/form_pet_status.png")
	for spec in BUTTON_SPECS:
		var mode: int = spec[0]
		var node_name := "Btn%s" % String(spec[3])
		var btn := get_node_or_null(node_name) as Button
		if btn == null:
			btn = Button.new()
			btn.name = node_name
			add_child(btn)
		btn.position = spec[2]
		btn.size = BUTTON_SIZE
		btn.custom_minimum_size = BUTTON_SIZE
		btn.tooltip_text = spec[3]
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_states(btn, spec[1], spec[3])
		btn.pressed.connect(choose_mode.bind(mode))
		mode_buttons[mode] = btn


## Fills the popup for one pet row. slot is 1-based (1..4) like the original.
func populate(slot: int, pet: Dictionary = {}, p_in_training: bool = false, p_mount_blocked: bool = false) -> void:
	_build_ui_if_needed()
	current_slot = clampi(slot, 1, 4)
	current_pet = pet
	in_training = p_in_training or bool(pet.get("in_training", false))
	mount_blocked = p_mount_blocked or bool(pet.get("mount_blocked", false))


## Position of the popup for a pet row, relative to the team window's parent (0x327f50).
static func popup_position(team_window_position: Vector2, slot: int) -> Vector2:
	return team_window_position + Vector2(ANCHOR_X, ANCHOR_Y - WINDOW_HEIGHT + float(slot - 1) * ROW_PITCH)


func open_at(team_window_position: Vector2, slot: int, pet: Dictionary = {}) -> void:
	populate(slot, pet)
	position = popup_position(team_window_position, current_slot)
	open_window()


func open_window() -> void:
	_build_ui_if_needed()
	visible = true
	move_to_front()


func close_window() -> void:
	visible = false
	window_closed.emit()


func toggle_window() -> void:
	if visible:
		close_window()
	else:
		open_window()


## Same effect as clicking a button: refuse, or emit the chosen mode and hide (OnClick 0x327d9c).
func choose_mode(mode: int) -> bool:
	AuthAudioScript.play_click()
	if in_training:
		action_refused.emit(MSG_IN_TRAINING)
		close_window()
		return false
	if mode == MODE_RIDE and mount_blocked:
		action_refused.emit(MSG_CANT_MOUNT)
		close_window()
		return false
	pet_mode_selected.emit(current_slot, mode, current_pet)
	close_window()
	return true


static func team_action_for_mode(mode: int) -> String:
	return TEAM_ACTIONS[clampi(mode, 0, 2)]


func _apply_states(btn: Button, prefix: String, fallback: String) -> void:
	var normal := _tex("assets/hud/%s_normal.png" % prefix)
	if normal == null:
		btn.text = fallback
		return
	btn.text = ""
	var states := {"normal": normal, "hover": _tex("assets/hud/%s_hover.png" % prefix), "pressed": _tex("assets/hud/%s_pressed.png" % prefix)}
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxTexture.new()
		var t: Texture2D = states.get(state, null)
		box.texture = t if t else normal
		btn.add_theme_stylebox_override(state, box)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _tex(rel_path: String) -> Texture2D:
	var p := "res://" + rel_path
	return load(p) as Texture2D if ResourceLoader.exists(p) else null
