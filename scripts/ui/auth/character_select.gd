class_name CharacterSelect
extends Control

## Authentic 2-Slot Centered Character Selection Screen for Wonderland Online.
## Features:
## - Two centered side-by-side 337x352 character slot cards (CardSlot0 on the left, CardSlot1 on the right)
##   anchored to screen center (anchors_preset = 8) so they remain centered at any window resolution
## - Separated [ Leave ] (BtnBack) button placed outside and centered below the two character cards
## - Form_SelectRole_Empty_R.jpg with centered [ Create ] button for empty slots
## - Form_SelectRole_Info_R.jpg with full InfoOverlay (cutout BustRect, ElementIcon, stats, walking SpritePreview,
##   rotation arrows, [ Login ], and [ Del Char ]) for occupied slots
## - Audio integration: wav0151.wav click sound on all button clicks

signal character_selected(slot_index: int)
signal create_requested(slot_index: int)
signal delete_requested(slot_index: int)
signal back_requested()

const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")
const AuthAudio = preload("res://scripts/ui/auth/auth_audio.gd")

const FORM_EMPTY_PATH: String = "res://assets/menu/Skins/white/Form_SelectRole_Empty_R.jpg"
const FORM_INFO_PATH: String = "res://assets/menu/Skins/white/Form_SelectRole_Info_R.jpg"
const SFX_CLICK_PATH: String = "res://assets/sound/wav0151.wav"
const DEFAULT_HEADING: int = IsometricMath.Heading.SOUTH_WEST

const SLOT_TAB_TEXTURES: Dictionary = {
	0: {
		"normal": "res://assets/auth/btn_slot_0_normal.png",
		"active": "res://assets/auth/btn_slot_0_active.png"
	},
	1: {
		"normal": "res://assets/auth/btn_slot_1_normal.png",
		"active": "res://assets/auth/btn_slot_1_active.png"
	},
	2: {
		"normal": "res://assets/auth/btn_slot_2_normal.png",
		"active": "res://assets/auth/btn_slot_2_active.png"
	}
}

const ELEMENT_ICONS: Dictionary = {
	1: "res://assets/hud/icon_element_1.png",
	2: "res://assets/hud/icon_element_2.png",
	3: "res://assets/hud/icon_element_3.png",
	4: "res://assets/hud/icon_element_4.png",
	"earth": "res://assets/hud/icon_element_1.png",
	"water": "res://assets/hud/icon_element_2.png",
	"fire": "res://assets/hud/icon_element_3.png",
	"wind": "res://assets/hud/icon_element_4.png"
}

@onready var card_slot_0: Control = $CardSlot0
@onready var card_slot_1: Control = $CardSlot1
@onready var btn_back: TextureButton = $BtnBack

var account_name: String = "default"
var selected_slot_index: int = 0
var is_loading: bool = false
var _characters: Dictionary = {}
var _slot_rotations: Dictionary = {0: DEFAULT_HEADING, 1: DEFAULT_HEADING, 2: DEFAULT_HEADING}
var _anim_timer: float = 0.0

var _sfx_stream: AudioStream = null
var _sfx_player: AudioStreamPlayer = null

# Active card and child node dynamic accessors
var card: Control:
	get: return _get_card_node(selected_slot_index)
var card_bg: TextureRect:
	get:
		var c := card
		return c.get_node_or_null("CardBg") as TextureRect if c else null
var slot_tabs_bar: Control:
	get:
		var c := card
		return c.get_node_or_null("SlotTabsBar") as Control if c else null
var btn_slot_0: TextureButton:
	get: return card_slot_0.get_node_or_null("SlotTabsBar/BtnSlot0") as TextureButton if card_slot_0 else null
var btn_slot_1: TextureButton:
	get: return card_slot_1.get_node_or_null("SlotTabsBar/BtnSlot1") as TextureButton if card_slot_1 else null
var btn_create: TextureButton:
	get:
		var c := card
		return c.get_node_or_null("BtnCreateChar") as TextureButton if c else null
