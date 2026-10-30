class_name GpsWindow
extends Control

## GPS / save-point window (TGPSForm, constructor aLogin.exe 0x13df70, paint 0x13eaec).
## Control table (left, top, w, h) decoded from the constructor:
##   form "Form_GPS" (290,200) 223x223   | Btn_Close_s_1 (W-50=173, 25) 17x17
##   Btn_SetPoint (82,120) 56x20         | Btn_Transmi (82,145) 56x20 | btn_close_1 (82,170) 56x20
##   Btn_ArrowL_7 (22,80) 14x13          | Btn_ArrowR_7 (188,80) 14x13
## Paint: the selected slot (byte +0x14b, 1..5) reads a 6-byte record {map_id, x, y} at player+0x2358;
## map name (SceneData record, 0x83 bytes, name at +8) is centred at y=70 (x = W/2 - len/2*8),
## "X:"+x at (40,90), "Y:"+y at (120,90), colour 0xFFE0. Empty slot shows Big5 "無紀錄場景"
## ("no recorded scene"). Arrows only step slots for GPS items 0x8593 / 0x8645 (34195 / 34373):
## left decrements while slot >= 2, right increments while slot <= 4. Other GPS items keep slot 1.
## SetPoint asks "Confirm Save Point here?" (0x13e448); Transmi checks state then teleports (0x13e5d0..).
## Offline: slots persist in user://gps_points.json.

signal point_saved(slot: int, point: Dictionary)
signal teleport_requested(slot: int, point: Dictionary)
signal slot_changed(slot: int)
signal window_closed

const S = preload("res://scripts/ui/hud/wlo_window_skin.gd")

const WINDOW_SIZE: Vector2 = Vector2(223, 223)
const DEFAULT_POSITION: Vector2 = Vector2(290, 200)
const SAVE_PATH: String = "user://gps_points.json"
const SLOT_COUNT: int = 5
const MULTI_SLOT_ITEM_IDS: Array[int] = [0x8593, 0x8645]
const TEXT_COLOR_565: int = 0xFFE0
const EMPTY_TEXT: String = "No recorded scene"

var background: TextureRect
var close_button: TextureButton
var btn_set_point: TextureButton
var btn_transmi: TextureButton
var btn_close: TextureButton
var btn_arrow_left: TextureButton
var btn_arrow_right: TextureButton
var map_label: Label
var x_label: Label
var y_label: Label
var confirm_label: Label

var current_slot: int = 1
var gps_item_id: int = 0
var _points: Array[Dictionary] = []
var _current_position: Dictionary = {}
var _pending_confirm: bool = false
var _built: bool = false


func _init() -> void:
	name = "GpsWindow"
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	position = DEFAULT_POSITION
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in SLOT_COUNT:
		_points.append({})
	_load()


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	background = S.background(self, "gps_form", WINDOW_SIZE)
	S.make_draggable(self, background)
	var color := S.rgb565(TEXT_COLOR_565)
	map_label = S.label(self, "MapName", Rect2(38, 62, 148, 18), color, 12, HORIZONTAL_ALIGNMENT_CENTER)
	x_label = S.label(self, "CoordX", Rect2(40, 86, 76, 18), color, 12)
	y_label = S.label(self, "CoordY", Rect2(120, 86, 66, 18), color, 12)
	confirm_label = S.label(self, "ConfirmHint", Rect2(10, 196, 203, 16), Color(0.25, 0.3, 0.5), 11, HORIZONTAL_ALIGNMENT_CENTER)
	confirm_label.add_theme_constant_override("outline_size", 0)
	confirm_label.visible = false
	btn_set_point = S.button(self, "BtnSetPoint", "gps_btn_set_point", Rect2(82, 120, 56, 20), "Save Point")
	btn_transmi = S.button(self, "BtnTransmi", "gps_btn_transmi", Rect2(82, 145, 56, 20), "Teleport")
	btn_close = S.button(self, "BtnClose", "gps_btn_close", Rect2(82, 170, 56, 20), "Close")
	btn_arrow_left = S.button(self, "BtnArrowL", "gps_btn_arrow_l", Rect2(22, 80, 14, 13))
	btn_arrow_right = S.button(self, "BtnArrowR", "gps_btn_arrow_r", Rect2(188, 80, 14, 13))
	close_button = S.button(self, "CloseButton", "skin_btn_close_s_1", Rect2(WINDOW_SIZE.x - 50, 25, 17, 17), "Close")
	btn_set_point.pressed.connect(_on_set_point)
	btn_transmi.pressed.connect(_on_transmi)
	btn_close.pressed.connect(close)
	close_button.pressed.connect(close)
	btn_arrow_left.pressed.connect(step_slot.bind(-1))
	btn_arrow_right.pressed.connect(step_slot.bind(1))
	_refresh()


