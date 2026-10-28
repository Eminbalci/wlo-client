class_name HUDActionDock
extends RefCounted

## Sub-controller for Wonderland Online HUD Bottom Action Dock (280x70).
## Encapsulates the 6 authentic circular action buttons (Status, Skill, Quest, Team, Friends, System),
## backward-compatible btn_11..btn_16 accessors, and the bottom location readout label.

signal status_pressed
signal skill_pressed
signal quest_pressed
signal team_pressed
signal friends_pressed
signal system_pressed
signal button_triggered(button_id: int)

var _hud: Control = null

# Node references
var action_dock: Control = null
var action_bg: TextureRect = null
var location_label: Label = null
var btn_status: TextureButton = null
var btn_skill: TextureButton = null
var btn_quest: TextureButton = null
var btn_team: TextureButton = null
var btn_friends: TextureButton = null
var btn_system: TextureButton = null

# Compatibility accessors
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

## Initializes references, loads 3-state textures and connects button callbacks
func setup(hud: Control, nodes: Dictionary = {}) -> void:
	_hud = hud
	
	action_dock = nodes.get("action_dock", hud.get_node_or_null("BottomActionDock"))
	action_bg = nodes.get("action_bg", hud.get_node_or_null("BottomActionDock/ActionBackground"))
	location_label = nodes.get("location_label", hud.get_node_or_null("BottomActionDock/LocationLabel"))
	btn_status = nodes.get("btn_status", hud.get_node_or_null("BottomActionDock/ButtonContainer/BtnStatus"))
	btn_skill = nodes.get("btn_skill", hud.get_node_or_null("BottomActionDock/ButtonContainer/BtnSkill"))
	btn_quest = nodes.get("btn_quest", hud.get_node_or_null("BottomActionDock/ButtonContainer/BtnQuest"))
	btn_team = nodes.get("btn_team", hud.get_node_or_null("BottomActionDock/ButtonContainer/BtnTeam"))
	btn_friends = nodes.get("btn_friends", hud.get_node_or_null("BottomActionDock/ButtonContainer/BtnFriends"))
	btn_system = nodes.get("btn_system", hud.get_node_or_null("BottomActionDock/ButtonContainer/BtnSystem"))
	
	_setup_background()
	_setup_buttons()

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

## Sets up authentic 3-state textures and click signals for all 6 buttons
func _setup_buttons() -> void:
	var buttons: Array[Dictionary] = [
		{"node": btn_status, "id": 1, "sig": status_pressed, "method": "toggle_character_status", "tip": "Character Status & Inventory [C / I]"},
		{"node": btn_skill, "id": 2, "sig": skill_pressed, "method": "toggle_skill_window", "tip": "Skills [S]"},
		{"node": btn_quest, "id": 3, "sig": quest_pressed, "method": "toggle_compound_window", "tip": "Compound [V]"},
		{"node": btn_team, "id": 4, "sig": team_pressed, "method": "toggle_team_window", "tip": "Team & Party [T]"},
		{"node": btn_friends, "id": 5, "sig": friends_pressed, "method": "toggle_friends_window", "tip": "Friends & Community [F]"},
		{"node": btn_system, "id": 6, "sig": system_pressed, "method": "toggle_system_window", "tip": "System Settings [Esc]"},
	]
	
	for item in buttons:
		var btn: TextureButton = item["node"]
		if not btn:
			continue
		var btn_id: int = item["id"]
		var norm := _load_texture_file("assets/hud/btn_dock_%d_normal.png" % btn_id)
		var hov := _load_texture_file("assets/hud/btn_dock_%d_hover.png" % btn_id)
		var press := _load_texture_file("assets/hud/btn_dock_%d_pressed.png" % btn_id)
		if norm: btn.texture_normal = norm
		if hov: btn.texture_hover = hov
		if press: btn.texture_pressed = press
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		if item.has("tip"):
			btn.tooltip_text = item["tip"]
		
		var target_sig: Signal = item["sig"]
		var target_method: String = item["method"]
		
		var on_pressed := func() -> void:
			target_sig.emit()
			button_triggered.emit(btn_id)
			if _hud and _hud.has_method(target_method):
				_hud.call(target_method)
		
		if not btn.pressed.is_connected(on_pressed):
			btn.pressed.connect(on_pressed)

## Updates the bottom location label readout (e.g. "Ship Deck  X: 899  Y: 1102")
func update_location(map_name: String, x: int, y: int) -> void:
	var clean_name: String = map_name
	if clean_name.length() >= 5 and (clean_name[3] == "%" or clean_name.begins_with("0") or clean_name.begins_with("1") or clean_name.begins_with("2")):
		# Sanitize 3-digit prefix and symbols if present (e.g. "024%&Name" -> strip first 5 chars)
		if clean_name.length() > 5 and clean_name[3] in ["%", "&", "_", "-"]:
			clean_name = clean_name.substr(5)
		elif clean_name.length() > 3 and clean_name[3] == "%":
			clean_name = clean_name.substr(5)
	if location_label:
		location_label.text = "%s  X: %d  Y: %d" % [clean_name, x, y]

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
