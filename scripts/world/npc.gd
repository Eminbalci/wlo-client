class_name NpcEntity
extends Node2D

## 2:1 Axonometric NPC Entity for Wonderland Online.
## Supports interactive clicking, nameplates, authentic JMA / JRole sprites,
## 128x128 canvas grounding without foot jitter, and HUD dialogue triggering.

signal npc_interacted(npc: NpcEntity)

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const MapData = preload("res://scripts/map/map_data.gd")

@export var npc_id: int = 7
@export var npc_name: String = "Captain Robinson":
	set(val):
		npc_name = val
		if nameplate:
			nameplate.text = val
@export var model_jmp: String = ""
@export var model_jma: String = "001.jma"
@export var world_position: Vector2 = Vector2(1720.0, 906.0):
	set(val):
		world_position = val
		if is_inside_tree():
			_update_screen_position()
@export var heading: int = IsometricMath.Heading.SOUTH:
	set(val):
		heading = val
		if is_inside_tree() and _anim_data:
			_update_frame()

var facing_direction: int:
	get:
		return heading
	set(val):
		heading = val

@export var original_heading: int = -1

var world_pos: Vector2:
	get:
		return world_position
	set(val):
		world_position = val
@export var level: int = 1
@export var hp: int = 100
@export var max_hp: int = 100
@export var sp: int = 50
@export var max_sp: int = 50
@export var element: int = 0 # 0=None, 1=Earth, 2=Water, 3=Fire, 4=Wind
@export var walk_behavior: int = 1
@export var entity_type: int = 1
@export var is_broken: bool = false
@export var is_wild_monster: bool = false
@export var spawn_position: Vector2 = Vector2.ZERO
@export var is_hidden_by_preevent: bool = false
@export var talk_id: int = 0
@export var talk_image: int = 0
@export var click_id: int = 0
@export var template_id: int = 0
@export var eve_rotation: int = 5
@export_multiline var dialogue_text: String = "Welcome aboard the ship! I am the Captain. We are setting sail for North Island soon. Make sure you are prepared!"
@export var dialogue_choices: Array[String] = ["I am ready!", "Tell me more about North Island."]

func set_preevent_visibility(p_visible: bool) -> void:
	visible = p_visible
	is_hidden_by_preevent = not p_visible
	if click_area:
		click_area.monitoring = p_visible
		click_area.monitorable = p_visible
		click_area.input_pickable = p_visible
	if not p_visible:
		is_moving = false

var texture: Texture2D:
	get:
		return sprite.texture if sprite else null
	set(val):
		_apply_texture(val)

func set_texture(tex: Texture2D) -> void:
	_apply_texture(tex)

var _anim_data = null
var _portrait_texture: ImageTexture = null
var _anim_frame_timer: float = 0.0
var _current_frame_idx: int = -1
var _frame_cache: Dictionary = {} # int -> ImageTexture
## Cached sprite offset per model_jmp to avoid per-frame pixel scan
static var _offset_cache: Dictionary = {} # String -> float (offset_y)

var is_moving: bool = false
@export var is_standing: bool = true
var target_world_position: Vector2 = Vector2.ZERO
@export var move_speed: float = 60.0

@export var walksteps: Array[Vector2] = []
@export var walkstep_delays: Array[float] = []
@export var is_patrol_ping_pong: bool = true
var _patrol_forward: bool = true
var _current_step_idx: int = 0
var _step_wait_timer: float = 0.0
var _is_waiting_at_step: bool = false
var map_data = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var nameplate: Label = $Nameplate
@onready var click_area: Area2D = $ClickArea

func _ready() -> void:
	if original_heading == -1:
		original_heading = heading
	if nameplate:
		nameplate.text = npc_name
	if walksteps.size() > 1 and world_position.distance_to(walksteps[0]) < 5.0:
		_current_step_idx = 1
		_patrol_forward = true
	_load_npc_art()
	_update_screen_position()
	
	if is_hidden_by_preevent:
		visible = false
		if click_area:
			click_area.monitoring = false
			click_area.monitorable = false
			click_area.input_pickable = false
	
	if click_area:
		click_area.input_event.connect(_on_click_area_input_event)

