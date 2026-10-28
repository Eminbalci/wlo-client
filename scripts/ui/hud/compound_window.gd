class_name CompoundWindow
extends Control

## Authentic Wonderland Online Compound / Alchemy Window (Form_Compound_1, 299x467).
## Decoded directly from aLogin.exe TRe_CompoundForm and Compound.dat/Compound2.Dat.
## Provides 1 Main Base Slot, 4 Sub Material Slots, 50-slot Inventory Grid,
## Junior/Primary Alchemy skill toggle, 23-frame animated Compounding VFX,
## authentic synthesis rank calculations, and robust validation checks.

signal compound_started
signal compound_completed(result_id: int, result_name: String, is_success: bool)
signal window_closed

const FORM_WIDTH: float = 299.0
const FORM_HEIGHT: float = 467.0
const FRAME_COUNT: int = 23
const FRAME_HEIGHT: float = 95.0
const FRAME_WIDTH: float = 90.0

# UI Node References
var background_rect: TextureRect = null
var title_label: Label = null
var btn_close: TextureButton = null
var btn_bottom_close: TextureButton = null
var btn_skill_check: TextureButton = null
var lbl_skill: Label = null
var btn_compsk_1: TextureButton = null
var btn_compsk_2: TextureButton = null
var btn_compsk_3: TextureButton = null
var role_frame_rect: TextureRect = null
var role_avatar_rect: TextureRect = null
var grid_container: GridContainer = null
var main_slot_btn: TextureButton = null
var sub_slot_btns: Array[TextureButton] = []
var btn_compound: TextureButton = null
var compounding_rect: TextureRect = null
var status_label: Label = null
var sfx_player: AudioStreamPlayer = null

# State
var is_compounding: bool = false
var use_alchemy_skill: bool = true
var active_skill_tier: int = 1 # 1: Junior Alchemy (-2..+2), 2: Intermediate (-1..+3), 3: Senior (0..+4)
var _anim_frames: Array[AtlasTexture] = []
var _current_frame_idx: int = 0
var _anim_timer: float = 0.0

# Slots data: Dictionary with {id: int, count: int, name: String, icon_id: int, rank: int, is_book: bool, orig_slot: int}
var main_slot_data: Dictionary = {}
var sub_slots_data: Array[Dictionary] = [{}, {}, {}, {}]

# Reference to HUD or Player Inventory
var _hud: Control = null
var _inventory_items: Array[Dictionary] = []
var _bag_slot_buttons: Array[TextureButton] = []

# Cached Compound2.Dat Crafting Recipes (788 recipes)
static var _recipes_cache: Array[Dictionary] = []
static var _recipes_loaded: bool = false

## Loads and decodes all 788 crafting recipes from Compound2.Dat
static func ensure_recipes_loaded() -> void:
	if _recipes_loaded:
		return
	_recipes_loaded = true
	var candidate_paths := [
		"res://assets/data/Compound2.Dat",
		"res://assets/data/Compound2.dat",
		"D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/Compound2.Dat",
		"D:/GitHub/Wonderland-Private-Server/Data/Compound2.dat",
	]
	var file_path := ""
	for p in candidate_paths:
		if FileAccess.file_exists(p):
			file_path = p
			break
	if file_path.is_empty():
		return
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	var data := file.get_buffer(file.get_length())
	var rec_size: int = 65
	var total: int = data.size() / rec_size
	for i in range(1, total):
		var offset: int = i * rec_size
		var res_id: int = ((data.decode_u16(offset) ^ 0xFBBC) - 3) & 0xFFFF
		if res_id == 0 or res_id == 60003:
			continue
		var plan_id: int = ((data.decode_u16(offset + 2) ^ 0xFBBC) - 3) & 0xFFFF
		var tool_id: int = ((data.decode_u16(offset + 5) ^ 0xFBBC) - 3) & 0xFFFF
		var amt: int = ((data[offset + 7] ^ 0xD3) - 3) & 0xFF
		var mats: Array[Dictionary] = []
		for m in range(5):
			var m_off: int = offset + 11 + m * 3
			var mid: int = ((data.decode_u16(m_off) ^ 0xFBBC) - 3) & 0xFFFF
			var mamt: int = ((data[m_off + 2] ^ 0xD3) - 3) & 0xFF
			if mid > 0 and mamt > 0 and mid != 60003:
				mats.append({"id": mid, "amount": mamt})
		if not mats.is_empty():
			_recipes_cache.append({
				"result_id": res_id,
				"amount": maxi(1, amt),
				"plan_id": plan_id,
				"tool_id": tool_id,
				"ingredients": mats
			})

