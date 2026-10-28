class_name HUDInventory
extends RefCounted

## Dedicated controller encapsulating the 45-slot inventory grid, item operations,
## drag-and-drop mechanics, quick-equip/use, gold tracking, and authentic hover tooltips.

const ItemTooltipScene = preload("res://scripts/ui/item_tooltip.gd")

var hud: Control = null
var inventory_grid: Control = null
var gold_label: Label = null
var status_dock: Control = null
var item_tooltip: PanelContainer = null
var close_button: Button = null

var inventory_slots: Array[Button] = []
var inventory_icons: Array[TextureRect] = []
var inventory_counts: Array[Label] = []
var inventory_data: Array[Dictionary] = []
var current_gold: int = 0
var current_page: int = 0
const TOTAL_PAGES: int = 2
signal page_changed(new_page: int)

func set_page(page: int) -> void:
	current_page = clampi(page, 0, TOTAL_PAGES - 1)
	page_changed.emit(current_page)
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", "Inventory Page: %d/%d" % [current_page + 1, TOTAL_PAGES], "System")

## Closes / hides the inventory and character status window
func close_inventory() -> void:
	if inventory_grid and inventory_grid.get_parent():
		inventory_grid.get_parent().visible = false
	var char_win = hud.get_node_or_null("FloatingWindows/CharacterWindow") if hud else null
	if char_win:
		char_win.visible = false
	var inv_win = hud.get_node_or_null("FloatingWindows/InventoryWindow") if hud else null
	if inv_win:
		inv_win.visible = false
	if hud and "window_manager_ctrl" in hud and hud.window_manager_ctrl:
		hud.window_manager_ctrl.window_toggled.emit("CharacterWindow", false)
		hud.window_manager_ctrl.window_toggled.emit("InventoryWindow", false)

## Initializes and wires up the inventory sub-controller with node references
func setup(p_hud: Control, nodes: Dictionary) -> void:
	hud = p_hud
	inventory_grid = nodes.get("inventory_grid", null) as Control
	gold_label = nodes.get("gold_label", null) as Label
	status_dock = nodes.get("status_dock", null) as Control
	item_tooltip = nodes.get("item_tooltip", null) as PanelContainer

	# Ensure grid position is shifted down 4px (Y=71.0) to align with authentic WLO inventory parchment grid
	if inventory_grid:
		inventory_grid.position.y = 71.0

	# Wire ornate close button
	close_button = nodes.get("inventory_close_button", null) as Button
	if not close_button and inventory_grid and inventory_grid.get_parent():
		close_button = inventory_grid.get_parent().get_node_or_null("CloseButton") as Button
	if not close_button and hud:
		close_button = hud.get_node_or_null("FloatingWindows/CharacterWindow/CloseButton") as Button
	if close_button:
		if not close_button.pressed.is_connected(close_inventory):
			close_button.pressed.connect(close_inventory)

	var inv_win = hud.get_node_or_null("FloatingWindows/InventoryWindow") if hud else null
	if inv_win:
		var inv_close_btn = inv_win.get_node_or_null("CloseButton") as Button
		if inv_close_btn and not inv_close_btn.pressed.is_connected(close_inventory):
			inv_close_btn.pressed.connect(close_inventory)

	if not item_tooltip and hud:
		var existing_tooltip := hud.get_node_or_null("ItemTooltip") as PanelContainer
		if existing_tooltip:
			item_tooltip = existing_tooltip
		else:
			item_tooltip = ItemTooltipScene.new()
			item_tooltip.name = "ItemTooltip"
			hud.add_child(item_tooltip)

	_setup_grid()
	_populate_starter_items()

