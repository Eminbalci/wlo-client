class_name HUDPlayerStatus
extends RefCounted

## Sub-controller for Wonderland Online HUD Player Status Dock (241x116).
## Encapsulates player avatar animation (14 roles with blinking state machine),
## element badge, HP/SP/EXP progress bars with 3-layer chroma mask shaders, and stats readout.

const CHROMA_MASK_SHADER_CODE: String = """shader_type canvas_item;
render_mode blend_mix;

uniform vec4 chroma_color : source_color = vec4(1.0, 0.0, 1.0, 1.0); // Default magenta key
uniform float chroma_tolerance : hint_range(0.0, 1.0) = 0.05;
uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// Chroma mask keying
	if (distance(col.rgb, chroma_color.rgb) <= chroma_tolerance) {
		discard;
	}
	if (UV.x > fill_ratio) {
		discard;
	}
	COLOR = col * COLOR;
}
"""

var _hud: Control = null

# Node references
var status_dock: Control = null
var status_bg: TextureRect = null
var avatar_bg: ColorRect = null
var avatar_rect: TextureRect = null
var name_label: Label = null
var level_label: Label = null
var hp_label: Label = null
var hp_bar: Range = null
var sp_label: Label = null
var sp_bar: Range = null
var exp_label: Label = null
var exp_bar: Range = null
var element_icon: TextureRect = null
var hp_channel_under: TextureRect = null
var sp_channel_under: TextureRect = null
var gold_label: Label = null

# Avatar blinking state machine
var _avatar_frames: Array[Texture2D] = []
var _avatar_blink_timer: float = 0.0
var _avatar_blink_duration: float = 0.15
var _avatar_blink_interval: float = 3.5
var _avatar_is_blinking: bool = false
var _current_player_role_id: int = 6
var _current_player_element: Variant = "Fire"

# 3-layer Chroma Mask Shader material
var _chroma_shader_material: ShaderMaterial = null

## Initializes references and sets up visual components
func setup(hud: Control, nodes: Dictionary = {}) -> void:
	_hud = hud
	
	status_dock = nodes.get("status_dock", hud.get_node_or_null("PlayerStatusDock"))
	status_bg = nodes.get("status_bg", hud.get_node_or_null("PlayerStatusDock/StatusBackground"))
	avatar_bg = nodes.get("avatar_bg", hud.get_node_or_null("PlayerStatusDock/AvatarBg"))
	avatar_rect = nodes.get("avatar_rect", hud.get_node_or_null("PlayerStatusDock/AvatarRect"))
	name_label = nodes.get("name_label", hud.get_node_or_null("PlayerStatusDock/NameLabel"))
	level_label = nodes.get("level_label", hud.get_node_or_null("PlayerStatusDock/LevelLabel"))
	hp_label = nodes.get("hp_label", hud.get_node_or_null("PlayerStatusDock/HpLabel"))
	hp_bar = nodes.get("hp_bar", hud.get_node_or_null("PlayerStatusDock/HpBar"))
	sp_label = nodes.get("sp_label", hud.get_node_or_null("PlayerStatusDock/SpLabel"))
	sp_bar = nodes.get("sp_bar", hud.get_node_or_null("PlayerStatusDock/SpBar"))
	exp_label = nodes.get("exp_label", hud.get_node_or_null("PlayerStatusDock/ExpLabel"))
	exp_bar = nodes.get("exp_bar", hud.get_node_or_null("PlayerStatusDock/ExpBar"))
	element_icon = nodes.get("element_icon", hud.get_node_or_null("PlayerStatusDock/ElementIcon"))
	hp_channel_under = nodes.get("hp_channel_under", hud.get_node_or_null("PlayerStatusDock/HpChannelUnder"))
	sp_channel_under = nodes.get("sp_channel_under", hud.get_node_or_null("PlayerStatusDock/SpChannelUnder"))
	gold_label = nodes.get("gold_label", hud.get_node_or_null("PlayerStatusDock/GoldLabel"))
	
	_setup_chroma_shader()
	_setup_status_dock_textures()
	_setup_status_bars()
	
	if avatar_rect:
		avatar_rect.position = Vector2(30, -4)
		avatar_rect.size = Vector2(72, 72)
		# Ensure avatar_rect renders strictly behind status_bg and hp_bar
		if status_dock and status_bg and avatar_rect.get_index() > status_bg.get_index():
			status_dock.move_child(avatar_rect, status_bg.get_index())
	if avatar_bg:
		avatar_bg.visible = false
		avatar_bg.position = Vector2(18, 18)
		avatar_bg.size = Vector2(64, 64)