func _compute_frame_index(total_frames: int) -> int:
	if total_frames <= 0:
		return 0
	if total_frames >= 64:
		var stand_base: int = 32 if not is_moving else 0
		var sub_idx: int = int(_anim_frame_timer * (6.0 if is_moving else 2.5)) % 4
		return (stand_base + (heading % 8) * 4 + sub_idx) % total_frames
	elif total_frames == 32:
		# Check if 8-way stationary stand character (e.g. 1274.jmp where frame 0 starts with '08')
		if _anim_data != null and not _anim_data.frames.is_empty() and _anim_data.frames[0].name.begins_with("08"):
			var sub_idx: int = int(_anim_frame_timer * 2.5) % 4
			return ((heading % 8) * 4 + sub_idx) % total_frames
		
		# Standard 4-diagonal walk (frames 0..15) + 4-diagonal stand (frames 16..31)
		# 01/09: NW (diag 0), 03/11: SW (diag 1), 05/13: SE (diag 2), 07/15: NE (diag 3)
		var diag_idx: int = 0
		match heading % 8:
			IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
				diag_idx = 0
			IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
				diag_idx = 1
			IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
				diag_idx = 2
			IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
				diag_idx = 3
		if is_moving:
			var base: int = diag_idx * 4
			var sub_idx: int = int(_anim_frame_timer * 6.0) % 4
			return (base + sub_idx) % total_frames
		else:
			var base: int = 16 + diag_idx * 4
			var sub_idx: int = int(_anim_frame_timer * 2.5) % 4
			return (base + sub_idx) % total_frames
	elif total_frames == 16:
		var sub_idx: int = int(_anim_frame_timer * (6.0 if is_moving else 2.5)) % 4
		var diag_block: int = 0
		match heading % 8:
			IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
				diag_block = 0
			IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
				diag_block = 1
			IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
				diag_block = 2
			IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
				diag_block = 3
		return (diag_block * 4 + sub_idx) % total_frames
	elif total_frames == 8:
		if _anim_data != null and not _anim_data.frames.is_empty() and _anim_data.frames[0].name.begins_with("01"):
			var diag_idx: int = 0
			match heading % 8:
				IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
					diag_idx = 0
				IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
					diag_idx = 1
				IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
					diag_idx = 2
				IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
					diag_idx = 3
			if is_moving:
				return diag_idx % total_frames
			else:
				return (4 + diag_idx) % total_frames
		return heading % 8
	elif total_frames == 4:
		match heading % 8:
			IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
				return 0
			IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
				return 1
			IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
				return 2
			IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
				return 3
		return 0
	elif total_frames == 2:
		return 1 if is_broken else 0
	else:
		return int(_anim_frame_timer * 2.0) % total_frames

func _process(delta: float) -> void:
	if not visible or is_hidden_by_preevent:
		return
	if not walksteps.is_empty():
		_process_walksteps(delta)
	
	if not _anim_data or _anim_data.frames.is_empty():
		return
	
	_anim_frame_timer += delta
	var total_frames: int = _anim_data.frames.size()
	var frame_idx: int = _compute_frame_index(total_frames)
	
	if frame_idx == _current_frame_idx:
		return
	
	_current_frame_idx = frame_idx
	var frame: ImageTexture = _get_frame_texture(frame_idx)
	if frame:
		_apply_texture(frame)

func _advance_patrol_step() -> void:
	if walksteps.is_empty():
		_current_step_idx = 0
		return
	if not is_patrol_ping_pong:
		_current_step_idx = (_current_step_idx + 1) % walksteps.size()
		return
	if walksteps.size() <= 1:
		_current_step_idx = 0
		return
	if _patrol_forward:
		if _current_step_idx + 1 < walksteps.size():
			_current_step_idx += 1
		else:
			_patrol_forward = false
			_current_step_idx = maxi(0, _current_step_idx - 1)
	else:
		if _current_step_idx - 1 >= 0:
			_current_step_idx -= 1
		else:
			_patrol_forward = true
			_current_step_idx = mini(walksteps.size() - 1, _current_step_idx + 1)

