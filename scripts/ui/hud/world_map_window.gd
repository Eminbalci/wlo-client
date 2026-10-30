class_name WorldMapWindow
extends Control

## World map (TGlobaForm, constructor aLogin.exe 0x13f5d8), rebuilt from the control table:
## - form "GlobaMap" at (30,30), 667x538 (0x29b x 0x21a), skin GlobaMap.bmp
## - "Btn_Close_s_3" at (W-20, 3) 18x18
## - 41 "GlobaBtn" markers (ship wheel, 2 frames 18x17). Marker i (1..41) reads record i of the
##   28-byte table at 0x4b8944 {x, y, hidden, hint_x, hint_y, med_sea, 0} and name i-1 of the
##   pointer table at 0x4b8880. Position = (Round(x / sx) + 146, Round(y / sy) + 17) with
##   sx = 12000 / (W - 167) and sy = 12000 / (H - 38) (float 12000.0 at 0x13f8c8) = 24 for both.
## - hint = name + " (" + ("Med. Sea" if med_sea) + hint_x + "," + hint_y + ")"  (verbatim concat)
## The magic-map item variant (TMagicMap, 0x22193c) uses the same layout with the 40-entry table
## at 0x4bbf10 / names 0x4bbe50; select it with `use_magic_map_table`.
## The original markers only show hints (no OnClick in TGlobaForm); clicking here emits
## `location_selected` so the HUD can centre/route, and in magic-map mode `teleport_requested`.

signal location_selected(index: int, location: Dictionary)
signal teleport_requested(index: int, location: Dictionary)
signal window_closed

const S = preload("res://scripts/ui/hud/wlo_window_skin.gd")

const WINDOW_SIZE: Vector2 = Vector2(667, 538)
const DEFAULT_POSITION: Vector2 = Vector2(30, 30)
const MAP_UNITS: float = 12000.0
const MARKER_ORIGIN: Vector2 = Vector2(146, 17)
const MARKER_SIZE: Vector2 = Vector2(18, 17)
const CLOSE_RECT: Rect2 = Rect2(667 - 20, 3, 18, 18)

## TGlobaForm table 0x4b8944 + names 0x4b8880: [name, x, y, hint_x, hint_y, med_sea]
const GLOBA_POINTS: Array = [
	["China", 6900, 3050, 6900, 3050, 0], ["Calcutta", 4842, 4000, 4842, 4000, 0],
	["Oslya", 6782, 8555, 6782, 8555, 0], ["Mayan Forest", 11722, 5955, 11722, 5955, 0],
	["Universal", 4950, 6650, 4950, 6650, 0], ["Revival", 10662, 9700, 10662, 9700, 0],
	["Hawaii Isle", 9000, 4000, 9000, 4000, 0], ["S.Pole", 6460, 11195, 6460, 11195, 0],
	["Korea", 6960, 2255, 6960, 2255, 0], ["Iceberg", 11482, 10675, 11482, 10675, 0],
	["Kyoto", 7692, 2235, 7692, 2235, 0], ["Taiwan", 7200, 3600, 7200, 3600, 0],
	["S.Island", 7500, 9700, 7500, 9700, 0], ["N.Island", 7450, 8460, 7450, 8460, 0],
	["Stoowa Isle", 7100, 10200, 7100, 10200, 0], ["Mag's Fleet", 8869, 10580, 8869, 10580, 0],
	["Egypt", 1300, 3135, 1300, 3135, 0], ["Madagascar", 2002, 6765, 2002, 6765, 0],
	["Zhen's Fleet", 5920, 5000, 5920, 5000, 0], ["Polo", 6012, 5675, 6012, 5675, 0],
	["Hezrou", 6682, 6675, 6682, 6675, 0], ["Cook's Fleet", 7802, 10015, 7802, 10015, 0],
	["SnowIsle", 2202, 10975, 2202, 10975, 0], ["Inca", 11462, 7895, 11462, 7895, 0],
	["Ghostdom", 9162, 1335, 9162, 1335, 0], ["Shayii", 8422, 1635, 8422, 1635, 0],
	["Yazhou", 6350, 3900, 6350, 3900, 0], ["Bangkok", 5882, 4435, 5882, 4435, 0],
	["LionIsle", 4382, 4875, 4382, 4875, 0], ["Centaur Isle", 3902, 6215, 3902, 6215, 0],
	["Sky City", 4402, 10275, 4402, 10275, 0], ["Africa", 1422, 5415, 1422, 5415, 0],
	["Yamatai", 7750, 2570, 7750, 2570, 0], ["Train Island", 8530, 7601, 8530, 7601, 0],
	["Athens", 900, 2235, 3057, 2573, 1], ["Rome", 350, 2000, 2635, 2242, 1],
	["Persia", 3000, 3050, 3000, 3050, 0], ["Filipino", 7390, 4375, 7390, 4375, 0],
	["Avignon", -100, 1700, 2207, 1952, 1], ["Fog Jungle", -200, 900, 1987, 1219, 1],
	["Deep Jungle", 1300, 2485, 3427, 2717, 1],
]