## Configures the 5x9 (45 slots) authentic inventory grid
func _setup_grid() -> void:
	if not inventory_grid:
		return

	inventory_slots.clear()
	inventory_icons.clear()
	inventory_counts.clear()
	inventory_data.clear()
	inventory_data.resize(45)
	for idx in range(45):
		inventory_data[idx] = {}

	const GRID_COLS: int = 5
	const GRID_ROWS: int = 9
	const SLOT_STRIDE: int = 34
	const SLOT_SIZE := Vector2(34, 34)

	var normal_style := StyleBoxEmpty.new()
	var focus_style := StyleBoxEmpty.new()

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.12)
	hover_style.border_color = Color(1.0, 0.9, 0.4, 0.75)
	hover_style.border_width_left = 1
	hover_style.border_width_top = 1
	hover_style.border_width_right = 1
	hover_style.border_width_bottom = 1
	hover_style.corner_radius_top_left = 2
	hover_style.corner_radius_top_right = 2
	hover_style.corner_radius_bottom_right = 2
	hover_style.corner_radius_bottom_left = 2

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.25)
	pressed_style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	pressed_style.border_width_left = 1
	pressed_style.border_width_top = 1
	pressed_style.border_width_right = 1
	pressed_style.border_width_bottom = 1
	pressed_style.corner_radius_top_left = 2
	pressed_style.corner_radius_top_right = 2
	pressed_style.corner_radius_bottom_right = 2
	pressed_style.corner_radius_bottom_left = 2

	for i in range(GRID_COLS * GRID_ROWS):
		var col: int = i % GRID_COLS
		var row: int = int(i / GRID_COLS)
		var slot_pos := Vector2(col * SLOT_STRIDE, row * SLOT_STRIDE)

		var slot_btn: Button = inventory_grid.get_node_or_null("Slot%d" % i) as Button
		if not slot_btn:
			var slot_script = load("res://scripts/ui/inventory_slot_button.gd")
			if slot_script:
				slot_btn = Button.new()
				slot_btn.set_script(slot_script)
			else:
				slot_btn = Button.new()
			slot_btn.name = "Slot%d" % i
			inventory_grid.add_child(slot_btn)

		if "hud_ref" in slot_btn:
			slot_btn.hud_ref = hud
		if "slot_index" in slot_btn:
			slot_btn.slot_index = i

		slot_btn.position = slot_pos
		slot_btn.custom_minimum_size = SLOT_SIZE
		slot_btn.size = SLOT_SIZE
		slot_btn.flat = true
		slot_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		slot_btn.add_theme_stylebox_override("normal", normal_style)
		slot_btn.add_theme_stylebox_override("hover", hover_style)
		slot_btn.add_theme_stylebox_override("pressed", pressed_style)
		slot_btn.add_theme_stylebox_override("focus", focus_style)

		var slot_idx: int = i
		if not slot_btn.pressed.is_connected(func(): _on_inventory_slot_clicked(slot_idx)):
			slot_btn.pressed.connect(func(): _on_inventory_slot_clicked(slot_idx))

		inventory_slots.append(slot_btn)

		var icon: TextureRect = slot_btn.get_node_or_null("Icon") as TextureRect
		if not icon:
			icon = TextureRect.new()
			icon.name = "Icon"
			slot_btn.add_child(icon)
		icon.position = Vector2(1, 1)
		icon.size = Vector2(32, 32)
		icon.z_index = 2
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_icons.append(icon)

		var count_lbl: Label = slot_btn.get_node_or_null("CountLabel") as Label
		if not count_lbl:
			count_lbl = Label.new()
			count_lbl.name = "CountLabel"
			slot_btn.add_child(count_lbl)
		count_lbl.position = Vector2(2, 18)
		count_lbl.size = Vector2(30, 14)
		count_lbl.z_index = 3
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_lbl.add_theme_font_size_override("font_size", 9)
		count_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		count_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
		count_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		count_lbl.add_theme_constant_override("shadow_offset_x", 1)
		count_lbl.add_theme_constant_override("shadow_offset_y", 1)
		count_lbl.add_theme_constant_override("outline_size", 1)
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_lbl.text = ""
		inventory_counts.append(count_lbl)

