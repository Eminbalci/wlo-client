class_name StatusDock
extends Control

## Modern, flexible Wonderland Online Status Dock.
## Features dynamic HP/SP/EXP progress bars with smooth tween interpolation,
## responsive avatar icon with blinking animation, element indicator,
## and a wrapping buff/debuff container row.

signal hp_changed(current: int, max_val: int)
signal sp_changed(current: int, max_val: int)
signal exp_changed(current: int, max_val: int)
signal role_changed(role_id: int)
signal element_changed(element: Variant)

const CIRCLE_AVATAR_SHADER_CODE: String = """shader_type canvas_item;
render_mode blend_mix;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	if (dist > 0.49) {
		discard;
	}
	vec4 col = texture(TEXTURE, UV);
	float alpha = smoothstep(0.49, 0.46, dist);
	COLOR = vec4(col.rgb, col.a * alpha) * COLOR;
}
"""

const CHROMA_MASK_SHADER_CODE: String = """shader_type canvas_item;
render_mode blend_mix;

uniform vec4 chroma_color : source_color = vec4(1.0, 0.0, 1.0, 1.0); // Default magenta key
uniform float chroma_tolerance : hint_range(0.0, 1.0) = 0.05;
uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (distance(col.rgb, chroma_color.rgb) <= chroma_tolerance) {
		discard;
	}
	if (UV.x > fill_ratio) {
		discard;
	}
	COLOR = col * COLOR;
}
"""

# UI Node References
@onready var status_bg: TextureRect = $StatusBackground if has_node("StatusBackground") else null
@onready var avatar_bg: ColorRect = $AvatarBg if has_node("AvatarBg") else null
@onready var avatar_rect: TextureRect = $AvatarRect if has_node("AvatarRect") else null
@onready var element_icon: TextureRect = $ElementIcon if has_node("ElementIcon") else null
@onready var hp_channel_under: TextureRect = $HpChannelUnder if has_node("HpChannelUnder") else null
@onready var sp_channel_under: TextureRect = $SpChannelUnder if has_node("SpChannelUnder") else null
@onready var hp_bar: Range = $HpBar if has_node("HpBar") else null
@onready var sp_bar: Range = $SpBar if has_node("SpBar") else null
@onready var exp_bar: Range = $ExpBar if has_node("ExpBar") else null
@onready var name_label: Label = $NameLabel if has_node("NameLabel") else null
@onready var level_label: Label = $LevelLabel if has_node("LevelLabel") else null
@onready var hp_label: Label = $HpLabel if has_node("HpLabel") else null
@onready var sp_label: Label = $SpLabel if has_node("SpLabel") else null
@onready var exp_label: Label = $ExpLabel if has_node("ExpLabel") else null
@onready var gold_label: Label = $GoldLabel if has_node("GoldLabel") else null
@onready var buff_container: HFlowContainer = $BuffContainer if has_node("BuffContainer") else null

# Tween interpolation handles
var _hp_tween: Tween = null
var _sp_tween: Tween = null
var _exp_tween: Tween = null

# Cached numeric stats
var current_hp: int = 245
var max_hp: int = 245
var current_sp: int = 180
var max_sp: int = 180
var current_exp: int = 4500
var max_exp: int = 10000
var current_role_id: int = 6
var current_element: Variant = "Fire"

# Avatar blinking state machine
var _avatar_frames: Array[Texture2D] = []
var _avatar_blink_timer: float = 0.0
var _avatar_blink_duration: float = 0.15
var _avatar_blink_interval: float = 3.5
var _avatar_is_blinking: bool = false

# 3-layer Chroma Mask Shader material
var _chroma_shader_material: ShaderMaterial = null

# Active buffs: Dictionary of { id: String, { "texture": Texture2D, "duration": float, "node": TextureRect } }
var _active_buffs: Dictionary = {}

func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_LEFT
	if avatar_rect and status_bg and avatar_rect.get_index() > status_bg.get_index():
		move_child(avatar_rect, status_bg.get_index())
	_setup_chroma_shader()
	_setup_status_textures()
	_setup_buff_container()
	set_role(current_role_id)
	set_element(current_element)

func _process(delta: float) -> void:
	_process_avatar_blinking(delta)
	_process_buff_durations(delta)

## Sets up chroma shader material for bars
func _setup_chroma_shader() -> void:
	var shader := Shader.new()
	shader.code = CHROMA_MASK_SHADER_CODE
	_chroma_shader_material = ShaderMaterial.new()
	_chroma_shader_material.shader = shader
	_chroma_shader_material.set_shader_parameter("chroma_color", Color(1.0, 0.0, 1.0, 1.0))
	_chroma_shader_material.set_shader_parameter("chroma_tolerance", 0.05)

