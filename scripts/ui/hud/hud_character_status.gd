class_name HUDCharacterStatus
extends RefCounted

## Dedicated controller encapsulating character status labels, equipment sockets,
## drag-and-drop equipment swapping, paper doll composite textures, and combat stats calculation.

const SkinButtonScript = preload("res://scripts/ui/hud/skin_button.gd")
const FormulaData = preload("res://scripts/database/formula_data.gd")
const ELEMENT_ICON_FORMAT: String = "res://assets/hud/icon_element_%d.png"
const ELEMENT_IDS: Dictionary = {"earth": 1, "water": 2, "fire": 3, "wind": 4}

var hud: Control = null
var player: Node2D = null
var char_window: Control = null
var char_paper_doll: TextureRect = null
var item_tooltip: PanelContainer = null

# Character Window Stat Labels
var stat_name: Label = null
var stat_level: Label = null
var stat_element: Label = null
var stat_left_hp: Label = null
var stat_left_sp: Label = null
var stat_left_exp: Label = null
var stat_atk: Label = null
var stat_def: Label = null
var stat_matk: Label = null
var stat_mdef: Label = null
var stat_spd: Label = null
var stat_str: Label = null
var stat_con: Label = null
var stat_int: Label = null
var stat_wis: Label = null
var stat_agi: Label = null
var stat_free: Label = null

# Stat Point Allocation & Current Character State
var current_name: String = "Daniel"
var current_level: int = 1
var current_hp: int = 320
var current_max_hp: int = 320
var current_sp: int = 150
var current_max_sp: int = 150
var current_exp: int = 0
var current_max_exp: int = 10000

var current_str: int = 10
var current_con: int = 10
var current_int: int = 6
var current_wis: int = 6
var current_agi: int = 18
var current_free: int = 0
## Job byte of the real client (0x1f9c); 0 = none. Jobs 1..6 give +10% to one combat stat.
var current_job: int = 0

var stat_add_buttons: Dictionary = {} # String (stat_name) -> Button

# Header overlays seen in the real client's item window (name row, LV, potential, arrows, Close)
var header_name: Label = null
var header_level: Label = null
var header_potential: Label = null
var current_potential: int = 0
var header_element: TextureRect = null
var header_buttons: Dictionary = {} # String -> TextureButton

var current_inventory_page: int = 0 # 0 = Page 1, 1 = Page 2
const TOTAL_INVENTORY_PAGES: int = 2

var shoes_view_mode: int = 0 # 0 = Normal Footwear/Boots, 1 = Riding Shoes / Mount Gear

signal inventory_page_changed(page_idx: int)
signal shoes_view_mode_changed(mode_idx: int)

# Equipment Sockets and Data
var equipment_slots: Dictionary = {} # socket_name (String) -> Button
var equipment_data: Dictionary = {}  # socket_name (String) -> Dictionary
var current_equip_layers: Dictionary = {}

# Base Combat Stats
var base_atk: int = 26
var base_def: int = 25
var base_matk: int = 15
var base_mdef: int = 14
var base_spd: int = 21

var current_role_id: int = 6
var current_element: String = "Fire"

# Paper Doll 3/4 Isometric Stance & Breathing Animation (Heading SOUTH_WEST: frame 44..47)
var _paper_doll_frames: Array = []
var _paper_doll_timer: float = 0.0
var _paper_doll_heading: int = 3 # IsometricMath.Heading.SOUTH_WEST
var _paper_doll_base_frame: int = 44 # 32 + 3 * 4 = 44

## Initializes and wires up the character status sub-controller
func setup(p_hud: Control, nodes: Dictionary) -> void:
	hud = p_hud
	char_window = nodes.get("char_window", null) as Control
	char_paper_doll = nodes.get("char_paper_doll", null) as TextureRect
	item_tooltip = nodes.get("item_tooltip", null) as PanelContainer

	stat_name = nodes.get("stat_name", null) as Label
	stat_level = nodes.get("stat_level", null) as Label
	stat_element = nodes.get("stat_element", null) as Label
	stat_left_hp = nodes.get("stat_left_hp", null) as Label
	stat_left_sp = nodes.get("stat_left_sp", null) as Label
	stat_left_exp = nodes.get("stat_left_exp", null) as Label
	stat_atk = nodes.get("stat_atk", null) as Label
	stat_def = nodes.get("stat_def", null) as Label
	stat_matk = nodes.get("stat_matk", null) as Label
	stat_mdef = nodes.get("stat_mdef", null) as Label
	stat_spd = nodes.get("stat_spd", null) as Label
	stat_str = nodes.get("stat_str", null) as Label
	stat_con = nodes.get("stat_con", null) as Label
	stat_int = nodes.get("stat_int", null) as Label
	stat_wis = nodes.get("stat_wis", null) as Label
	stat_agi = nodes.get("stat_agi", null) as Label
	stat_free = nodes.get("stat_free", null) as Label

	# The real item window shows name, LV and element orb in its header (see docs/re/ui_windows.md);
	# those are drawn by _build_window_extras(), so the old floating labels stay hidden.
	if stat_name: stat_name.visible = false
	if stat_level: stat_level.visible = false
	if stat_element: stat_element.visible = false
	if char_paper_doll:
		char_paper_doll.position.y = 127.0
	if stat_free:
		stat_free.position = Vector2(142, 314)
		stat_free.size = Vector2(40, 14)

	_setup_equipment_sockets()
	_setup_stat_allocation_buttons()
	_build_window_extras()

