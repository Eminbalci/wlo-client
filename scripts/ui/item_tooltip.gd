class_name ItemTooltip
extends PanelContainer

const ItemDatabase = preload("res://scripts/database/item_database.gd")

## Item hover tooltip rebuilt from aLogin.exe 0x2a2058 (see docs/re/item_window_and_tooltip.md).
## The real client fills a TStringList with one line per entry, in this order:
##   "[ Name+forge ]", "<Non-tradeable>", stat lines ("DEF: +1 "), "Type: ...", "Rank: N",
##   "LV Req: N", potion "left/total", "Time: ...", "Uses: N ", "Content:...", "State: Good",
##   "Socket: ...", "Model: ...", description.
## Every line is drawn in RGB565 0xFFE0 (yellow); only the durability word can be 0xF800 (red).
## Window is 0xC4 = 196 px wide, 20 px per line, text inset 10 px.

const TOOLTIP_WIDTH: int = 196
const LINE_HEIGHT: int = 20
const TEXT_INSET: int = 10

var _title_label: Label = null
var _lines_box: VBoxContainer = null
var _stats_container: VBoxContainer = null # holds the stat lines ("DEF: +1 ")
var _desc_label: Label = null
var _lines: Array[Dictionary] = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	visible = false
	_build_ui()

func _build_ui() -> void:
	# Background/border colours are NOT recovered from the binary (open question); a dark translucent
	# panel is used so the authentic yellow text stays readable.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.2, 0.85)
	style.border_color = Color(0.45, 0.55, 0.8, 1.0)
	style.set_border_width_all(1)
	style.content_margin_left = TEXT_INSET
	style.content_margin_right = TEXT_INSET
	style.content_margin_top = TEXT_INSET
	style.content_margin_bottom = TEXT_INSET
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(TOOLTIP_WIDTH, 0)

	_lines_box = VBoxContainer.new()
	_lines_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines_box.add_theme_constant_override("separation", 0)
	add_child(_lines_box)

	_title_label = _make_line_label("TitleLabel")
	_lines_box.add_child(_title_label)
	_stats_container = VBoxContainer.new()
	_stats_container.name = "StatsContainer"
	_stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_container.add_theme_constant_override("separation", 0)
	_lines_box.add_child(_stats_container)
	_desc_label = _make_line_label("DescLabel")
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(TOOLTIP_WIDTH - 2 * TEXT_INSET, LINE_HEIGHT)
	_lines_box.add_child(_desc_label)

func _make_line_label(lbl_name: String) -> Label:
	var lbl := Label.new()
	lbl.name = lbl_name
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.custom_minimum_size = Vector2(0, LINE_HEIGHT)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", ItemDatabase.TOOLTIP_TEXT_COLOR)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl

## Returns the plain text of the lines currently shown (handy for tests / logs).
func get_lines_text() -> PackedStringArray:
	var out := PackedStringArray()
	for l in _lines:
		out.append(str(l["text"]))
	return out

## Resolves an ItemRecord for the given dictionary: the GameDatabase record when available,
## otherwise a transient record built from the dictionary fields.
func _resolve_record(item_data: Dictionary) -> ItemDatabase.ItemRecord:
	var item_id: int = int(item_data.get("id", 0))
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root:
		var game_db: Node = main_loop.root.get_node_or_null("/root/GameDatabase")
		if game_db and "items" in game_db and game_db.items:
			var rec = game_db.items.get_item(item_id)
			if rec:
				return rec
	var r := ItemDatabase.ItemRecord.new()
	r.id = item_id
	r.name = str(item_data.get("name", "Unknown Item"))
	r.description = str(item_data.get("description", item_data.get("desc", "")))
	r.level = int(item_data.get("level", 0))
	r.equip_pos = int(item_data.get("equip_pos", 0))
	r.item_type = int(item_data.get("item_type", 0))
	r.rank = int(item_data.get("rank", 0))
	r.has_dat_record = item_data.has("rank")
	r.flags = int(item_data.get("flags", 0))
	var codes := {"hp": 25, "sp": 26, "exp": 36, "amity": 64, "maxhp": 207, "maxsp": 208,
		"atk": 210, "def": 211, "spd": 214, "matk": 215, "mdef": 216}
	var types: Array[int] = []
	var values: Array[int] = []
	var attrs = item_data.get("attributes", item_data.get("stats", {}))
	if attrs is Dictionary:
		for k in attrs:
			var code: int = int(codes.get(str(k).to_lower(), 0))
			if code > 0:
				types.append(code)
				values.append(100 + int(attrs[k]))
	if types.is_empty():
		if int(item_data.get("hp_restore", 0)) > 0:
			types.append(25)
			values.append(100 + int(item_data["hp_restore"]))
		if int(item_data.get("sp_restore", 0)) > 0:
			types.append(26)
			values.append(100 + int(item_data["sp_restore"]))
	r.status_types = types
	r.status_values = values
	return r

