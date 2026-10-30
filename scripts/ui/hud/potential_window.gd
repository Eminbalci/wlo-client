class_name PotentialWindow
extends Control

## Form_Potential_1 ("Potential", awaken) and Form_Potential_2 ("Potential Return"), opened from
## the item window's Potential button. Decoded from aLogin.exe (docs/re/potential_window.md):
## - 0x1e4d48 (awaken) / 0x1e7b48 (return): skin Form_Potential_1 299x520 / Form_Potential_2 299x460
##   (white skin set); Btn_Close_s_1 at (249,26) 18x18 hint [ESC]; btn_ok_1 at (87,473|414) and
##   Btn_Cancel_1 at (163,473|414), 56x20; 5 | 4 team rows at (32, 78 + 34*i); list control bounds
##   (32,79,233,168); 12 Icon_PotentialMark_1 positions; item slot (56,366 | 74,328) 30x30 holding
##   item 0x85DD (34269).
## - row painter: name at row+(38,8); level right-aligned at row.x+165; potential "N" (red $F800)
##   + "/12" right-aligned at row.x+228.
## - stats painter: STR..AGI value at (60, 274+16*i) and red "+N" at x 86 (awaken) /
##   (66, 236+16*i) and blue "-N" at x 92 (return).

signal window_closed
signal row_selected(index: int, entry: Dictionary)
## Emitted by OK when the selected row passes the checks the client makes before using the pill.
signal potential_confirmed(mode: int, index: int, entry: Dictionary)
signal action_refused(message: String)

const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")

const MODE_AWAKEN: int = 1
const MODE_RETURN: int = 2
const MAX_POTENTIAL: int = 12
const POTENTIAL_PILL_ITEM_ID: int = 34269 # 0x85DD, put into the slot by both constructors
const WINDOW_WIDTH: float = 299.0
const ROW_ORIGIN: Vector2 = Vector2(32, 78)
const ROW_PITCH: float = 34.0
const ROW_SIZE: Vector2 = Vector2(233, 33)
const NAME_OFFSET: Vector2 = Vector2(38, 8)
const LEVEL_RIGHT_X: float = 165.0
const POTENTIAL_RIGHT_X: float = 228.0
const CLOSE_POS: Vector2 = Vector2(249, 26)
const CLOSE_SIZE: Vector2 = Vector2(18, 18)
const BUTTON_SIZE: Vector2 = Vector2(56, 20)
const MARK_SIZE: Vector2 = Vector2(21, 21)
const STAT_NAMES: Array[String] = ["str", "con", "int", "wis", "agi"]
const STAT_PITCH: float = 16.0
const INK: Color = Color8(8, 8, 8) # $0841 (RGB565)
const RED: Color = Color8(248, 0, 0) # $F800
const BLUE: Color = Color8(0, 0, 248) # $001F

## Per-mode layout decoded from the two constructors and painters.
const LAYOUTS: Dictionary = {
	1: {
		"skin": "assets/hud/form_potential_1.png", "height": 520.0, "rows": 5, "buttons_y": 473.0,
		"slot": Vector2(56, 366), "stat_origin": Vector2(60, 274), "delta_x": 86.0,
		"marks": [Vector2(201, 259), Vector2(230, 277), Vector2(245, 305), Vector2(245, 337),
			Vector2(230, 367), Vector2(201, 385), Vector2(167, 385), Vector2(138, 367),
			Vector2(123, 337), Vector2(123, 305), Vector2(138, 277), Vector2(167, 259)],
	},
	2: {
		"skin": "assets/hud/form_potential_2.png", "height": 460.0, "rows": 4, "buttons_y": 414.0,
		"slot": Vector2(74, 328), "stat_origin": Vector2(66, 236), "delta_x": 92.0,
		"marks": [Vector2(207, 221), Vector2(236, 239), Vector2(251, 267), Vector2(251, 299),
			Vector2(236, 329), Vector2(207, 347), Vector2(173, 347), Vector2(144, 329),
			Vector2(129, 299), Vector2(129, 267), Vector2(144, 239), Vector2(173, 221)],
	},
}