## Creates and compiles the 3-layer chroma mask shader material
func _setup_chroma_shader() -> void:
	var shader := Shader.new()
	shader.code = CHROMA_MASK_SHADER_CODE
	_chroma_shader_material = ShaderMaterial.new()
	_chroma_shader_material.shader = shader
	_chroma_shader_material.set_shader_parameter("chroma_color", Color(1.0, 0.0, 1.0, 1.0))
	_chroma_shader_material.set_shader_parameter("chroma_tolerance", 0.05)

## Ensures all required node references are bound from HUD
func _ensure_node_bindings() -> void:
	if not _hud:
		return
	if not status_dock:
		status_dock = _hud.get_node_or_null("PlayerStatusDock")
	if not status_bg:
		status_bg = _hud.get_node_or_null("PlayerStatusDock/StatusBackground")
	if not avatar_bg:
		avatar_bg = _hud.get_node_or_null("PlayerStatusDock/AvatarBg")
	if not avatar_rect:
		avatar_rect = _hud.get_node_or_null("PlayerStatusDock/AvatarRect")
	if not name_label:
		name_label = _hud.get_node_or_null("PlayerStatusDock/NameLabel")
	if not level_label:
		level_label = _hud.get_node_or_null("PlayerStatusDock/LevelLabel")
	if not hp_label:
		hp_label = _hud.get_node_or_null("PlayerStatusDock/HpLabel")
	if not hp_bar:
		hp_bar = _hud.get_node_or_null("PlayerStatusDock/HpBar")
	if not sp_label:
		sp_label = _hud.get_node_or_null("PlayerStatusDock/SpLabel")
	if not sp_bar:
		sp_bar = _hud.get_node_or_null("PlayerStatusDock/SpBar")
	if not exp_label:
		exp_label = _hud.get_node_or_null("PlayerStatusDock/ExpLabel")
	if not exp_bar:
		exp_bar = _hud.get_node_or_null("PlayerStatusDock/ExpBar")
	if not element_icon:
		element_icon = _hud.get_node_or_null("PlayerStatusDock/ElementIcon")
	if not hp_channel_under:
		hp_channel_under = _hud.get_node_or_null("PlayerStatusDock/HpChannelUnder")
	if not sp_channel_under:
		sp_channel_under = _hud.get_node_or_null("PlayerStatusDock/SpChannelUnder")
	if not gold_label:
		gold_label = _hud.get_node_or_null("PlayerStatusDock/GoldLabel")

## Per-frame update for avatar blinking state machine
func process(delta: float) -> void:
	if status_dock and status_dock.visible and avatar_rect and _avatar_frames.size() > 1:
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

## Updates player status labels and progress bars
func set_player_stats(p_name: String, p_lvl: int, p_hp: int, p_max_hp: int, p_sp: int, p_max_sp: int, p_exp: Variant, p_max_exp: int = 100) -> void:
	_ensure_node_bindings()
	if name_label:
		name_label.text = p_name
	if level_label:
		level_label.text = "LV %d" % p_lvl
	if hp_label:
		hp_label.text = "HP   %d/%d" % [p_hp, p_max_hp]
	if hp_bar:
		hp_bar.max_value = p_max_hp
		hp_bar.value = p_hp
	if sp_label:
		sp_label.text = "SP   %d/%d" % [p_sp, p_max_sp]
	if sp_bar:
		sp_bar.max_value = p_max_sp
		sp_bar.value = p_sp
	
	var exp_pct: float = 0.0
	if p_exp is float:
		exp_pct = float(p_exp)
	elif p_max_exp > 0:
		exp_pct = (float(p_exp) / float(p_max_exp)) * 100.0
	
	if exp_label:
		exp_label.text = "%d%%" % int(exp_pct)
	if exp_bar:
		exp_bar.max_value = 100.0
		exp_bar.value = exp_pct