var info_overlay: Control:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay") as Control if c else null
var bust_rect: TextureRect:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/BustRect") as TextureRect if c else null
var element_icon: TextureRect:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/ElementIcon") as TextureRect if c else null
var element_label_node: Label:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/ElementLabel") as Label if c else null
var name_label_node: Label:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/NameLabel") as Label if c else null
var level_label_node: Label:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/LevelLabel") as Label if c else null
var hp_label_node: Label:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/HpLabel") as Label if c else null
var sp_label_node: Label:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/SpLabel") as Label if c else null
var exp_bar_node: ProgressBar:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/ExpBar") as ProgressBar if c else null
var exp_label_node: Label:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/ExpLabel") as Label if c else null
var gold_label_node: Label:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/GoldLabel") as Label if c else null
var sprite_preview_rect: TextureRect:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/SpritePreview") as TextureRect if c else null
var btn_arrow_left: TextureButton:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/BtnArrowLeft") as TextureButton if c else null
var btn_arrow_right: TextureButton:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/BtnArrowRight") as TextureButton if c else null
var btn_login: TextureButton:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/BtnLogin") as TextureButton if c else null
var btn_del: TextureButton:
	get:
		var c := card
		return c.get_node_or_null("InfoOverlay/BtnDelChar") as TextureButton if c else null

# Backward compatibility properties for test suites
var slot_tabs: Array:
	get: return [card_slot_0, card_slot_1]
var btn_prev: TextureButton:
	get: return btn_back
var btn_leave: TextureButton:
	get: return btn_back
var leave_button: TextureButton:
	get: return btn_back
var back_button: TextureButton:
	get: return btn_back
var btn_turn_l: TextureButton:
	get:
		var ov := info_overlay
		if ov and ov.has_node("BtnTurnL"):
			return ov.get_node("BtnTurnL") as TextureButton
		return btn_arrow_left
var btn_turn_r: TextureButton:
	get:
		var ov := info_overlay
		if ov and ov.has_node("BtnTurnR"):
			return ov.get_node("BtnTurnR") as TextureButton
		return btn_arrow_right
var char_name_label: Label:
	get: return name_label_node
var element_label: Label:
	get: return element_label_node
var btn_enter_world: TextureButton:
	get: return btn_login
var preview_rect: Control:
	get: return sprite_preview_rect
var empty_prompt_label: Control:
	get: return card_bg
var enter_world_button: TextureButton:
	get: return btn_enter_world
var create_button: TextureButton:
	get: return btn_create
var delete_button: TextureButton:
	get: return btn_del
var details_name_label: Label:
	get: return char_name_label
var details_element_label: Label:
	get: return element_label

func _ready() -> void:
	_init_audio()
	_setup_signals()
	_setup_turn_aliases()
	refresh_characters()

func _init_audio() -> void:
	if ResourceLoader.exists(SFX_CLICK_PATH):
		_sfx_stream = load(SFX_CLICK_PATH) as AudioStream
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "CharSelectSFX"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

func _play_click_sfx() -> void:
	if _sfx_player and _sfx_stream and _sfx_player.is_inside_tree():
		_sfx_player.stream = _sfx_stream
		_sfx_player.play()
	AuthAudio.play_click()

func _setup_turn_aliases() -> void:
	# BtnTurnL / BtnTurnR are served by BtnArrowLeft / BtnArrowRight through the
	# btn_turn_l / btn_turn_r accessors; spawning duplicate buttons put a stray
	# arrow at each card's top-left corner.
	pass

func _setup_signals() -> void:
	for s_idx in [0, 1]:
		var c_node: Control = _get_card_node(s_idx)
		if not c_node:
			continue
		var tab_btn := c_node.get_node_or_null("SlotTabsBar/BtnSlot%d" % s_idx) as TextureButton
		if tab_btn:
			tab_btn.pressed.connect(func(): _on_slot_tab_pressed(s_idx))
		var login_b := c_node.get_node_or_null("InfoOverlay/BtnLogin") as TextureButton
		if login_b:
			login_b.pressed.connect(func():
				selected_slot_index = s_idx
				_on_slot_login_pressed(s_idx)
			)
		var del_b := c_node.get_node_or_null("InfoOverlay/BtnDelChar") as TextureButton
		if del_b:
			del_b.pressed.connect(func():
				selected_slot_index = s_idx
				_on_slot_del_pressed(s_idx)
			)
		var create_b := c_node.get_node_or_null("BtnCreateChar") as TextureButton
		if create_b:
			create_b.pressed.connect(func():
				selected_slot_index = s_idx
				_on_slot_create_pressed(s_idx)
			)
		var arr_l := c_node.get_node_or_null("InfoOverlay/BtnArrowLeft") as TextureButton
		if arr_l:
			arr_l.pressed.connect(func():
				selected_slot_index = s_idx
				_rotate_slot_character(s_idx, -1)
			)
		var arr_r := c_node.get_node_or_null("InfoOverlay/BtnArrowRight") as TextureButton
		if arr_r:
			arr_r.pressed.connect(func():
				selected_slot_index = s_idx
				_rotate_slot_character(s_idx, 1)
			)

	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)