## Finds a matching recipe from Compound2.Dat given placed ingredient counts
static func find_matching_recipe(placed_mats: Dictionary) -> Dictionary:
	ensure_recipes_loaded()
	for rec in _recipes_cache:
		var ings: Array = rec.get("ingredients", [])
		if ings.is_empty():
			continue
		var matches: bool = true
		for ing in ings:
			var req_id: int = int(ing.get("id", 0))
			var req_amt: int = int(ing.get("amount", 1))
			if placed_mats.get(req_id, 0) < req_amt:
				matches = false
				break
		if matches:
			return rec
	return {}

# Dragging support
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(FORM_WIDTH, FORM_HEIGHT)
	size = Vector2(FORM_WIDTH, FORM_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_ui_layout()
	_load_animation_frames()
	_refresh_slots_ui()

func setup(hud: Control) -> void:
	_hud = hud
	refresh_inventory_from_hud()
	_refresh_role_avatar()

## Synchronizes available bag items from HUD inventory
func refresh_inventory_from_hud() -> void:
	_inventory_items.clear()
	if _hud:
		var raw_slots: Array = []
		if "inventory_ctrl" in _hud and _hud.inventory_ctrl != null and _hud.inventory_ctrl.inventory_data is Array:
			raw_slots = _hud.inventory_ctrl.inventory_data
		elif "inventory" in _hud and _hud.inventory != null:
			var inv = _hud.inventory
			if "inventory_data" in inv and inv.inventory_data is Array:
				raw_slots = inv.inventory_data
			elif "slots" in inv and inv.slots is Array:
				raw_slots = inv.slots
		elif "_inventory_data" in _hud and _hud._inventory_data is Array:
			raw_slots = _hud._inventory_data

		for i in range(raw_slots.size()):
			var slot_info = raw_slots[i]
			if slot_info is Dictionary and not slot_info.is_empty() and slot_info.get("id", 0) > 0:
				var it: Dictionary = slot_info.duplicate(true)
				it["orig_slot"] = i
				_inventory_items.append(it)
	_populate_bag_grid()

func _setup_ui_layout() -> void:
	# 1. Background Form Frame
	background_rect = TextureRect.new()
	background_rect.name = "FormBackground"
	background_rect.texture = _load_texture("assets/hud/form_compound_1.png")
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP
	background_rect.position = Vector2.ZERO
	background_rect.size = Vector2(FORM_WIDTH, FORM_HEIGHT)
	background_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(background_rect)

	# 2. Window Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Compound"
	title_label.position = Vector2(24, 22)
	title_label.size = Vector2(180, 20)
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.85, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0, 0.95))
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.visible = false # the skin bakes its own "compound" title
	add_child(title_label)

	# 3. Corner Close Button (Btn_Close_S_1: 0xf9=249, 0x18=24, 18x18)
	btn_close = TextureButton.new()
	btn_close.name = "BtnClose"
	btn_close.texture_normal = _load_texture("assets/hud/btn_close_normal.png")
	btn_close.texture_hover = _load_texture("assets/hud/btn_close_hover.png")
	btn_close.texture_pressed = _load_texture("assets/hud/btn_close_pressed.png")
	btn_close.ignore_texture_size = true
	btn_close.stretch_mode = TextureButton.STRETCH_SCALE
	WindowCloseButton.apply(btn_close, FORM_WIDTH) # sits on the baked x sphere
	btn_close.pressed.connect(close_window)
	add_child(btn_close)

	# 4. Alchemy Skill Checkbox & Label (btn_UnCheck_1 at 0x15=21, 0x32=50)
	btn_skill_check = TextureButton.new()
	btn_skill_check.name = "BtnSkillCheck"
	_update_checkbox_texture()
	btn_skill_check.ignore_texture_size = true
	btn_skill_check.stretch_mode = TextureButton.STRETCH_SCALE
	btn_skill_check.position = Vector2(21, 50)
	btn_skill_check.size = Vector2(16, 16)
	btn_skill_check.pressed.connect(_on_skill_checkbox_toggled)
	btn_skill_check.visible = false # the real window has no checkbox row (docs/re/ui_windows.md)
	add_child(btn_skill_check)

	lbl_skill = Label.new()
	lbl_skill.name = "LblSkill"
	lbl_skill.text = "Use Junior Alchemy"
	lbl_skill.position = Vector2(38, 52)
	lbl_skill.size = Vector2(150, 16)
	lbl_skill.add_theme_font_size_override("font_size", 11)
	lbl_skill.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0))
	lbl_skill.visible = false
	add_child(lbl_skill)

	# 4b. CompSk Tier Buttons (Btn_CompSk_1..3: 43x20 each)
	btn_compsk_1 = TextureButton.new()
	btn_compsk_1.name = "BtnCompSk1"
	btn_compsk_1.texture_normal = _load_texture("assets/hud/btn_compsk_1_normal.png")
	btn_compsk_1.texture_hover = _load_texture("assets/hud/btn_compsk_1_hover.png")
	btn_compsk_1.texture_pressed = _load_texture("assets/hud/btn_compsk_1_pressed.png")
	btn_compsk_1.ignore_texture_size = true
	btn_compsk_1.stretch_mode = TextureButton.STRETCH_SCALE
	btn_compsk_1.position = Vector2(21, 48)
	btn_compsk_1.size = Vector2(43, 20)
	btn_compsk_1.pressed.connect(_on_compsk_tier_selected.bind(1))
	btn_compsk_1.visible = false
	add_child(btn_compsk_1)

	btn_compsk_2 = TextureButton.new()
	btn_compsk_2.name = "BtnCompSk2"
	btn_compsk_2.texture_normal = _load_texture("assets/hud/btn_compsk_2_normal.png")
	btn_compsk_2.texture_hover = _load_texture("assets/hud/btn_compsk_2_hover.png")
	btn_compsk_2.texture_pressed = _load_texture("assets/hud/btn_compsk_2_pressed.png")
	btn_compsk_2.ignore_texture_size = true
	btn_compsk_2.stretch_mode = TextureButton.STRETCH_SCALE
	btn_compsk_2.position = Vector2(65, 48)
	btn_compsk_2.size = Vector2(43, 20)
	btn_compsk_2.pressed.connect(_on_compsk_tier_selected.bind(2))
	btn_compsk_2.visible = false
	add_child(btn_compsk_2)

	btn_compsk_3 = TextureButton.new()
	btn_compsk_3.name = "BtnCompSk3"
	btn_compsk_3.texture_normal = _load_texture("assets/hud/btn_compsk_3_normal.png")
	btn_compsk_3.texture_hover = _load_texture("assets/hud/btn_compsk_3_hover.png")
	btn_compsk_3.texture_pressed = _load_texture("assets/hud/btn_compsk_3_pressed.png")
	btn_compsk_3.ignore_texture_size = true
	btn_compsk_3.stretch_mode = TextureButton.STRETCH_SCALE
	btn_compsk_3.position = Vector2(109, 48)
	btn_compsk_3.size = Vector2(43, 20)
	btn_compsk_3.pressed.connect(_on_compsk_tier_selected.bind(3))
	btn_compsk_3.visible = false
	add_child(btn_compsk_3)

	# 4c. Active Role Standee Frame (Icon_RoleSelectFrame: 49x65 at X=204, Y=82)
	role_frame_rect = TextureRect.new()
	role_frame_rect.name = "RoleSelectFrame"
	role_frame_rect.texture = _load_texture("assets/hud/icon_role_select_frame.png")
	role_frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	role_frame_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	role_frame_rect.position = Vector2(204, 82)
	role_frame_rect.size = Vector2(49, 65)
	role_frame_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(role_frame_rect)

	role_avatar_rect = TextureRect.new()
	role_avatar_rect.name = "RoleAvatar"
	role_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	role_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	role_avatar_rect.position = Vector2(208, 92)
	role_avatar_rect.size = Vector2(41, 47)
	role_avatar_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(role_avatar_rect)
	_refresh_role_avatar()

	# 5. Inventory Bag Grid (5 columns x 10 rows at X=24, Y=76)
	var scroll := ScrollContainer.new()
	scroll.name = "BagScroll"
	scroll.position = Vector2(24, 76)
	scroll.size = Vector2(174, 344)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	grid_container = GridContainer.new()
	grid_container.name = "GridBag"
	grid_container.columns = 5
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)
	scroll.add_child(grid_container)

	# 6. Base / Main Slot (CompoundItem_Main at 0xce=206, 0xa7=167, 44x44)
	main_slot_btn = _create_slot_button(Vector2(206, 167), Vector2(44, 44), true)
	main_slot_btn.name = "CompoundItem_Main"
	main_slot_btn.pressed.connect(_on_main_slot_clicked)
	main_slot_btn.gui_input.connect(_on_main_slot_gui_input)
	add_child(main_slot_btn)

	# 7. 4 Material / Sub Slots (CompoundItem_Sub at (i-2)*51+230 -> 230, 281, 332, 383, 38x38)
	var sub_y_positions: Array[float] = [230.0, 281.0, 332.0, 383.0]
	sub_slot_btns.clear()
	for i in range(4):
		var sub_btn := _create_slot_button(Vector2(206, sub_y_positions[i]), Vector2(38, 38), false)
		sub_btn.name = "CompoundItem_Sub_%d" % i
		sub_btn.pressed.connect(_on_sub_slot_clicked.bind(i))
		sub_btn.gui_input.connect(_on_sub_slot_gui_input.bind(i))
		add_child(sub_btn)
		sub_slot_btns.append(sub_btn)

	# 8. Status / Feedback Label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Place base & materials."
	status_label.position = Vector2(200, 72)
	status_label.size = Vector2(80, 84)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1.0))
	add_child(status_label)

	# 9. Compound Button (Btn_Compound_1 at X=83, Y=429, 56x20)
	btn_compound = TextureButton.new()
	btn_compound.name = "BtnCompound"
	btn_compound.texture_normal = _load_texture("assets/hud/btn_compound_normal.png")
	btn_compound.texture_hover = _load_texture("assets/hud/btn_compound_hover.png")
	btn_compound.texture_pressed = _load_texture("assets/hud/btn_compound_pressed.png")
	btn_compound.ignore_texture_size = true
	btn_compound.stretch_mode = TextureButton.STRETCH_SCALE
	btn_compound.position = Vector2(83, 429)
	btn_compound.size = Vector2(56, 20)
	btn_compound.pressed.connect(start_compound)
	add_child(btn_compound)

	# 9b. Bottom Close Button (Btn_Close_1 at X=159, Y=429, 56x20)
	btn_bottom_close = TextureButton.new()
	btn_bottom_close.name = "BtnBottomClose"
	btn_bottom_close.texture_normal = _load_texture("assets/hud/btn_close_1_normal.png")
	btn_bottom_close.texture_hover = _load_texture("assets/hud/btn_close_1_hover.png")
	btn_bottom_close.texture_pressed = _load_texture("assets/hud/btn_close_1_pressed.png")
	btn_bottom_close.ignore_texture_size = true
	btn_bottom_close.stretch_mode = TextureButton.STRETCH_SCALE
	btn_bottom_close.position = Vector2(159, 429)
	btn_bottom_close.size = Vector2(56, 20)
	btn_bottom_close.pressed.connect(close_window)
	add_child(btn_bottom_close)

	# 10. Compounding Animation Overlay (Centered over Main crucible at 228, 189 -> Vector2(183, 142))
	compounding_rect = TextureRect.new()
	compounding_rect.name = "CompoundingAnim"
	compounding_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	compounding_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	compounding_rect.position = Vector2(183, 142)
	compounding_rect.size = Vector2(FRAME_WIDTH, FRAME_HEIGHT)
	compounding_rect.visible = false
	compounding_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(compounding_rect)

	# 11. Audio Player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = &"Master"
	add_child(sfx_player)