## Populates starting inventory items from PServer defaults
func _populate_starter_items() -> void:
	set_inventory_data_item(0, create_item_record(34038, 1227, 1, "Notepad", "Beginner guide and notepad", ""))
	set_inventory_data_item(1, create_item_record(34058, 1651, 1, "Remote Control", "Auto-combat assistant controller", ""))
	set_inventory_data_item(2, create_item_record(32176, 1042, 50, "Fugu Hot Pot", "Full recovery food", ""))
	set_inventory_data_item(3, create_item_record(34014, 1859, 10, "Tao Rice Ball", "Pet and character food", ""))
	set_inventory_data_item(4, create_item_record(34026, 1768, 5, "Protective EXP Pill", "Prevents EXP loss upon death", ""))
	set_inventory_data_item(5, create_item_record(34169, 3025, 1, "Bamboo Dragonfly", "Starter flying mount vehicle", ""))
	set_inventory_data_item(6, create_item_record(34190, 2039, 3, "10X Holy EXP Potion", "Boosts experience gain", ""))
	set_inventory_data_item(7, create_item_record(34253, 3061, 5, "Training Ticket", "Training island pass", ""))
	set_inventory_data_item(8, create_item_record(32011, 1011, 10, "Bread", "Restores 50 HP", ""))
	set_inventory_data_item(9, create_item_record(32002, 1292, 5, "Rice Wine", "Restores 30 SP", ""))
	set_inventory_data_item(10, create_item_record(48010, 8000, 1, "Raft", "Starter water vehicle for navigating ocean and rivers", ""))

## Creates a standard item record dictionary with metadata
func create_item_record(
	id: int, icon_id: int, count: int, iname: String, desc: String,
	equip_slot: String = "", jma: String = "", jmp: String = "", stats: Dictionary = {}
) -> Dictionary:
	var final_icon: int = icon_id
	if id > 0 and (final_icon <= 0 or final_icon == id):
		var res: int = _resolve_item_icon_id(id)
		if res > 0:
			final_icon = res

	var hp_rest: int = 0
	var sp_rest: int = 0
	var amity_rest: int = 0
	var final_desc: String = desc
	var final_name: String = iname
	var final_equip: String = equip_slot

	if id > 0:
		var db = _get_game_database()
		if db and "items" in db and db.items:
			var rec = db.items.get_item(id)
			if rec:
				if final_name.is_empty():
					final_name = rec.name
				if final_desc.is_empty():
					final_desc = rec.description
				if final_equip.is_empty() and rec.equip_pos > 0 and rec.equip_pos <= 6:
					match rec.equip_pos:
						1: final_equip = "head"
						2: final_equip = "body"
						3: final_equip = "weapon"
						4: final_equip = "wrist"
						5: final_equip = "shoes"
						6: final_equip = "special"
				if rec.has_method("get_hp_restore"):
					hp_rest = rec.get_hp_restore()
				if rec.has_method("get_sp_restore"):
					sp_rest = rec.get_sp_restore()
				if rec.has_method("get_amity_restore"):
					amity_rest = rec.get_amity_restore()

	return {
		"id": id,
		"icon_id": final_icon,
		"count": count,
		"name": final_name,
		"desc": final_desc,
		"description": final_desc,
		"equip_slot": final_equip,
		"jma": jma,
		"jmp": jmp,
		"stats": stats,
		"hp_restore": hp_rest,
		"sp_restore": sp_rest,
		"amity_restore": amity_rest
	}

## Adds an item to the first available inventory slot (or stacks with existing)
func add_inventory_item(item_id: int, count: int = 1, item_name: String = "", icon_id: int = -1, p_desc: String = "") -> bool:
	var final_icon: int = icon_id
	var desc: String = p_desc

	if final_icon <= 0 or item_name.is_empty():
		var db = _get_game_database()
		if db and "items" in db and db.items:
			var rec = db.items.get_item(item_id)
			if rec:
				if final_icon <= 0:
					final_icon = rec.icon_id
				if item_name.is_empty():
					item_name = rec.name
				if desc.is_empty():
					desc = rec.description

	# Check if existing item can be stacked
	for i in range(inventory_data.size()):
		var itm: Dictionary = inventory_data[i]
		if not itm.is_empty() and int(itm.get("id", 0)) == item_id:
			var cur_count: int = int(itm.get("count", 1))
			itm["count"] = cur_count + count
			_refresh_inventory_slot(i)
			return true

	# Find first empty slot
	for i in range(inventory_data.size()):
		if inventory_data[i].is_empty() or int(inventory_data[i].get("id", 0)) <= 0:
			var rec := create_item_record(item_id, final_icon, count, item_name, desc, "")
			set_inventory_data_item(i, rec)
			return true

	_log_system_message("Inventory is full!")
	return false