func _process(delta: float) -> void:
	if not visible:
		return
	_anim_timer += delta
	for s_idx in [0, 1]:
		var target_idx: int = selected_slot_index if (s_idx == 1 and selected_slot_index == 2) else s_idx
		var char_data: Dictionary = _characters.get(str(target_idx), {})
		if not char_data.is_empty():
			_update_slot_sprite_preview(target_idx)

func refresh_slots() -> void:
	refresh_characters()

func refresh_characters() -> void:
	_characters.clear()
	var loaded: Dictionary = CharacterManager.get_characters(account_name)
	for k in loaded.keys():
		_characters[k] = loaded[k]

	if _characters.is_empty():
		var SavedAccounts = preload("res://scripts/ui/auth/saved_accounts_manager.gd")
		var last_acc: String = SavedAccounts.get_last_used_account()
		if not last_acc.is_empty() and last_acc != account_name:
			var fallback_chars: Dictionary = CharacterManager.get_characters(last_acc)
			if not fallback_chars.is_empty():
				account_name = last_acc
				_characters = fallback_chars
	if _characters.is_empty():
		var gdb := get_node_or_null("/root/GameDatabase")
		if gdb and "active_character" in gdb and not gdb.active_character.is_empty():
			_characters["0"] = gdb.active_character.duplicate()

	_update_slot_card(0)
	_update_slot_card(1)
	if selected_slot_index == 2:
		_update_slot_card(2)
	_update_slot_tabs()

func set_slot_character(slot_idx: int, char_data: Dictionary) -> void:
	_characters[str(slot_idx)] = char_data
	_update_slot_card(slot_idx)

func set_loading(loading: bool) -> void:
	is_loading = loading
	_update_loading_state()

func _update_loading_state() -> void:
	for s_idx in [0, 1]:
		var c_node: Control = _get_card_node(s_idx)
		if not c_node:
			continue
		var loading_overlay := c_node.get_node_or_null("LoadingOverlay") as Control
		if is_loading:
			if not loading_overlay:
				loading_overlay = Control.new()
				loading_overlay.name = "LoadingOverlay"
				loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
				loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
				
				var bg := ColorRect.new()
				bg.name = "LoadingBg"
				bg.set_anchors_preset(Control.PRESET_FULL_RECT)
				bg.color = Color(0.04, 0.06, 0.1, 0.75)
				loading_overlay.add_child(bg)

				var lbl := Label.new()
				lbl.name = "LoadingLabel"
				lbl.text = "Loading..."
				lbl.set_anchors_preset(Control.PRESET_CENTER)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", 14)
				lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 1.0))
				lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.1, 0.2, 1.0))
				lbl.add_theme_constant_override("outline_size", 2)
				loading_overlay.add_child(lbl)

				c_node.add_child(loading_overlay)
			loading_overlay.visible = true
			var b_create := c_node.get_node_or_null("BtnCreateChar") as TextureButton
			if b_create: b_create.disabled = true
			var b_login := c_node.get_node_or_null("InfoOverlay/BtnLogin") as TextureButton
			if b_login: b_login.disabled = true
			var b_del := c_node.get_node_or_null("InfoOverlay/BtnDelChar") as TextureButton
			if b_del: b_del.disabled = true
		else:
			if loading_overlay:
				loading_overlay.visible = false
			_update_slot_card(s_idx)

func select_slot(slot_idx: int) -> void:
	selected_slot_index = clampi(slot_idx, 0, 2)
	_update_slot_tabs()
	_update_slot_card(0)
	_update_slot_card(selected_slot_index if selected_slot_index >= 1 else 1)