func _create_slot_button(pos: Vector2, btn_size: Vector2, is_main: bool) -> TextureButton:
	var btn := TextureButton.new()
	btn.position = pos
	btn.size = btn_size
	btn.custom_minimum_size = btn_size
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	# Create slot backing panel
	var panel := Panel.new()
	panel.name = "SlotBacking"
	panel.size = btn_size
	panel.z_index = 0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The skin already draws the slot frames and their "x" placeholders, so the backing stays
	# transparent (a filled panel hid them behind grey boxes).
	var style := StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", style)
	btn.add_child(panel)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.z_index = 2
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size = Vector2(32, 32)
	icon_rect.position = (btn_size - Vector2(32, 32)) * 0.5
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon_rect)

	var count_lbl := Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.z_index = 3
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_lbl.size = Vector2(btn_size.x - 4, 16)
	count_lbl.position = Vector2(2, btn_size.y - 18)
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	count_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	count_lbl.add_theme_constant_override("outline_size", 2)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(count_lbl)

	return btn

func _load_animation_frames() -> void:
	_anim_frames.clear()
	var anim_tex := _load_texture("assets/hud/compounding_anim.png")
	if not anim_tex:
		return
	for i in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = anim_tex
		atlas.region = Rect2(0.0, float(i) * FRAME_HEIGHT, FRAME_WIDTH, FRAME_HEIGHT)
		_anim_frames.append(atlas)

