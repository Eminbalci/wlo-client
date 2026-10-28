class_name HUDManager
extends Control

## Modern, responsive HUD Facade and Dock Layout Manager.
## Coordinates StatusDock, RadarMinimap, ChatDock, BottomActionDock, and HotbarDock.
## Enforces modern Godot 4 anchor presets (PRESET_TOP_LEFT, PRESET_TOP_RIGHT,
## PRESET_BOTTOM_LEFT, PRESET_BOTTOM_RIGHT / PRESET_CENTER_BOTTOM) and calculates
## responsive non-overlapping dock geometry across arbitrary aspect ratios
## (4:3, 16:9, 16:10, 21:9 ultrawide, 32:9).

# Signals
signal dialogue_choice_selected(choice_index: int, choice_text: String)
signal hotkey_action_triggered(slot_index: int)
signal dialogue_closed
signal chat_message_sent(channel: String, text: String)
signal equipment_changed(equip_layers: Dictionary)
signal banner_emitted(text: String)
signal minimap_clicked(norm_pos: Vector2)
signal chat_tab_changed(tab_name: String)
signal overhead_bubble_emitted(text_or_code: String)
signal minimap_zoom_changed(new_zoom: float)
signal minimap_collapsed_changed(is_collapsed: bool)
signal responsive_layout_updated(viewport_size: Vector2)

# Dock References
var status_dock_node: Control = null
var minimap_dock_node: Control = null
var chat_dock_node: Control = null
var action_dock_node: Control = null
var hotbar_dock_node: Control = null

# Configuration
@export var min_viewport_size: Vector2 = Vector2(800, 600)
@export var dock_margin: float = 6.0

func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_discover_and_wire_docks()
	
	if get_viewport():
		if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
			get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	_update_responsive_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_responsive_layout()

func _on_viewport_size_changed() -> void:
	_update_responsive_layout()

## Discovers dock nodes either from child scenes or by standardized names
func _discover_and_wire_docks() -> void:
	# 1. Status Dock
	status_dock_node = get_node_or_null("PlayerStatusDock")
	if not status_dock_node:
		status_dock_node = get_node_or_null("StatusDock")
		
	# 2. Minimap Dock
	minimap_dock_node = get_node_or_null("RadarMinimapDock")
	if not minimap_dock_node:
		minimap_dock_node = get_node_or_null("RadarMinimap")
		
	# 3. Chat Dock
	chat_dock_node = get_node_or_null("ChatDock")
	
	# 4. Action Dock
	action_dock_node = get_node_or_null("BottomActionDock")
	if not action_dock_node:
		action_dock_node = get_node_or_null("ActionDock")
		
	# 5. Hotbar Dock
	hotbar_dock_node = get_node_or_null("HotbarDock")
	
	_connect_dock_signals()

## Wires up signals between child docks and this manager
func _connect_dock_signals() -> void:
	if chat_dock_node:
		if chat_dock_node.has_signal("message_sent") and not chat_dock_node.is_connected("message_sent", _on_chat_dock_message_sent):
			chat_dock_node.connect("message_sent", _on_chat_dock_message_sent)
		if chat_dock_node.has_signal("tab_changed") and not chat_dock_node.is_connected("tab_changed", _on_chat_dock_tab_changed):
			chat_dock_node.connect("tab_changed", _on_chat_dock_tab_changed)
		if chat_dock_node.has_signal("overhead_bubble_emitted") and not chat_dock_node.is_connected("overhead_bubble_emitted", _on_chat_dock_overhead_bubble):
			chat_dock_node.connect("overhead_bubble_emitted", _on_chat_dock_overhead_bubble)
			
	if minimap_dock_node:
		if minimap_dock_node.has_signal("minimap_clicked") and not minimap_dock_node.is_connected("minimap_clicked", _on_minimap_dock_clicked):
			minimap_dock_node.connect("minimap_clicked", _on_minimap_dock_clicked)
		if minimap_dock_node.has_signal("zoom_changed") and not minimap_dock_node.is_connected("zoom_changed", _on_minimap_dock_zoom_changed):
			minimap_dock_node.connect("zoom_changed", _on_minimap_dock_zoom_changed)
		if minimap_dock_node.has_signal("collapsed_changed") and not minimap_dock_node.is_connected("collapsed_changed", _on_minimap_dock_collapsed_changed):
			minimap_dock_node.connect("collapsed_changed", _on_minimap_dock_collapsed_changed)
			
	if action_dock_node:
		if action_dock_node.has_signal("hotkey_action_triggered") and not action_dock_node.is_connected("hotkey_action_triggered", _on_action_dock_hotkey_triggered):
			action_dock_node.connect("hotkey_action_triggered", _on_action_dock_hotkey_triggered)