func _update_slot_tabs() -> void:
	if btn_slot_0:
		var t0_key := "active" if selected_slot_index == 0 else "normal"
		var t0_path: String = SLOT_TAB_TEXTURES[0].get(t0_key, "")
		if not t0_path.is_empty() and ResourceLoader.exists(t0_path):
			btn_slot_0.texture_normal = load(t0_path)
	if btn_slot_1:
		var t1_key := "active" if selected_slot_index >= 1 else "normal"
		var t1_path: String = SLOT_TAB_TEXTURES[1].get(t1_key, "")
		if not t1_path.is_empty() and ResourceLoader.exists(t1_path):
			btn_slot_1.texture_normal = load(t1_path)

func _update_slot_card(slot_idx: int) -> void:
	var c_node: Control = _get_card_node(slot_idx)
	if not c_node:
		return

	var c_bg := c_node.get_node_or_null("CardBg") as TextureRect
	var ov := c_node.get_node_or_null("InfoOverlay") as Control
	var b_create := c_node.get_node_or_null("BtnCreateChar") as TextureButton
	var b_login := c_node.get_node_or_null("InfoOverlay/BtnLogin") as TextureButton
	var b_del := c_node.get_node_or_null("InfoOverlay/BtnDelChar") as TextureButton
	var b_bust := c_node.get_node_or_null("InfoOverlay/BustRect") as TextureRect
	var b_elem_icon := c_node.get_node_or_null("InfoOverlay/ElementIcon") as TextureRect
	var l_elem := c_node.get_node_or_null("InfoOverlay/ElementLabel") as Label
	var l_name := c_node.get_node_or_null("InfoOverlay/NameLabel") as Label
	var l_lvl := c_node.get_node_or_null("InfoOverlay/LevelLabel") as Label
	var l_hp := c_node.get_node_or_null("InfoOverlay/HpLabel") as Label
	var l_sp := c_node.get_node_or_null("InfoOverlay/SpLabel") as Label
	var p_exp := c_node.get_node_or_null("InfoOverlay/ExpBar") as ProgressBar
	var l_exp := c_node.get_node_or_null("InfoOverlay/ExpLabel") as Label
	var l_gold := c_node.get_node_or_null("InfoOverlay/GoldLabel") as Label

	var char_data: Dictionary = _characters.get(str(slot_idx), {})
	var has_char: bool = not char_data.is_empty()

	if btn_back:
		btn_back.visible = true
		btn_back.disabled = false

	if has_char:
		if c_bg and ResourceLoader.exists(FORM_INFO_PATH):
			c_bg.texture = load(FORM_INFO_PATH)
		if ov:
			ov.visible = true
		if b_create:
			b_create.visible = false
			b_create.disabled = true
		if b_login:
			b_login.visible = true
			b_login.disabled = false
		if b_del:
			b_del.visible = true
			b_del.disabled = false

		var first_name: String = str(char_data.get("first_name", ""))
		var last_name: String = str(char_data.get("last_name", ""))
		var full_name: String = ""
		if not first_name.is_empty() and not last_name.is_empty():
			full_name = "%s %s" % [first_name, last_name]
		elif not first_name.is_empty():
			full_name = first_name
		else:
			full_name = str(char_data.get("name", ""))

		if l_name:
			l_name.text = full_name
		if l_elem:
			l_elem.text = str(char_data.get("element", "Water"))
		if l_lvl:
			l_lvl.text = str(int(char_data.get("level", 1)))

		var hp: int = int(char_data.get("hp", 150))
		var max_hp: int = int(char_data.get("max_hp", hp))
		if l_hp:
			l_hp.text = "%d / %d" % [hp, max_hp]

		var sp: int = int(char_data.get("sp", 100))
		var max_sp: int = int(char_data.get("max_sp", sp))
		if l_sp:
			l_sp.text = "%d / %d" % [sp, max_sp]

		var exp_val: int = int(char_data.get("exp", 0))
		if l_exp:
			l_exp.text = "%d%%" % exp_val
		if p_exp:
			p_exp.value = exp_val

		if l_gold:
			l_gold.text = str(int(char_data.get("gold", 0)))

		if b_elem_icon:
			var elem: Variant = char_data.get("element", "fire")
			var elem_key: Variant = elem.to_lower() if elem is String else elem
			if ELEMENT_ICONS.has(elem_key) and ResourceLoader.exists(ELEMENT_ICONS[elem_key]):
				b_elem_icon.texture = load(ELEMENT_ICONS[elem_key])
				b_elem_icon.visible = true
			else:
				b_elem_icon.visible = false

		var role_id: int = int(char_data.get("role_id", 1))
		if b_bust:
			var bust_tex: Texture2D = null
			var loader := get_node_or_null("/root/ArchiveLoader")
			if loader and loader.has_method("get_avatar_frames"):
				var frames: Array = loader.get_avatar_frames(role_id)
				if not frames.is_empty():
					bust_tex = frames[0]
			if not bust_tex:
				var bust_path := "res://assets/hud/avatar_role_%d_0.png" % role_id
				if ResourceLoader.exists(bust_path):
					bust_tex = load(bust_path)
			b_bust.texture = bust_tex

		_update_slot_sprite_preview(slot_idx)
	else:
		if c_bg and ResourceLoader.exists(FORM_EMPTY_PATH):
			c_bg.texture = load(FORM_EMPTY_PATH)
		if ov:
			ov.visible = false
		if b_create:
			b_create.visible = true
			b_create.disabled = false
		if b_login:
			b_login.disabled = true
		if b_del:
			b_del.disabled = true