func _update_checkbox_texture() -> void:
	if not btn_skill_check:
		return
	var path := "assets/hud/btn_checkbox_checked.png" if use_alchemy_skill else "assets/hud/btn_checkbox_unchecked.png"
	btn_skill_check.texture_normal = _load_texture(path)

func _on_skill_checkbox_toggled() -> void:
	use_alchemy_skill = not use_alchemy_skill
	_update_checkbox_texture()
	_play_sfx("res://assets/sound/wav0151.wav")
	if status_label:
		status_label.text = ("Skill: Junior Alchemy Active (+1 Rank tier)" if use_alchemy_skill else "Skill: Basic Synthesis Only")

func _on_compsk_tier_selected(tier: int) -> void:
	active_skill_tier = clampi(tier, 1, 3)
	use_alchemy_skill = true
	_update_checkbox_texture()
	_play_sfx("res://assets/sound/wav0151.wav")
	var tier_names: Array[String] = ["Junior Alchemy", "Intermediate Alchemy", "Senior Alchemy"]
	var tier_name: String = tier_names[active_skill_tier - 1]
	if lbl_skill:
		lbl_skill.text = "Use " + tier_name
	if status_label:
		status_label.text = "Active: %s" % tier_name

func _refresh_role_avatar() -> void:
	if not role_avatar_rect:
		return
	var rid: int = 6
	if _hud and "current_role_id" in _hud and int(_hud.current_role_id) > 0:
		rid = int(_hud.current_role_id)
	elif _hud and "player" in _hud and _hud.player != null and "role_id" in _hud.player and int(_hud.player.role_id) > 0:
		rid = int(_hud.player.role_id)
	var loader: Node = get_node_or_null("/root/ArchiveLoader") if is_inside_tree() else null
	if loader and loader.has_method("get_role_avatar"):
		var tex = loader.get_role_avatar(rid)
		if tex:
			role_avatar_rect.texture = tex
			return
	var fallback := "res://assets/hud/role_avatar_%d.png" % rid
	if ResourceLoader.exists(fallback):
		role_avatar_rect.texture = load(fallback)

