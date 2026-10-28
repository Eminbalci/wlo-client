class_name BottomActionDock
extends Control

## Modern, flexible Wonderland Online Bottom Action Dock (280x70).
## Encapsulates the 6 authentic circular action buttons (Status, Skill, Quest, Team, Friends, System),
## backward-compatible btn_11..btn_16 accessors, location readout,
## tooltips, hotkey triggers, drag-and-drop slots, and responsive anchor presets.

signal status_pressed
signal skill_pressed
signal quest_pressed
signal team_pressed
signal friends_pressed
signal system_pressed
signal button_triggered(button_id: int)
signal hotkey_action_triggered(slot_index: int)

enum AnchorMode {
	ANCHOR_BOTTOM_RIGHT,
	ANCHOR_CENTER_BOTTOM
}

# UI Node References
@onready var action_bg: TextureRect = $ActionBackground if has_node("ActionBackground") else null
@onready var location_label: Label = $LocationLabel if has_node("LocationLabel") else null
@onready var button_container: HBoxContainer = $ButtonContainer if has_node("ButtonContainer") else null
@onready var btn_status: TextureButton = $ButtonContainer/BtnStatus if has_node("ButtonContainer/BtnStatus") else null
@onready var btn_skill: TextureButton = $ButtonContainer/BtnSkill if has_node("ButtonContainer/BtnSkill") else null
@onready var btn_quest: TextureButton = $ButtonContainer/BtnQuest if has_node("ButtonContainer/BtnQuest") else null
@onready var btn_team: TextureButton = $ButtonContainer/BtnTeam if has_node("ButtonContainer/BtnTeam") else null
@onready var btn_friends: TextureButton = $ButtonContainer/BtnFriends if has_node("ButtonContainer/BtnFriends") else null
@onready var btn_system: TextureButton = $ButtonContainer/BtnSystem if has_node("ButtonContainer/BtnSystem") else null

# Backward compatibility accessors
var btn_11: TextureButton:
	get: return btn_status
var btn_12: TextureButton:
	get: return btn_skill
var btn_13: TextureButton:
	get: return btn_quest
var btn_14: TextureButton:
	get: return btn_team
var btn_15: TextureButton:
	get: return btn_friends
var btn_16: TextureButton:
	get: return btn_system
var btn_inventory: TextureButton:
	get: return btn_status
var btn_battle: TextureButton:
	get: return btn_system

var current_anchor_mode: AnchorMode = AnchorMode.ANCHOR_BOTTOM_RIGHT

# Quickslot data for drag-and-drop binding (slot index 0..5)
var _quickslots: Array[Dictionary] = []

func _ready() -> void:
	_init_quickslots()
	set_anchor_mode(current_anchor_mode)
	_setup_background()
	_setup_buttons()

func _init_quickslots() -> void:
	_quickslots.clear()
	for i in range(6):
		_quickslots.append({})

## Sets responsive anchor preset (BOTTOM_RIGHT or CENTER_BOTTOM)
func set_anchor_mode(mode: AnchorMode) -> void:
	current_anchor_mode = mode
	if mode == AnchorMode.ANCHOR_BOTTOM_RIGHT:
		anchors_preset = Control.PRESET_BOTTOM_RIGHT
		anchor_left = 1.0
		anchor_top = 1.0
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = -282.0
		offset_top = -78.0
		offset_right = 0.0
		offset_bottom = -10.0
		grow_horizontal = Control.GROW_DIRECTION_BEGIN
		grow_vertical = Control.GROW_DIRECTION_BEGIN
	elif mode == AnchorMode.ANCHOR_CENTER_BOTTOM:
		anchors_preset = Control.PRESET_CENTER_BOTTOM
		anchor_left = 0.5
		anchor_top = 1.0
		anchor_right = 0.5
		anchor_bottom = 1.0
		offset_left = -141.0
		offset_top = -78.0
		offset_right = 141.0
		offset_bottom = -10.0
		grow_horizontal = Control.GROW_DIRECTION_BOTH
		grow_vertical = Control.GROW_DIRECTION_BEGIN

## Sets up background texture (visible, lowered to cradle action buttons from underneath)
func _setup_background() -> void:
	if not action_bg:
		return
	action_bg.visible = true
	var tex := _load_texture_file("assets/hud/btn_background_2.png")
	if tex:
		action_bg.texture = tex
	action_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_bg.position = Vector2(7.0, 34.0)
	action_bg.size = Vector2(268.0, 37.0)

## Sets up 3-state textures, compound tooltips, and click signals for all 6 buttons
func _setup_buttons() -> void:
	var buttons: Array[Dictionary] = [
		{"node": btn_status, "id": 1, "sig": status_pressed, "default_tip": "Character Status & Inventory [S / I]"},
		{"node": btn_skill, "id": 2, "sig": skill_pressed, "default_tip": "Skills [K]"},
		{"node": btn_quest, "id": 3, "sig": quest_pressed, "default_tip": "Compound [C]"},
		{"node": btn_team, "id": 4, "sig": team_pressed, "default_tip": "Team & Party [T]"},
		{"node": btn_friends, "id": 5, "sig": friends_pressed, "default_tip": "Friends & Community [F]"},
		{"node": btn_system, "id": 6, "sig": system_pressed, "default_tip": "System Settings [Esc]"},
	]
	
	for item in buttons:
		var btn: TextureButton = item["node"]
		if not btn:
			continue
		var btn_id: int = item["id"]
		var default_tip: String = item["default_tip"]
		if btn.tooltip_text.is_empty():
			btn.tooltip_text = default_tip
			
		_load_button_textures(btn, btn_id)
		
		if not btn.pressed.is_connected(_on_button_pressed.bind(btn_id)):
			btn.pressed.connect(_on_button_pressed.bind(btn_id))