var mode: int = MODE_AWAKEN
var entries: Array[Dictionary] = []
var stats: Dictionary = {}
var stat_deltas: Dictionary = {}
var selected_index: int = 0

var background: TextureRect = null
var close_button: Button = null
var ok_button: Button = null
var cancel_button: Button = null
var row_buttons: Array[Button] = []
var row_name_labels: Array[Label] = []
var row_level_labels: Array[Label] = []
var row_potential_labels: Array[Label] = []
var row_max_labels: Array[Label] = []
var mark_rects: Array[TextureRect] = []
var stat_value_labels: Array[Label] = []
var stat_delta_labels: Array[Label] = []
var item_slot: TextureRect = null
var _dynamic: Control = null


func _init() -> void:
	_apply_size()


func _ready() -> void:
	_rebuild()


func _apply_size() -> void:
	custom_minimum_size = Vector2(WINDOW_WIDTH, float(LAYOUTS[mode]["height"]))
	size = custom_minimum_size


func layout() -> Dictionary:
	return LAYOUTS[mode]


## Switches between Form_Potential_1 (MODE_AWAKEN) and Form_Potential_2 (MODE_RETURN).
func set_mode(p_mode: int) -> void:
	var m := MODE_RETURN if p_mode == MODE_RETURN else MODE_AWAKEN
	if m == mode and _dynamic != null:
		return
	mode = m
	_rebuild()


## entries: row 0 = the player, then the pets, each {name, level, potential, mercenary?}.
## p_stats: {str, con, int, wis, agi}; p_deltas: the same keys with the pill's change.
func populate(p_entries: Array, p_stats: Dictionary = {}, p_deltas: Dictionary = {}) -> void:
	entries.clear()
	for e in p_entries:
		if e is Dictionary:
			entries.append(e)
	stats = p_stats
	stat_deltas = p_deltas
	if _dynamic == null:
		_rebuild()
	selected_index = clampi(selected_index, 0, maxi(0, mini(entries.size(), int(layout()["rows"])) - 1))
	_refresh()


## Builds the rows from existing game data: a HUDCharacterStatus-like object (current_name,
## current_level, current_potential, current_str..current_agi) and a TeamWindow-like object
## (_pet_entries()). Either may be null.
func populate_from_game(character_status: Object, team_window: Object = null) -> void:
	var rows: Array = []
	var st := {}
	if character_status != null:
		rows.append({
			"name": str(character_status.get("current_name")),
			"level": int(character_status.get("current_level")),
			"potential": int(character_status.get("current_potential")),
		})
		for s in STAT_NAMES:
			st[s] = int(character_status.get("current_" + s))
	if team_window != null and team_window.has_method("_pet_entries"):
		for pet in team_window.call("_pet_entries"):
			rows.append({
				"name": str(pet.get("name", "")),
				"level": int(pet.get("level", 1)),
				"potential": int(pet.get("potential", 0)),
				"mercenary": bool(pet.get("mercenary", false)),
			})
	populate(rows, st)


func select_row(index: int) -> void:
	if index < 0 or index >= mini(entries.size(), int(layout()["rows"])):
		return
	selected_index = index
	_refresh()
	row_selected.emit(index, entries[index])


func get_selected_entry() -> Dictionary:
	return entries[selected_index] if selected_index < entries.size() else {}


## OK (btn_ok_1, OnClick 0x1e68b8 / return variant): runs the checks whose messages the
## handler references, then emits potential_confirmed.
func confirm() -> bool:
	AuthAudioScript.play_click()
	var entry := get_selected_entry()
	if entry.is_empty():
		return false
	var pot := int(entry.get("potential", 0))
	var msg := ""
	if bool(entry.get("mercenary", false)):
		msg = "Not for mercenaries"
	elif mode == MODE_AWAKEN and pot >= MAX_POTENTIAL:
		msg = "Reached max potential"
	elif mode == MODE_RETURN and pot <= 0:
		msg = "No potential on this"
	if not msg.is_empty():
		action_refused.emit(msg)
		return false
	potential_confirmed.emit(mode, selected_index, entry)
	return true