## Sets up authentic textures
func _setup_status_textures() -> void:
	if not status_bg:
		return
	if not status_bg.texture:
		var bg_tex := _load_texture_file("assets/hud/hud_status_frame_transparent_channels.png")
		if not bg_tex:
			bg_tex = _load_texture_file("assets/hud/hud_status_exact.png")
		if not bg_tex:
			bg_tex = _load_texture_file("assets/hud/hud_status_top_left.png")
		if bg_tex:
			status_bg.texture = bg_tex
		else:
			var loader := _get_archive_loader()
			if loader and loader.has_method("get_ui_texture"):
				var def_bg: ImageTexture = loader.get_ui_texture("menu/Skins/default/Form_State_1.bmp")
				if def_bg:
					status_bg.texture = def_bg

	if avatar_rect and avatar_rect.material == null:
		var c_shader := Shader.new()
		c_shader.code = CIRCLE_AVATAR_SHADER_CODE
		var c_mat := ShaderMaterial.new()
		c_mat.shader = c_shader
		avatar_rect.material = c_mat

	if hp_channel_under and not hp_channel_under.texture:
		var hp_under_tex := _load_texture_file("assets/hud/bar_hp_empty.png")
		if hp_under_tex:
			hp_channel_under.texture = hp_under_tex
	if sp_channel_under and not sp_channel_under.texture:
		var sp_under_tex := _load_texture_file("assets/hud/bar_sp_empty.png")
		if sp_under_tex:
			sp_channel_under.texture = sp_under_tex

	if hp_bar and hp_bar is TextureProgressBar:
		var hp_prog := hp_bar as TextureProgressBar
		if not hp_prog.texture_progress:
			var hp_tex := _load_texture_file("assets/hud/bar_hp_fill.png")
			if hp_tex:
				hp_prog.texture_progress = hp_tex
				hp_prog.material = _chroma_shader_material
	if sp_bar and sp_bar is TextureProgressBar:
		var sp_prog := sp_bar as TextureProgressBar
		if not sp_prog.texture_progress:
			var sp_tex := _load_texture_file("assets/hud/bar_sp_fill.png")
			if sp_tex:
				sp_prog.texture_progress = sp_tex
				sp_prog.material = _chroma_shader_material
	if exp_bar and exp_bar is TextureProgressBar:
		var exp_prog := exp_bar as TextureProgressBar
		if not exp_prog.texture_progress:
			var exp_tex := _load_texture_file("assets/hud/bar_exp_fill.png")
			if exp_tex:
				exp_prog.texture_progress = exp_tex

## Ensures a wrapping container for buffs/debuffs exists
func _setup_buff_container() -> void:
	if not buff_container:
		buff_container = HFlowContainer.new()
		buff_container.name = "BuffContainer"
		buff_container.position = Vector2(8, 185)
		buff_container.size = Vector2(230, 48)
		buff_container.add_theme_constant_override("h_separation", 4)
		buff_container.add_theme_constant_override("v_separation", 4)
		buff_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(buff_container)

## Smoothly updates HP with optional tween interpolation
func set_hp(p_hp: int, p_max: int, smooth: bool = true) -> void:
	current_hp = p_hp
	max_hp = maxi(1, p_max)
	
	if hp_bar:
		hp_bar.max_value = float(max_hp)
		if smooth and is_inside_tree():
			if _hp_tween and _hp_tween.is_valid():
				_hp_tween.kill()
			_hp_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_hp_tween.tween_property(hp_bar, "value", float(current_hp), 0.3)
		else:
			hp_bar.value = float(current_hp)
	
	if hp_label:
		hp_label.text = "HP   %d/%d" % [current_hp, max_hp]
	hp_changed.emit(current_hp, max_hp)

## Smoothly updates SP with optional tween interpolation
func set_sp(p_sp: int, p_max: int, smooth: bool = true) -> void:
	current_sp = p_sp
	max_sp = maxi(1, p_max)
	
	if sp_bar:
		sp_bar.max_value = float(max_sp)
		if smooth and is_inside_tree():
			if _sp_tween and _sp_tween.is_valid():
				_sp_tween.kill()
			_sp_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_sp_tween.tween_property(sp_bar, "value", float(current_sp), 0.3)
		else:
			sp_bar.value = float(current_sp)
	
	if sp_label:
		sp_label.text = "SP   %d/%d" % [current_sp, max_sp]
	sp_changed.emit(current_sp, max_sp)

## Smoothly updates EXP with optional tween interpolation
func set_exp(p_exp: int, p_max: int, smooth: bool = true) -> void:
	current_exp = p_exp
	max_exp = maxi(1, p_max)
	var pct: float = clampf((float(current_exp) / float(max_exp)) * 100.0, 0.0, 100.0)
	
	if exp_bar:
		exp_bar.max_value = 100.0
		if smooth and is_inside_tree():
			if _exp_tween and _exp_tween.is_valid():
				_exp_tween.kill()
			_exp_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_exp_tween.tween_property(exp_bar, "value", pct, 0.3)
		else:
			exp_bar.value = pct
			
	if exp_label:
		exp_label.text = "%d%%" % int(pct)
	exp_changed.emit(current_exp, max_exp)