func _process_walksteps(delta: float) -> void:
	if walksteps.is_empty():
		return
	if _is_waiting_at_step:
		if is_moving:
			is_moving = false
			_anim_frame_timer = 0.0
			_update_frame()
		_step_wait_timer -= delta
		if _step_wait_timer <= 0.0:
			_is_waiting_at_step = false
			_advance_patrol_step()
		return
	
	var target: Vector2 = walksteps[_current_step_idx]
	var diff := target - world_position
	var dist := diff.length()
	var step_dist := move_speed * delta
	if dist <= step_dist or dist < 2.0:
		if map_data and map_data.has_method("is_walkable"):
			var cur_grid: Vector2i = MapData.world_to_grid(world_position)
			if map_data.is_walkable(cur_grid.x, cur_grid.y, 0):
				var target_grid: Vector2i = MapData.world_to_grid(target)
				if not map_data.is_walkable(target_grid.x, target_grid.y, 0):
					if is_moving:
						is_moving = false
						_anim_frame_timer = 0.0
						_update_frame()
					_is_waiting_at_step = true
					_step_wait_timer = 1.0
					_advance_patrol_step()
					return
		world_position = target
		if is_moving:
			is_moving = false
			_anim_frame_timer = 0.0
			_update_frame()
		_is_waiting_at_step = true
		var wait_time: float = walkstep_delays[_current_step_idx] if _current_step_idx < walkstep_delays.size() else 0.0
		_step_wait_timer = wait_time
	else:
		var dir := diff.normalized()
		var next_pos: Vector2 = world_position + dir * step_dist
		
		# Obstacle / Wall collision check against map_data
		if map_data and map_data.has_method("is_walkable"):
			var cur_grid: Vector2i = MapData.world_to_grid(world_position)
			if map_data.is_walkable(cur_grid.x, cur_grid.y, 0):
				var next_grid: Vector2i = MapData.world_to_grid(next_pos)
				if not map_data.is_walkable(next_grid.x, next_grid.y, 0):
					# Collision detected: do not move into wall, switch to wait and reverse waypoint
					if is_moving:
						is_moving = false
						_anim_frame_timer = 0.0
						_update_frame()
					_is_waiting_at_step = true
					_step_wait_timer = 1.0
					_advance_patrol_step()
					return
		
		if not is_moving:
			is_moving = true
			_anim_frame_timer = 0.0
		heading = IsometricMath.get_heading(world_position, target)
		world_position = next_pos
		_update_screen_position()

func restore_facing() -> void:
	if original_heading >= 0:
		heading = original_heading
		facing_direction = original_heading
		if _anim_data:
			_update_frame()

func _update_frame() -> void:
	if not _anim_data or _anim_data.frames.is_empty():
		return
	var total_frames: int = _anim_data.frames.size()
	var frame_idx: int = _compute_frame_index(total_frames)
	_current_frame_idx = frame_idx
	var frame: ImageTexture = _get_frame_texture(frame_idx)
	if frame:
		_apply_texture(frame)

func _load_npc_art() -> void:
	var loader := get_node_or_null("/root/ArchiveLoader")
	if not loader:
		return
	
	if sprite:
		sprite.flip_h = false
	
	# Auto-resolve sprite from NpcDatabase when npc_id is set and model_jmp not explicitly defined
	if model_jmp.is_empty() and npc_id > 0:
		var db = get_node_or_null("/root/GameDatabase")
		if db and "npcs" in db and db.npcs:
			var rec = db.npcs.get_npc(npc_id)
			if rec and rec.sprite_id > 0:
				model_jmp = "%d.jmp" % rec.sprite_id
				var pkg: int = int(rec.sprite_id / 1000)
				model_jma = "%03d.jma" % pkg
				if npc_name.is_empty() or npc_name.begins_with("NPC_"):
					npc_name = rec.name
	
	if not model_jmp.is_empty():
		var jmp_num: int = model_jmp.to_int()
		if jmp_num > 0 and (model_jma.is_empty() or model_jma == "001.jma"):
			var pkg: int = int(jmp_num / 1000)
			model_jma = "%03d.jma" % pkg
		_anim_data = loader.get_jma_animation(model_jma, model_jmp)
		if _anim_data:
			_update_frame()
			return
	
	# Fallback roles
	if npc_id == 7 or npc_id == 8 or npc_id == 14003: # Captain
		model_jmp = "1038.jmp"
		model_jma = "001.jma"
		_anim_data = loader.get_jma_animation("001.jma", "1038.jmp")
	elif npc_id == 6 or npc_id == 4 or npc_id == 1 or npc_id == 14001 or npc_id == 14002: # Sailor / Crew
		model_jmp = "1037.jmp"
		model_jma = "001.jma"
		_anim_data = loader.get_jma_animation("001.jma", "1037.jmp")
	
	if _anim_data:
		_update_frame()
		return
	
	var fallback_sheet: ImageTexture = loader.get_role_sprite_sheet(npc_id, 0)
	if fallback_sheet:
		_apply_texture(fallback_sheet)