func _on_slot_tab_pressed(idx: int) -> void:
	_play_click_sfx()
	select_slot(idx)

func _update_slot_sprite_preview(slot_idx: int) -> void:
	var c_node: Control = _get_card_node(slot_idx)
	if not c_node:
		return
	var sprite_rect := c_node.get_node_or_null("InfoOverlay/SpritePreview") as TextureRect
	if not sprite_rect:
		return

	var char_data: Dictionary = _characters.get(str(slot_idx), {})
	if char_data.is_empty():
		sprite_rect.texture = null
		return

	var role_id: int = int(char_data.get("role_id", 1))
	var rot: int = _slot_rotations.get(slot_idx, DEFAULT_HEADING)
	var sub_idx: int = int(_anim_timer * 8.0) % 4
	var frame_idx: int = (rot % 8) * 4 + sub_idx

	var loader := get_node_or_null("/root/ArchiveLoader")
	if loader and loader.has_method("get_player_composite_frames"):
		var equip_layers: Dictionary = char_data.get("equipment", {})
		var frames: Array = loader.get_player_composite_frames(role_id, equip_layers)
		if not frames.is_empty():
			if frame_idx >= frames.size():
				frame_idx = frame_idx % frames.size()
			if frames[frame_idx] != null:
				sprite_rect.texture = frames[frame_idx]
				return

	var standee_path := "res://assets/auth/standees/standee_role_%d.png" % role_id
	if ResourceLoader.exists(standee_path):
		sprite_rect.texture = load(standee_path)
		return

	var fallback_path := "res://assets/hud/avatar_role_%d_0.png" % role_id
	if ResourceLoader.exists(fallback_path):
		sprite_rect.texture = load(fallback_path)

func _rotate_slot_character(slot_idx: int, dir: int) -> void:
	_play_click_sfx()
	var current_rot: int = _slot_rotations.get(slot_idx, DEFAULT_HEADING)
	_slot_rotations[slot_idx] = (current_rot + dir + 8) % 8
	_update_slot_sprite_preview(slot_idx)

func _on_slot_login_pressed(slot_idx: int) -> void:
	_play_click_sfx()
	var char_data: Dictionary = _characters.get(str(slot_idx), {})
	if char_data.is_empty():
		return
	var gdb := get_node_or_null("/root/GameDatabase")
	if gdb and "active_character" in gdb:
		gdb.active_character = char_data.duplicate()
	character_selected.emit(slot_idx)

func _on_slot_create_pressed(slot_idx: int) -> void:
	_play_click_sfx()
	create_requested.emit(slot_idx)

func _on_slot_del_pressed(slot_idx: int) -> void:
	_play_click_sfx()
	CharacterManager.delete_character(slot_idx, account_name)
	_characters.erase(str(slot_idx))
	_update_slot_card(slot_idx)
	delete_requested.emit(slot_idx)

func _on_back_pressed() -> void:
	_play_click_sfx()
	back_requested.emit()

func get_selected_character() -> Dictionary:
	return _characters.get(str(selected_slot_index), {})

func _get_card_node(slot_idx: int) -> Control:
	if slot_idx == 0:
		return card_slot_0 if card_slot_0 else get_node_or_null("CardSlot0") as Control
	return card_slot_1 if card_slot_1 else get_node_or_null("CardSlot1") as Control