## Populates the 50 inventory bag grid buttons
func _populate_bag_grid() -> void:
	if not grid_container:
		return
	for child in grid_container.get_children():
		child.queue_free()
	_bag_slot_buttons.clear()

	for i in range(50):
		var slot_btn := _create_slot_button(Vector2.ZERO, Vector2(32, 32), false)
		slot_btn.custom_minimum_size = Vector2(32, 32)
		if i < _inventory_items.size():
			var item: Dictionary = _inventory_items[i]
			_render_slot_content(slot_btn, item)
			slot_btn.tooltip_text = "%s (ID: %d)" % [item.get("name", "Item"), item.get("id", 0)]
			slot_btn.pressed.connect(_on_bag_item_clicked.bind(item, i))
			slot_btn.gui_input.connect(_on_bag_slot_gui_input.bind(item, i))
		else:
			_render_slot_content(slot_btn, {})
		grid_container.add_child(slot_btn)
		_bag_slot_buttons.append(slot_btn)

func _on_bag_slot_gui_input(event: InputEvent, item: Dictionary, bag_index: int) -> void:
	if is_compounding:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			_on_bag_item_clicked(item, bag_index)

func _on_main_slot_gui_input(event: InputEvent) -> void:
	if is_compounding:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			_on_main_slot_clicked()

func _on_sub_slot_gui_input(event: InputEvent, slot_idx: int) -> void:
	if is_compounding:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			_on_sub_slot_clicked(slot_idx)

func _render_slot_content(btn: TextureButton, data: Dictionary) -> void:
	var icon: TextureRect = btn.get_node_or_null("Icon") as TextureRect
	var count_lbl: Label = btn.get_node_or_null("CountLabel") as Label
	if not icon or not count_lbl:
		return
	
	icon.z_index = 2
	count_lbl.z_index = 3
	btn.move_child(icon, -1)
	btn.move_child(count_lbl, -1)
	
	if data.is_empty() or int(data.get("id", 0)) <= 0:
		icon.texture = null
		count_lbl.text = ""
		btn.tooltip_text = ""
		return
	
	var item_id: int = int(data.get("id", 0))
	var icon_id: int = int(data.get("icon_id", 1000))
	var count: int = int(data.get("count", 1))
	var item_name: String = str(data.get("name", "Item"))
	
	icon.texture = _resolve_item_icon(icon_id)
	count_lbl.text = str(count) if count > 1 else ""
	btn.tooltip_text = "%s (ID: %d)" % [item_name, item_id]

func _resolve_item_icon(icon_id: int) -> Texture2D:
	var loader: Node = get_node_or_null("/root/ArchiveLoader") if is_inside_tree() else null
	if loader and loader.has_method("get_item_icon"):
		var tex = loader.get_item_icon(icon_id)
		if tex: return tex
	var fallback_paths := [
		"res://assets/hud/icon_%d.png" % icon_id,
		"res://assets/hud/item_%d.png" % icon_id,
		"res://assets/hud/item_icon_sample.png"
	]
	for p in fallback_paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

## Handles placing an item from the bag into the next available compound slot
func _on_bag_item_clicked(item: Dictionary, bag_index: int) -> void:
	if is_compounding:
		return
	var item_id: int = int(item.get("id", 0))
	var item_name: String = str(item.get("name", ""))
	var is_book: bool = _is_alchemy_book(item_id, item_name)
	
	# 1. Check if item can go to main slot
	if main_slot_data.is_empty():
		if is_book:
			_show_error("Book can't be base item")
			return
		if _is_large_item(item_id, item_name):
			_show_error("Cant compound large item")
			return
		main_slot_data = _extract_one_from_bag(item, bag_index)
		_refresh_slots_ui()
		return
	
	# 2. Check if item can go to one of the 4 sub slots
	for i in range(4):
		if sub_slots_data[i].is_empty():
			if is_book:
				if _has_any_alchemy_book():
					_show_error("Can use only 1 Alchemy Book")
					return
			sub_slots_data[i] = _extract_one_from_bag(item, bag_index)
			_refresh_slots_ui()
			return
	
	_show_error("Compound material slots full!")

