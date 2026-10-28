class_name HUDHotbar
extends RefCounted

const HotbarSlotButtonClass = preload("res://scripts/ui/hotbar_slot_button.gd")

## Sub-controller for Wonderland Online HUD Right Hotbar Dock (56x274).
## Encapsulates the 8 quickslots (F1..F8, 27px stride), 4-page paging mechanism,
## authentic background skin loading, drag-and-drop item/skill binding, and slot activation.

signal slot_activated(slot_index: int)
signal page_changed(page_index: int)

var _hud: Control = null

# Node references
var hotbar_dock: Control = null
var hotbar_bg: TextureRect = null
var slots_container: Control = null
var page_controls: Control = null
var btn_page_prev: BaseButton = null
var page_display: Control = null
var page_label: Label = null
var btn_page_next: BaseButton = null

# Slot arrays (active page)
var _hotkey_buttons: Array[Button] = []
var _hotkey_icons: Array[TextureRect] = []

# 4 Pages of 8 slots: each holds null or {type: "item"|"skill", id: int, name: String, icon_tex: Texture2D}
var _current_page: int = 0
var _hotbar_data: Array = []
var _page_textures: Array[Texture2D] = []

## Initializes references, loads background art, sets up 4 pages and 8 quickslots
func setup(hud: Control, nodes: Dictionary = {}) -> void:
	_hud = hud
	
	hotbar_dock = nodes.get("hotbar_dock", hud.get_node_or_null("HotbarDock"))
	hotbar_bg = nodes.get("hotbar_bg", hud.get_node_or_null("HotbarDock/HotbarBackground"))
	slots_container = nodes.get("slots_container", hud.get_node_or_null("HotbarDock/SlotsContainer"))
	
	_init_page_data()
	_load_background()
	_setup_slots()
	_setup_page_controls()
	_refresh_slots()

## Initializes 4 pages of 8 slots each and loads page indicator textures
func _init_page_data() -> void:
	_hotbar_data.clear()
	for p in range(4):
		var page_arr: Array = []
		for s in range(8):
			page_arr.append(null)
		_hotbar_data.append(page_arr)
	
	_page_textures.clear()
	for p in range(1, 5):
		var tex := _load_texture_file("assets/hud/hotbar_page_%d.png" % p)
		_page_textures.append(tex)
	
	# Sample default icons for first two slots on page 0
	var loader := _get_archive_loader()
	if loader and loader.has_method("get_item_icon"):
		var item_tex = loader.get_item_icon(1000)
		if item_tex:
			_hotbar_data[0][0] = {
				"type": "item",
				"id": 1000,
				"name": "Healing Potion",
				"icon_tex": item_tex
			}
		var herb_tex = loader.get_item_icon(1001)
		if herb_tex:
			_hotbar_data[0][1] = {
				"type": "item",
				"id": 1001,
				"name": "Mana Herb",
				"icon_tex": herb_tex
			}

## Loads authentic Form_HotKey_V.bmp from ArchiveLoader
func _load_background() -> void:
	var loader := _get_archive_loader()
	if loader and hotbar_bg and loader.has_method("get_ui_texture"):
		var hk_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_HotKey_V.bmp")
		if hk_tex:
			hotbar_bg.texture = hk_tex
	elif hotbar_bg and not hotbar_bg.texture:
		var tex := _load_texture_file("assets/hud/hud_hotkey_vertical.png")
		if tex:
			hotbar_bg.texture = tex