func open_window() -> void:
	if _dynamic == null:
		_rebuild()
	visible = true
	move_to_front()
	_refresh()


func close_window() -> void:
	AuthAudioScript.play_click()
	visible = false
	window_closed.emit()


func toggle_window() -> void:
	if visible:
		close_window()
	else:
		open_window()


# ---------------------------------------------------------------- building

func _rebuild() -> void:
	_apply_size()
	var lay := layout()
	background = get_node_or_null("Background") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
	background.position = Vector2.ZERO
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_PASS
	background.texture = _tex(lay["skin"])

	close_button = get_node_or_null("CloseButton") as Button
	if close_button == null:
		close_button = Button.new()
		close_button.name = "CloseButton"
		add_child(close_button)
	WindowCloseButton.apply(close_button, WINDOW_WIDTH)
	# Decoded position of Btn_Close_s_1; the skin bakes the sphere, so the button stays a hit area.
	close_button.position = CLOSE_POS
	close_button.custom_minimum_size = CLOSE_SIZE
	close_button.size = CLOSE_SIZE
	close_button.tooltip_text = "[ESC]"
	if not close_button.pressed.is_connected(close_window):
		close_button.pressed.connect(close_window)

	if _dynamic != null:
		remove_child(_dynamic)
		_dynamic.free()
	_dynamic = Control.new()
	_dynamic.name = "Content"
	_dynamic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dynamic.size = size
	add_child(_dynamic)
	move_child(close_button, -1)
	row_buttons.clear(); row_name_labels.clear(); row_level_labels.clear()
	row_potential_labels.clear(); row_max_labels.clear(); mark_rects.clear()
	stat_value_labels.clear(); stat_delta_labels.clear()

	for i in int(lay["rows"]):
		var origin := ROW_ORIGIN + Vector2(0, ROW_PITCH * i)
		var row := Button.new()
		row.name = "Row%d" % i
		row.flat = true
		row.position = origin
		row.size = ROW_SIZE
		row.focus_mode = Control.FOCUS_NONE
		row.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.add_theme_stylebox_override("hover", _fill(Color(1, 1, 1, 0.25)))
		row.add_theme_stylebox_override("pressed", _fill(Color(0.55, 0.7, 0.95, 0.35)))
		row.pressed.connect(select_row.bind(i))
		_dynamic.add_child(row)
		row_buttons.append(row)
		row_name_labels.append(_label(row, "Name", NAME_OFFSET, Vector2(120, 16), HORIZONTAL_ALIGNMENT_LEFT, INK))
		row_level_labels.append(_label(row, "Level", Vector2(LEVEL_RIGHT_X - 40, NAME_OFFSET.y), Vector2(40, 16), HORIZONTAL_ALIGNMENT_RIGHT, INK))
		row_max_labels.append(_label(row, "PotentialMax", Vector2(POTENTIAL_RIGHT_X - 22, NAME_OFFSET.y), Vector2(22, 16), HORIZONTAL_ALIGNMENT_RIGHT, INK))
		row_potential_labels.append(_label(row, "Potential", Vector2(POTENTIAL_RIGHT_X - 22 - 20, NAME_OFFSET.y), Vector2(20, 16), HORIZONTAL_ALIGNMENT_RIGHT, RED))

	var mark_tex := _tex("assets/hud/icon_potential_mark_1.png")
	var marks: Array = lay["marks"]
	for i in marks.size():
		var m := TextureRect.new()
		m.name = "Mark%d" % i
		m.texture = mark_tex
		m.position = marks[i]
		m.size = MARK_SIZE
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dynamic.add_child(m)
		mark_rects.append(m)

	var so: Vector2 = lay["stat_origin"]
	for i in STAT_NAMES.size():
		var y := so.y + STAT_PITCH * i
		stat_value_labels.append(_label(_dynamic, "Stat_%s" % STAT_NAMES[i], Vector2(so.x, y), Vector2(26, 16), HORIZONTAL_ALIGNMENT_LEFT, INK))
		stat_delta_labels.append(_label(_dynamic, "Delta_%s" % STAT_NAMES[i], Vector2(float(lay["delta_x"]), y), Vector2(28, 16), HORIZONTAL_ALIGNMENT_LEFT, RED if mode == MODE_AWAKEN else BLUE))

	item_slot = TextureRect.new()
	item_slot.name = "ItemSlot"
	item_slot.position = lay["slot"]
	item_slot.size = Vector2(30, 30)
	item_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_slot.tooltip_text = "Potential Pill (item %d)" % POTENTIAL_PILL_ITEM_ID
	item_slot.texture = _pill_icon()
	_dynamic.add_child(item_slot)

	var by := float(lay["buttons_y"])
	ok_button = _skin_button("BtnOk", "btn_ok_1", Vector2(87, by), "OK")
	ok_button.pressed.connect(confirm)
	cancel_button = _skin_button("BtnCancel", "btn_cancel_1", Vector2(163, by), "Cancel")
	cancel_button.tooltip_text = "[ESC]"
	cancel_button.pressed.connect(close_window)
	_refresh()