## Configures the tooltip from an inventory/equipment item dictionary.
## Optional instance keys: forge, wear, used, socket_name, model_name, content_name, time_left_hours, compound.
func display_item(item_data: Dictionary) -> void:
	if item_data.is_empty() or int(item_data.get("id", 0)) <= 0:
		visible = false
		return
	var rec := _resolve_record(item_data)
	var name_override := str(item_data.get("name", ""))
	if rec.name.is_empty() and not name_override.is_empty():
		rec.name = name_override
	_lines = ItemDatabase.build_tooltip_lines(rec, item_data)

	for child in _lines_box.get_children():
		if child != _title_label and child != _desc_label and child != _stats_container:
			_lines_box.remove_child(child)
			child.queue_free()

	var has_desc: bool = not bool(item_data.get("compound", false)) and not rec.description.is_empty()
	var body_end: int = _lines.size() - (1 if has_desc else 0)
	_title_label.text = str(_lines[0]["text"]) if not _lines.is_empty() else rec.name
	_lines_box.move_child(_title_label, 0)
	for child in _stats_container.get_children():
		_stats_container.remove_child(child)
		child.queue_free()
	for i in range(1, body_end):
		var line: Dictionary = _lines[i]
		var lbl := _make_line_label("Line%d" % i)
		if line.has("state_word"):
			# Client draws "State: " in yellow, then the word in the state colour.
			var row := HBoxContainer.new()
			row.name = "StateRow"
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lbl.text = "State: "
			row.add_child(lbl)
			var word := _make_line_label("StateWord")
			word.text = str(line["state_word"])
			word.add_theme_color_override("font_color", line["state_color"])
			row.add_child(word)
			_lines_box.add_child(row)
		elif line.get("stat", false):
			lbl.text = str(line["text"])
			_stats_container.add_child(lbl)
		else:
			lbl.text = str(line["text"])
			lbl.add_theme_color_override("font_color", line["color"])
			_lines_box.add_child(lbl)
	_stats_container.visible = _stats_container.get_child_count() > 0
	var stats_at: int = 1
	for i in range(_lines.size()):
		if _lines[i].get("stat", false):
			stats_at = i
			break
		if i > 0 and str(_lines[i]["text"]).begins_with("Type: "):
			stats_at = i
			break
	_lines_box.move_child(_stats_container, stats_at)
	_desc_label.visible = has_desc
	_desc_label.text = rec.description if has_desc else ""
	_lines_box.move_child(_desc_label, _lines_box.get_child_count() - 1)
	visible = true
	reset_size()

## Client placement (0x2a4825..0x2a48c9): x = slot right + 2; if the box would pass x = 800 it goes
## to slot left - width - 2; y = slot top, pulled up so the bottom stays inside y = 600.
func position_at(slot_global_pos: Vector2, slot_size: Vector2) -> void:
	reset_size()
	var vp_size := Vector2(800, 600)
	if is_inside_tree():
		vp_size = get_viewport_rect().size
	var target_x: float = slot_global_pos.x + slot_size.x + 2.0
	if target_x + size.x > vp_size.x:
		target_x = slot_global_pos.x - size.x - 2.0
	var target_y: float = slot_global_pos.y
	if target_y + size.y > vp_size.y:
		target_y = vp_size.y - size.y
	global_position = Vector2(maxf(0.0, target_x), maxf(0.0, target_y))