## Removes an item from the inventory by ID and count. Returns true if found and deducted.
func remove_item_by_id(item_id: int, count: int = 1) -> bool:
	var needed: int = count
	for i in range(inventory_data.size()):
		var itm: Dictionary = inventory_data[i]
		if not itm.is_empty() and int(itm.get("id", 0)) == item_id:
			var cur_count: int = int(itm.get("count", 1))
			if cur_count <= needed:
				needed -= cur_count
				clear_inventory_slot(i)
			else:
				itm["count"] = cur_count - needed
				needed = 0
				_refresh_inventory_slot(i)
			if needed <= 0:
				return true
	return needed < count

## Sets or updates an inventory slot item (backward-compatible API)
func set_inventory_item(slot_idx: int, icon_id: int, count: int = 1, item_id: int = 0, item_name: String = "") -> void:
	if slot_idx < 0 or slot_idx >= inventory_slots.size():
		return
	if slot_idx < inventory_data.size():
		if icon_id > 0:
			var effective_id: int = item_id if item_id > 0 else icon_id
			inventory_data[slot_idx] = create_item_record(effective_id, icon_id, count, item_name, "")
		else:
			inventory_data[slot_idx] = {}
	_refresh_inventory_slot(slot_idx)

## Sets an item dictionary into an inventory slot and updates visual display
func set_inventory_data_item(slot_idx: int, item: Dictionary) -> void:
	if slot_idx < 0 or slot_idx >= inventory_data.size():
		return
	inventory_data[slot_idx] = item.duplicate()
	_refresh_inventory_slot(slot_idx)