func _extract_one_from_bag(item: Dictionary, _bag_index: int) -> Dictionary:
	var extracted: Dictionary = item.duplicate(true)
	extracted["count"] = 1
	var remaining: int = int(item.get("count", 1)) - 1
	if remaining <= 0:
		_inventory_items.erase(item)
	else:
		item["count"] = remaining
	_populate_bag_grid()
	return extracted

func _on_main_slot_clicked() -> void:
	if is_compounding or main_slot_data.is_empty():
		return
	_return_slot_to_bag(main_slot_data)
	main_slot_data.clear()
	_refresh_slots_ui()

func _on_sub_slot_clicked(slot_idx: int) -> void:
	if is_compounding or slot_idx < 0 or slot_idx >= 4 or sub_slots_data[slot_idx].is_empty():
		return
	_return_slot_to_bag(sub_slots_data[slot_idx])
	sub_slots_data[slot_idx].clear()
	_refresh_slots_ui()

func _return_slot_to_bag(slot_data: Dictionary) -> void:
	var returned_id: int = int(slot_data.get("id", 0))
	var merged := false
	for item in _inventory_items:
		if int(item.get("id", 0)) == returned_id:
			item["count"] = int(item.get("count", 1)) + int(slot_data.get("count", 1))
			merged = true
			break
	if not merged:
		_inventory_items.append(slot_data.duplicate(true))
	_populate_bag_grid()

func _refresh_slots_ui(update_status: bool = true) -> void:
	if main_slot_btn:
		_render_slot_content(main_slot_btn, main_slot_data)
	for i in range(4):
		if i < sub_slot_btns.size():
			_render_slot_content(sub_slot_btns[i], sub_slots_data[i])
	
	if update_status and status_label:
		if main_slot_data.is_empty():
			status_label.text = ""
		else:
			var mats: int = _get_active_materials_count()
			status_label.text = "Materials: %d / 5 ready." % mats

func _get_active_materials_count() -> int:
	var cnt := 0
	if not main_slot_data.is_empty(): cnt += 1
	for s in sub_slots_data:
		if not s.is_empty(): cnt += 1
	return cnt

func _has_any_alchemy_book() -> bool:
	for s in sub_slots_data:
		if not s.is_empty() and _is_alchemy_book(int(s.get("id", 0)), str(s.get("name", ""))):
			return true
	return false

func _is_alchemy_book(id: int, item_name: String) -> bool:
	var n := item_name.to_lower()
	return n.contains("alchemy book") or n.contains("alchemy bk") or (id >= 47001 and id <= 47004)

func _is_large_item(_id: int, item_name: String) -> bool:
	var n := item_name.to_lower()
	return n.contains("canoe") or n.contains("raft") or n.contains("airship") or n.contains("car") or n.contains("tent")

func _show_error(msg: String) -> void:
	if status_label:
		status_label.text = msg
	if _hud and _hud.has_method("add_chat_message"):
		_hud.add_chat_message("System", msg, "System")
	_play_sfx("res://assets/sound/SEB0024.WAV")

## Initiates authentic compounding synthesis
func start_compound() -> void:
	if is_compounding:
		return
	
	# Validation Phase
	if main_slot_data.is_empty():
		_show_error("No materials to compound")
		return
	
	var total_mats := _get_active_materials_count()
	var has_book := _has_any_alchemy_book()
	
	if has_book:
		if total_mats < 3:
			_show_error("Use at least 2 mats and Alchemy Book")
			return
	else:
		if total_mats < 2:
			_show_error("Use at least 2 materials")
			return
	
	# Begin Compounding Animation Sequence
	is_compounding = true
	if btn_compound: btn_compound.disabled = true
	if status_label: status_label.text = "Compounding in progress..."
	if compounding_rect:
		compounding_rect.visible = true
		_current_frame_idx = 0
		_anim_timer = 0.0
	
	compound_started.emit()
	_play_sfx("res://assets/sound/SEB0008.WAV")

func _process(delta: float) -> void:
	if is_compounding:
		_anim_timer += delta
		if _anim_timer >= 0.05:
			_anim_timer = 0.0
			_current_frame_idx += 1
			if _current_frame_idx >= _anim_frames.size():
				_on_compound_animation_finished()
			elif compounding_rect:
				compounding_rect.texture = _anim_frames[_current_frame_idx]