## Recalculates and enforces responsive anchor positions and bounds across arbitrary aspect ratios
func _update_responsive_layout() -> void:
	var vp_size: Vector2 = size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		if get_viewport():
			vp_size = get_viewport().get_visible_rect().size
		else:
			vp_size = Vector2(1280, 720)
			
	recalculate_responsive_layout(vp_size)

## Performs responsive positioning, collision avoidance, and preset assignments
func recalculate_responsive_layout(vp_size: Vector2) -> void:
	var w: float = vp_size.x
	var h: float = vp_size.y
	
	# 1. PlayerStatusDock: Anchored Top-Left (PRESET_TOP_LEFT)
	if status_dock_node:
		status_dock_node.set_anchors_preset(Control.PRESET_TOP_LEFT)
		status_dock_node.anchor_left = 0.0
		status_dock_node.anchor_top = 0.0
		status_dock_node.anchor_right = 0.0
		status_dock_node.anchor_bottom = 0.0
		status_dock_node.offset_left = 0.0
		status_dock_node.offset_top = 0.0
		status_dock_node.position = Vector2(0.0, 0.0)
		
	# 2. RadarMinimapDock: Anchored Top-Right (PRESET_TOP_RIGHT)
	if minimap_dock_node:
		minimap_dock_node.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		minimap_dock_node.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		var mm_w: float = 226.0
		minimap_dock_node.anchor_left = 1.0
		minimap_dock_node.anchor_top = 0.0
		minimap_dock_node.anchor_right = 1.0
		minimap_dock_node.anchor_bottom = 0.0
		minimap_dock_node.offset_left = -mm_w
		minimap_dock_node.offset_top = 0.0
		minimap_dock_node.offset_right = 0.0
		minimap_dock_node.offset_bottom = 144.0
		minimap_dock_node.position = Vector2(w - mm_w, 0.0)
		
	# 3. HotbarDock: Anchored Top-Right below minimap
	if hotbar_dock_node:
		hotbar_dock_node.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		hotbar_dock_node.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		var hb_w: float = 56.0
		hotbar_dock_node.anchor_left = 1.0
		hotbar_dock_node.anchor_top = 0.0
		hotbar_dock_node.anchor_right = 1.0
		hotbar_dock_node.anchor_bottom = 0.0
		hotbar_dock_node.offset_left = -hb_w
		hotbar_dock_node.offset_top = 163.0
		hotbar_dock_node.offset_right = 0.0
		hotbar_dock_node.offset_bottom = 437.0
		hotbar_dock_node.position = Vector2(w - hb_w, 163.0)
		
	# 4. BottomActionDock: Anchored Bottom-Right (PRESET_BOTTOM_RIGHT)
	var act_w: float = 282.0
	if action_dock_node:
		action_dock_node.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		action_dock_node.anchor_left = 1.0
		action_dock_node.anchor_top = 1.0
		action_dock_node.anchor_right = 1.0
		action_dock_node.anchor_bottom = 1.0
		action_dock_node.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		action_dock_node.grow_vertical = Control.GROW_DIRECTION_BEGIN
		action_dock_node.offset_left = -act_w
		action_dock_node.offset_top = -78.0
		action_dock_node.offset_right = 0.0
		action_dock_node.offset_bottom = -10.0
		action_dock_node.position = Vector2(w - act_w, h - 78.0)
		
	# 5. ChatDock: Anchored Bottom-Left (PRESET_BOTTOM_LEFT)
	if chat_dock_node:
		chat_dock_node.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		chat_dock_node.anchor_left = 0.0
		chat_dock_node.anchor_top = 1.0
		chat_dock_node.anchor_right = 0.0
		chat_dock_node.anchor_bottom = 1.0
		chat_dock_node.grow_vertical = Control.GROW_DIRECTION_BEGIN
		chat_dock_node.offset_left = 0.0
		chat_dock_node.offset_top = -25.0
		chat_dock_node.offset_bottom = 0.0
		chat_dock_node.position = Vector2(0.0, h - 25.0)
		
		# Collision Avoidance on Narrow Viewports (e.g. 800x600 in 4:3)
		# ChatDock default width is 524. 524 + 282 = 806.
		# If available width is < 810, compress chat dock width dynamically
		var available_chat_w: float = w - act_w - 6.0
		var target_chat_w: float = 524.0
		if available_chat_w < 524.0:
			target_chat_w = maxf(380.0, available_chat_w)
			
		chat_dock_node.offset_right = target_chat_w
		chat_dock_node.size.x = target_chat_w
		if chat_dock_node.has_method("set_dock_width"):
			chat_dock_node.set_dock_width(target_chat_w)
			
	responsive_layout_updated.emit(vp_size)

