class_name NotebookWindow
extends Control

## The Notepad item of the real client opens the "Notebook": a small menu (Quest Log / Monster Book / Star Book).
## Monster Book = "collection book" listing every monster the character has met with its stats; Star Book = a full
## screen night sky of constellations. Layouts measured from live captures (docs/re/ui_windows.md).

signal quest_log_requested
signal closed

const SkinButtonScript = preload("res://scripts/ui/hud/skin_button.gd")
const PillScript = preload("res://scripts/ui/hud/pill_button.gd")
const SAVE_PATH: String = "user://monster_book.json"
const MENU_SKIN: String = "res://assets/menu/Skins/white/Form_NoteBook.bmp"
const BOOK_SKIN: String = "res://assets/menu/Skins/white/Form_Cellection_1.bmp"
const ROWS_PER_PAGE: int = 10
const NAME_LIMIT: int = 12
const CONSTELLATIONS: int = 28
const ELEMENT_ICON_FORMAT: String = "res://assets/hud/icon_element_%d.png"

var menu_panel: Control = null
var book_panel: Control = null
var sky_panel: Control = null
var book_rows: Array[Button] = []
var pager_label: Label = null
var detail_labels: Dictionary = {}
var detail_sprite: TextureRect = null
var detail_element: TextureRect = null

var _entries: Array[Dictionary] = [] # {"id": int, "name": String}
var _page: int = 0
var _selected: int = -1
var _constellation_buttons: Array[TextureButton] = []


func _ready() -> void:
	name = "NotebookWindow"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_entries()
	_build_menu()
	_build_book()
	_build_sky()
	close_all()


func open_menu() -> void:
	close_all()
	menu_panel.visible = true
	visible = true
	move_to_front()


func open_monster_book() -> void:
	close_all()
	_refresh_book()
	book_panel.visible = true
	visible = true
	move_to_front()


func open_star_book() -> void:
	close_all()
	sky_panel.visible = true
	visible = true
	move_to_front()


func close_all() -> void:
	for panel in [menu_panel, book_panel, sky_panel]:
		if panel:
			panel.visible = false
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


# ---------------------------------------------------------------- monster collection

## Records a monster the character has met (called after a battle). Returns true when it is new.
func register_monster(template_id: int, monster_name: String) -> bool:
	for entry in _entries:
		if int(entry["id"]) == template_id:
			return false
	_entries.append({"id": template_id, "name": monster_name})
	_save_entries()
	if book_panel and book_panel.visible:
		_refresh_book()
	return true


func entry_count() -> int:
	return _entries.size()


func _load_entries() -> void:
	_entries.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is Array:
		for item in data:
			if item is Dictionary and item.has("id"):
				_entries.append({"id": int(item["id"]), "name": str(item.get("name", ""))})


func _save_entries() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_entries))


# ---------------------------------------------------------------- menu

func _skin_panel(path: String, panel_name: String) -> Control:
	var panel := Control.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var tex := SkinButtonScript.keyed_texture(path)
	if tex:
		var bg := TextureRect.new()
		bg.name = "Background"
		bg.texture = tex
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bg)
		panel.size = tex.get_size()
	add_child(panel)
	return panel


func _center(panel: Control) -> void:
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(800, 600)
	panel.position = ((viewport_size - panel.size) / 2.0).floor()


func _close_button(panel: Control, offset_from_right: float = 40.0) -> Button:
	var btn := Button.new()
	btn.name = "CloseX"
	WindowCloseButton.apply(btn, panel.size.x)
	btn.pressed.connect(close_all)
	panel.add_child(btn)
	return btn


func _build_menu() -> void:
	menu_panel = _skin_panel(MENU_SKIN, "NotebookMenu")
	_center(menu_panel)
	_close_button(menu_panel)
	var specs := [["MissionBook", Vector2(63, 52), "quest"], ["MonsterBook", Vector2(63, 94), "monster"], ["StarBook", Vector2(63, 136), "star"]]
	for spec in specs:
		var btn: TextureButton = SkinButtonScript.make(spec[0], spec[1], "Btn_%s" % spec[0])
		var which: String = spec[2]
		btn.pressed.connect(func() -> void: _on_menu_choice(which))
		menu_panel.add_child(btn)
	var close_pill := PillScript.make("Close", Vector2(83, 191), Vector2(56, 18))
	close_pill.name = "MenuClose"
	close_pill.pressed.connect(close_all)
	menu_panel.add_child(close_pill)