## Controls that the real item window has on top of its baked skin, positioned from a live capture:
## header arrows beside the title, element orb + name + LV row, Potential button, arrows under the
## paper doll and the Close button at the bottom.
func _build_window_extras() -> void:
	if char_window == null or char_window.get_node_or_null("HeaderName") != null:
		return
	var dark := Color(0.12, 0.14, 0.26, 1.0)
	header_element = TextureRect.new()
	header_element.name = "HeaderElement"
	header_element.position = Vector2(30, 49)
	header_element.size = Vector2(20, 20)
	header_element.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_element.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_element.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_window.add_child(header_element)
	header_name = _make_header_label("HeaderName", Vector2(54, 51), Vector2(120, 16), 11, dark)
	header_level = _make_header_label("HeaderLevel", Vector2(21, 78), Vector2(60, 16), 12, Color(0.2, 0.26, 0.5, 1.0))
	header_potential = _make_header_label("HeaderPotential", Vector2(172, 80), Vector2(30, 16), 11, dark)
	header_potential.text = "0"
	var specs := [
		["TitlePrev", "ArrowL_4", Vector2(146, 21)],
		["TitleNext", "ArrowR_4", Vector2(221, 21)],
		["ShoesPrev", "ArrowL_1", Vector2(40, 237)],
		["ShoesNext", "ArrowR_1", Vector2(139, 237)],
		["Potential", "Potential_1", Vector2(126, 79)],
		["Close", "Close_1", Vector2(164, 413)],
	]
	for spec in specs:
		var btn: TextureButton = SkinButtonScript.make(spec[1], spec[2], "Header%s" % spec[0])
		char_window.add_child(btn)
		header_buttons[spec[0]] = btn
	header_buttons["Close"].pressed.connect(_on_header_close_pressed)
	if header_buttons.has("TitlePrev"):
		header_buttons["TitlePrev"].pressed.connect(_on_title_prev_pressed)
	if header_buttons.has("TitleNext"):
		header_buttons["TitleNext"].pressed.connect(_on_title_next_pressed)
	if header_buttons.has("ShoesPrev"):
		header_buttons["ShoesPrev"].pressed.connect(_on_shoes_toggle_pressed)
	if header_buttons.has("ShoesNext"):
		header_buttons["ShoesNext"].pressed.connect(_on_shoes_toggle_pressed)
	if header_buttons.has("Potential"):
		header_buttons["Potential"].pressed.connect(_on_potential_button_pressed)
	_refresh_header()