func _on_compound_animation_finished() -> void:
	is_compounding = false
	if compounding_rect:
		compounding_rect.visible = false
		compounding_rect.texture = null
	if btn_compound:
		btn_compound.disabled = false
	
	# Execute Authentic Synthesis Formula
	var main_id: int = int(main_slot_data.get("id", 0))
	var main_rank: int = _resolve_item_rank(main_id)
	var catalyst_tier: int = 1 if use_alchemy_skill else 0
	
	for s in sub_slots_data:
		if not s.is_empty():
			var s_id: int = int(s.get("id", 0))
			if _is_alchemy_book(s_id, str(s.get("name", ""))):
				catalyst_tier += 2
	
	var synthesis_result := _calculate_authentic_result(main_id, main_rank, catalyst_tier)
	var res_id: int = synthesis_result["id"]
	var res_name: String = synthesis_result["name"]
	var res_icon: int = synthesis_result["icon"]
	var is_success: bool = synthesis_result["success"]
	var out_count: int = synthesis_result.get("count", 1)

	# Deduct consumed materials from client inventory
	_commit_inventory_deduction()

	# Award synthesized item to player inventory
	if _hud and _hud.has_method("add_inventory_item"):
		_hud.add_inventory_item(res_id, out_count, res_name, res_icon)
	
	var msg := ("Compound Success! Obtained %s!" % res_name) if is_success else ("Compound Failed: Obtained %s..." % res_name)
	if status_label: status_label.text = msg
	if _hud and _hud.has_method("add_chat_message"):
		_hud.add_chat_message("System", msg, "System")
	if _hud and _hud.has_method("show_center_notification"):
		_hud.show_center_notification(msg, res_icon)
	
	_play_sfx("res://assets/sound/wav9911.wav" if is_success else "res://assets/sound/SEB0024.WAV")
	
	# Clear compound slots and refresh
	main_slot_data.clear()
	for i in range(4): sub_slots_data[i].clear()
	_refresh_slots_ui(false)
	refresh_inventory_from_hud()
	
	compound_completed.emit(res_id, res_name, is_success)

func _calculate_authentic_result(main_id: int, main_rank: int, catalyst_tier: int) -> Dictionary:
	var db = get_node_or_null("/root/GameDatabase") if is_inside_tree() else null
	
	# 1. First, check if exact ingredients match a defined recipe from Compound2.Dat
	var placed_mats: Dictionary = {}
	if main_id > 0:
		placed_mats[main_id] = placed_mats.get(main_id, 0) + 1
	var sub_ranks: Array[int] = []
	for s in sub_slots_data:
		if not s.is_empty():
			var sid: int = int(s.get("id", 0))
			if sid > 0:
				if not _is_alchemy_book(sid, str(s.get("name", ""))):
					placed_mats[sid] = placed_mats.get(sid, 0) + 1
					sub_ranks.append(_resolve_item_rank(sid))
	
	var exact_recipe := find_matching_recipe(placed_mats)
	if not exact_recipe.is_empty():
		var res_id: int = exact_recipe.get("result_id", 0)
		var out_amt: int = exact_recipe.get("amount", 1)
		var res_name := "Synthesized Item"
		var res_icon := 1001
		if db and db.items:
			var rec_item = db.items.get_item(res_id)
			if rec_item:
				res_name = rec_item.name
				res_icon = rec_item.icon_id
		return {
			"id": res_id,
			"name": res_name,
			"icon": res_icon,
			"count": out_amt,
			"success": true
		}
	
	# 2. Authentic Alchemy Grade Synthesis Formula (Spec 37 / AC64)
	var avg_sub_rank: float = float(main_rank)
	if not sub_ranks.is_empty():
		var sum_r: int = 0
		for r in sub_ranks:
			sum_r += r
		avg_sub_rank = float(sum_r) / float(sub_ranks.size())
	
	var base_grade: int = int(floor((float(main_rank) + avg_sub_rank) / 2.0))
	var delta_g: int = 0
	if use_alchemy_skill:
		match active_skill_tier:
			1: # Junior Alchemy: -2 <= DeltaG <= +2, + catalyst book bonus
				delta_g = randi_range(-2, 2) + catalyst_tier
			2: # Intermediate Alchemy: -1 <= DeltaG <= +3, + catalyst book bonus
				delta_g = randi_range(-1, 3) + catalyst_tier
			3: # Senior Alchemy: 0 <= DeltaG <= +4, + catalyst book bonus
				delta_g = randi_range(0, 4) + catalyst_tier
			_:
				delta_g = randi_range(-2, 2) + catalyst_tier
	else:
		# Primary Alchemy (no skill): -3 <= DeltaG <= +1, no book bonus
		delta_g = randi_range(-3, 1)
	
	var target_rank: int = maxi(1, base_grade + delta_g)
	var is_success: bool = (delta_g >= 0) or (use_alchemy_skill and randf() < 0.75)
	
	if not is_success:
		# Compounding failure yields Slime / Trash (36001) or raw clay
		var trash_id: int = 36001
		var trash_name := "Slime"
		var trash_icon := 1077
		if db and db.items:
			var tr = db.items.get_item(trash_id)
			if tr:
				trash_name = tr.name
				trash_icon = tr.icon_id
		return {
			"id": trash_id,
			"name": trash_name,
			"icon": trash_icon,
			"count": 1,
			"success": false
		}
	
	# Try upgrading or matching an item in database with target rank
	if db and db.items:
		var candidate = db.items.get_item(main_id)
		if candidate and candidate.equip_pos > 0:
			# Look for higher tier equipment of same slot
			for test_id in range(main_id + 1, main_id + 30):
				var next_item = db.items.get_item(test_id)
				if next_item and next_item.equip_pos == candidate.equip_pos and next_item.get_rank() == target_rank:
					return {
						"id": test_id,
						"name": next_item.name,
						"icon": next_item.icon_id,
						"count": 1,
						"success": true
					}
		elif candidate and candidate.equip_pos == 0:
			var mat_name: String = str(candidate.get_material_name())
			for test_id in range(main_id + 1, main_id + 30):
				var next_mat = db.items.get_item(test_id)
				if next_mat and next_mat.get_material_name() == mat_name and next_mat.get_rank() == target_rank:
					return {
						"id": test_id,
						"name": next_mat.name,
						"icon": next_mat.icon_id,
						"count": 1,
						"success": true
					}
	
	# Standard fallback: upgrade item or create refined elixir
	var upgraded_id: int = main_id + 1 if main_id > 0 else 46001
	var rec_name := "Refined Elixir"
	var rec_icon := 1050
	if db and db.items:
		var rec = db.items.get_item(upgraded_id)
		if rec:
			rec_name = rec.name
			rec_icon = rec.icon_id if rec.icon_id > 0 else 1050
	
	return {
		"id": upgraded_id,
		"name": rec_name,
		"icon": rec_icon,
		"count": 1,
		"success": true
	}