# Signal forwarding handlers
func _on_chat_dock_message_sent(channel: String, text: String) -> void:
	chat_message_sent.emit(channel, text)

func _on_chat_dock_tab_changed(tab_name: String) -> void:
	chat_tab_changed.emit(tab_name)

func _on_chat_dock_overhead_bubble(code_or_text: String) -> void:
	overhead_bubble_emitted.emit(code_or_text)

func _on_minimap_dock_clicked(norm_pos: Vector2) -> void:
	minimap_clicked.emit(norm_pos)

func _on_minimap_dock_zoom_changed(new_zoom: float) -> void:
	minimap_zoom_changed.emit(new_zoom)

func _on_minimap_dock_collapsed_changed(is_collapsed: bool) -> void:
	minimap_collapsed_changed.emit(is_collapsed)

func _on_action_dock_hotkey_triggered(slot_index: int) -> void:
	hotkey_action_triggered.emit(slot_index)

## Applies character stat dictionary to StatusDock
func apply_character_data(data: Dictionary) -> void:
	if status_dock_node:
		if data.has("role_id") and status_dock_node.has_method("set_role"):
			status_dock_node.set_role(int(data["role_id"]))
		if data.has("element") and status_dock_node.has_method("set_element"):
			status_dock_node.set_element(data["element"])
		if data.has("name") and status_dock_node.has_method("set_player_name"):
			status_dock_node.set_player_name(str(data["name"]))
		if data.has("level") and status_dock_node.has_method("set_player_level"):
			status_dock_node.set_player_level(int(data["level"]))
		if data.has("hp") and data.has("max_hp") and status_dock_node.has_method("set_hp"):
			status_dock_node.set_hp(int(data["hp"]), int(data["max_hp"]))
		if data.has("sp") and data.has("max_sp") and status_dock_node.has_method("set_sp"):
			status_dock_node.set_sp(int(data["sp"]), int(data["max_sp"]))
		if data.has("exp") and data.has("max_exp") and status_dock_node.has_method("set_exp"):
			status_dock_node.set_exp(int(data["exp"]), int(data["max_exp"]))
		if data.has("gold") and status_dock_node.has_method("set_gold"):
			status_dock_node.set_gold(int(data["gold"]))

## Adds a message to ChatDock
func add_chat_message(channel: String, text: String, sender: String = "") -> void:
	if chat_dock_node and chat_dock_node.has_method("add_message"):
		chat_dock_node.add_message(channel, text, sender)

## Updates Minimap location and coordinates
func update_minimap(world_pos: Vector2, pixel_size: Vector2) -> void:
	if minimap_dock_node and minimap_dock_node.has_method("update_coordinates"):
		minimap_dock_node.update_coordinates(world_pos, pixel_size)