func _make_header_label(node_name: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = pos
	label.size = label_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	char_window.add_child(label)
	return label


func _refresh_header() -> void:
	if header_name == null:
		return
	header_name.text = current_name
	header_level.text = "LV %d" % current_level
	var element_id: int = int(ELEMENT_IDS.get(current_element.to_lower(), 0))
	var path: String = ELEMENT_ICON_FORMAT % element_id
	header_element.texture = load(path) as Texture2D if element_id > 0 and ResourceLoader.exists(path) else null


func _on_header_close_pressed() -> void:
	if hud != null and hud.has_method("toggle_inventory") and char_window != null and char_window.visible:
		hud.toggle_inventory()
	elif char_window != null:
		char_window.hide()

func _on_title_prev_pressed() -> void:
	if current_inventory_page > 0:
		set_inventory_page(current_inventory_page - 1)

func _on_title_next_pressed() -> void:
	if current_inventory_page < TOTAL_INVENTORY_PAGES - 1:
		set_inventory_page(current_inventory_page + 1)

func set_inventory_page(page: int) -> void:
	current_inventory_page = clampi(page, 0, TOTAL_INVENTORY_PAGES - 1)
	if hud and "inventory_ctrl" in hud and hud.inventory_ctrl:
		if hud.inventory_ctrl.has_method("set_page"):
			hud.inventory_ctrl.set_page(current_inventory_page)
	inventory_page_changed.emit(current_inventory_page)
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", "Switched to inventory page %d/%d." % [current_inventory_page + 1, TOTAL_INVENTORY_PAGES], "System")

func _on_shoes_toggle_pressed() -> void:
	shoes_view_mode = 1 if shoes_view_mode == 0 else 0
	shoes_view_mode_changed.emit(shoes_view_mode)
	var shoes_btn = char_window.get_node_or_null("Slot_shoes") as Button if char_window else null
	if shoes_btn:
		if shoes_view_mode == 1:
			shoes_btn.tooltip_text = "Riding Shoes / Mount Gear Slot"
		else:
			shoes_btn.tooltip_text = "Shoes Slot (Boots)"
	if hud and hud.has_method("add_chat_message"):
		var mode_name: String = "Riding / Mount Gear" if shoes_view_mode == 1 else "Normal Footwear"
		hud.add_chat_message("System", "Shoes view switched to: %s." % mode_name, "System")

func _on_potential_button_pressed() -> void:
	if hud and hud.has_method("open_potential"):
		hud.open_potential()
	elif hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", "Potential System: Current Potential Level %d." % current_potential, "System")


## Configures the 6 authentic equipment sockets around the paper doll
func _setup_equipment_sockets() -> void:
	if not char_window:
		return

	var sockets: Array = [
		{"name": "head", "pos": Vector2(83, 84), "tip": "Head Slot (Hat/Helmet)"},
		{"name": "weapon", "pos": Vector2(23, 124), "tip": "Hand / Weapon Slot"},
		{"name": "wrist", "pos": Vector2(146, 124), "tip": "Arm / Wrist Slot"},
		{"name": "special", "pos": Vector2(23, 184), "tip": "Special Slot (Ring/Accessory)"},
		{"name": "body", "pos": Vector2(146, 184), "tip": "Body Slot (Clothes/Armor)"},
		{"name": "shoes", "pos": Vector2(83, 222), "tip": "Shoes Slot (Boots)"},
	]

	for sock in sockets:
		var sname: String = sock["name"]
		var s_pos: Vector2 = sock["pos"]
		var s_tip: String = sock.get("tip", sname.capitalize() + " Slot")

		var btn: Button = char_window.get_node_or_null("Slot_" + sname) as Button
		if not btn:
			var btn_script = load("res://scripts/ui/equipment_socket_button.gd")
			if btn_script:
				btn = Button.new()
				btn.set_script(btn_script)
			else:
				btn = Button.new()
			btn.name = "Slot_" + sname
			char_window.add_child(btn)

		if "hud_ref" in btn:
			btn.hud_ref = hud
		if "socket_name" in btn:
			btn.socket_name = sname

		btn.position = s_pos
		btn.size = Vector2(34, 34)
		btn.custom_minimum_size = Vector2(34, 34)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = s_tip

		var icon: TextureRect = btn.get_node_or_null("Icon") as TextureRect
		if not icon:
			icon = TextureRect.new()
			icon.name = "Icon"
			btn.add_child(icon)
		icon.position = Vector2(1, 1)
		icon.size = Vector2(32, 32)
		icon.z_index = 2
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		equipment_slots[sname] = btn

	# Aliases
	if equipment_slots.has("weapon"):
		equipment_slots["hand"] = equipment_slots["weapon"]
	if equipment_slots.has("wrist"):
		equipment_slots["arm"] = equipment_slots["wrist"]
	if equipment_slots.has("shoes"):
		equipment_slots["foot"] = equipment_slots["shoes"]
		equipment_slots["feet"] = equipment_slots["shoes"]
	if equipment_slots.has("body"):
		equipment_slots["clothes"] = equipment_slots["body"]
		equipment_slots["armor"] = equipment_slots["body"]
	if equipment_slots.has("head"):
		equipment_slots["cap"] = equipment_slots["head"]
		equipment_slots["helmet"] = equipment_slots["head"]

	var body_icon: int = _resolve_item_icon_id(21003)
	if body_icon <= 0: body_icon = 1096
	var shoes_icon: int = _resolve_item_icon_id(24003)
	if shoes_icon <= 0: shoes_icon = 1095
	var wep_icon: int = _resolve_item_icon_id(11033)
	if wep_icon <= 0: wep_icon = 2466

	var w_prefix := "004" if current_role_id == 6 else ("003" if current_role_id == 2 else "002")
	var w_jma := w_prefix + "w.jma"
	var w_jmp := w_prefix.substr(2, 1) + "040.jmp"
	equipment_data["body"] = _create_item_record(21003, body_icon, 1, "Harness Pants", "DEF +2", "body", w_prefix + "e.jma", w_prefix.substr(2, 1) + "301.jmp", {"def": 2})
	equipment_data["shoes"] = _create_item_record(24003, shoes_icon, 1, "Pink Shoes", "DEF +1, SPD +1", "shoes", w_prefix + "s.jma", w_prefix.substr(2, 1) + "401.jmp", {"def": 1, "spd": 1})
	equipment_data["weapon"] = _create_item_record(11033, wep_icon, 1, "Iron Sword", "ATK +8", "weapon", w_jma, w_jmp, {"atk": 8})
	equipment_data.erase("head")
	equipment_data.erase("wrist")
	equipment_data.erase("special")

	current_equip_layers = {
		"clothes": {"jma": w_prefix + "e.jma", "jmp": w_prefix.substr(2, 1) + "301.jmp"},
		"body": {"jma": w_prefix + "e.jma", "jmp": w_prefix.substr(2, 1) + "301.jmp"},
		"shoes": {"jma": w_prefix + "s.jma", "jmp": w_prefix.substr(2, 1) + "401.jmp"},
		"weapon": {"jma": w_jma, "jmp": w_jmp},
		"hand": {"jma": w_jma, "jmp": w_jmp},
	}

	_update_equipment_socket_icons()
	update_character_paper_doll(current_equip_layers)
	_update_combat_stats()

## Applies full character data dictionary and synchronizes player stats, equipment, and paper doll
func apply_character_data(char_data: Dictionary) -> void:
	if char_data.is_empty():
		return

	var r_id: int = int(char_data.get("role_id", current_role_id))
	var c_name: String = str(char_data.get("name", "Betty"))
	var c_level: int = int(char_data.get("level", 1))
	var c_element: String = str(char_data.get("element", "Wind"))
	var c_hp: int = int(char_data.get("hp", 320))
	var c_max_hp: int = int(char_data.get("max_hp", c_hp))
	var c_sp: int = int(char_data.get("sp", 150))
	var c_max_sp: int = int(char_data.get("max_sp", c_sp))
	var c_exp: int = int(char_data.get("exp", 0))
	var c_max_exp: int = int(char_data.get("max_exp", FormulaData.exp_to_next_level(c_level)))

	var c_str: int = int(char_data.get("str", 10))
	var c_con: int = int(char_data.get("con", 10))
	var c_int: int = int(char_data.get("int", 6))
	var c_wis: int = int(char_data.get("wis", 6))
	var c_agi: int = int(char_data.get("agi", 18))
	var c_free: int = int(char_data.get("free_points", 0))
	var c_gold: int = int(char_data.get("gold", 500))

	current_role_id = r_id
	current_element = c_element

	if hud and hud.has_method("set_player_role"):
		hud.set_player_role(r_id)
	if hud and hud.has_method("set_player_element"):
		hud.set_player_element(c_element)

	var exp_pct: float = (float(c_exp) / float(c_max_exp) * 100.0) if c_max_exp > 0 else 0.0
	if hud and hud.has_method("set_player_stats"):
		hud.set_player_stats(c_name, c_level, c_hp, c_max_hp, c_sp, c_max_sp, exp_pct)

	var gdb = _get_game_database()
	var role_def: Dictionary = {}
	if gdb and gdb.has_method("get_role"):
		role_def = gdb.get_role(r_id)

	if char_data.has("equipment") and char_data["equipment"] is Dictionary and not char_data["equipment"].is_empty():
		current_equip_layers = char_data["equipment"].duplicate()
	else:
		current_equip_layers.clear()
		equipment_data.clear()

		var clothes_jma: String = role_def.get("default_clothes_archive", "")
		var clothes_jmp: String = role_def.get("default_clothes_jmp", "")
		var clothes_id: int = int(role_def.get("default_clothes_item_id", 0))
		if not clothes_jma.is_empty() and not clothes_jmp.is_empty():
			current_equip_layers["clothes"] = {"jma": clothes_jma, "jmp": clothes_jmp}
			current_equip_layers["body"] = {"jma": clothes_jma, "jmp": clothes_jmp}
			var c_icon_id: int = _resolve_item_icon_id(clothes_id)
			var c_rec = gdb.items.get_item(clothes_id) if (gdb and "items" in gdb and gdb.items and clothes_id > 0) else null
			var clothes_item_name: String = c_rec.name if c_rec else "Starter Clothes"
			var clothes_desc: String = c_rec.description if c_rec else "DEF +2"
			equipment_data["body"] = _create_item_record(clothes_id, c_icon_id, 1, clothes_item_name, clothes_desc, "body", clothes_jma, clothes_jmp, {"def": 2})

		var shoes_jma: String = role_def.get("default_shoes_archive", "")
		var shoes_jmp: String = role_def.get("default_shoes_jmp", "")
		var shoes_id: int = int(role_def.get("default_shoes_item_id", 0))
		if not shoes_jma.is_empty() and not shoes_jmp.is_empty():
			current_equip_layers["shoes"] = {"jma": shoes_jma, "jmp": shoes_jmp}
			var s_icon_id: int = _resolve_item_icon_id(shoes_id)
			var s_rec = gdb.items.get_item(shoes_id) if (gdb and "items" in gdb and gdb.items and shoes_id > 0) else null
			var s_name: String = s_rec.name if s_rec else "Starter Shoes"
			var s_desc: String = s_rec.description if s_rec else "DEF +1, SPD +1"
			equipment_data["shoes"] = _create_item_record(shoes_id, s_icon_id, 1, s_name, s_desc, "shoes", shoes_jma, shoes_jmp, {"def": 1, "spd": 1})

		var r_body: String = str(role_def.get("body_archive", "004.jma" if r_id == 6 else "003.jma")).to_lower()
		var w_prefix := "004" if r_body.contains("004") else ("003" if r_body.contains("003") else ("002" if r_body.contains("002") else "005"))
		var w_jma := w_prefix + "w.jma"
		var w_jmp := w_prefix.substr(2, 1) + "040.jmp"
		var w_rec = gdb.items.get_item(11033) if (gdb and "items" in gdb and gdb.items) else null
		var w_icon_id: int = w_rec.icon_id if (w_rec and w_rec.icon_id > 0) else 2466
		equipment_data["weapon"] = _create_item_record(11033, w_icon_id, 1, "Iron Sword", "ATK +8", "weapon", w_jma, w_jmp, {"atk": 8})
		current_equip_layers["weapon"] = {"jma": w_jma, "jmp": w_jmp}
		current_equip_layers["hand"] = {"jma": w_jma, "jmp": w_jmp}

		var head_jma: String = role_def.get("default_head_archive", "")
		var head_jmp: String = role_def.get("default_head_jmp", "")
		var head_id: int = int(role_def.get("default_head_item_id", 0))
		if not head_jma.is_empty() and not head_jmp.is_empty():
			current_equip_layers["head"] = {"jma": head_jma, "jmp": head_jmp}
			var h_icon_id: int = _resolve_item_icon_id(head_id)
			var h_rec = gdb.items.get_item(head_id) if (gdb and "items" in gdb and gdb.items and head_id > 0) else null
			var h_name: String = h_rec.name if h_rec else "Starter Hat"
			var h_desc: String = h_rec.description if h_rec else ""
			equipment_data["head"] = _create_item_record(head_id, h_icon_id, 1, h_name, h_desc, "head", head_jma, head_jmp, {})

	update_character_stats(c_name, c_level, c_element, c_hp, c_max_hp, c_sp, c_max_sp, c_exp, c_max_exp, c_str, c_con, c_int, c_wis, c_agi, c_free)
	_update_equipment_socket_icons()
	update_character_paper_doll(current_equip_layers)

	var player_node = hud.get("player") if hud else null
	if not player_node and player:
		player_node = player
	if player_node and player_node.has_method("set_equipment"):
		player_node.set_equipment(current_equip_layers)
	if hud and hud.has_signal("equipment_changed"):
		hud.equipment_changed.emit(current_equip_layers)

	var inv_ctrl = _get_inventory_controller()
	if inv_ctrl and inv_ctrl.has_method("update_gold"):
		inv_ctrl.update_gold(c_gold)
	elif hud and hud.has_method("update_gold"):
		hud.update_gold(c_gold)

## Updates the CharacterWindow stat labels and combat stats
func update_character_stats(
	c_name: String, c_lvl: int, c_elem: String,
	c_hp: int, c_max_hp: int, c_sp: int, c_max_sp: int,
	c_exp: int, c_max_exp: int,
	c_str: int, c_con: int, c_int: int, c_wis: int, c_agi: int, c_free: int
) -> void:
	current_name = c_name
	current_level = c_lvl
	current_element = c_elem
	current_hp = c_hp
	current_max_hp = c_max_hp
	current_sp = c_sp
	current_max_sp = c_max_sp
	current_exp = c_exp
	current_max_exp = c_max_exp
	current_str = c_str
	current_con = c_con
	current_int = c_int
	current_wis = c_wis
	current_agi = c_agi
	current_free = c_free


	if stat_name:
		stat_name.text = c_name
		stat_name.visible = false
	if stat_level:
		stat_level.text = "%d" % c_lvl
		stat_level.visible = false
	if stat_element:
		stat_element.text = c_elem
		stat_element.visible = false
	if stat_left_hp: stat_left_hp.text = "%d / %d" % [c_hp, c_max_hp]
	if stat_left_sp: stat_left_sp.text = "%d / %d" % [c_sp, c_max_sp]
	if stat_left_exp: stat_left_exp.text = "%d / %d" % [c_exp, c_max_exp]
	if stat_str: stat_str.text = "%d" % c_str
	if stat_con: stat_con.text = "%d" % c_con
	if stat_int: stat_int.text = "%d" % c_int
	if stat_wis: stat_wis.text = "%d" % c_wis
	if stat_agi: stat_agi.text = "%d" % c_agi
	if stat_free: stat_free.text = "%d" % c_free

	_refresh_header()
	_update_combat_stats()
	_update_stat_allocation_buttons_visibility()

## Restores character HP up to current_max_hp and synchronizes all docks and UI readouts
func restore_hp(amount: int) -> int:
	if amount <= 0:
		return 0
	var old_hp: int = current_hp
	current_hp = mini(current_max_hp, current_hp + amount)
	var restored: int = current_hp - old_hp
	if stat_left_hp:
		stat_left_hp.text = "%d / %d" % [current_hp, current_max_hp]
	_refresh_header()
	_sync_active_character_data()
	if hud and hud.has_method("set_player_stats"):
		var exp_pct: float = float(current_exp) / float(maxi(1, current_max_exp)) * 100.0
		hud.set_player_stats(current_name, current_level, current_hp, current_max_hp, current_sp, current_max_sp, exp_pct)
	return restored

## Stat points per level: the C# server adds 3 per level (Equip.SetLevel); not yet observed in the real client.
const STAT_POINTS_PER_LEVEL: int = 3

## Adds EXP within the current level and levels up on the real client's curve (FormulaData).
## Returns the EXP actually added (0 at the level cap).
func add_experience(amount: int) -> int:
	if amount <= 0:
		return 0
	var cap: int = FormulaData.max_level()
	if current_level >= cap:
		return 0
	current_max_exp = FormulaData.exp_to_next_level(current_level)
	current_exp += amount
	var levelled: bool = false
	while current_level < cap and current_exp >= current_max_exp:
		current_exp -= current_max_exp
		current_level += 1
		current_free += STAT_POINTS_PER_LEVEL
		# Max HP / SP grow by the server formula's difference, so equipment bonuses already in them are kept.
		current_max_hp += FormulaData.max_hp(current_level, current_con) - FormulaData.max_hp(current_level - 1, current_con)
		current_max_sp += FormulaData.max_sp(current_level, current_wis) - FormulaData.max_sp(current_level - 1, current_wis)
		current_max_exp = FormulaData.exp_to_next_level(current_level)
		levelled = true
	var added: int = amount
	if current_level >= cap:
		added -= current_exp
		current_exp = 0
	if levelled:
		update_character_stats(current_name, current_level, current_element, current_hp, current_max_hp, current_sp, current_max_sp, current_exp, current_max_exp, current_str, current_con, current_int, current_wis, current_agi, current_free)
	elif stat_left_exp:
		stat_left_exp.text = "%d / %d" % [current_exp, current_max_exp]
	_refresh_header()
	_sync_active_character_data()
	if hud != null and hud.has_method("set_player_stats"):
		var exp_pct: float = float(current_exp) / float(maxi(1, current_max_exp)) * 100.0
		hud.set_player_stats(current_name, current_level, current_hp, current_max_hp, current_sp, current_max_sp, exp_pct)
	return added

## Restores character SP up to current_max_sp and synchronizes all docks and UI readouts
func restore_sp(amount: int) -> int:
	if amount <= 0:
		return 0
	var old_sp: int = current_sp
	current_sp = mini(current_max_sp, current_sp + amount)
	var restored: int = current_sp - old_sp
	if stat_left_sp:
		stat_left_sp.text = "%d / %d" % [current_sp, current_max_sp]
	_refresh_header()
	_sync_active_character_data()
	if hud and hud.has_method("set_player_stats"):
		var exp_pct: float = float(current_exp) / float(maxi(1, current_max_exp)) * 100.0
		hud.set_player_stats(current_name, current_level, current_hp, current_max_hp, current_sp, current_max_sp, exp_pct)
	return restored

## Sets up interactive [+] stat point allocation buttons in CharacterWindow
func _setup_stat_allocation_buttons() -> void:
	if not char_window:
		return
	var stats_config: Array[Dictionary] = [
		{"name": "str", "y": 335.0},
		{"name": "con", "y": 351.0},
		{"name": "int", "y": 367.0},
		{"name": "wis", "y": 383.0},
		{"name": "agi", "y": 399.0},
	]
	for cfg in stats_config:
		var sname: String = str(cfg["name"])
		var sy: float = float(cfg["y"])
		var btn: Button = char_window.get_node_or_null("BtnAdd_" + sname) as Button
		if not btn:
			btn = Button.new()
			btn.name = "BtnAdd_" + sname
			btn.text = "+"
			btn.size = Vector2(14, 14)
			btn.position = Vector2(178, sy)
			btn.add_theme_font_size_override("font_size", 9)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.35, 0.5, 0.85)
			sb.corner_radius_top_left = 2
			sb.corner_radius_top_right = 2
			sb.corner_radius_bottom_left = 2
			sb.corner_radius_bottom_right = 2
			btn.add_theme_stylebox_override("normal", sb)
			btn.pressed.connect(allocate_stat_point.bind(sname))
			char_window.add_child(btn)
		stat_add_buttons[sname] = btn
	_update_stat_allocation_buttons_visibility()