## Backward-compatible alias for set_player_stats
func update_player_stats(p_name: String, p_lvl: int, p_hp: int, p_max_hp: int, p_sp: int, p_max_sp: int, p_exp: Variant, p_max_exp: int = 100) -> void:
	set_player_stats(p_name, p_lvl, p_hp, p_max_hp, p_sp, p_max_sp, p_exp, p_max_exp)

## Dynamically sets character role (1..14) and loads avatar animation frames from 008.jma
func set_player_role(role_id: int) -> void:
	_ensure_node_bindings()
	_current_player_role_id = role_id
	_avatar_frames.clear()
	
	var loader: Node = null
	if _hud and _hud.is_inside_tree():
		loader = _hud.get_node_or_null("/root/ArchiveLoader")
	if not loader and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			loader = st.root.get_node_or_null("ArchiveLoader")
	
	if loader and loader.has_method("get_avatar_frames"):
		var loaded_frames = loader.get_avatar_frames(role_id)
		if not loaded_frames.is_empty():
			for f in loaded_frames:
				if f is Texture2D:
					_avatar_frames.append(f)
	
	if _avatar_frames.is_empty():
		var f0 := _load_texture_file("assets/hud/avatar_role_%d_0.png" % role_id)
		var f1 := _load_texture_file("assets/hud/avatar_role_%d_1.png" % role_id)
		if f0:
			_avatar_frames.append(f0)
		if f1:
			_avatar_frames.append(f1)
	
	_avatar_is_blinking = false
	_avatar_blink_timer = 0.0
	if not _avatar_frames.is_empty() and avatar_rect:
		avatar_rect.texture = _avatar_frames[0]
	
	# Update element icon dynamically from role definition
	var elem_name := "Wind"
	var db: Node = null
	if _hud and _hud.is_inside_tree():
		db = _hud.get_node_or_null("/root/GameDatabase")
	if not db and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			db = st.root.get_node_or_null("GameDatabase")
	if db and db.has_method("get_role"):
		var role_def: Dictionary = db.get_role(role_id)
		if not role_def.is_empty():
			elem_name = role_def.get("element", "Wind")
	update_player_element(elem_name)

## Sets the elemental affinity icon badge (Wind, Water, Fire, Earth)
func set_player_element(elem: Variant) -> void:
	update_player_element(elem)

## Updates the elemental affinity icon badge (Wind, Water, Fire, Earth)
func update_player_element(elem: Variant) -> void:
	_ensure_node_bindings()
	_current_player_element = elem
	if not element_icon:
		return
	
	var icon_id: int = 4
	if elem is int:
		icon_id = clampi(elem, 1, 4)
	elif elem is String:
		var s := (elem as String).to_lower()
		if "earth" in s:
			icon_id = 1
		elif "water" in s:
			icon_id = 2
		elif "fire" in s:
			icon_id = 3
		elif "wind" in s:
			icon_id = 4
	
	var tex := _load_texture_file("assets/hud/icon_element_%d.png" % icon_id)
	if tex:
		element_icon.texture = tex