## Sets up the 8 vertical hotbar action slots (F1..F8, 27px stride)
func _setup_slots() -> void:
	if not slots_container:
		return
	
	_hotkey_buttons.clear()
	_hotkey_icons.clear()
	
	for i in range(8):
		var slot_btn = slots_container.get_node_or_null("Slot%d" % (i + 1))
		if not slot_btn:
			slot_btn = HotbarSlotButtonClass.new()
			slot_btn.name = "Slot%d" % (i + 1)
			slot_btn.position = Vector2(6, 28 + i * 27)
			slot_btn.size = Vector2(44, 25)
			slot_btn.flat = true
			slots_container.add_child(slot_btn)
		else:
			slot_btn.position = Vector2(6, 28 + i * 27)
			slot_btn.size = Vector2(44, 25)
		
		slot_btn.slot_index = i
		slot_btn.hotbar_ref = self
		
		var slot_idx: int = i
		var on_pressed := func() -> void:
			activate_slot(slot_idx)
		if not slot_btn.pressed.is_connected(on_pressed):
			slot_btn.pressed.connect(on_pressed)
		_hotkey_buttons.append(slot_btn)
		
		# Key indicator label: preserved for test suite / screen-readers, but kept visually hidden
		# so the authentic F1..F8 artwork already baked into Form_HotKey_V.bmp is cleanly displayed.
		var lbl: Label = slot_btn.get_node_or_null("KeyLabel")
		if not lbl:
			lbl = Label.new()
			lbl.name = "KeyLabel"
			lbl.position = Vector2(0, 5)
			lbl.size = Vector2(18, 15)
			lbl.text = "F%d" % (i + 1)
			lbl.visible = false
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_btn.add_child(lbl)
		else:
			lbl.text = "F%d" % (i + 1)
			lbl.visible = false
		
		# Item/Skill icon placed in 24x24 authentic slot box (x=19..43) side-by-side with label
		var icon: TextureRect = slot_btn.get_node_or_null("Icon")
		if not icon:
			icon = TextureRect.new()
			icon.name = "Icon"
			icon.position = Vector2(19, 1)
			icon.size = Vector2(24, 24)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot_btn.add_child(icon)
		else:
			icon.position = Vector2(19, 1)
			icon.size = Vector2(24, 24)
		_hotkey_icons.append(icon)

## Sets up authentic 4-page paging controls (◀ ① ▶) at bottom of HotbarDock (y = 246..272)
func _setup_page_controls() -> void:
	var parent_dock: Control = hotbar_dock if hotbar_dock else slots_container
	if not parent_dock:
		return
	
	page_controls = parent_dock.get_node_or_null("PageControls") as Control
	if not page_controls:
		page_controls = Control.new()
		page_controls.name = "PageControls"
		page_controls.position = Vector2(0, 246)
		page_controls.size = Vector2(56, 26)
		page_controls.mouse_filter = Control.MOUSE_FILTER_PASS
		parent_dock.add_child(page_controls)
	
	# Previous Page button (◀)
	var btn_prev: TextureButton = page_controls.get_node_or_null("BtnPagePrev") as TextureButton
	if not btn_prev:
		btn_prev = TextureButton.new()
		btn_prev.name = "BtnPagePrev"
		btn_prev.position = Vector2(6, 4)
		btn_prev.size = Vector2(14, 16)
		btn_prev.custom_minimum_size = Vector2(14, 16)
		btn_prev.ignore_texture_size = true
		btn_prev.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn_prev.tooltip_text = "Previous Page (1-4)"
		var p_norm := _load_texture_file("assets/hud/btn_hotbar_prev_normal.png")
		var p_hov := _load_texture_file("assets/hud/btn_hotbar_prev_hover.png")
		var p_press := _load_texture_file("assets/hud/btn_hotbar_prev_pressed.png")
		if p_norm: btn_prev.texture_normal = p_norm
		if p_hov: btn_prev.texture_hover = p_hov
		if p_press: btn_prev.texture_pressed = p_press
		page_controls.add_child(btn_prev)
	btn_page_prev = btn_prev
	if not btn_page_prev.pressed.is_connected(prev_page):
		btn_page_prev.pressed.connect(prev_page)
	
	# Page Number Graphic / Label
	var p_rect: TextureRect = page_controls.get_node_or_null("PageDisplay") as TextureRect
	if not p_rect:
		p_rect = TextureRect.new()
		p_rect.name = "PageDisplay"
		p_rect.position = Vector2(21, 4)
		p_rect.size = Vector2(14, 16)
		p_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		page_controls.add_child(p_rect)
	page_display = p_rect
	
	var p_lbl: Label = page_controls.get_node_or_null("PageLabel") as Label
	if not p_lbl:
		p_lbl = Label.new()
		p_lbl.name = "PageLabel"
		p_lbl.position = Vector2(20, 2)
		p_lbl.size = Vector2(16, 18)
		p_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p_lbl.add_theme_font_size_override("font_size", 11)
		p_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1.0))
		p_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		p_lbl.add_theme_constant_override("shadow_offset_x", 1)
		p_lbl.add_theme_constant_override("shadow_offset_y", 1)
		p_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		page_controls.add_child(p_lbl)
	page_label = p_lbl
	
	# Next Page button (▶)
	var btn_next: TextureButton = page_controls.get_node_or_null("BtnPageNext") as TextureButton
	if not btn_next:
		btn_next = TextureButton.new()
		btn_next.name = "BtnPageNext"
		btn_next.position = Vector2(36, 4)
		btn_next.size = Vector2(14, 16)
		btn_next.custom_minimum_size = Vector2(14, 16)
		btn_next.ignore_texture_size = true
		btn_next.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn_next.tooltip_text = "Next Page (1-4)"
		var n_norm := _load_texture_file("assets/hud/btn_hotbar_next_normal.png")
		var n_hov := _load_texture_file("assets/hud/btn_hotbar_next_hover.png")
		var n_press := _load_texture_file("assets/hud/btn_hotbar_next_pressed.png")
		if n_norm: btn_next.texture_normal = n_norm
		if n_hov: btn_next.texture_hover = n_hov
		if n_press: btn_next.texture_pressed = n_press
		page_controls.add_child(btn_next)
	btn_page_next = btn_next
	if not btn_page_next.pressed.is_connected(next_page):
		btn_page_next.pressed.connect(next_page)
	
	_update_page_display()