## Updates visibility of [+] stat allocation buttons depending on free_points
func _update_stat_allocation_buttons_visibility() -> void:
	var can_add: bool = current_free > 0
	for sname in stat_add_buttons:
		var btn: Button = stat_add_buttons[sname]
		if btn:
			btn.visible = can_add

## Allocates 1 free attribute point to the specified stat
func allocate_stat_point(stat_name: String) -> bool:
	if current_free <= 0:
		return false
	match stat_name.to_lower():
		"str":
			current_str += 1
		"con":
			current_con += 1
			var hp_gain: int = FormulaData.max_hp(current_level, current_con) - FormulaData.max_hp(current_level, current_con - 1)
			current_max_hp += hp_gain
			current_hp += hp_gain
		"int":
			current_int += 1
		"wis":
			current_wis += 1
			var sp_gain: int = FormulaData.max_sp(current_level, current_wis) - FormulaData.max_sp(current_level, current_wis - 1)
			current_max_sp += sp_gain
			current_sp += sp_gain
		"agi":
			current_agi += 1
		_:
			return false
	current_free -= 1
	update_character_stats(
		current_name, current_level, current_element,
		current_hp, current_max_hp, current_sp, current_max_sp,
		current_exp, current_max_exp,
		current_str, current_con, current_int, current_wis, current_agi,
		current_free
	)
	_sync_active_character_data()
	if hud and hud.has_method("set_player_stats"):
		var exp_pct: float = (float(current_exp) / float(current_max_exp) * 100.0) if current_max_exp > 0 else 0.0
		hud.set_player_stats(current_name, current_level, current_hp, current_max_hp, current_sp, current_max_sp, exp_pct)
	_play_auth_click()
	return true