## Decodes the frame onto a 128x128 canvas using (pivot_x, pivot_y) to avoid foot jitter.
func _get_frame_texture(frame_idx: int) -> ImageTexture:
	var loader := get_node_or_null("/root/ArchiveLoader")
	if loader and loader.has_method("get_jma_frame_128") and not model_jmp.is_empty():
		return loader.get_jma_frame_128(model_jma, model_jmp, frame_idx)
	
	if _frame_cache.has(frame_idx):
		return _frame_cache[frame_idx]
	
	if not _anim_data:
		return null
	
	var j_frame = _anim_data.get_frame(frame_idx)
	if not j_frame or j_frame.width <= 0 or j_frame.height <= 0:
		return null
	
	var layer_img: Image = _anim_data.decode_frame_image(frame_idx)
	if not layer_img:
		return null
	
	var cw: int = maxi(128, j_frame.bound_w)
	var ch: int = maxi(128, j_frame.bound_h)
	var canvas := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blend_rect(
		layer_img,
		Rect2i(0, 0, j_frame.width, j_frame.height),
		Vector2i(j_frame.pivot_x, j_frame.pivot_y)
	)
	var tex := ImageTexture.create_from_image(canvas)
	_frame_cache[frame_idx] = tex
	return tex

func _apply_texture(tex: Texture2D) -> void:
	if not sprite:
		if has_node("Sprite2D"):
			sprite = get_node("Sprite2D")
	if not sprite or not tex:
		return
	sprite.texture = tex
	var h := float(tex.get_height())
	if model_jmp in ["1088.jmp", "1089.jmp"] and int(h) == 256:
		sprite.offset = Vector2(-3.0 if model_jmp == "1088.jmp" else 0.0, -96.0)
	elif int(h) == 128 or int(h) == 256:
		sprite.offset = Vector2(0, -35.0)
	else:
		sprite.offset = Vector2(0, -roundf(h * 0.27)) if h > 0 else Vector2(0, -35.0)
	var head_height := 86.0
	if npc_id == 11000 or model_jmp == "1035.jmp":
		head_height = 40.0
	elif model_jmp == "1088.jmp" or model_jmp == "1089.jmp":
		head_height = 92.0
	_head_height = head_height
	if not click_area and has_node("ClickArea"):
		click_area = get_node("ClickArea")
	if click_area:
		click_area.position = Vector2(0, -head_height / 2.0)
	if not nameplate and has_node("Nameplate"):
		nameplate = get_node("Nameplate")
	if nameplate:
		nameplate.offset_bottom = -head_height - 2.0
		nameplate.offset_top = -head_height - 22.0
	_update_emotion_container_position()

## Isometric ground alignment: shift sprite down 8px so feet land on tile surface.
const GROUND_OFFSET_Y: float = 8.0

func _update_screen_position() -> void:
	position = world_position + Vector2(0.0, GROUND_OFFSET_Y)
	z_index = clampi(int(world_position.y), -4096, 4096)

var _head_height: float = 86.0
var _emotion_container: Node2D = null
var _emotion_label: Label = null
var _quest_marker_label: Label = null
var _speech_bubble_panel: PanelContainer = null
var _speech_bubble_label: Label = null
var _speech_bubble_tween: Tween = null
var _emotion_tween: Tween = null
var _quest_marker_type: String = "none"

var emotion_container: Node2D:
	get:
		return _emotion_container

var emotion_label: Label:
	get:
		return _emotion_label

var speech_bubble_label: Label:
	get:
		return _speech_bubble_label

## Convenience alias for setting quest marker
func show_quest_marker(available: bool, turn_in: bool = false) -> void:
	if turn_in:
		set_quest_marker("turn_in")
	elif available:
		set_quest_marker("available")
	else:
		set_quest_marker("none")