func _load_button_textures(btn: TextureButton, btn_id: int) -> void:
	var tex_normal := _load_texture_file("assets/hud/btn_%d_normal.png" % btn_id)
	var tex_pressed := _load_texture_file("assets/hud/btn_%d_pressed.png" % btn_id)
	var tex_hover := _load_texture_file("assets/hud/btn_%d_hover.png" % btn_id)
	
	if tex_normal and tex_pressed:
		btn.texture_normal = tex_normal
		btn.texture_pressed = tex_pressed
		btn.texture_hover = tex_hover if tex_hover else tex_normal
	else:
		var loader := _get_archive_loader()
		if loader and loader.has_method("get_ui_texture"):
			var n: ImageTexture = loader.get_ui_texture("menu/Skins/default/Btn_%d_1.bmp" % btn_id)
			var p: ImageTexture = loader.get_ui_texture("menu/Skins/default/Btn_%d_2.bmp" % btn_id)
			var d: ImageTexture = loader.get_ui_texture("menu/Skins/default/Btn_%d_3.bmp" % btn_id)
			if n: btn.texture_normal = n
			if p: btn.texture_pressed = p
			if d: btn.texture_disabled = d
			btn.texture_hover = p if p else n

func _on_button_pressed(btn_id: int) -> void:
	button_triggered.emit(btn_id)
	match btn_id:
		1: status_pressed.emit()
		2: skill_pressed.emit()
		3: quest_pressed.emit()
		4: team_pressed.emit()
		5: friends_pressed.emit()
		6: system_pressed.emit()

## Triggers an action button or quickslot by index (1..6)
func trigger_hotkey(hotkey_index: int) -> void:
	if hotkey_index >= 1 and hotkey_index <= 6:
		_on_button_pressed(hotkey_index)
		hotkey_action_triggered.emit(hotkey_index - 1)

## Updates the location text display
func set_location_text(location_name: String, x: int, y: int) -> void:
	if location_label:
		location_label.text = "%s  X: %d  Y: %d" % [location_name, x, y]

## Sets a compound tooltip with title, hotkey, and description
func set_compound_tooltip(button_id: int, title: String, hotkey: String, desc: String) -> void:
	var btn: TextureButton = null
	match button_id:
		1: btn = btn_status
		2: btn = btn_skill
		3: btn = btn_quest
		4: btn = btn_team
		5: btn = btn_friends
		6: btn = btn_system
	if btn:
		btn.tooltip_text = "%s [%s]\n%s" % [title, hotkey, desc]

## Binds a skill or item data dictionary to a slot
func bind_slot_data(slot_idx: int, data: Dictionary) -> void:
	if slot_idx >= 0 and slot_idx < _quickslots.size():
		_quickslots[slot_idx] = data
		if data.has("name"):
			var tip: String = data.get("name", "")
			if data.has("desc"):
				tip += "\n" + data.get("desc", "")
			var btn: TextureButton = _get_button_by_slot(slot_idx)
			if btn:
				btn.tooltip_text = tip

## Gets the slot data dictionary
func get_slot_data(slot_idx: int) -> Dictionary:
	if slot_idx >= 0 and slot_idx < _quickslots.size():
		return _quickslots[slot_idx]
	return {}

## Drag and drop support: accept drop on the dock
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data.has("item_id") or data.has("skill_id") or data.has("type"))

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var slot_idx: int = _get_slot_index_at_position(at_position)
	if slot_idx >= 0 and data is Dictionary:
		bind_slot_data(slot_idx, data)

func _get_slot_index_at_position(pos: Vector2) -> int:
	if not button_container:
		return 0
	var local_x: float = pos.x - button_container.position.x
	var slot_w: float = 46.0
	var idx: int = int(local_x / slot_w)
	return clampi(idx, 0, 5)

func _get_button_by_slot(slot_idx: int) -> TextureButton:
	match slot_idx:
		0: return btn_status
		1: return btn_skill
		2: return btn_quest
		3: return btn_team
		4: return btn_friends
		5: return btn_system
		_: return null

func _load_texture_file(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var abs_path := ProjectSettings.globalize_path("res://" + path.trim_prefix("res://"))
	if FileAccess.file_exists(abs_path):
		var img := Image.new()
		if img.load(abs_path) == OK:
			return ImageTexture.create_from_image(img)
	return null

func _get_archive_loader() -> Node:
	if is_inside_tree():
		var l := get_node_or_null("/root/ArchiveLoader")
		if l: return l
	if Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			return st.root.get_node_or_null("ArchiveLoader")
	return null