func _sync_active_character_data() -> void:
	var slot := 0
	if hud and "current_character_slot" in hud:
		slot = int(hud.current_character_slot)
	var char_data := CharacterManager.get_character(slot)
	if char_data.is_empty():
		char_data = {
			"name": current_name,
			"level": current_level,
			"element": current_element,
			"hp": current_hp,
			"max_hp": current_max_hp,
			"sp": current_sp,
			"max_sp": current_max_sp,
			"exp": current_exp,
			"max_exp": current_max_exp,
			"str": current_str,
			"con": current_con,
			"int": current_int,
			"wis": current_wis,
			"agi": current_agi,
			"free_points": current_free,
			"role_id": current_role_id
		}
	else:
		char_data["str"] = current_str
		char_data["con"] = current_con
		char_data["int"] = current_int
		char_data["wis"] = current_wis
		char_data["agi"] = current_agi
		char_data["free_points"] = current_free
		char_data["hp"] = current_hp
		char_data["max_hp"] = current_max_hp
		char_data["sp"] = current_sp
		char_data["max_sp"] = current_max_sp
	CharacterManager.save_character(slot, char_data)

func _play_auth_click() -> void:
	var auth_audio = hud.get_node_or_null("/root/AuthAudio") if (hud and hud.is_inside_tree()) else null
	if auth_audio and auth_audio.has_method("play_ui_click"):
		auth_audio.play_ui_click()
	elif hud and hud.has_node("SFXPlayer"):
		var sp: AudioStreamPlayer = hud.get_node("SFXPlayer") as AudioStreamPlayer
		if sp:
			sp.stream = load("res://assets/sound/wav0151.wav")
			sp.play()

## Drag & drop handler: Initiates drag from an equipment socket
func get_equipment_drag_data(socket_name: String) -> Variant:
	var sname: String = _normalize_socket_name(socket_name)
	var item: Dictionary = equipment_data.get(sname, {})
	if item.is_empty() or int(item.get("id", 0)) <= 0:
		return null
	var icon_tex: Texture2D = null
	if equipment_slots.has(sname):
		var icon_rect: TextureRect = equipment_slots[sname].get_node_or_null("Icon") as TextureRect
		if icon_rect:
			icon_tex = icon_rect.texture
	return {
		"type": "equipment",
		"socket_name": sname,
		"item": item,
		"icon_tex": icon_tex
	}