func _resolve_item_rank(item_id: int) -> int:
	var db = get_node_or_null("/root/GameDatabase") if is_inside_tree() else null
	if db and db.items:
		var rec = db.items.get_item(item_id)
		if rec: return rec.get_rank()
	return 1

func _commit_inventory_deduction() -> void:
	if not _hud:
		return
	var items_to_remove: Array[int] = []
	if not main_slot_data.is_empty():
		items_to_remove.append(int(main_slot_data.get("id", 0)))
	for s in sub_slots_data:
		if not s.is_empty():
			items_to_remove.append(int(s.get("id", 0)))
	
	for item_id in items_to_remove:
		if _hud.has_method("remove_inventory_item"):
			_hud.remove_inventory_item(item_id, 1)
		elif _hud.has_method("remove_item_by_id"):
			_hud.remove_item_by_id(item_id, 1)
		elif "inventory" in _hud and _hud.inventory != null and _hud.inventory.has_method("remove_item_by_id"):
			_hud.inventory.remove_item_by_id(item_id, 1)
		elif "inventory_ctrl" in _hud and _hud.inventory_ctrl != null and _hud.inventory_ctrl.has_method("remove_item_by_id"):
			_hud.inventory_ctrl.remove_item_by_id(item_id, 1)

func close_window() -> void:
	is_compounding = false
	if compounding_rect:
		compounding_rect.visible = false
		compounding_rect.texture = null
	if btn_compound:
		btn_compound.disabled = false
	# Return placed items back to bag before closing
	if not main_slot_data.is_empty():
		_return_slot_to_bag(main_slot_data)
		main_slot_data.clear()
	for i in range(4):
		if not sub_slots_data[i].is_empty():
			_return_slot_to_bag(sub_slots_data[i])
			sub_slots_data[i].clear()
	_refresh_slots_ui()
	_play_sfx("res://assets/sound/wav0151.wav")
	visible = false
	window_closed.emit()

func toggle_window() -> void:
	if visible:
		close_window()
	else:
		if compounding_rect and not is_compounding:
			compounding_rect.visible = false
			compounding_rect.texture = null
		refresh_inventory_from_hud()
		_refresh_role_avatar()
		_refresh_slots_ui()
		visible = true

func _load_texture(rel_path: String) -> Texture2D:
	var res_path := rel_path if rel_path.begins_with("res://") else ("res://" + rel_path)
	if ResourceLoader.exists(res_path):
		return load(res_path)
	var abs_path := "D:/Godot/WonderlandOnline/wonderland-online-client/" + rel_path
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null

func _play_sfx(path: String) -> void:
	if not sfx_player or not sfx_player.is_inside_tree():
		return
	if ResourceLoader.exists(path):
		sfx_player.stream = load(path)
		sfx_player.play()

# Floating Draggable Window Implementation
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# Allow dragging when clicking upper header area (Y <= 45)
				if mb.position.y <= 45.0:
					_is_dragging = true
					_drag_offset = get_global_mouse_position() - global_position
			else:
				_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		var new_pos := get_global_mouse_position() - _drag_offset
		if get_viewport():
			var vp_size := get_viewport_rect().size
			new_pos.x = clampf(new_pos.x, 0.0, vp_size.x - FORM_WIDTH)
			new_pos.y = clampf(new_pos.y, 0.0, vp_size.y - FORM_HEIGHT)
		global_position = new_pos