# --- public API -------------------------------------------------------------------------------

func open(item_id: int = 0) -> void:
	_build()
	gps_item_id = item_id
	if not is_multi_slot():
		current_slot = 1
	_pending_confirm = false
	visible = true
	move_to_front()
	_refresh()


func close() -> void:
	visible = false
	_pending_confirm = false
	window_closed.emit()


func is_multi_slot() -> bool:
	return MULTI_SLOT_ITEM_IDS.has(gps_item_id)


## Where the player stands now; SetPoint stores this into the current slot.
func set_current_position(map_id: int, x: int, y: int, map_name: String = "") -> void:
	_current_position = {"map_id": map_id, "x": x, "y": y, "map_name": map_name}


func get_point(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT:
		return {}
	return _points[slot - 1]


func set_point(slot: int, point: Dictionary) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		return
	_points[slot - 1] = point.duplicate()
	_save()
	_refresh()


func step_slot(direction: int) -> void:
	if not is_multi_slot():
		current_slot = 1
	elif direction < 0 and current_slot >= 2:
		current_slot -= 1
	elif direction > 0 and current_slot <= SLOT_COUNT - 1:
		current_slot += 1
	slot_changed.emit(current_slot)
	_refresh()


## Saves the current position into the current slot (what the original does after the
## "Confirm Save Point here?" dialog is accepted).
func confirm_save_point() -> bool:
	_pending_confirm = false
	if _current_position.is_empty() or int(_current_position.get("map_id", 0)) == 0:
		_refresh()
		return false
	var point := _current_position.duplicate()
	if String(point.get("map_name", "")) == "":
		point["map_name"] = _scene_name(int(point.map_id))
	_points[current_slot - 1] = point
	_save()
	point_saved.emit(current_slot, point)
	_refresh()
	return true


func display_name_for(point: Dictionary) -> String:
	if point.is_empty() or int(point.get("map_id", 0)) == 0:
		return EMPTY_TEXT
	var n := String(point.get("map_name", ""))
	return n if n != "" else _scene_name(int(point.map_id))


# --- internals --------------------------------------------------------------------------------

func _on_set_point() -> void:
	if _pending_confirm:
		confirm_save_point()
		return
	_pending_confirm = true
	_refresh()


func _on_transmi() -> void:
	var point := get_point(current_slot)
	if point.is_empty() or int(point.get("map_id", 0)) == 0:
		return
	teleport_requested.emit(current_slot, point.duplicate())


func _refresh() -> void:
	if not _built:
		return
	var point := get_point(current_slot)
	map_label.text = display_name_for(point)
	var has_point := not point.is_empty() and int(point.get("map_id", 0)) != 0
	x_label.visible = has_point
	y_label.visible = has_point
	if has_point:
		x_label.text = "X: %d" % int(point.x)
		y_label.text = "Y: %d" % int(point.y)
	var multi := is_multi_slot()
	btn_arrow_left.visible = multi
	btn_arrow_right.visible = multi
	btn_arrow_left.disabled = current_slot <= 1
	btn_arrow_right.disabled = current_slot >= SLOT_COUNT
	confirm_label.visible = _pending_confirm
	confirm_label.text = "Confirm Save Point here? (press again)"


func _scene_name(map_id: int) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var db: Node = tree.root.get_node_or_null("GameDatabase") if tree != null else null
	if db != null and db.get("scenes") != null:
		var rec = db.scenes.get_scene(map_id)
		if rec != null and String(rec.name) != "":
			return String(rec.name)
	return "Map %d" % map_id


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"points": _points}))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.get("points") is Array:
		var arr: Array = parsed.points
		for i in mini(arr.size(), SLOT_COUNT):
			if arr[i] is Dictionary:
				var p: Dictionary = arr[i]
				for k in ["map_id", "x", "y"]:
					if p.has(k):
						p[k] = int(p[k])
				_points[i] = p