## Switches to a specific hotbar page (0..3)
func set_page(page_index: int) -> void:
	_current_page = posmod(page_index, 4)
	_update_page_display()
	_refresh_slots()
	page_changed.emit(_current_page)
	if _hud and _hud.has_signal("hotbar_page_changed"):
		_hud.emit_signal("hotbar_page_changed", _current_page)

## Returns current active hotbar page (0..3)
func get_current_page() -> int:
	return _current_page

## Cycles to the previous page
func prev_page() -> void:
	set_page(_current_page - 1)

## Cycles to the next page
func next_page() -> void:
	set_page(_current_page + 1)

## Updates the page indicator graphic and label
func _update_page_display() -> void:
	if page_display is TextureRect:
		if _current_page >= 0 and _current_page < _page_textures.size() and _page_textures[_current_page] != null:
			(page_display as TextureRect).texture = _page_textures[_current_page]
			(page_display as TextureRect).visible = true
			if page_label:
				page_label.visible = false
		else:
			(page_display as TextureRect).visible = false
			if page_label:
				page_label.visible = true
	
	var circled_nums = ["①", "②", "③", "④"]
	var str_num: String = circled_nums[_current_page] if _current_page < circled_nums.size() else str(_current_page + 1)
	if page_label:
		page_label.text = str_num
	
	var tip := "Hotbar Page %d / 4" % (_current_page + 1)
	if page_display: page_display.tooltip_text = tip
	if page_label: page_label.tooltip_text = tip

## Refreshes slot icons and tooltips from current page data
func _refresh_slots() -> void:
	for i in range(8):
		if i >= _hotkey_icons.size() or i >= _hotkey_buttons.size():
			continue
		var entry = _hotbar_data[_current_page][i] if _current_page < _hotbar_data.size() else null
		var icon: TextureRect = _hotkey_icons[i]
		var btn: Button = _hotkey_buttons[i]
		if entry != null and entry is Dictionary:
			icon.texture = entry.get("icon_tex", null)
			btn.tooltip_text = "[F%d] %s" % [i + 1, str(entry.get("name", "Action Slot"))]
		else:
			icon.texture = null
			btn.tooltip_text = "F%d (Empty - Drag item or skill here)" % (i + 1)

## Activates hotbar slot (0..7 for F1..F8) on current page
func activate_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= 8:
		return
	slot_activated.emit(slot_index)
	if _hud:
		if _hud.has_signal("hotkey_action_triggered"):
			_hud.emit_signal("hotkey_action_triggered", slot_index)
	
	var entry = _hotbar_data[_current_page][slot_index] if _current_page < _hotbar_data.size() else null
	if entry != null and entry is Dictionary:
		var etype: String = str(entry.get("type", ""))
		var eid: int = int(entry.get("id", 0))
		var ename: String = str(entry.get("name", "Action"))
		
		if etype == "item":
			var inv_ctrl = _hud.get("inventory_ctrl") if _hud else null
			var used: bool = false
			if inv_ctrl and "inventory_data" in inv_ctrl:
				for inv_i in range(inv_ctrl.inventory_data.size()):
					var itm = inv_ctrl.inventory_data[inv_i]
					if itm is Dictionary and int(itm.get("id", 0)) == eid:
						if inv_ctrl.has_method("use_or_equip_inventory_item"):
							inv_ctrl.use_or_equip_inventory_item(inv_i)
							used = true
							break
			if not used:
				if _hud and _hud.has_method("add_chat_message"):
					_hud.call("add_chat_message", "System", "Used item: %s." % ename, "System")
		elif etype == "skill":
			if _hud and _hud.has_method("use_skill"):
				_hud.call("use_skill", eid)
			elif _hud and _hud.has_method("add_chat_message"):
				_hud.call("add_chat_message", "System", "Cast skill: %s." % ename, "System")
	else:
		if _hud and _hud.has_method("add_chat_message"):
			_hud.call("add_chat_message", "System", "Action Slot F%d (Page %d) is empty." % [slot_index + 1, _current_page + 1], "System")