func _on_menu_choice(which: String) -> void:
	match which:
		"quest":
			close_all()
			quest_log_requested.emit()
		"monster":
			open_monster_book()
		"star":
			open_star_book()


# ---------------------------------------------------------------- collection book

func _build_book() -> void:
	book_panel = _skin_panel(BOOK_SKIN, "CollectionBook")
	_center(book_panel)
	_close_button(book_panel)
	for i in ROWS_PER_PAGE:
		var row := Button.new()
		row.name = "BookRow_%d" % i
		row.flat = true
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.clip_text = true
		row.position = Vector2(17, 44 + i * 24.0)
		row.size = Vector2(193, 22)
		row.add_theme_font_size_override("font_size", 10)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			row.add_theme_color_override(color_name, Color(0.08, 0.1, 0.2, 1.0))
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(1.0, 0.8, 0.62, 0.7)
		var pad := StyleBoxEmpty.new()
		pad.content_margin_left = 4.0
		pad.content_margin_top = 4.0
		hover.content_margin_left = 4.0
		hover.content_margin_top = 4.0
		for state in ["normal", "pressed", "focus", "disabled"]:
			row.add_theme_stylebox_override(state, pad)
		row.add_theme_stylebox_override("hover", hover)
		var row_index: int = i
		row.pressed.connect(func() -> void: _select_row(row_index))
		book_panel.add_child(row)
		book_rows.append(row)
	var prev := SkinButtonScript.make("ArrowL_4", Vector2(70, 286), "BookPrev")
	prev.pressed.connect(func() -> void: _turn_page(-1))
	book_panel.add_child(prev)
	var next := SkinButtonScript.make("ArrowR_4", Vector2(146, 286), "BookNext")
	next.pressed.connect(func() -> void: _turn_page(1))
	book_panel.add_child(next)
	pager_label = Label.new()
	pager_label.name = "BookPager"
	pager_label.position = Vector2(88, 289)
	pager_label.size = Vector2(58, 18)
	pager_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pager_label.add_theme_font_size_override("font_size", 10)
	pager_label.add_theme_color_override("font_color", Color(0.1, 0.16, 0.62, 1.0))
	book_panel.add_child(pager_label)
	var dark := Color(0.08, 0.1, 0.2)
	var captions := {
		"name": [Vector2(229, 66), 10, dark],
		"level": [Vector2(372, 62), 10, dark],
		"hp": [Vector2(247, 86), 10, dark],
		"sp": [Vector2(322, 86), 10, dark],
		"str": [Vector2(252, 106), 10, dark],
		"con": [Vector2(252, 125), 10, dark],
		"int": [Vector2(252, 144), 10, dark],
		"wis": [Vector2(252, 163), 10, dark],
		"agi": [Vector2(252, 182), 10, dark],
	}
	for key in captions.keys():
		var spec: Array = captions[key]
		var label := Label.new()
		label.name = "Detail_%s" % key
		label.position = spec[0]
		label.size = Vector2(80, 16)
		label.add_theme_font_size_override("font_size", spec[1])
		label.add_theme_color_override("font_color", spec[2])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		book_panel.add_child(label)
		detail_labels[key] = label
	detail_sprite = TextureRect.new()
	detail_sprite.name = "DetailSprite"
	detail_sprite.position = Vector2(300, 160)
	detail_sprite.size = Vector2(110, 90)
	detail_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book_panel.add_child(detail_sprite)
	detail_element = TextureRect.new()
	detail_element.name = "DetailElement"
	detail_element.position = Vector2(413, 56)
	detail_element.size = Vector2(22, 22)
	detail_element.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_element.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book_panel.add_child(detail_element)
	var close_pill := PillScript.make("Close", Vector2(202, 323), Vector2(56, 18))
	close_pill.name = "BookClose"
	close_pill.pressed.connect(close_all)
	book_panel.add_child(close_pill)


func _page_count() -> int:
	return maxi(1, ceili(float(_entries.size()) / ROWS_PER_PAGE))


func _turn_page(step: int) -> void:
	_page = clampi(_page + step, 0, _page_count() - 1)
	_refresh_book()


func _select_row(row_index: int) -> void:
	var entry_index := _page * ROWS_PER_PAGE + row_index
	if entry_index >= _entries.size():
		return
	_selected = entry_index
	_refresh_book()