## Sets up authentic 3-layer chroma mask textures on status dock
func _setup_status_dock_textures() -> void:
	if not status_dock:
		return
	
	if _avatar_frames.is_empty():
		set_player_role(_current_player_role_id)
	elif avatar_rect:
		avatar_rect.texture = _avatar_frames[0]
	
	update_player_element(_current_player_element)
	
	# Layer 1: Under channels
	var hp_under_tex := _load_texture_file("assets/hud/hud_bar_hp_under.png")
	if hp_channel_under:
		hp_channel_under.texture = hp_under_tex
	
	var sp_under_tex := _load_texture_file("assets/hud/hud_bar_sp_under.png")
	if sp_channel_under:
		sp_channel_under.texture = sp_under_tex
	
	# Layer 2: TextureProgressBars with authentic fill
	var hp_prog := hp_bar as TextureProgressBar
	if hp_prog:
		hp_prog.texture_under = hp_under_tex
		hp_prog.texture_progress = _load_texture_file("assets/hud/Main_Hp.png")
		hp_prog.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
		hp_prog.material = null
	
	var sp_prog := sp_bar as TextureProgressBar
	if sp_prog:
		sp_prog.texture_under = sp_under_tex
		sp_prog.texture_progress = _load_texture_file("assets/hud/Main_Sp.png")
		sp_prog.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
		sp_prog.material = null
	
	# Layer 3: Top Frame with transparent channel cutouts
	if status_bg:
		status_bg.texture = _load_texture_file("assets/hud/hud_status_frame_transparent_channels.png")
	
	var exp_prog := exp_bar as TextureProgressBar
	if exp_prog:
		exp_prog.texture_under = _load_texture_file("assets/hud/main_exp_under.png")
		exp_prog.texture_progress = _load_texture_file("assets/hud/main_exp.png")
		exp_prog.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
		exp_prog.material = null

## Set fallback styleboxes for status bars if not using TextureProgressBar
func _setup_status_bars() -> void:
	if not hp_bar or not sp_bar or not exp_bar:
		return
	
	if hp_bar is ProgressBar:
		# HP Bar: Rich crimson red with dark background
		var hp_bg_style := StyleBoxFlat.new()
		hp_bg_style.bg_color = Color(0.04, 0.02, 0.02, 0.85)
		hp_bg_style.set_border_width_all(1)
		hp_bg_style.border_color = Color(0.15, 0.05, 0.05, 0.9)
		hp_bg_style.set_corner_radius_all(2)
		
		var hp_fill_style := StyleBoxFlat.new()
		hp_fill_style.bg_color = Color(0.88, 0.15, 0.15, 1.0)
		hp_fill_style.border_width_top = 1
		hp_fill_style.border_color = Color(1.0, 0.45, 0.35, 1.0)
		hp_fill_style.set_corner_radius_all(2)
		hp_bar.add_theme_stylebox_override("background", hp_bg_style)
		hp_bar.add_theme_stylebox_override("fill", hp_fill_style)
	
	if sp_bar is ProgressBar:
		# SP Bar: Vibrant cobalt blue with dark background
		var sp_bg_style := StyleBoxFlat.new()
		sp_bg_style.bg_color = Color(0.02, 0.04, 0.10, 0.85)
		sp_bg_style.set_border_width_all(1)
		sp_bg_style.border_color = Color(0.05, 0.10, 0.20, 0.9)
		sp_bg_style.set_corner_radius_all(2)
		
		var sp_fill_style := StyleBoxFlat.new()
		sp_fill_style.bg_color = Color(0.15, 0.45, 0.95, 1.0)
		sp_fill_style.border_width_top = 1
		sp_fill_style.border_color = Color(0.45, 0.75, 1.0, 1.0)
		sp_fill_style.set_corner_radius_all(2)
		sp_bar.add_theme_stylebox_override("background", sp_bg_style)
		sp_bar.add_theme_stylebox_override("fill", sp_fill_style)
	
	if exp_bar is ProgressBar:
		# EXP Bar: Amber gold with dark background
		var exp_bg_style := StyleBoxFlat.new()
		exp_bg_style.bg_color = Color(0.08, 0.06, 0.02, 0.85)
		exp_bg_style.set_border_width_all(1)
		exp_bg_style.border_color = Color(0.12, 0.10, 0.02, 0.9)
		exp_bg_style.set_corner_radius_all(1)
		
		var exp_fill_style := StyleBoxFlat.new()
		exp_fill_style.bg_color = Color(0.95, 0.80, 0.10, 1.0)
		exp_fill_style.border_width_top = 1
		exp_fill_style.border_color = Color(1.0, 0.90, 0.50, 1.0)
		exp_fill_style.set_corner_radius_all(1)
		exp_bar.add_theme_stylebox_override("background", exp_bg_style)
		exp_bar.add_theme_stylebox_override("fill", exp_fill_style)

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