## Drag & drop handler: Initiates drag from a hotbar slot
func get_slot_drag_data(slot_idx: int) -> Variant:
	if slot_idx < 0 or slot_idx >= 8:
		return null
	var entry = _hotbar_data[_current_page][slot_idx] if _current_page < _hotbar_data.size() else null
	if entry == null or not (entry is Dictionary):
		return null
	return {
		"type": "hotbar",
		"page": _current_page,
		"slot_index": slot_idx,
		"entry": entry,
		"icon_tex": entry.get("icon_tex", null),
		"id": entry.get("id", 0),
		"name": entry.get("name", "")
	}

## Drag & drop handler: Validates drop target on a hotbar slot
func can_drop_on_slot(_slot_idx: int, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var dtype: String = str(data.get("type", ""))
	return dtype in ["item", "inventory", "skill", "hotbar"]

## Drag & drop handler: Drops an item, skill, or hotbar entry onto a slot
func drop_on_slot(slot_idx: int, data: Variant) -> void:
	if not can_drop_on_slot(slot_idx, data):
		return
	var dtype: String = str(data.get("type", ""))
	var loader := _get_archive_loader()
	
	if dtype == "inventory":
		var itm: Dictionary = data.get("item", {})
		var iid: int = int(itm.get("id", 0))
		var iname: String = str(itm.get("name", "Item %d" % iid))
		var itex: Texture2D = data.get("icon_tex", null)
		if not itex and loader and loader.has_method("get_item_icon"):
			itex = loader.get_item_icon(iid)
		_hotbar_data[_current_page][slot_idx] = {
			"type": "item",
			"id": iid,
			"name": iname,
			"icon_tex": itex
		}
		_refresh_slots()
		if _hud and _hud.has_method("add_chat_message"):
			_hud.call("add_chat_message", "System", "Assigned %s to slot F%d (Page %d)." % [iname, slot_idx + 1, _current_page + 1], "System")
			
	elif dtype == "item":
		var iid: int = int(data.get("id", 0))
		var iname: String = str(data.get("name", "Item %d" % iid))
		var itex: Texture2D = data.get("icon_tex", null)
		if not itex and loader and loader.has_method("get_item_icon"):
			itex = loader.get_item_icon(iid)
		_hotbar_data[_current_page][slot_idx] = {
			"type": "item",
			"id": iid,
			"name": iname,
			"icon_tex": itex
		}
		_refresh_slots()
		if _hud and _hud.has_method("add_chat_message"):
			_hud.call("add_chat_message", "System", "Assigned %s to slot F%d (Page %d)." % [iname, slot_idx + 1, _current_page + 1], "System")

	elif dtype == "skill":
		var sid: int = int(data.get("id", 0))
		var sname: String = str(data.get("name", "Skill %d" % sid))
		var stex: Texture2D = data.get("icon_tex", null)
		if not stex and loader and loader.has_method("get_skill_icon"):
			stex = loader.get_skill_icon(sid)
		_hotbar_data[_current_page][slot_idx] = {
			"type": "skill",
			"id": sid,
			"name": sname,
			"icon_tex": stex
		}
		_refresh_slots()
		if _hud and _hud.has_method("add_chat_message"):
			_hud.call("add_chat_message", "System", "Assigned %s to slot F%d (Page %d)." % [sname, slot_idx + 1, _current_page + 1], "System")

	elif dtype == "hotbar":
		var from_page: int = int(data.get("page", _current_page))
		var from_slot: int = int(data.get("slot_index", 0))
		var temp = _hotbar_data[_current_page][slot_idx]
		_hotbar_data[_current_page][slot_idx] = _hotbar_data[from_page][from_slot]
		_hotbar_data[from_page][from_slot] = temp
		_refresh_slots()

## Binds a skill to a hotbar slot (0..7 for F1..F8) on the active or specified page
func bind_skill(slot_index: int, skill_id: int, skill_name: String = "", icon_tex: Texture2D = null, page_index: int = -1) -> bool:
	if slot_index < 0 or slot_index >= 8:
		return false
	var page: int = _current_page if page_index < 0 else clampi(page_index, 0, 3)
	if not icon_tex:
		var loader := _get_archive_loader()
		if loader and loader.has_method("get_skill_icon"):
			icon_tex = loader.get_skill_icon(skill_id)
		elif ResourceLoader.exists("res://assets/hud/icon_element_3.png"):
			icon_tex = load("res://assets/hud/icon_element_3.png")
	if skill_name.is_empty():
		skill_name = "Skill %d" % skill_id
	_hotbar_data[page][slot_index] = {
		"type": "skill",
		"id": skill_id,
		"name": skill_name,
		"icon_tex": icon_tex
	}
	_refresh_slots()
	if _hud and _hud.has_method("add_chat_message"):
		_hud.call("add_chat_message", "System", "Assigned %s to slot F%d (Page %d)." % [skill_name, slot_index + 1, page + 1], "System")
	return true

## Returns the bound entry dictionary in slot_index (0..7) on current page (or null if empty)
func get_slot_data(slot_index: int, page_index: int = -1) -> Variant:
	if slot_index < 0 or slot_index >= 8:
		return null
	var page: int = _current_page if page_index < 0 else clampi(page_index, 0, 3)
	return _hotbar_data[page][slot_index]

## Handles right-click clear on a slot
func on_slot_right_clicked(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < 8:
		var entry = _hotbar_data[_current_page][slot_idx]
		if entry != null:
			var ename: String = str(entry.get("name", "Slot"))
			_hotbar_data[_current_page][slot_idx] = null
			_refresh_slots()
			if _hud and _hud.has_method("add_chat_message"):
				_hud.call("add_chat_message", "System", "Cleared %s from slot F%d." % [ename, slot_idx + 1], "System")

## Sets icon texture for a specific hotbar slot on active page
func set_slot_icon(slot_index: int, texture: Texture2D) -> void:
	if slot_index >= 0 and slot_index < _hotkey_icons.size():
		_hotkey_icons[slot_index].texture = texture

## Returns Button node for a slot
func get_slot_button(slot_index: int) -> Button:
	if slot_index >= 0 and slot_index < _hotkey_buttons.size():
		return _hotkey_buttons[slot_index]
	return null

## Returns TextureRect icon node for a slot
func get_slot_icon(slot_index: int) -> TextureRect:
	if slot_index >= 0 and slot_index < _hotkey_icons.size():
		return _hotkey_icons[slot_index]
	return null

## Sets slot entry explicitly
func set_slot_entry(slot_index: int, entry: Dictionary, page: int = -1) -> void:
	var target_page := _current_page if page < 0 else page
	if target_page >= 0 and target_page < _hotbar_data.size():
		if slot_index >= 0 and slot_index < 8:
			_hotbar_data[target_page][slot_index] = entry
			if target_page == _current_page:
				_refresh_slots()

## Returns slot entry
func get_slot_entry(slot_index: int, page: int = -1) -> Dictionary:
	var target_page := _current_page if page < 0 else page
	if target_page >= 0 and target_page < _hotbar_data.size():
		if slot_index >= 0 and slot_index < 8:
			var e = _hotbar_data[target_page][slot_index]
			if e is Dictionary:
				return e
	return {}

## Clears slot entry
func clear_slot(slot_index: int, page: int = -1) -> void:
	var target_page := _current_page if page < 0 else page
	if target_page >= 0 and target_page < _hotbar_data.size():
		if slot_index >= 0 and slot_index < 8:
			_hotbar_data[target_page][slot_index] = null
			if target_page == _current_page:
				_refresh_slots()

## Helper to fetch ArchiveLoader
func _get_archive_loader() -> Node:
	if _hud and _hud.is_inside_tree():
		var l := _hud.get_node_or_null("/root/ArchiveLoader")
		if l: return l
	if Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			return st.root.get_node_or_null("ArchiveLoader")
	return null

## Helper to load texture from resource or filesystem path
func _load_texture_file(rel_path: String) -> Texture2D:
	var res_path: String = rel_path if rel_path.begins_with("res://") else ("res://" + rel_path)
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is Texture2D:
			return res
	var abs_path: String = "D:/Godot/WonderlandOnline/wonderland-online-client/" + rel_path if not rel_path.begins_with("res://") else ProjectSettings.globalize_path(rel_path)
	if not FileAccess.file_exists(abs_path):
		return null
	var img := Image.new()
	var err := img.load(abs_path)
	if err == OK:
		return ImageTexture.create_from_image(img)
	return null
