class_name BlackNameListWindow
extends Control

## Blocked player list (Go client: settings/form.go, THL_BlackNameListForm, form_BlackNameList).
## The list is local to the client (Go keeps it in settings Local.Blacklist, no server packet).
## Layout is the Go constants in form-local pixels: the panel at (55,41) 264x415 (the Go window
## origin), name editor on the row at y 59, OK (197,59), list (26,90) 240x190, Delete (111,348),
## Close (105,380), corner close (215,24). Names are capped at 14 characters and a name already
## in the list is refused.

signal closed
signal list_changed

const FORM_POS := Vector2(55, 41)
const FORM_SIZE := Vector2(264, 415)
const MAX_NAME := 14
const DEFAULT_SAVE_PATH := "user://blacklist.json"
const SKIN_PATH := "res://assets/menu/Skins/white/form_BlackNameList.bmp"
const INK := Color("#2b2b2b")

var names: Array[String] = []
var save_path: String = DEFAULT_SAVE_PATH

var _editor: LineEdit
var _list: ItemList
var _delete_btn: Button
var _close_btn: Button


func _ready() -> void:
	position = FORM_POS
	size = FORM_SIZE
	custom_minimum_size = FORM_SIZE
	visible = false
	load_names()
	_build()
	_refresh()


func _build() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = load(SKIN_PATH) as Texture2D
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_editor = LineEdit.new()
	_editor.name = "NameEditor"
	_editor.position = Vector2(26, 59)
	_editor.size = Vector2(165, 20)
	_editor.max_length = MAX_NAME
	_editor.add_theme_color_override("font_color", INK)
	_editor.text_submitted.connect(func(_t: String) -> void: add_name(_editor.text))
	add_child(_editor)

	var ok := Button.new()
	ok.name = "Add"
	ok.text = "OK"
	ok.position = Vector2(197, 59)
	ok.size = Vector2(39, 20)
	ok.pressed.connect(func() -> void: add_name(_editor.text))
	add_child(ok)

	_list = ItemList.new()
	_list.name = "BlockedList"
	_list.position = Vector2(26, 90)
	_list.size = Vector2(240, 190)
	_list.select_mode = ItemList.SELECT_SINGLE
	_list.add_theme_color_override("font_color", INK)
	_list.item_selected.connect(func(_i: int) -> void: _refresh())
	add_child(_list)

	_delete_btn = Button.new()
	_delete_btn.name = "Delete"
	_delete_btn.text = "Delete"
	_delete_btn.position = Vector2(111, 348)
	_delete_btn.size = Vector2(43, 20)
	_delete_btn.pressed.connect(delete_selected)
	add_child(_delete_btn)

	_close_btn = Button.new()
	_close_btn.name = "Close"
	_close_btn.text = "Close"
	_close_btn.position = Vector2(105, 380)
	_close_btn.size = Vector2(56, 20)
	_close_btn.pressed.connect(close)
	add_child(_close_btn)

	var corner := Button.new()
	corner.name = "CornerClose"
	corner.position = Vector2(215, 24)
	corner.size = Vector2(18, 18)
	corner.pressed.connect(close)
	add_child(corner)


## True when `name` is already on the list (exact match, as the Go client compares the Big5 bytes).
func is_blocked(name: String) -> bool:
	return names.has(name)


## Adds a trimmed name. Returns false for empty, duplicate or over-long names.
func add_name(raw: String) -> bool:
	var name := raw.strip_edges()
	if name == "" or name.length() > MAX_NAME or is_blocked(name):
		return false
	names.append(name)
	_editor.clear()
	save_names()
	_refresh()
	list_changed.emit()
	return true


## Removes the selected name. Returns false when nothing is selected.
func delete_selected() -> bool:
	var selected := _list.get_selected_items()
	if selected.is_empty():
		return false
	var index: int = selected[0]
	if index < 0 or index >= names.size():
		return false
	names.remove_at(index)
	save_names()
	_refresh()
	list_changed.emit()
	return true


func _refresh() -> void:
	if _list == null:
		return
	_list.clear()
	for n in names:
		_list.add_item(n)
	_delete_btn.disabled = _list.get_selected_items().is_empty()


func load_names() -> void:
	names.clear()
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		for v in parsed:
			if v is String and (v as String) != "":
				names.append(v)


func save_names() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(names))
	f.close()


func open() -> void:
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	closed.emit()