## TMagicMap table 0x4bbf10 + names 0x4bbe50 (40 entries).
const MAGIC_MAP_POINTS: Array = [
	["China", 6900, 3050, 6900, 3050, 0], ["Calcutta", 4842, 4000, 4842, 4000, 0],
	["Oslya", 6782, 8555, 6782, 8555, 0], ["Mayan Forest", 11722, 5955, 11722, 5955, 0],
	["Universal", 4950, 6650, 4950, 6650, 0], ["Revival", 10662, 9700, 10662, 9700, 0],
	["Hawaii Isle", 9000, 4000, 9000, 4000, 0], ["S.Pole", 6460, 11195, 6460, 11195, 0],
	["Korea", 6960, 2255, 6960, 2255, 0], ["Iceberg", 11482, 10675, 11482, 10675, 0],
	["Kyoto", 7692, 2235, 7692, 2235, 0], ["Taiwan", 7200, 3600, 7200, 3600, 0],
	["S.Island", 7500, 9700, 7500, 9700, 0], ["N.Island", 7450, 8460, 7450, 8460, 0],
	["Stoowa Isle", 7100, 10200, 7100, 10200, 0], ["Egypt", 1300, 3135, 1300, 3135, 0],
	["Madagascar", 2002, 6765, 2002, 6765, 0], ["Polo", 6012, 5675, 6012, 5675, 0],
	["Hezrou", 6682, 6675, 6682, 6675, 0], ["SnowIsle", 2202, 10975, 2202, 10975, 0],
	["Inca", 11462, 7895, 11462, 7895, 0], ["Ghostdom", 9162, 1335, 9162, 1335, 0],
	["Shayii", 8422, 1635, 8422, 1635, 0], ["Yazhou", 6350, 3900, 6350, 3900, 0],
	["Bangkok", 5882, 4435, 5882, 4435, 0], ["LionIsle", 4382, 4875, 4382, 4875, 0],
	["Centaur Isle", 3902, 6215, 3902, 6215, 0], ["Sky City", 4402, 10275, 4402, 10275, 0],
	["Africa", 1422, 5415, 1422, 5415, 0], ["Yamatai", 7750, 2570, 7750, 2570, 0],
	["Athens", 900, 2235, 3057, 2573, 1], ["Small Hawaii", 8800, 3600, 8800, 3600, 0],
	["Train Island", 8530, 7601, 8530, 7601, 0], ["Rome", 350, 2000, 2635, 2242, 1],
	["Persia", 3000, 3050, 3000, 3050, 0], ["Filipino", 7390, 4375, 7390, 4375, 0],
	["Lost Jungle", -100, 1700, 2207, 1952, 1], ["Fog Jungle", -200, 900, 1987, 1219, 1],
	["Chang'an", 6175, 2900, 6175, 2900, 0], ["Deep Jungle", 1300, 2485, 3427, 2717, 1],
]

@export var use_magic_map_table: bool = false

var background: TextureRect
var close_button: TextureButton
var markers: Array[TextureButton] = []
var _locations: Array[Dictionary] = []
var _built: bool = false


func _init() -> void:
	name = "WorldMapWindow"
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	position = DEFAULT_POSITION
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	background = S.background(self, "world_globa_map", WINDOW_SIZE)
	S.make_draggable(self, background)
	_rebuild_markers()
	close_button = S.button(self, "CloseButton", "world_btn_close_s_3", CLOSE_RECT, "Close")
	close_button.pressed.connect(close)


## Pixel position of a table point on the 667x538 map (scale 12000 / (W-167), 12000 / (H-38)).
static func map_to_pixel(map_x: int, map_y: int) -> Vector2:
	var sx := MAP_UNITS / (WINDOW_SIZE.x - 167.0)
	var sy := MAP_UNITS / (WINDOW_SIZE.y - 38.0)
	return Vector2(roundi(map_x / sx) + MARKER_ORIGIN.x, roundi(map_y / sy) + MARKER_ORIGIN.y)


static func hint_for(row: Array) -> String:
	return "%s (%s%d,%d)" % [row[0], "Med. Sea" if int(row[5]) == 1 else "", int(row[3]), int(row[4])]


func _rebuild_markers() -> void:
	for m in markers:
		m.queue_free()
	markers.clear()
	_locations.clear()
	var table: Array = MAGIC_MAP_POINTS if use_magic_map_table else GLOBA_POINTS
	for i in table.size():
		var row: Array = table[i]
		var loc := {
			"index": i + 1, "name": row[0], "map_x": row[1], "map_y": row[2],
			"coord_x": row[3], "coord_y": row[4], "med_sea": int(row[5]) == 1,
			"hint": hint_for(row), "pixel": map_to_pixel(row[1], row[2]),
		}
		_locations.append(loc)
		var btn := S.button(self, "Marker%02d" % (i + 1), "world_globa_btn", Rect2(loc.pixel, MARKER_SIZE), loc.hint)
		btn.pressed.connect(_on_marker_pressed.bind(i))
		markers.append(btn)


func set_magic_map_mode(enabled: bool) -> void:
	use_magic_map_table = enabled
	if _built:
		_rebuild_markers()
		if close_button:
			move_child(close_button, get_child_count() - 1)


func get_locations() -> Array[Dictionary]:
	return _locations


func find_location(location_name: String) -> Dictionary:
	for loc in _locations:
		if String(loc.name).to_lower() == location_name.to_lower():
			return loc
	return {}


func open() -> void:
	_build()
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	window_closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _on_marker_pressed(i: int) -> void:
	var loc: Dictionary = _locations[i]
	location_selected.emit(i + 1, loc)
	if use_magic_map_table:
		teleport_requested.emit(i + 1, loc)