func _short_name(full: String) -> String:
	return full.substr(0, NAME_LIMIT) # the original cuts names at 12 characters


func _refresh_book() -> void:
	pager_label.text = "%d/%d" % [_page + 1, _page_count()]
	for i in ROWS_PER_PAGE:
		var entry_index := _page * ROWS_PER_PAGE + i
		var row := book_rows[i]
		row.text = _short_name(str(_entries[entry_index]["name"])) if entry_index < _entries.size() else ""
	_fill_detail()


func _fill_detail() -> void:
	for key in detail_labels.keys():
		detail_labels[key].text = ""
	detail_sprite.texture = null
	detail_element.texture = null
	if _selected < 0 or _selected >= _entries.size():
		_set_caption_texts(null)
		return
	var game_db: Node = null
	if Engine.get_main_loop() is SceneTree:
		game_db = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameDatabase")
	var rec = game_db.npcs.get_npc(int(_entries[_selected]["id"])) if (game_db != null and "npcs" in game_db) else null
	_set_caption_texts(rec)
	if rec == null:
		return
	detail_labels["name"].text = str(rec.name).strip_edges()
	detail_labels["level"].text = "%d" % int(rec.level)
	detail_labels["hp"].text = "%d" % int(rec.max_hp)
	detail_labels["sp"].text = "%d" % int(rec.max_sp)
	for stat in ["str", "con", "int", "wis", "agi"]:
		detail_labels[stat].text = "%d" % int(rec.stats.get(stat, 0))
	var element_path: String = ELEMENT_ICON_FORMAT % clampi(int(rec.element), 0, 4)
	if int(rec.element) > 0 and ResourceLoader.exists(element_path):
		detail_element.texture = load(element_path) as Texture2D
	var loader: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("ArchiveLoader") if Engine.get_main_loop() is SceneTree else null
	if loader and loader.has_method("get_npc_texture"):
		detail_sprite.texture = loader.get_npc_texture(int(rec.sprite_id), 3)


## The baked skin holds the captions (LV, HP, SP, STR ...); nothing to draw here, the hook keeps tests simple.
func _set_caption_texts(_rec) -> void:
	pass


# ---------------------------------------------------------------- star book

func _build_sky() -> void:
	sky_panel = Control.new()
	sky_panel.name = "StarSky"
	sky_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.0, 0.0, 0.02, 1.0)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_panel.add_child(backdrop)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261028
	for i in 700:
		var star := ColorRect.new()
		var bright: float = rng.randf_range(0.35, 1.0)
		star.color = Color(bright, bright, minf(1.0, bright + 0.15), 1.0)
		star.size = Vector2.ONE * (2.0 if rng.randf() < 0.08 else 1.0)
		star.position = Vector2(rng.randf_range(0, 800), rng.randf_range(0, 600))
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(star)
	# The constellation pictures are scattered over the sky; each sheet stacks a plain and a labelled frame.
	var slot_rng := RandomNumberGenerator.new()
	slot_rng.seed = 77
	for n in range(1, CONSTELLATIONS + 1):
		var path := "res://assets/menu/Skins/default/Star_%d.bmp" % n
		if not ResourceLoader.exists(path):
			continue
		var tex := SkinButtonScript.keyed_texture(path)
		if tex == null:
			continue
		var half := Vector2(tex.get_width(), floorf(tex.get_height() / 2.0))
		var btn := TextureButton.new()
		btn.name = "Constellation_%d" % n
		var plain := AtlasTexture.new()
		plain.atlas = tex
		plain.region = Rect2(Vector2.ZERO, half)
		var labelled := AtlasTexture.new()
		labelled.atlas = tex
		labelled.region = Rect2(Vector2(0, half.y), half)
		btn.texture_normal = plain
		btn.texture_hover = labelled
		btn.size = half * 0.42
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.position = Vector2(((n - 1) % 7) * 112.0 + 12.0, floorf((n - 1) / 7.0) * 140.0 + 18.0)
		sky_panel.add_child(btn)
		_constellation_buttons.append(btn)
	var close_btn := Button.new()
	close_btn.name = "SkyClose"
	close_btn.flat = true
	close_btn.text = ""
	close_btn.position = Vector2(776, 6)
	close_btn.size = Vector2(22, 22)
	close_btn.pressed.connect(close_all)
	sky_panel.add_child(close_btn)
	add_child(sky_panel)
