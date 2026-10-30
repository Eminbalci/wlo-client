class_name ChannelWindow
extends Control

## "Channel on-off" window (TTH_channelForm, constructor aLogin.exe 0x29c0cc).
## Control table (left, top, w, h):
##   form "Form_channel_1" (150,100) 169x237 (bitmap is 166x237)
##   Btn_On_1 x5: (86, 47 + 30*(i-1)) 39x20, i = 1..5, tag = i, OnClick 0x29c3c4
##   Btn_OK_2 (41,199) 56x20 -> 0x29c444 | Btn_Close_2 (86,199) 56x20, hint "[ESC]"
## Behaviour: each channel has a committed flag (+0x150+i) and a pending flag (+0x156+i).
## Clicking toggles the pending flag and swaps the bitmap Btn_On_1 <-> Btn_Off_1. OK copies pending
## into committed, packs them into a bit mask (0x49c694) and sends it (0x2d6ad8, dl=0x21, cl=3),
## then closes. Close/ESC drops the pending changes. Row labels are baked into the skin:
## Local, Whisper, Team, Guild, World (top to bottom). Index -> channel follows that order (the
## bitmap order; the bit numbering of the mask is not verified).
## Offline: committed state persists in user://chat_channels.json.

signal channels_changed(states: Dictionary)
signal window_closed

const S = preload("res://scripts/ui/hud/wlo_window_skin.gd")

const WINDOW_SIZE: Vector2 = Vector2(169, 237)
const DEFAULT_POSITION: Vector2 = Vector2(150, 100)
const CHANNELS: Array[String] = ["Local", "Whisper", "Team", "Guild", "World"]
const TOGGLE_X: int = 86
const TOGGLE_Y0: int = 47
const TOGGLE_PITCH: int = 30
const TOGGLE_SIZE: Vector2 = Vector2(39, 20)
const SAVE_PATH: String = "user://chat_channels.json"

var background: TextureRect
var btn_ok: TextureButton
var btn_close: TextureButton
var toggles: Array[TextureButton] = []

var _committed: Dictionary = {}
var _pending: Dictionary = {}
var _built: bool = false


func _init() -> void:
	name = "ChannelWindow"
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	position = DEFAULT_POSITION
	mouse_filter = Control.MOUSE_FILTER_STOP
	for c in CHANNELS:
		_committed[c] = true # constructor sets every flag to 1
	_load()
	_pending = _committed.duplicate()


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	background = S.background(self, "channel_form", Vector2(166, 237))
	S.make_draggable(self, background)
	for i in CHANNELS.size():
		var rect := Rect2(TOGGLE_X, TOGGLE_Y0 + TOGGLE_PITCH * i, TOGGLE_SIZE.x, TOGGLE_SIZE.y)
		var btn := S.button(self, "Toggle%s" % CHANNELS[i], "channel_btn_on", rect, CHANNELS[i])
		btn.pressed.connect(toggle_channel.bind(CHANNELS[i]))
		toggles.append(btn)
	btn_ok = S.button(self, "BtnOK", "channel_btn_ok", Rect2(41, 199, 39, 20), "Confirm")
	btn_close = S.button(self, "BtnClose", "channel_btn_close", Rect2(86, 199, 39, 20), "[ESC]")
	btn_ok.pressed.connect(confirm)
	btn_close.pressed.connect(close)
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


# --- public API -------------------------------------------------------------------------------

func open() -> void:
	_build()
	_pending = _committed.duplicate()
	visible = true
	move_to_front()
	_refresh()


## Discards pending toggles (Btn_Close_2 / ESC).
func close() -> void:
	_pending = _committed.duplicate()
	visible = false
	_refresh()
	window_closed.emit()


func toggle_channel(channel: String) -> void:
	if not _pending.has(channel):
		return
	_pending[channel] = not bool(_pending[channel])
	_refresh()


## Btn_OK_2: commit, persist, notify, close.
func confirm() -> void:
	_committed = _pending.duplicate()
	_save()
	channels_changed.emit(_committed.duplicate())
	visible = false
	window_closed.emit()


func is_channel_on(channel: String) -> bool:
	return bool(_committed.get(channel, true))


func is_pending_on(channel: String) -> bool:
	return bool(_pending.get(channel, true))


func get_states() -> Dictionary:
	return _committed.duplicate()


## Populate from outside (e.g. server state) without emitting.
func set_states(states: Dictionary) -> void:
	for c in CHANNELS:
		if states.has(c):
			_committed[c] = bool(states[c])
	_pending = _committed.duplicate()
	_refresh()


## Bit mask in row order (bit 0 = Local ... bit 4 = World). Bit order is a guess.
func get_mask() -> int:
	var mask := 0
	for i in CHANNELS.size():
		if is_channel_on(CHANNELS[i]):
			mask |= 1 << i
	return mask


# --- internals --------------------------------------------------------------------------------

func _refresh() -> void:
	if not _built:
		return
	for i in CHANNELS.size():
		var on := is_pending_on(CHANNELS[i])
		var stem := "channel_btn_on" if on else "channel_btn_off"
		var btn := toggles[i]
		btn.texture_normal = S.tex(stem + "_normal")
		btn.texture_hover = S.tex(stem + "_hover")
		btn.texture_pressed = S.tex(stem + "_pressed")
		btn.tooltip_text = "%s: %s" % [CHANNELS[i], "On" if on else "Off"]


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_committed))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for c in CHANNELS:
			if parsed.has(c):
				_committed[c] = bool(parsed[c])
