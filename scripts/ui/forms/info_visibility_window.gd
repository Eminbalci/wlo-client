class_name InfoVisibilityWindow
extends Control

## "Info Visibility" options = the real client's Form_Huminfo (aLogin.exe ctor 0x29c55c, skin
## menu/Skins/white/Form_HumInfo_1.bmp 186x379, form at (150,100)). It is NOT another player's info
## card: the skin bakes the title "Info Visibility" and eleven option captions. That the System window's
## "Info Visibility (Setup)" button opens it is a GUESS (the opener was not traced).
## Evidence: docs/re/info_visibility_window.md.
##
## Layout (decoded immediates, window-local):
##   11 check boxes btn_Check_1 / btn_UnCheck_1 16x16 at (19, 43 + 30*i), toggle handler 0x29c7dc
##   Btn_OK_2 (51,337) 56x20 hit area (39x20 art) = apply (0x29c89c)    Btn_Close_2 (97,337) 56x20 = revert + close
## The ctor starts every option checked (both the applied [0x164+i] and pending [0x16f+i] arrays = 1).
## Option 10 ("Show Adventure Level") answers "Unavailable" and cannot be toggled.

signal settings_applied(flags: Array) ## Array[bool] of OPTION_NAMES.size()
signal message(text: String)
signal window_closed

const WINDOW_SIZE: Vector2 = Vector2(186, 379)
const DEFAULT_POSITION: Vector2 = Vector2(150, 100)
const CHECK_X: int = 19
const CHECK_Y0: int = 43
const CHECK_PITCH: int = 30
const CHECK_SIZE: Vector2 = Vector2(16, 16)
const OK_RECT: Rect2 = Rect2(51, 337, 56, 20)
const CLOSE_RECT: Rect2 = Rect2(97, 337, 56, 20)
const UNAVAILABLE_INDEX: int = 9 ## 0-based; the client tags boxes 1..10 and blocks tag 10

## Captions baked into the skin, top to bottom (read from the bitmap).
const OPTION_NAMES: Array[String] = [
	"Show name of my pet",
	"Show names of other's pet",
	"Show other players' pet",
	"Show my nickname",
	"Show my guild name",
	"Other players' names",
	"Other players' nicknames",
	"Other players' guilds",
	"Show full sized tents",
	"Show \"Adventure Level\"",
	"Show Other Players",
]

var applied: Array[bool] = []
var pending: Array[bool] = []
var is_open: bool = false

var background: TextureRect = null
var check_boxes: Array[TextureButton] = []
var btn_ok: TextureButton = null
var btn_close: TextureButton = null

var _tex_check: Array[Texture2D] = []
var _tex_uncheck: Array[Texture2D] = []
var _built: bool = false


func _init() -> void:
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in range(OPTION_NAMES.size()):
		applied.append(true)
		pending.append(true)


func _ready() -> void:
	_build()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_build()


func _build() -> void:
	if _built:
		return
	_built = true
	size = WINDOW_SIZE
	background = SkinWindowKit.background(self, "form_hum_info_1", WINDOW_SIZE)
	for st in ["normal", "hover", "pressed"]:
		_tex_check.append(SkinWindowKit.tex("btn_check_1_" + st))
		_tex_uncheck.append(SkinWindowKit.tex("btn_uncheck_1_" + st))
	for i in range(OPTION_NAMES.size()):
		var rect := Rect2(Vector2(CHECK_X, CHECK_Y0 + CHECK_PITCH * i), CHECK_SIZE)
		var cb := SkinWindowKit.button(self, "Check%d" % i, "btn_check_1", rect)
		cb.tooltip_text = OPTION_NAMES[i]
		var idx: int = i
		cb.pressed.connect(func() -> void: toggle(idx))
		check_boxes.append(cb)
	btn_ok = SkinWindowKit.button(self, "BtnOK", "btn_ok_2", OK_RECT)
	btn_close = SkinWindowKit.button(self, "BtnClose", "btn_close_2", CLOSE_RECT)
	btn_ok.pressed.connect(apply_and_close)
	btn_close.pressed.connect(close_window)
	_refresh()


func open(current: Array = []) -> void:
	_build()
	for i in range(mini(current.size(), applied.size())):
		applied[i] = bool(current[i])
	pending = applied.duplicate()
	_refresh()
	is_open = true
	visible = true


func toggle(index: int) -> void:
	if index == UNAVAILABLE_INDEX:
		message.emit("Unavailable")
		return
	if index < 0 or index >= pending.size():
		return
	pending[index] = not pending[index]
	_refresh()


func apply_and_close() -> void:
	applied = pending.duplicate()
	settings_applied.emit(applied.duplicate())
	_hide()


## Btn_Close_2: drop the pending changes.
func close_window() -> void:
	pending = applied.duplicate()
	_refresh()
	_hide()


func _hide() -> void:
	is_open = false
	visible = false
	window_closed.emit()


func _refresh() -> void:
	for i in range(check_boxes.size()):
		var frames: Array[Texture2D] = _tex_check if pending[i] else _tex_uncheck
		check_boxes[i].texture_normal = frames[0]
		check_boxes[i].texture_hover = frames[1]
		check_boxes[i].texture_pressed = frames[2]