## Drag & drop handler: Validates drop target on an equipment socket
func can_drop_on_equipment_socket(target_socket: String, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var sname: String = _normalize_socket_name(target_socket)
	var dtype: String = str(data.get("type", ""))
	if dtype == "inventory":
		var item: Dictionary = data.get("item", {})
		return _is_item_compatible_with_socket(item, sname)
	elif dtype == "equipment":
		var source_socket: String = _normalize_socket_name(str(data.get("socket_name", "")))
		if source_socket == sname:
			return false
		var source_item: Dictionary = data.get("item", {})
		var target_item: Dictionary = equipment_data.get(sname, {})
		var can_source_go: bool = _is_item_compatible_with_socket(source_item, sname)
		if not can_source_go:
			return false
		if target_item.is_empty() or int(target_item.get("id", 0)) <= 0:
			return true
		return _is_item_compatible_with_socket(target_item, source_socket)
	return false

## Drag & drop handler: Executes drop on an equipment socket
func drop_on_equipment_socket(target_socket: String, data: Variant) -> void:
	if not can_drop_on_equipment_socket(target_socket, data):
		return
	var sname: String = _normalize_socket_name(target_socket)
	var dtype: String = str(data.get("type", ""))
	var inv_ctrl = _get_inventory_controller()

	if dtype == "inventory":
		var source_slot: int = int(data.get("slot_index", -1))
		var new_item: Dictionary = data.get("item", {})
		var old_equipped: Dictionary = equipment_data.get(sname, {})

		if not old_equipped.is_empty() and int(old_equipped.get("id", 0)) > 0:
			if inv_ctrl:
				inv_ctrl.set_inventory_data_item(source_slot, old_equipped)
			elif hud and "_inventory_data" in hud:
				hud._inventory_data[source_slot] = old_equipped
				if hud.has_method("_refresh_inventory_slot"):
					hud._refresh_inventory_slot(source_slot)
		else:
			if inv_ctrl:
				inv_ctrl.clear_inventory_slot(source_slot)
			elif hud and hud.has_method("clear_inventory_slot"):
				hud.clear_inventory_slot(source_slot)

		equipment_data[sname] = new_item
		_sync_equipment_layer(sname, new_item)
		_update_equipment_socket_icons()
		_update_combat_stats()
		_log_system_message("Equipped %s." % new_item.get("name", sname.capitalize()))

	elif dtype == "equipment":
		var source_socket: String = _normalize_socket_name(str(data.get("socket_name", "")))
		var source_item: Dictionary = data.get("item", {})
		var target_item: Dictionary = equipment_data.get(sname, {})
		equipment_data[sname] = source_item
		_sync_equipment_layer(sname, source_item)
		if not target_item.is_empty() and int(target_item.get("id", 0)) > 0:
			equipment_data[source_socket] = target_item
			_sync_equipment_layer(source_socket, target_item)
		else:
			equipment_data.erase(source_socket)
			_sync_equipment_layer(source_socket, {})
		_update_equipment_socket_icons()
		_update_combat_stats()

## Handles click on an equipment socket (quick unequip to inventory)
func on_equipment_socket_clicked(socket_name: String) -> void:
	var sname: String = _normalize_socket_name(socket_name)
	var item: Dictionary = equipment_data.get(sname, {})
	if item.is_empty() or int(item.get("id", 0)) <= 0:
		return

	var inv_ctrl = _get_inventory_controller()
	var empty_slot: int = -1
	if inv_ctrl and "inventory_data" in inv_ctrl:
		for i in range(inv_ctrl.inventory_data.size()):
			if inv_ctrl.inventory_data[i].is_empty() or int(inv_ctrl.inventory_data[i].get("id", 0)) <= 0:
				empty_slot = i
				break
	elif hud and "_inventory_data" in hud:
		for i in range(hud._inventory_data.size()):
			if hud._inventory_data[i].is_empty() or int(hud._inventory_data[i].get("id", 0)) <= 0:
				empty_slot = i
				break

	if empty_slot == -1:
		_log_system_message("Inventory is full!")
		return

	if inv_ctrl:
		inv_ctrl.set_inventory_data_item(empty_slot, item)
	elif hud and "_inventory_data" in hud:
		hud._inventory_data[empty_slot] = item
		if hud.has_method("_refresh_inventory_slot"):
			hud._refresh_inventory_slot(empty_slot)

	equipment_data.erase(sname)
	_sync_equipment_layer(sname, {})
	_update_equipment_socket_icons()
	_update_combat_stats()
	_log_system_message("Unequipped %s." % item.get("name", sname.capitalize()))

## Sets equipment dictionary directly and updates visual components
func set_equipment(layers: Dictionary) -> void:
	if current_equip_layers == layers:
		return
	current_equip_layers = layers.duplicate()
	update_character_paper_doll(current_equip_layers)
	_update_equipment_socket_icons()
	_update_combat_stats()
	if hud and hud.has_signal("equipment_changed"):
		hud.equipment_changed.emit(current_equip_layers)

## Sets equipment slot directly by item_id (resolving icon and metadata via GameDatabase)
func set_equipment_slot(slot_name: String, item_id: int) -> void:
	var sname := _normalize_socket_name(slot_name)
	if item_id <= 0:
		unequip_item(sname)
		return

	var gdb = _get_game_database()
	var icon_id: int = _resolve_item_icon_id(item_id)
	var iname: String = "Equipment"
	var desc: String = ""
	var stats: Dictionary = {}
	if gdb and "items" in gdb and gdb.items:
		var rec = gdb.items.get_item(item_id)
		if rec:
			if icon_id <= 0:
				icon_id = rec.icon_id
			iname = rec.name
			desc = rec.description

	var itm: Dictionary = _create_item_record(item_id, icon_id, 1, iname, desc, sname, "", "", stats)
	equipment_data[sname] = itm
	_sync_equipment_layer(sname, itm)
	_update_equipment_socket_icons()
	_update_combat_stats()

## Equips a layer by name with optional visual JMA/JMP files
func equip_item(slot_name: String, jma_file: String = "", jmp_file: String = "", icon_id: int = -1, item_name: String = "") -> void:
	var sname := _normalize_socket_name(slot_name)
	var default_id: int = 11033 if (sname == "hand" or sname == "weapon") else (24003 if sname == "shoes" else (22001 if sname == "head" else 21003))
	var final_icon: int = icon_id
	if final_icon <= 0:
		final_icon = _resolve_item_icon_id(default_id)
	if final_icon <= 0:
		final_icon = 2466 if (sname == "hand" or sname == "weapon") else (1095 if sname == "shoes" else (1088 if sname == "head" else 1096))

	var iname: String = item_name if not item_name.is_empty() else ("Iron Sword" if (sname == "hand" or sname == "weapon") else ("Pink Shoes" if sname == "shoes" else "Equipment"))
	var stats: Dictionary = {"atk": 12} if (sname == "hand" or sname == "weapon") else ({"def": 3, "spd": 2} if sname == "shoes" else {})
	var itm: Dictionary = _create_item_record(default_id, final_icon, 1, iname, "", sname, jma_file, jmp_file, stats)
	equipment_data[sname] = itm
	_sync_equipment_layer(sname, itm)
	_update_equipment_socket_icons()
	_update_combat_stats()

## Unequips a layer by name
func unequip_item(slot_name: String) -> void:
	var sname := _normalize_socket_name(slot_name)
	if equipment_data.has(sname):
		equipment_data.erase(sname)
	_sync_equipment_layer(sname, {})
	_update_equipment_socket_icons()
	_update_combat_stats()

## Swaps an equipment item and returns the displaced item record (or empty)
func swap_equipment_item(slot_name: String, item: Dictionary) -> Dictionary:
	var sname := _normalize_socket_name(slot_name)
	var old_item: Dictionary = equipment_data.get(sname, {})
	equipment_data[sname] = item
	_sync_equipment_layer(sname, item)
	_update_equipment_socket_icons()
	_update_combat_stats()
	return old_item

## Sets an item directly in equipment data and syncs layers
func set_equipment_slot_item(slot_name: String, item: Dictionary) -> void:
	var sname := _normalize_socket_name(slot_name)
	equipment_data[sname] = item
	_sync_equipment_layer(sname, item)
	_update_equipment_socket_icons()
	_update_combat_stats()

## Returns current equipment layers
func get_equipment() -> Dictionary:
	return current_equip_layers.duplicate()

## Updates the CharacterWindow PaperDoll texture based on equip_layers
func update_character_paper_doll(equip_dict: Dictionary = {}) -> void:
	if not equip_dict.is_empty():
		current_equip_layers = equip_dict.duplicate()
	var loader = _get_archive_loader()
	if not loader or not char_paper_doll:
		return
	var player_node = hud.get("player") if hud else null
	if not player_node and player:
		player_node = player
	var rid: int = player_node.role_id if (player_node and "role_id" in player_node and player_node.role_id > 0) else current_role_id
	if loader.has_method("get_player_composite_frames"):
		var frames: Array = loader.get_player_composite_frames(rid, current_equip_layers)
		if not frames.is_empty():
			_paper_doll_frames = frames
			var stand_frame: int = get_paper_doll_frame_index()
			if stand_frame < frames.size():
				char_paper_doll.texture = frames[stand_frame]
			else:
				char_paper_doll.texture = frames[0]

## Returns the authentic 3/4 isometric stance heading (SOUTH_WEST / Heading 3)
func get_paper_doll_heading() -> int:
	return _paper_doll_heading

## Returns the current animated frame index for paper doll idle breathing
func get_paper_doll_frame_index() -> int:
	if _paper_doll_frames.is_empty():
		return _paper_doll_base_frame
	if _paper_doll_base_frame + 3 < _paper_doll_frames.size():
		return _paper_doll_base_frame + (int(_paper_doll_timer * 3.0) % 4)
	return int(_paper_doll_timer * 3.0) % _paper_doll_frames.size()

## Drives continuous idle breathing animation of the paper doll character
func process(delta: float) -> void:
	if not char_window or not char_window.visible:
		return
	if _paper_doll_frames.is_empty():
		if char_paper_doll and char_paper_doll.texture == null:
			update_character_paper_doll()
		return
	_paper_doll_timer += delta
	var frame_idx := get_paper_doll_frame_index()
	if frame_idx < _paper_doll_frames.size() and char_paper_doll:
		char_paper_doll.texture = _paper_doll_frames[frame_idx]

## Shows authentic hover tooltip for equipped item in paper doll socket
func show_equipment_item_tooltip(socket_name: String, socket_global_pos: Vector2, socket_size: Vector2) -> void:
	if not item_tooltip:
		return
	var sname := _normalize_socket_name(socket_name)
	if not equipment_data.has(sname):
		hide_item_tooltip()
		return
	var itm: Dictionary = equipment_data[sname]
	if itm.is_empty() or int(itm.get("id", 0)) <= 0:
		hide_item_tooltip()
		return
	if item_tooltip.has_method("display_item"):
		item_tooltip.display_item(itm)
	if item_tooltip.has_method("position_at"):
		item_tooltip.position_at(socket_global_pos, socket_size)

## Hides the item tooltip
func hide_item_tooltip() -> void:
	if item_tooltip:
		item_tooltip.visible = false

# ==============================================================================
# Internal Helpers
# ==============================================================================

func _update_equipment_socket_icons() -> void:
	var sockets: Array[String] = ["head", "weapon", "wrist", "body", "special", "shoes"]
	var gdb = _get_game_database()
	for sname in sockets:
		if not equipment_slots.has(sname):
			continue
		var btn: Button = equipment_slots[sname]
		var icon: TextureRect = btn.get_node_or_null("Icon") as TextureRect
		if equipment_data.has(sname) and not equipment_data[sname].is_empty():
			var item: Dictionary = equipment_data[sname]
			var item_id: int = int(item.get("id", 0))
			var icon_id: int = int(item.get("icon_id", 0))

			if item_id > 0 and gdb and "items" in gdb and gdb.items:
				var rec = gdb.items.get_item(item_id)
				if rec and rec.icon_id > 0:
					icon_id = rec.icon_id
					item["icon_id"] = icon_id
					if str(item.get("name", "")).is_empty() or item.get("name") == "Starter Clothes" or item.get("name") == "Starter Shoes" or item.get("name") == "Starter Hat":
						item["name"] = rec.name
					if str(item.get("desc", "")).is_empty():
						item["desc"] = rec.description
			elif icon_id > 0 and icon_id == item_id:
				var res_id: int = _resolve_item_icon_id(icon_id)
				if res_id > 0:
					icon_id = res_id
					item["icon_id"] = icon_id

			if icon and icon_id > 0:
				icon.texture = _load_item_icon(icon_id)
				icon.z_index = 2
				btn.move_child(icon, -1)
			elif icon:
				icon.texture = null
			btn.tooltip_text = "%s\n%s" % [item.get("name", sname.capitalize()), item.get("desc", "")]
		else:
			if icon:
				icon.texture = null
			btn.tooltip_text = "%s Slot" % sname.capitalize()

## Sum of the equipped items' combat bonuses per stat.
func get_equipment_bonus() -> Dictionary:
	var equip: Dictionary = {"atk": 0, "def": 0, "matk": 0, "mdef": 0, "spd": 0}
	for sname in equipment_data:
		var itm: Dictionary = equipment_data[sname]
		var st: Dictionary = itm.get("stats", {})
		for key in equip:
			equip[key] += int(st.get(key, 0))
	return equip

## ATK / DEF / MATK / MDEF / SPD for the current attributes, level and element (`equip`: bonus per stat).
func get_combat_stats(equip: Dictionary = {}) -> Dictionary:
	var element_id: int = int(ELEMENT_IDS.get(current_element.to_lower(), 0))
	var attrs: Dictionary = {"atk": current_str, "def": current_con, "matk": current_int, "mdef": current_wis, "spd": current_agi}
	var result: Dictionary = {}
	for key in attrs:
		result[key] = FormulaData.combat_stat(key, int(attrs[key]), current_level, int(equip.get(key, 0)), element_id, current_job)
	return result

## Combat stats from Formula.dat as the real client computes them (FormulaData.combat_stat); equipment adds its bonus.
func _update_combat_stats() -> void:
	var stats: Dictionary = get_combat_stats(get_equipment_bonus())
	var bases: Dictionary = get_combat_stats()
	base_atk = bases["atk"]
	base_def = bases["def"]
	base_matk = bases["matk"]
	base_mdef = bases["mdef"]
	base_spd = bases["spd"]
	var total_atk: int = stats["atk"]
	var total_def: int = stats["def"]
	var total_matk: int = stats["matk"]
	var total_mdef: int = stats["mdef"]
	var total_spd: int = stats["spd"]

	if stat_atk: stat_atk.text = "%d" % total_atk
	if stat_def: stat_def.text = "%d" % total_def
	if stat_matk: stat_matk.text = "%d" % total_matk
	if stat_mdef: stat_mdef.text = "%d" % total_mdef
	if stat_spd: stat_spd.text = "%d" % total_spd

func _sync_equipment_layer(socket_name: String, item: Dictionary) -> void:
	var sname := _normalize_socket_name(socket_name)
	var has_item: bool = not item.is_empty() and int(item.get("id", 0)) > 0
	match sname:
		"head":
			if has_item:
				current_equip_layers["cap"] = {"jma": item.get("jma", "003c.jma"), "jmp": item.get("jmp", "3201.jmp")}
				current_equip_layers["head"] = current_equip_layers["cap"]
			else:
				current_equip_layers.erase("cap")
				current_equip_layers.erase("head")
		"weapon":
			if has_item:
				current_equip_layers["weapon"] = {"jma": item.get("jma", "003w.jma"), "jmp": item.get("jmp", "3040.jmp")}
				current_equip_layers["hand"] = current_equip_layers["weapon"]
			else:
				current_equip_layers.erase("weapon")
				current_equip_layers.erase("hand")
		"body":
			if has_item:
				current_equip_layers["clothes"] = {"jma": item.get("jma", "003e.jma"), "jmp": item.get("jmp", "3301.jmp")}
				current_equip_layers["body"] = current_equip_layers["clothes"]
			else:
				current_equip_layers["clothes"] = ""
				current_equip_layers.erase("body")
		"wrist":
			if has_item:
				current_equip_layers["arm"] = {"jma": item.get("jma", ""), "jmp": item.get("jmp", "")}
				current_equip_layers["wrist"] = current_equip_layers["arm"]
			else:
				current_equip_layers.erase("arm")
				current_equip_layers.erase("wrist")
		"shoes":
			if has_item:
				current_equip_layers["shoes"] = {"jma": item.get("jma", "003s.jma"), "jmp": item.get("jmp", "3401.jmp")}
			else:
				current_equip_layers["shoes"] = ""
		"special":
			if has_item:
				current_equip_layers["special"] = {"jma": item.get("jma", ""), "jmp": item.get("jmp", "")}
			else:
				current_equip_layers.erase("special")

	update_character_paper_doll(current_equip_layers)
	if hud and hud.has_signal("equipment_changed"):
		hud.equipment_changed.emit(current_equip_layers)
	var player_node = hud.get("player") if hud else null
	if player_node and player_node.has_method("set_equipment"):
		player_node.set_equipment(current_equip_layers)

func _create_item_record(id: int, icon_id: int, count: int, iname: String, desc: String, equip_slot: String = "", jma: String = "", jmp: String = "", stats: Dictionary = {}) -> Dictionary:
	var final_icon: int = icon_id
	if id > 0 and (final_icon <= 0 or final_icon == id):
		var res: int = _resolve_item_icon_id(id)
		if res > 0:
			final_icon = res
	return {
		"id": id,
		"icon_id": final_icon,
		"count": count,
		"name": iname,
		"desc": desc,
		"description": desc,
		"equip_slot": equip_slot,
		"jma": jma,
		"jmp": jmp,
		"stats": stats
	}

func _load_item_icon(icon_id: int) -> Texture2D:
	if icon_id <= 0:
		return null
	var loader = _get_archive_loader()
	if loader and loader.has_method("get_item_icon"):
		return loader.get_item_icon(icon_id)
	return null

func _resolve_item_icon_id(item_id: int) -> int:
	if item_id <= 0:
		return 0
	var gdb = _get_game_database()
	if gdb and "items" in gdb and gdb.items:
		var rec = gdb.items.get_item(item_id)
		if rec and rec.icon_id > 0:
			return rec.icon_id
	return 0

func _normalize_socket_name(socket_name: String) -> String:
	var s := socket_name.to_lower().strip_edges()
	if s == "cap" or s == "helmet" or s == "head":
		return "head"
	if s == "clothes" or s == "armor" or s == "body":
		return "body"
	if s == "sword" or s == "weapon" or s == "weapons" or s == "hand" or s == "hands":
		return "weapon"
	if s == "arm" or s == "arms" or s == "wrist" or s == "wrists" or s == "gloves" or s == "bracers":
		return "wrist"
	if s == "feet" or s == "boots" or s == "shoes" or s == "foot":
		return "shoes"
	if s == "ring" or s == "accessory" or s == "special":
		return "special"
	return s

func _is_item_compatible_with_socket(item: Dictionary, socket_name: String) -> bool:
	if item.is_empty() or int(item.get("id", 0)) <= 0:
		return false
	var sname := _normalize_socket_name(socket_name)
	var ep: int = int(item.get("equip_pos", 0))
	if ep == 0:
		var eslot := _normalize_socket_name(str(item.get("equip_slot", "")))
		return eslot == sname
	match ep:
		1: return sname == "head"
		2: return sname == "body"
		3: return sname == "weapon"
		4: return sname == "wrist"
		5: return sname == "shoes"
		6, 7: return sname == "special"
	return false

func _get_archive_loader() -> Node:
	if hud and hud.is_inside_tree():
		return hud.get_node_or_null("/root/ArchiveLoader")
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("ArchiveLoader")
	return null

func _get_game_database() -> Node:
	if hud and hud.is_inside_tree():
		return hud.get_node_or_null("/root/GameDatabase")
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("GameDatabase")
	return null

func _get_inventory_controller() -> Variant:
	if hud and "inventory" in hud:
		return hud.get("inventory")
	return null

func _log_system_message(msg: String) -> void:
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", msg, "System")