## Clears an inventory slot
func clear_inventory_slot(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < inventory_data.size():
		inventory_data[slot_idx] = {}
	_refresh_inventory_slot(slot_idx)

## Clears all inventory slots
func clear_inventory() -> void:
	for i in range(inventory_data.size()):
		inventory_data[i] = {}
		_refresh_inventory_slot(i)

## Returns the Button for a given inventory slot (0..44)
func get_inventory_slot(slot_idx: int) -> Button:
	if slot_idx >= 0 and slot_idx < inventory_slots.size():
		return inventory_slots[slot_idx]
	return null

## Updates gold display in CharacterWindow and PlayerStatusDock
func update_gold(amount: int) -> void:
	current_gold = amount
	if gold_label:
		gold_label.text = "%d" % amount
	if status_dock:
		var dock_gold := status_dock.get_node_or_null("GoldLabel") as Label
		if dock_gold:
			dock_gold.text = "Gold %d" % amount

## Drag & drop handler: Initiates drag from an inventory slot
func get_inventory_drag_data(slot_idx: int) -> Variant:
	if slot_idx < 0 or slot_idx >= inventory_data.size():
		return null
	var item: Dictionary = inventory_data[slot_idx]
	if item.is_empty() or int(item.get("id", 0)) <= 0:
		return null
	var icon_tex: Texture2D = null
	if slot_idx < inventory_icons.size():
		icon_tex = inventory_icons[slot_idx].texture
	return {
		"type": "inventory",
		"slot_index": slot_idx,
		"item": item,
		"icon_tex": icon_tex
	}

## Drag & drop handler: Validates drop target on an inventory slot
func can_drop_on_inventory_slot(target_slot: int, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	if target_slot < 0 or target_slot >= inventory_data.size():
		return false
	var dtype: String = str(data.get("type", ""))
	if dtype == "inventory":
		return true
	elif dtype == "equipment":
		var target_item: Dictionary = inventory_data[target_slot]
		if target_item.is_empty() or int(target_item.get("id", 0)) <= 0:
			return true
		var source_socket: String = str(data.get("socket_name", ""))
		return _is_item_compatible_with_socket(target_item, source_socket)
	return false

## Drag & drop handler: Executes drop on an inventory slot
func drop_on_inventory_slot(target_slot: int, data: Variant) -> void:
	if not can_drop_on_inventory_slot(target_slot, data):
		return
	var dtype: String = str(data.get("type", ""))
	if dtype == "inventory":
		var source_slot: int = int(data.get("slot_index", -1))
		if source_slot == target_slot or source_slot < 0 or source_slot >= inventory_data.size():
			return
		var temp: Dictionary = inventory_data[target_slot]
		inventory_data[target_slot] = inventory_data[source_slot]
		inventory_data[source_slot] = temp
		_refresh_inventory_slot(source_slot)
		_refresh_inventory_slot(target_slot)
		var item_name: String = str(inventory_data[target_slot].get("name", "Item"))
		_log_system_message("Moved %s to slot %d." % [item_name, target_slot + 1])
	elif dtype == "equipment":
		var source_socket: String = _normalize_socket_name(str(data.get("socket_name", "")))
		var char_ctrl = _get_character_status_controller()
		var source_item: Dictionary = {}
		if char_ctrl and "equipment_data" in char_ctrl:
			source_item = char_ctrl.equipment_data.get(source_socket, {})
		elif hud and "_equipment_data" in hud:
			source_item = hud._equipment_data.get(source_socket, {})

		var target_item: Dictionary = inventory_data[target_slot]
		if target_item.is_empty() or int(target_item.get("id", 0)) <= 0:
			inventory_data[target_slot] = source_item
			if char_ctrl and char_ctrl.has_method("unequip_item"):
				char_ctrl.unequip_item(source_socket)
			elif hud and hud.has_method("unequip_item"):
				hud.unequip_item(source_socket)
			_refresh_inventory_slot(target_slot)
			_log_system_message("Unequipped %s." % source_item.get("name", source_socket.capitalize()))
		else:
			inventory_data[target_slot] = source_item
			if char_ctrl and char_ctrl.has_method("set_equipment_slot_item"):
				char_ctrl.set_equipment_slot_item(source_socket, target_item)
			elif hud and hud.has_method("equip_item"):
				hud.equip_item(source_socket)
			_refresh_inventory_slot(target_slot)
			_log_system_message("Equipped %s, unequipped %s." % [target_item.get("name", ""), source_item.get("name", "")])

## Handles right-click on an inventory slot (quick use or equip)
func on_inventory_slot_right_clicked(slot_idx: int) -> void:
	use_or_equip_inventory_item(slot_idx)

## Handles double-click on an inventory slot (quick use or equip)
func on_inventory_slot_double_clicked(slot_idx: int) -> void:
	use_or_equip_inventory_item(slot_idx)

## Uses a consumable item or equips an equippable item
const NOTEPAD_ITEM_ID: int = 34038

func use_or_equip_inventory_item(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= inventory_data.size():
		return
	var item: Dictionary = inventory_data[slot_idx]
	if item.is_empty() or int(item.get("id", 0)) <= 0:
		return
	var item_id: int = int(item.get("id", 0))

	# 0. The Notepad opens the Notebook (observed: double-click in the real client)
	if item_id == NOTEPAD_ITEM_ID:
		if hud and hud.has_method("open_notebook"):
			hud.open_notebook()
		return

	# 1. Mount / vehicle check
	var vtype: int = _get_vehicle_type(item_id)
	var player_node: Node2D = hud.get("player") if hud else null
	if vtype != 0 and player_node and player_node.has_method("mount_vehicle"):
		var cur_veh: int = int(player_node.get("current_vehicle")) if "current_vehicle" in player_node else 0
		if cur_veh == vtype:
			if player_node.has_method("dismount_vehicle"):
				player_node.dismount_vehicle()
			_log_system_message("Dismounted %s." % item.get("name", "Vehicle"))
		else:
			player_node.mount_vehicle(vtype)
			_log_system_message("Boarded %s! Traversal mode updated." % item.get("name", "Vehicle"))
		return

	# 2. Equipment check
	var eslot: String = _normalize_socket_name(str(item.get("equip_slot", "")))
	if eslot.is_empty() and int(item.get("equip_pos", 0)) > 0:
		match int(item.get("equip_pos", 0)):
			1: eslot = "head"
			2: eslot = "body"
			3: eslot = "weapon"
			4: eslot = "wrist"
			5: eslot = "shoes"
			6: eslot = "special"

	if not eslot.is_empty():
		var char_ctrl = _get_character_status_controller()
		var old_item: Dictionary = {}
		if char_ctrl and char_ctrl.has_method("swap_equipment_item"):
			old_item = char_ctrl.swap_equipment_item(eslot, item)
		elif hud and hud.has_method("equip_item"):
			if "_equipment_data" in hud and hud._equipment_data.has(eslot):
				old_item = hud._equipment_data[eslot]
				hud._equipment_data[eslot] = item
				if hud.has_method("_sync_equipment_layer"):
					hud._sync_equipment_layer(eslot, item)
				if hud.has_method("_update_equipment_socket_icons"):
					hud._update_equipment_socket_icons()
				if hud.has_method("_update_combat_stats"):
					hud._update_combat_stats()

		if not old_item.is_empty() and int(old_item.get("id", 0)) > 0:
			inventory_data[slot_idx] = old_item
		else:
			inventory_data[slot_idx] = {}
		_refresh_inventory_slot(slot_idx)
		_log_system_message("Equipped %s." % item.get("name", eslot.capitalize()))
	else:
		# 3. Consumable item use
		var iname: String = str(item.get("name", "Item"))
		var count: int = int(item.get("count", 1))

		# Resolve HP/SP restoration
		var hp_rest: int = int(item.get("hp_restore", 0))
		var sp_rest: int = int(item.get("sp_restore", 0))
		var amity_rest: int = int(item.get("amity_restore", 0))

		if hp_rest <= 0 and sp_rest <= 0 and amity_rest <= 0:
			var db = _get_game_database()
			if db and "items" in db and db.items:
				var rec = db.items.get_item(item_id)
				if rec:
					if rec.has_method("get_hp_restore"):
						hp_rest = rec.get_hp_restore()
					if rec.has_method("get_sp_restore"):
						sp_rest = rec.get_sp_restore()
					if rec.has_method("get_amity_restore"):
						amity_rest = rec.get_amity_restore()

		var restore_parts: Array[String] = []
		var char_ctrl = _get_character_status_controller()
		if char_ctrl:
			if hp_rest > 0 and char_ctrl.has_method("restore_hp"):
				var act_hp: int = char_ctrl.restore_hp(hp_rest)
				restore_parts.append("+%d HP" % act_hp)
			if sp_rest > 0 and char_ctrl.has_method("restore_sp"):
				var act_sp: int = char_ctrl.restore_sp(sp_rest)
				restore_parts.append("+%d SP" % act_sp)

		if count > 1:
			item["count"] = count - 1
			_refresh_inventory_slot(slot_idx)
		else:
			inventory_data[slot_idx] = {}
			_refresh_inventory_slot(slot_idx)

		_play_auth_click()

		if restore_parts.is_empty():
			_log_system_message("Used %s." % iname)
			if hud and hud.has_method("show_toast"):
				hud.show_toast("Used %s" % iname)
		else:
			var effect_str: String = ", ".join(restore_parts)
			_log_system_message("Used %s (%s)." % [iname, effect_str])
			if hud and hud.has_method("show_toast"):
				hud.show_toast("Used %s (%s)" % [iname, effect_str])

func _play_auth_click() -> void:
	var auth_audio = hud.get_node_or_null("/root/AuthAudio") if (hud and hud.is_inside_tree()) else null
	if auth_audio and auth_audio.has_method("play_ui_click"):
		auth_audio.play_ui_click()
	elif hud and hud.has_node("SFXPlayer"):
		var sp: AudioStreamPlayer = hud.get_node("SFXPlayer") as AudioStreamPlayer
		if sp:
			sp.stream = load("res://assets/sound/wav0151.wav")
			sp.play()

## Shows authentic hover tooltip for an item in inventory
func show_inventory_item_tooltip(slot_idx: int, slot_global_pos: Vector2, slot_size: Vector2) -> void:
	if not item_tooltip:
		return
	if slot_idx < 0 or slot_idx >= inventory_data.size():
		hide_item_tooltip()
		return
	var itm: Dictionary = inventory_data[slot_idx]
	if itm.is_empty() or int(itm.get("id", 0)) <= 0:
		hide_item_tooltip()
		return
	if item_tooltip.has_method("display_item"):
		item_tooltip.display_item(itm)
	if item_tooltip.has_method("position_at"):
		item_tooltip.position_at(slot_global_pos, slot_size)

## Hides the item tooltip
func hide_item_tooltip() -> void:
	if item_tooltip:
		item_tooltip.visible = false

# ==============================================================================
# Internal Helpers
# ==============================================================================

func _on_inventory_slot_clicked(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= inventory_data.size():
		return
	var itm: Dictionary = inventory_data[slot_idx]
	if itm.is_empty() or int(itm.get("id", 0)) <= 0:
		return
	var iname: String = str(itm.get("name", "Item"))
	_log_system_message("Selected item: %s" % iname)
	var eslot: String = _normalize_socket_name(str(itm.get("equip_slot", "")))
	if not eslot.is_empty():
		use_or_equip_inventory_item(slot_idx)

func _refresh_inventory_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= inventory_data.size():
		return
	var item: Dictionary = inventory_data[slot_idx]
	var item_id: int = int(item.get("id", 0)) if not item.is_empty() else 0
	var icon_id: int = int(item.get("icon_id", 0)) if not item.is_empty() else 0
	if item_id > 0 and (icon_id <= 0 or icon_id == item_id):
		var res: int = _resolve_item_icon_id(item_id)
		if res > 0:
			icon_id = res
			item["icon_id"] = icon_id

	var count: int = int(item.get("count", 0)) if not item.is_empty() else 0
	var iname: String = str(item.get("name", "")) if not item.is_empty() else ""
	var desc: String = str(item.get("desc", "")) if not item.is_empty() else ""

	if slot_idx >= inventory_slots.size():
		return
	var slot_btn: Button = inventory_slots[slot_idx]
	var icon_rect: TextureRect = inventory_icons[slot_idx]
	var count_lbl: Label = inventory_counts[slot_idx]

	if icon_rect and icon_id > 0:
		icon_rect.texture = _load_item_icon(icon_id)
		icon_rect.z_index = 2
		if slot_btn and icon_rect.get_parent() == slot_btn:
			slot_btn.move_child(icon_rect, -1)
	elif icon_rect:
		icon_rect.texture = null

	if count_lbl:
		count_lbl.text = str(count) if count > 1 else ""
		count_lbl.z_index = 3
		if slot_btn and count_lbl.get_parent() == slot_btn:
			slot_btn.move_child(count_lbl, -1)

	if slot_btn:
		if not iname.is_empty():
			slot_btn.tooltip_text = "%s\n%s" % [iname, desc] if not desc.is_empty() else iname
		else:
			slot_btn.tooltip_text = ""

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

func _get_vehicle_type(item_id: int) -> int:
	match item_id:
		48010, 48016, 20001:
			return 1 # RAFT
		20002, 20003, 20004, 48044, 48087, 48097:
			return 2 # BOAT
		20005:
			return 3 # SHIP
		34169, 20007, 20008, 20009, 20010, 20015, 20019, 20020, 20021, 48053, 48058, 48059, 48081, 48086, 48089, 48100, 48105, 48108, 48120:
			return 4 # PLANE
		_:
			return 0 # NONE

func _get_archive_loader() -> Node:
	if hud and hud.is_inside_tree():
		return hud.get_node_or_null("/root/ArchiveLoader")
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("ArchiveLoader")
	return null

static var _static_game_db: Node = null
var character_status_ctrl: Variant = null

func _get_game_database() -> Node:
	var gdb: Node = null
	if hud and hud.is_inside_tree():
		gdb = hud.get_node_or_null("/root/GameDatabase")
	if not gdb:
		var loop = Engine.get_main_loop()
		if loop is SceneTree and loop.root:
			gdb = loop.root.get_node_or_null("GameDatabase")
	if not gdb and hud and hud.is_inside_tree() and hud.get_tree() and hud.get_tree().root:
		gdb = hud.get_tree().root.get_node_or_null("GameDatabase")
	if not gdb:
		if not _static_game_db:
			var gd_script = load("res://scripts/database/game_database.gd")
			if gd_script:
				_static_game_db = gd_script.new()
				_static_game_db.load_all()
		gdb = _static_game_db
	if gdb and "items" in gdb and gdb.items and gdb.items._items.is_empty():
		if gdb.has_method("load_all"):
			gdb.load_all()
	return gdb

func _get_character_status_controller() -> Variant:
	if character_status_ctrl:
		return character_status_ctrl
	if hud:
		var ctrl = hud.get("character_status_ctrl")
		if ctrl:
			return ctrl
		ctrl = hud.get("character_status")
		if ctrl:
			return ctrl
	return null

func _log_system_message(msg: String) -> void:
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", msg, "System")
