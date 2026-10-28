class_name ItemTooltip
extends PanelContainer

const ItemDatabase = preload("res://scripts/database/item_database.gd")

## Authentic Wonderland Online Inventory Item Hover Tooltip.
## Displays item name, level requirement, equipment type, stats (ATK, DEF, MATK, MDEF, SPD, HP, SP),
## durability, and authentic description with classic light blue parchment styling.

var _title_label: Label = null
var _type_label: Label = null
var _stats_container: VBoxContainer = null
var _durability_label: Label = null
var _separator: HSeparator = null
var _desc_label: Label = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100 # Render above all floating windows and docks
	visible = false
	_build_ui()

func _build_ui() -> void:
	# Authentic WLO Tooltip Style: Soft Ice-Blue Parchment with Deep Slate Border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.87, 0.92, 1.0, 0.96)
	style.border_color = Color(0.12, 0.24, 0.42, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 3)
	add_child(vbox)
	
	# 1. Item Name Header
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.add_theme_color_override("font_color", Color(0.05, 0.15, 0.32, 1.0))
	_title_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_title_label)
	
	# 2. Type & Level Requirement
	_type_label = Label.new()
	_type_label.name = "TypeLabel"
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_label.add_theme_color_override("font_color", Color(0.32, 0.42, 0.58, 1.0))
	_type_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_type_label)
	
	# 3. Stats List Container
	_stats_container = VBoxContainer.new()
	_stats_container.name = "StatsContainer"
	_stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_container.add_theme_constant_override("separation", 1)
	vbox.add_child(_stats_container)
	
	# 4. Durability Label
	_durability_label = Label.new()
	_durability_label.name = "DurabilityLabel"
	_durability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_durability_label.add_theme_color_override("font_color", Color(0.25, 0.35, 0.45, 1.0))
	_durability_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_durability_label)
	
	# 5. Separator
	_separator = HSeparator.new()
	_separator.name = "Separator"
	_separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.65, 0.75, 0.88, 0.8)
	sep_style.thickness = 1
	_separator.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(_separator)
	
	# 6. Description Text
	_desc_label = Label.new()
	_desc_label.name = "DescLabel"
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(180, 0)
	_desc_label.add_theme_color_override("font_color", Color(0.18, 0.22, 0.28, 1.0))
	_desc_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_desc_label)