func _init_emotion_container() -> void:
	if _emotion_container:
		return
	_emotion_container = Node2D.new()
	_emotion_container.name = "EmotionContainer"
	_emotion_container.z_index = 10
	add_child(_emotion_container)
	
	_emotion_label = Label.new()
	_emotion_label.name = "EmotionLabel"
	_emotion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emotion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_emotion_label.custom_minimum_size = Vector2(24, 24)
	_emotion_label.offset_left = -12
	_emotion_label.offset_right = 12
	_emotion_label.offset_top = -12
	_emotion_label.offset_bottom = 12
	_emotion_label.add_theme_font_size_override("font_size", 14)
	_emotion_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	_emotion_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_emotion_label.add_theme_constant_override("outline_size", 3)
	_emotion_container.add_child(_emotion_label)
	
	_quest_marker_label = Label.new()
	_quest_marker_label.name = "QuestMarker"
	_quest_marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quest_marker_label.custom_minimum_size = Vector2(24, 24)
	_quest_marker_label.offset_left = -12
	_quest_marker_label.offset_right = 12
	_quest_marker_label.offset_top = -12
	_quest_marker_label.offset_bottom = 12
	_quest_marker_label.add_theme_font_size_override("font_size", 16)
	_quest_marker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
	_quest_marker_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_quest_marker_label.add_theme_constant_override("outline_size", 3)
	_quest_marker_label.visible = false
	_emotion_container.add_child(_quest_marker_label)
	
	_emotion_container.visible = false
	_update_emotion_container_position()

func _update_emotion_container_position() -> void:
	if _emotion_container:
		_emotion_container.position = Vector2(0, -_head_height - 30.0)

## Sets the floating quest availability / turn-in marker above NPC head
func set_quest_marker(type: String) -> void:
	_init_emotion_container()
	_quest_marker_type = type
	if not _emotion_container or not _emotion_label:
		return
	
	if type == "available":
		_emotion_label.text = "!"
		_emotion_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0)) # Gold !
		if _quest_marker_label:
			_quest_marker_label.text = "!"
			_quest_marker_label.visible = true
		_emotion_container.visible = true
		_start_marker_bobbing()
	elif type == "turn_in":
		_emotion_label.text = "?"
		_emotion_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0)) # Gold ?
		if _quest_marker_label:
			_quest_marker_label.text = "?"
			_quest_marker_label.visible = true
		_emotion_container.visible = true
		_start_marker_bobbing()
	elif type == "in_progress":
		_emotion_label.text = "?"
		_emotion_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0)) # Silver/Gray ?
		if _quest_marker_label:
			_quest_marker_label.text = "?"
			_quest_marker_label.visible = true
		_emotion_container.visible = true
		_start_marker_bobbing()
	else:
		_quest_marker_type = "none"
		if _quest_marker_label:
			_quest_marker_label.visible = false
		if _emotion_tween and _emotion_tween.is_valid():
			_emotion_tween.kill()
		_emotion_container.visible = false

func _start_marker_bobbing() -> void:
	if _emotion_tween and _emotion_tween.is_valid():
		_emotion_tween.kill()
	var base_y: float = -_head_height - 30.0
	_emotion_container.position.y = base_y
	_emotion_container.scale = Vector2(1, 1)
	_emotion_container.modulate.a = 1.0
	_emotion_tween = create_tween().set_loops()
	_emotion_tween.tween_property(_emotion_container, "position:y", base_y - 6.0, 0.5).set_trans(Tween.TRANS_SINE)
	_emotion_tween.tween_property(_emotion_container, "position:y", base_y, 0.5).set_trans(Tween.TRANS_SINE)