func _refresh() -> void:
	if _dynamic == null:
		return
	for i in row_buttons.size():
		var has := i < entries.size()
		var e: Dictionary = entries[i] if has else {}
		row_name_labels[i].text = str(e.get("name", "")) if has else ""
		row_level_labels[i].text = str(int(e.get("level", 0))) if has else ""
		row_potential_labels[i].text = str(int(e.get("potential", 0))) if has else ""
		row_max_labels[i].text = "/%d" % MAX_POTENTIAL if has else ""
		row_buttons[i].disabled = not has
		row_buttons[i].add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		row_buttons[i].add_theme_stylebox_override("normal", _fill(Color(0.55, 0.7, 0.95, 0.30)) if (has and i == selected_index) else StyleBoxEmpty.new())
	var lit := clampi(int(get_selected_entry().get("potential", 0)), 0, MAX_POTENTIAL)
	for i in mark_rects.size():
		mark_rects[i].visible = i < lit
	for i in STAT_NAMES.size():
		var key := STAT_NAMES[i]
		stat_value_labels[i].text = str(int(stats[key])) if stats.has(key) else ""
		var d := int(stat_deltas.get(key, 0))
		stat_delta_labels[i].text = ("+%d" if mode == MODE_AWAKEN else "-%d") % absi(d) if d != 0 else ""


func _label(parent: Control, node_name: String, pos: Vector2, sz: Vector2, align: int, color: Color) -> Label:
	var l := Label.new()
	l.name = node_name
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _skin_button(node_name: String, prefix: String, pos: Vector2, fallback: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = BUTTON_SIZE
	btn.custom_minimum_size = BUTTON_SIZE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := _tex("assets/hud/%s_normal.png" % prefix)
	if normal == null:
		btn.text = fallback
	else:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var t := _tex("assets/hud/%s_%s.png" % [prefix, state])
			var box := StyleBoxTexture.new()
			box.texture = t if t else normal
			btn.add_theme_stylebox_override(state, box)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_dynamic.add_child(btn)
	return btn


## Icon of item 34269 when the ArchiveLoader / GameDatabase autoloads are present (never forces a load).
func _pill_icon() -> Texture2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var gdb := tree.root.get_node_or_null("GameDatabase")
	var loader := tree.root.get_node_or_null("ArchiveLoader")
	if gdb == null or loader == null or not bool(gdb.get("is_loaded")) or not loader.has_method("get_item_icon"):
		return null
	var rec = gdb.items.get_item(POTENTIAL_PILL_ITEM_ID)
	if rec == null or rec.icon_id <= 0:
		return null
	return loader.get_item_icon(rec.icon_id)


func _fill(c: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = c
	return b


func _tex(rel_path: String) -> Texture2D:
	var p := "res://" + rel_path
	return load(p) as Texture2D if ResourceLoader.exists(p) else null