## Configures the tooltip content using item record dictionary or database record
func display_item(item_data: Dictionary) -> void:
	if item_data.is_empty() or int(item_data.get("id", 0)) <= 0:
		visible = false
		return
	
	var item_id: int = int(item_data.get("id", 0))
	var iname: String = str(item_data.get("name", "Unknown Item"))
	var desc: String = str(item_data.get("description", ""))
	var lvl: int = int(item_data.get("level", 0))
	var dur: int = int(item_data.get("durability", 50))
	var max_dur: int = int(item_data.get("max_durability", 50))
	var equip_pos: int = int(item_data.get("equip_pos", 0))
	var rank_val: int = int(item_data.get("rank", 0))
	var mat_name: String = str(item_data.get("material_name", ""))
	if mat_name.is_empty() and item_data.has("materials") and item_data["materials"] is Array:
		var mats_arr: Array = item_data["materials"]
		if not mats_arr.is_empty():
			mat_name = ", ".join(mats_arr)
	
	# Check GameDatabase for full metadata if missing
	var game_db: Node = null
	var main_loop = Engine.get_main_loop()
	if main_loop and "root" in main_loop and main_loop.root:
		game_db = main_loop.root.get_node_or_null("/root/GameDatabase")
	var rec = null
	if game_db and "items" in game_db and game_db.items:
		rec = game_db.items.get_item(item_id)
		if rec:
			if iname.is_empty() or iname == "Unknown Item":
				iname = rec.name
			if desc.is_empty():
				desc = rec.description
			if lvl == 0:
				lvl = rec.level
			if equip_pos == 0:
				equip_pos = rec.equip_pos
			if rank_val == 0:
				rank_val = rec.get_rank()
			if mat_name.is_empty():
				mat_name = rec.get_material_name()
	
	if mat_name.is_empty():
		mat_name = ItemDatabase.resolve_material_name_from_info(iname, desc, equip_pos, item_id)
	if rank_val == 0:
		if equip_pos > 0 and lvl > 0:
			rank_val = maxi(1, int(lvl / 2))
		elif lvl > 0:
			rank_val = lvl
		else:
			rank_val = 1
	
	_title_label.text = iname
	
	# Equipment Type / Level / Material / Rank
	var type_str := ""
	if rec and rec.has_method("get_equip_slot_name"):
		type_str = rec.get_equip_slot_name()
	elif equip_pos > 0:
		match equip_pos:
			1: type_str = "Headgear"
			2: type_str = "Clothes"
			3: type_str = "Weapon"
			4: type_str = "Wrist / Shield"
			5: type_str = "Shoes"
			6: type_str = "Accessory"
			_: type_str = "Equipment"
	else:
		type_str = "Consumable / Item"
	
	if lvl > 0:
		if not mat_name.is_empty() and rank_val > 0:
			_type_label.text = "%s (Req. Lv: %d) | %s (Rank %d)" % [type_str, lvl, mat_name, rank_val]
		elif not mat_name.is_empty():
			_type_label.text = "%s (Req. Lv: %d) | %s" % [type_str, lvl, mat_name]
		elif rank_val > 0:
			_type_label.text = "%s (Req. Lv: %d) | Rank %d" % [type_str, lvl, rank_val]
		else:
			_type_label.text = "%s (Req. Lv: %d)" % [type_str, lvl]
	else:
		if not mat_name.is_empty() and rank_val > 0:
			_type_label.text = "%s | %s (Rank %d)" % [type_str, mat_name, rank_val]
		elif not mat_name.is_empty():
			_type_label.text = "%s | %s" % [type_str, mat_name]
		elif rank_val > 0:
			_type_label.text = "%s (Rank %d)" % [type_str, rank_val]
		else:
			_type_label.text = type_str
	
	# Clear previous stats
	for child in _stats_container.get_children():
		child.queue_free()
	
	# Populate formatted stats
	var stats: Array[Dictionary] = []
	if rec and rec.has_method("get_formatted_stats"):
		stats = rec.get_formatted_stats()
	elif item_data.has("attributes") and item_data["attributes"] is Dictionary:
		for k in item_data["attributes"]:
			var v = item_data["attributes"][k]
			var delta := int(v)
			stats.append({
				"name": str(k),
				"delta": delta,
				"text": "%s %s%d" % [str(k), "+" if delta >= 0 else "", delta],
				"is_positive": delta >= 0
			})
	else:
		if int(item_data.get("hp_restore", 0)) > 0:
			var hp_val: int = int(item_data["hp_restore"])
			stats.append({
				"name": "HP",
				"delta": hp_val,
				"text": "HP +%d" % hp_val,
				"is_positive": true
			})
		if int(item_data.get("sp_restore", 0)) > 0:
			var sp_val: int = int(item_data["sp_restore"])
			stats.append({
				"name": "SP",
				"delta": sp_val,
				"text": "SP +%d" % sp_val,
				"is_positive": true
			})
	
	for s in stats:
		var stat_lbl := Label.new()
		stat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat_lbl.text = s["text"]
		stat_lbl.add_theme_font_size_override("font_size", 11)
		if s["is_positive"]:
			# Royal Green for positive bonuses
			stat_lbl.add_theme_color_override("font_color", Color(0.06, 0.48, 0.16, 1.0))
		else:
			# Crimson for negative penalties
			stat_lbl.add_theme_color_override("font_color", Color(0.72, 0.12, 0.12, 1.0))
		_stats_container.add_child(stat_lbl)
	
	_stats_container.visible = not stats.is_empty()
	
	# Durability (displayed for equipment)
	if equip_pos > 0:
		_durability_label.text = "Durability: %d / %d" % [dur, max_dur]
		_durability_label.visible = true
	else:
		_durability_label.visible = false
	
	# Description
	if not desc.is_empty():
		_desc_label.text = desc
		_desc_label.visible = true
		_separator.visible = true
	else:
		_desc_label.visible = false
		_separator.visible = false
	
	visible = true
	reset_size()

## Positions the tooltip cleanly adjacent to the hovered slot
func position_at(slot_global_pos: Vector2, slot_size: Vector2) -> void:
	reset_size()
	var vp_size := Vector2(800, 600)
	if is_inside_tree():
		vp_size = get_viewport_rect().size
	var tooltip_size := size
	
	# Default: show to the left of inventory slot (as in authentic screenshot)
	var target_x: float = slot_global_pos.x - tooltip_size.x - 8.0
	if target_x < 8.0:
		# If off-screen to left, place to right of slot
		target_x = slot_global_pos.x + slot_size.x + 8.0
	
	var target_y: float = slot_global_pos.y
	if target_y + tooltip_size.y > vp_size.y - 8.0:
		target_y = vp_size.y - tooltip_size.y - 8.0
	if target_y < 8.0:
		target_y = 8.0
	
	global_position = Vector2(target_x, target_y)