## Displays an authentic emotion bubble reaction above NPC head (sweat, shock, heart, anger, etc.)
func show_emotion(emotion_type: String, duration: float = 2.0) -> void:
	_init_emotion_container()
	if not _emotion_container or not _emotion_label:
		return
	
	if _emotion_tween and _emotion_tween.is_valid():
		_emotion_tween.kill()
	
	var glyph: String = ""
	var color: Color = Color(1.0, 1.0, 1.0, 1.0)
	match emotion_type.to_lower():
		"exclamation", "!":
			glyph = "!"
			color = Color(1.0, 0.85, 0.1, 1.0)
		"question", "?":
			glyph = "?"
			color = Color(0.3, 0.8, 1.0, 1.0)
		"shock":
			glyph = "!!"
			color = Color(1.0, 0.3, 0.3, 1.0)
		"sweat":
			glyph = ";;"
			color = Color(0.4, 0.7, 1.0, 1.0)
		"heart":
			glyph = "<3"
			color = Color(1.0, 0.4, 0.6, 1.0)
		"anger":
			glyph = "#"
			color = Color(1.0, 0.2, 0.2, 1.0)
		"dots", "talking":
			glyph = "..."
			color = Color(1.0, 1.0, 0.8, 1.0)
		_:
			glyph = "..."
			color = Color(1.0, 1.0, 1.0, 1.0)
	
	_emotion_label.text = glyph
	_emotion_label.add_theme_color_override("font_color", color)
	_emotion_container.position = Vector2(0, -_head_height - 30.0)
	_emotion_container.scale = Vector2(0.2, 0.2)
	_emotion_container.modulate.a = 0.0
	_emotion_container.visible = true
	
	_emotion_tween = create_tween()
	# Pop in with overshoot bounce
	_emotion_tween.tween_property(_emotion_container, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_emotion_tween.parallel().tween_property(_emotion_container, "modulate:a", 1.0, 0.1)
	_emotion_tween.tween_property(_emotion_container, "scale", Vector2(1.0, 1.0), 0.1)
	# Hold for duration
	_emotion_tween.tween_interval(duration)
	# Fade out
	_emotion_tween.tween_property(_emotion_container, "modulate:a", 0.0, 0.3)
	_emotion_tween.finished.connect(func():
		if _quest_marker_type != "none":
			set_quest_marker(_quest_marker_type)
		else:
			_emotion_container.visible = false
	)

## Displays a styled overhead speech bubble above the NPC's head
func show_speech_bubble(text: String, duration: float = 3.0) -> void:
	if text.is_empty():
		return
	if not _speech_bubble_panel:
		_speech_bubble_panel = PanelContainer.new()
		_speech_bubble_panel.name = "SpeechBubblePanel"
		_speech_bubble_panel.z_index = 20
		_speech_bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.08, 0.14, 0.88)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.95, 0.82, 0.35, 0.95)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		_speech_bubble_panel.add_theme_stylebox_override("panel", sb)
		_speech_bubble_label = Label.new()
		_speech_bubble_label.name = "SpeechBubbleLabel"
		_speech_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_speech_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_speech_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_speech_bubble_label.custom_minimum_size = Vector2(140, 20)
		_speech_bubble_label.add_theme_font_size_override("font_size", 11)
		_speech_bubble_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9, 1.0))
		_speech_bubble_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		_speech_bubble_label.add_theme_constant_override("outline_size", 2)
		_speech_bubble_panel.add_child(_speech_bubble_label)
		add_child(_speech_bubble_panel)

	var clean_text: String = text.strip_edges()
	if clean_text.length() > 70:
		clean_text = clean_text.substr(0, 67) + "..."
	_speech_bubble_label.text = clean_text
	_speech_bubble_panel.reset_size()
	var w: float = clampf(_speech_bubble_panel.size.x, 140.0, 220.0)
	var h: float = maxf(_speech_bubble_panel.size.y, 28.0)
	_speech_bubble_panel.size = Vector2(w, h)
	_speech_bubble_panel.position = Vector2(-w * 0.5, -_head_height - h - 26.0)
	_speech_bubble_panel.modulate.a = 1.0
	_speech_bubble_panel.visible = true

	if _speech_bubble_tween and _speech_bubble_tween.is_valid():
		_speech_bubble_tween.kill()
	_speech_bubble_tween = create_tween()
	_speech_bubble_tween.tween_interval(duration)
	_speech_bubble_tween.tween_property(_speech_bubble_panel, "modulate:a", 0.0, 0.35)
	_speech_bubble_tween.finished.connect(func():
		if _speech_bubble_panel:
			_speech_bubble_panel.visible = false
	)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not visible or is_hidden_by_preevent:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	show_emotion("dots", 1.2)
	npc_interacted.emit(self)

func _draw() -> void:
	if npc_id in [10000, 18000, 18001] or model_jmp.to_lower() in ["1170.jmp", "1088.jmp", "1089.jmp"]:
		return
	# Subtle 2:1 axonometric circular drop shadow under NPC feet
	var shadow_col := Color(0, 0, 0, 0.35)
	_draw_iso_ellipse(Vector2(0, 0), 14.0, 7.0, shadow_col)

func _draw_iso_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	const SEGMENTS := 16
	for i in range(SEGMENTS):
		var theta := float(i) * (TAU / float(SEGMENTS))
		pts.append(center + Vector2(cos(theta) * rx, sin(theta) * ry))
	draw_colored_polygon(pts, col)