## Sets the player role and loads avatar animation frames
func set_role(role_id: int) -> void:
	current_role_id = role_id
	_avatar_frames.clear()
	
	var loader := _get_archive_loader()
	if loader and loader.has_method("get_avatar_frames"):
		var af: Array = loader.get_avatar_frames(role_id)
		for f in af:
			if f:
				_avatar_frames.append(f)

	if _avatar_frames.is_empty():
		for i in range(2):
			var path := "assets/hud/avatar_role_%d_%d.png" % [role_id, i]
			var tex := _load_texture_file(path)
			if tex:
				_avatar_frames.append(tex)
			
	if _avatar_frames.is_empty() and loader and loader.has_method("get_character_avatar"):
		var base_avatar: Texture2D = loader.get_character_avatar(role_id)
		if base_avatar:
			_avatar_frames.append(base_avatar)
				
	if not _avatar_frames.is_empty() and avatar_rect:
		avatar_rect.texture = _avatar_frames[0]
		if avatar_rect.material == null:
			var c_shader := Shader.new()
			c_shader.code = CIRCLE_AVATAR_SHADER_CODE
			var c_mat := ShaderMaterial.new()
			c_mat.shader = c_shader
			avatar_rect.material = c_mat
	role_changed.emit(role_id)

## Sets the elemental affinity icon (Earth=1, Water=2, Fire=3, Wind=4)
func set_element(elem: Variant) -> void:
	current_element = elem
	var elem_id: int = 1
	if elem is int:
		elem_id = clampi(elem, 1, 4)
	elif elem is String:
		match elem.to_lower():
			"earth": elem_id = 1
			"water": elem_id = 2
			"fire": elem_id = 3
			"wind": elem_id = 4
			_: elem_id = 1
			
	var path := "assets/hud/icon_element_%d.png" % elem_id
	var tex := _load_texture_file(path)
	if tex and element_icon:
		element_icon.texture = tex
	element_changed.emit(elem)

## Sets the player display name
func set_player_name(p_name: String) -> void:
	if name_label:
		name_label.text = p_name

## Sets the player level
func set_player_level(p_level: int) -> void:
	if level_label:
		level_label.text = "LV %d" % p_level

## Sets player gold
func set_gold(p_gold: int) -> void:
	if gold_label:
		gold_label.text = "Gold %d" % p_gold

## Adds a buff or debuff icon to the wrapping container
func add_buff(id: String, icon: Texture2D, duration: float = -1.0, tooltip: String = "") -> void:
	if not buff_container:
		_setup_buff_container()
	if _active_buffs.has(id):
		remove_buff(id)
		
	var buff_rect := TextureRect.new()
	buff_rect.name = "Buff_" + id
	buff_rect.custom_minimum_size = Vector2(20, 20)
	buff_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	buff_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	buff_rect.texture = icon
	buff_rect.tooltip_text = tooltip if tooltip != "" else id
	buff_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	buff_container.add_child(buff_rect)
	
	_active_buffs[id] = {
		"node": buff_rect,
		"duration": duration,
		"elapsed": 0.0
	}

## Removes a buff icon by id
func remove_buff(id: String) -> void:
	if _active_buffs.has(id):
		var data: Dictionary = _active_buffs[id]
		var node: Node = data.get("node", null)
		if node and is_instance_valid(node):
			node.queue_free()
		_active_buffs.erase(id)

## Clears all active buffs
func clear_buffs() -> void:
	for id in _active_buffs.keys():
		remove_buff(id)
	_active_buffs.clear()

## Returns active buffs count
func get_buff_count() -> int:
	return _active_buffs.size()

func _process_avatar_blinking(delta: float) -> void:
	if _avatar_frames.size() < 2 or not avatar_rect:
		return
	_avatar_blink_timer += delta
	if _avatar_is_blinking:
		if _avatar_blink_timer >= _avatar_blink_duration:
			_avatar_is_blinking = false
			_avatar_blink_timer = 0.0
			avatar_rect.texture = _avatar_frames[0]
	else:
		if _avatar_blink_timer >= _avatar_blink_interval:
			_avatar_is_blinking = true
			_avatar_blink_timer = 0.0
			avatar_rect.texture = _avatar_frames[1]

func _process_buff_durations(delta: float) -> void:
	if _active_buffs.is_empty():
		return
	var expired: Array[String] = []
	for id in _active_buffs.keys():
		var buff: Dictionary = _active_buffs[id]
		var dur: float = buff.get("duration", -1.0)
		if dur > 0.0:
			buff["elapsed"] = buff.get("elapsed", 0.0) + delta
			if buff["elapsed"] >= dur:
				expired.append(id)
	for id in expired:
		remove_buff(id)

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
