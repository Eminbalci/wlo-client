class_name PlayerEntity
extends Node2D

## 2:1 Axonometric Player Entity for Wonderland Online.
## Supports keyboard walking, click-to-move pathing, 8-directional kinematics,
## and in-memory sprite streaming from 002.jma / JRole.JMg.

signal position_updated(world_pos: Vector2)
signal heading_changed(heading: int)
signal equipment_changed(equip_layers: Dictionary)
signal movement_blocked(reason: String, target_pos: Vector2)
signal vehicle_changed(vehicle_type: VehicleType)
signal pet_mounted(pet_data: Dictionary)
signal pet_dismounted
signal wakeup_completed
signal motion_state_changed(new_state: MotionState)
signal stats_changed(stat_dict: Dictionary)

enum MotionState {
	WALK,
	IDLE,
	SIT,
	ATTACK,
	DEFEND,
	PRONE,
	VICTORY
}

enum VehicleType {
	NONE = 0,
	RAFT = 1,
	BOAT = 2,
	SHIP = 3,
	PLANE = 4
}

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const MapData = preload("res://scripts/map/map_data.gd")
const Pathfinder = preload("res://scripts/map/pathfinder.gd")
const RideData = preload("res://scripts/world/ride_data.gd")

@export var character_name: String = "Daniel":
	set(val):
		character_name = val
		if _nameplate or has_node("Nameplate"):
			nameplate.text = val
		_emit_stats_changed()
@export var role_id: int = 6:
	set(val):
		role_id = val
		_emit_stats_changed()
@export var move_speed: float = 120.0
@export var step_size: float = 14.0
@export var is_movement_locked: bool = false
@export var motion_state: MotionState = MotionState.IDLE:
	set(val):
		if motion_state == val:
			return
		motion_state = val
		_anim_frame_timer = 0.0
		if motion_state == MotionState.PRONE:
			if not is_prone:
				is_prone = true
			is_movement_locked = true
			_display_prone_frame()
		elif is_prone and motion_state != MotionState.PRONE:
			is_prone = false
			is_movement_locked = false
		motion_state_changed.emit(motion_state)
		queue_redraw()

@export var is_prone: bool = false:
	set(val):
		is_prone = val
		if is_prone:
			if motion_state != MotionState.PRONE:
				motion_state = MotionState.PRONE
			is_movement_locked = true
			_display_prone_frame()
		else:
			if motion_state == MotionState.PRONE:
				motion_state = MotionState.IDLE
			is_movement_locked = false
		queue_redraw()

var _awakening_frames: Array[ImageTexture] = []
var _is_animating_wakeup: bool = false:
	set(val):
		_is_animating_wakeup = val
		queue_redraw()

@export var current_vehicle: VehicleType = VehicleType.NONE:
	set(val):
		current_vehicle = val
		_pathfinder = null
		queue_redraw()
var map_data: MapData = null:
	set(val):
		map_data = val
		_pathfinder = null

@export var level: int = 10:
	set(val):
		level = val
		_emit_stats_changed()

@export var hp: int = 245:
	set(val):
		hp = val
		_emit_stats_changed()

@export var max_hp: int = 245:
	set(val):
		max_hp = val
		_emit_stats_changed()

@export var sp: int = 180:
	set(val):
		sp = val
		_emit_stats_changed()

@export var max_sp: int = 180:
	set(val):
		max_sp = val
		_emit_stats_changed()

@export var exp_percent: float = 45.0:
	set(val):
		exp_percent = val
		_emit_stats_changed()

func _emit_stats_changed() -> void:
	stats_changed.emit({
		"name": character_name,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"sp": sp,
		"max_sp": max_sp,
		"exp_percent": exp_percent,
		"role_id": role_id
	})

@export var world_position: Vector2 = Vector2(1042.0, 1075.0):
	set(val):
		world_position = val
		if is_inside_tree():
			_update_screen_position()
			position_updated.emit(world_position)
@export var current_heading: int = IsometricMath.Heading.SOUTH_WEST

var world_pos: Vector2:
	get:
		return world_position
	set(val):
		world_position = val

## Instantly relocates player to new_pos, resetting current movement target
func teleport_to(new_pos: Vector2) -> void:
	world_position = new_pos
	target_world_position = new_pos
	is_moving = false
	_current_waypoints.clear()
	if is_inside_tree():
		_update_screen_position()
		position_updated.emit(world_position)

var heading: int:
	get:
		return current_heading
	set(val):
		current_heading = val

var target_world_position: Vector2 = Vector2(1042.0, 1075.0)
var is_moving: bool = false
var _was_moving: bool = false
var _pathfinder: Pathfinder = null
var _current_waypoints: Array[Vector2] = []

var _composite_frames: Array[ImageTexture] = []
var equip_layers: Dictionary = {}
var _anim_data = null
var _anim_frame_timer: float = 0.0
var _anim_frame_index: int = 0
var _role_texture: ImageTexture = null

var _sprite: Sprite2D = null
var sprite: Sprite2D:
	get:
		if not _sprite and has_node("Sprite2D"):
			_sprite = get_node("Sprite2D")
		elif not _sprite:
			_sprite = Sprite2D.new()
			_sprite.name = "Sprite2D"
			_sprite.offset = Vector2(0, -41.0)
			add_child(_sprite)
		return _sprite
	set(val):
		_sprite = val

var _nameplate: Label = null
var nameplate: Label:
	get:
		if not _nameplate and has_node("Nameplate"):
			_nameplate = get_node("Nameplate")
		elif not _nameplate:
			_nameplate = Label.new()
			_nameplate.name = "Nameplate"
			_nameplate.offset_bottom = -88.0
			_nameplate.offset_top = -108.0
			add_child(_nameplate)
		return _nameplate
	set(val):
		_nameplate = val

func _ready() -> void:
	add_to_group("player")
	if nameplate:
		nameplate.text = character_name
	_load_player_art()
	_update_screen_position()

var archive_loader: Node = null

func _get_archive_loader() -> Node:
	if archive_loader:
		return archive_loader
	var r: Window = null
	if is_inside_tree() and get_tree():
		r = get_tree().root
	elif Engine.get_main_loop() is SceneTree:
		r = (Engine.get_main_loop() as SceneTree).root
	if r:
		var l = r.get_node_or_null("ArchiveLoader")
		if l:
			return l
		for c in r.get_children():
			if c.has_method("get_player_composite_frames"):
				return c
	return null

func _load_player_art() -> void:
	var loader := _get_archive_loader()
	if not loader:
		return
	
	if equip_layers.is_empty():
		var game_db = null
		if is_inside_tree():
			game_db = get_node_or_null("/root/GameDatabase")
		elif Engine.get_main_loop() is SceneTree:
			var st = Engine.get_main_loop() as SceneTree
			if st and st.root:
				game_db = st.root.get_node_or_null("GameDatabase")
		var r_data: Dictionary = game_db.get_role(role_id) if (game_db and game_db.has_method("get_role")) else {}
		var b_low := str(r_data.get("body_archive", "004.jma" if role_id == 6 else "003.jma")).to_lower()
		var w_prefix := "004" if b_low.contains("004") else ("003" if b_low.contains("003") else ("002" if b_low.contains("002") else "005"))
		equip_layers = {
			"clothes": {"jma": r_data.get("default_clothes_archive", w_prefix + "e.jma"), "jmp": r_data.get("default_clothes_jmp", w_prefix.substr(2, 1) + "300.jmp")},
			"shoes": {"jma": r_data.get("default_shoes_archive", w_prefix + "s.jma"), "jmp": r_data.get("default_shoes_jmp", w_prefix.substr(2, 1) + "400.jmp")},
			"weapon": {"jma": w_prefix + "w.jma", "jmp": w_prefix.substr(2, 1) + "040.jmp"}
		}
	
	# 1. Paper-doll composite frames (64 frames: 32 walk + 32 stand)
	_composite_frames = loader.get_player_composite_frames(role_id, equip_layers)
	if not _composite_frames.is_empty():
		var initial_frame_idx: int = 32 + current_heading * 4
		if initial_frame_idx >= _composite_frames.size():
			initial_frame_idx = 0
		_apply_texture(_composite_frames[initial_frame_idx])
		return
	
	# 2. Fallback: single JMA body animation
	var game_db_fb = null
	if is_inside_tree():
		game_db_fb = get_node_or_null("/root/GameDatabase")
	elif Engine.get_main_loop() is SceneTree:
		var st = Engine.get_main_loop() as SceneTree
		if st and st.root:
			game_db_fb = st.root.get_node_or_null("GameDatabase")
	var fallback_jma := "004.jma" if role_id == 6 else ("003.jma" if role_id == 2 else "002.jma")
	var fallback_jmp := "4000.jmp" if role_id == 6 else ("3000.jmp" if role_id == 2 else "2000.jmp")
	if game_db_fb and game_db_fb.has_method("get_role"):
		var r_data: Dictionary = game_db_fb.get_role(role_id)
		fallback_jma = str(r_data.get("body_archive", fallback_jma))
		fallback_jmp = str(r_data.get("body_jmp", fallback_jmp))
	_anim_data = loader.get_jma_animation(fallback_jma, fallback_jmp)
	if _anim_data:
		var frame0: ImageTexture = _anim_data.decode_frame(0)
		if frame0:
			_apply_texture(frame0)
			return
	
	# 3. Fallback: JRole sprite sheet
	_role_texture = loader.get_role_sprite_sheet(role_id, 0)
	if _role_texture:
		_apply_texture(_role_texture)

## Dynamically sets character role (1..14), updates name and art
func set_role(new_role_id: int) -> void:
	role_id = new_role_id
	var game_db = null
	if is_inside_tree():
		game_db = get_node_or_null("/root/GameDatabase")
	elif Engine.get_main_loop() is SceneTree:
		var st = Engine.get_main_loop() as SceneTree
		if st and st.root:
			game_db = st.root.get_node_or_null("GameDatabase")
	if game_db and game_db.has_method("get_role"):
		var r_data: Dictionary = game_db.get_role(role_id)
		character_name = str(r_data.get("name", character_name))
		if not nameplate:
			nameplate = get_node_or_null("Nameplate")
		if nameplate:
			nameplate.text = character_name
	_reload_composite_frames()

## Sets or updates equipment layers dictionary (e.g. {"cap": "002c.jma:2200.jmp", "clothes": "002e.jma:2320.jmp"})
func set_equipment(layers: Dictionary) -> void:
	if equip_layers == layers:
		return
	equip_layers = layers.duplicate()
	_reload_composite_frames()
	equipment_changed.emit(equip_layers)

func _draw() -> void:
	if not is_prone and not _is_animating_wakeup and current_vehicle == VehicleType.NONE:
		# Subtle soft translucent oval drop shadow below feet (radius 14 x 7)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2(0, -1), 14.0, Color(0.0, 0.0, 0.0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Equips an item into a layer (e.g. "cap", "clothes", "shoes", "weapon")
func equip_item(slot_name: String, item_data = null) -> void:
	if item_data == null or (item_data is String and item_data.is_empty()):
		equip_layers.erase(slot_name)
	else:
		equip_layers[slot_name] = item_data
	_reload_composite_frames()
	equipment_changed.emit(equip_layers)

## Unequips a layer
func unequip_item(slot_name: String) -> void:
	if not equip_layers.has(slot_name):
		return
	equip_layers.erase(slot_name)
	_reload_composite_frames()
	equipment_changed.emit(equip_layers)

## Returns current equipment layers
func get_equipment() -> Dictionary:
	return equip_layers.duplicate()

## Rebuilds/fetches composite frames and updates sprite immediately
func _reload_composite_frames() -> void:
	var loader := _get_archive_loader()
	if not loader:
		return
	_composite_frames = loader.get_player_composite_frames(role_id, equip_layers)
	if not _composite_frames.is_empty():
		_update_animation(0.0)

## Returns authentic prone frame index from 216-frame composite or 4000.jmp
func get_prone_frame_index() -> int:
	if _composite_frames.size() > 105:
		return 105
	elif _composite_frames.size() > 176 + (current_heading % 8):
		return 176 + (current_heading % 8)
	elif _composite_frames.size() > 54:
		return 54
	return 0

func _display_prone_frame() -> void:
	if not _composite_frames.is_empty():
		var idx := get_prone_frame_index()
		if idx < _composite_frames.size():
			_apply_texture(_composite_frames[idx])
			return
	if not _awakening_frames.is_empty():
		_apply_texture(_awakening_frames[0])
		return
	var loader := _get_archive_loader()
	if loader and loader.has_method("get_player_awakening_composite_frames"):
		_awakening_frames = loader.get_player_awakening_composite_frames(role_id, equip_layers)
		if not _awakening_frames.is_empty():
			_apply_texture(_awakening_frames[0])

## Plays the authentic sitting / resting animation cycle (frames 64..95)
func play_sit_animation() -> void:
	is_moving = false
	_current_waypoints.clear()
	motion_state = MotionState.SIT
	_anim_frame_timer = 0.0
	_update_animation(0.0)

## Plays the authentic standing / idle breathing animation cycle (frames 32..63)
func play_stand_animation() -> void:
	is_prone = false
	is_movement_locked = false
	motion_state = MotionState.IDLE
	_anim_frame_timer = 0.0
	_update_animation(0.0)

## Toggles between sitting and standing states
func toggle_sit_stand() -> void:
	if is_movement_locked or is_prone or _is_animating_wakeup or motion_state == MotionState.PRONE:
		return
	if motion_state == MotionState.SIT:
		play_stand_animation()
	else:
		play_sit_animation()

## Plays the authentic combat attack / weapon strike animation cycle (frames 96..143)
func play_attack_animation() -> void:
	is_moving = false
	_current_waypoints.clear()
	is_movement_locked = true
	motion_state = MotionState.ATTACK
	_anim_frame_timer = 0.0
	_update_animation(0.0)

## Plays the authentic hurt / defend recoil animation cycle (frames 144..175)
func play_hurt_animation() -> void:
	is_moving = false
	_current_waypoints.clear()
	is_movement_locked = true
	motion_state = MotionState.DEFEND
	_anim_frame_timer = 0.0
	_update_animation(0.0)

## Plays the authentic victory cheer / emote animation cycle (frames 200..215)
func play_victory_animation() -> void:
	is_moving = false
	_current_waypoints.clear()
	is_movement_locked = true
	motion_state = MotionState.VICTORY
	_anim_frame_timer = 0.0
	_update_animation(0.0)

func _apply_texture(tex: Texture2D) -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not sprite or not tex:
		return
	sprite.texture = tex
	var h := float(tex.get_height())
	if int(h) == 128:
		sprite.offset = Vector2(0, -41.0)
	else:
		sprite.offset = Vector2(0, -roundf(h * 0.32)) if h > 0 else Vector2(0, -41.0)
	if not nameplate:
		nameplate = get_node_or_null("Nameplate")
	if nameplate:
		nameplate.offset_bottom = -88.0
		nameplate.offset_top = -108.0

func _process(delta: float) -> void:
	_handle_input(delta)
	_update_movement(delta)
	_update_animation(delta)

func _handle_input(_delta: float) -> void:
	if is_movement_locked or is_prone or _is_animating_wakeup or motion_state in [MotionState.PRONE, MotionState.ATTACK, MotionState.DEFEND, MotionState.VICTORY]:
		return
	var walk_dx: float = 0.0
	var walk_dy: float = 0.0
	
	if Input.is_key_pressed(KEY_LEFT):
		walk_dx -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		walk_dx += 1.0
	if Input.is_key_pressed(KEY_UP):
		walk_dy -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		walk_dy += 1.0
	
	if walk_dx != 0.0 or walk_dy != 0.0:
		if motion_state == MotionState.SIT:
			play_stand_animation()
		var dir := Vector2(walk_dx, walk_dy).normalized()
		set_target_world_position(world_position + dir * step_size)

func mount_vehicle(vtype: VehicleType) -> void:
	current_vehicle = vtype
	vehicle_changed.emit(current_vehicle)

func dismount_vehicle() -> void:
	current_vehicle = VehicleType.NONE
	vehicle_changed.emit(current_vehicle)

func is_mounted() -> bool:
	return current_vehicle != VehicleType.NONE

func set_target_world_position(new_target: Vector2, allow_fallback: bool = true) -> bool:
	if is_movement_locked or is_prone or _is_animating_wakeup or motion_state in [MotionState.PRONE, MotionState.ATTACK, MotionState.DEFEND, MotionState.VICTORY]:
		is_moving = false
		_current_waypoints.clear()
		movement_blocked.emit("Movement is locked during action animation...", new_target)
		return false
	if motion_state == MotionState.SIT:
		play_stand_animation()
	if map_data:
		var grid_pos: Vector2i = MapData.world_to_grid(new_target)
		var flag: int = map_data.get_collision_byte(grid_pos.x, grid_pos.y)
		var check: Dictionary = MapData.check_traversal(flag, current_vehicle)
		
		# If fallback is explicitly disabled, strictly enforce direct target traversability
		if not allow_fallback and not check["allowed"]:
			is_moving = false
			_current_waypoints.clear()
			movement_blocked.emit(check["reason"], new_target)
			return false

		if _pathfinder == null or _pathfinder.map_data != map_data:
			_pathfinder = Pathfinder.new(map_data)
		var path: Array[Vector2] = _pathfinder.find_path(world_position, new_target, current_vehicle, allow_fallback)
		if path.is_empty():
			var reason: String = check["reason"] if not check["allowed"] else "Path is blocked by an obstacle."
			is_moving = false
			_current_waypoints.clear()
			movement_blocked.emit(reason, new_target)
			return false
		else:
			_current_waypoints = path
			target_world_position = _current_waypoints[0]
			is_moving = true
			current_heading = IsometricMath.get_heading(world_position, target_world_position)
			heading_changed.emit(current_heading)
			return true
	else:
		target_world_position = new_target
		var diff := target_world_position - world_position
		if diff.length() > 2.0:
			_current_waypoints = [target_world_position]
			current_heading = IsometricMath.get_heading(world_position, target_world_position)
			heading_changed.emit(current_heading)
			is_moving = true
		else:
			_current_waypoints.clear()
			is_moving = false
			return false
		return true
		return true

func move_to_world_pos(new_target: Vector2) -> bool:
	return set_target_world_position(new_target)

func move_to_screen_pos(screen_pos: Vector2) -> bool:
	return set_target_world_position(screen_pos)

func _update_movement(delta: float) -> void:
	if not is_moving:
		return
	
	var step: float = move_speed * delta
	var dist: float = world_position.distance_to(target_world_position)
	if dist <= step:
		world_position = target_world_position
		if not _current_waypoints.is_empty():
			_current_waypoints.pop_front()
		if _current_waypoints.is_empty():
			is_moving = false
		else:
			target_world_position = _current_waypoints[0]
			current_heading = IsometricMath.get_heading(world_position, target_world_position)
			heading_changed.emit(current_heading)
	else:
		world_position = world_position.move_toward(target_world_position, step)
	
	_update_screen_position()
	position_updated.emit(world_position)

func _update_screen_position() -> void:
	position = world_position
	z_index = clampi(int(world_position.y), -4096, 4096)

func _update_animation(delta: float) -> void:
	if _is_animating_wakeup:
		return
	# All 8 directions are natively modeled in WLO JMP sprites. No horizontal flip required.
	if sprite:
		sprite.flip_h = false
	
	if is_prone or motion_state == MotionState.PRONE:
		_display_prone_frame()
		return
	
	if is_moving != _was_moving:
		_anim_frame_timer = 0.0
		_was_moving = is_moving
		if is_moving:
			if motion_state != MotionState.PRONE:
				motion_state = MotionState.WALK
		else:
			if motion_state == MotionState.WALK:
				motion_state = MotionState.IDLE
	
	_anim_frame_timer += delta
	
	var frame_idx: int = 0
	var h: int = current_heading % 8
	
	match motion_state:
		MotionState.WALK:
			# Frames 0..31: 8 headings x 4 frames
			var sub_idx: int = int(_anim_frame_timer * 8.0) % 4
			frame_idx = h * 4 + sub_idx
		MotionState.IDLE:
			# Frames 32..63: 8 headings x 4 frames
			var sub_idx: int = int(_anim_frame_timer * 2.5) % 4
			frame_idx = 32 + h * 4 + sub_idx
		MotionState.SIT:
			# Frames 64..95: 8 headings x 4 frames
			var sub_idx: int = int(_anim_frame_timer * 2.5) % 4
			frame_idx = 64 + h * 4 + sub_idx
		MotionState.ATTACK:
			# Frames 96..143: 8 headings x 4 frames (112..143 weapon/melee strike)
			var sub_idx: int = int(_anim_frame_timer * 8.0)
			if sub_idx >= 4:
				motion_state = MotionState.IDLE
				is_movement_locked = false
				_anim_frame_timer = 0.0
				sub_idx = 0
			frame_idx = 112 + h * 4 + (sub_idx % 4)
		MotionState.DEFEND:
			# Frames 144..175: 8 headings x 4 frames
			var sub_idx: int = int(_anim_frame_timer * 6.0)
			if sub_idx >= 4:
				motion_state = MotionState.IDLE
				is_movement_locked = false
				_anim_frame_timer = 0.0
				sub_idx = 0
			frame_idx = 144 + h * 4 + (sub_idx % 4)
		MotionState.VICTORY:
			# Frames 200..215: 8 headings x 2 frames
			var step_count: int = int(_anim_frame_timer * 4.0)
			if step_count >= 8:
				motion_state = MotionState.IDLE
				is_movement_locked = false
				_anim_frame_timer = 0.0
				step_count = 0
			frame_idx = 200 + h * 2 + (step_count % 2)
		MotionState.PRONE:
			frame_idx = get_prone_frame_index()
		_:
			frame_idx = 32 + h * 4
	
	if not _composite_frames.is_empty():
		if frame_idx < 0 or frame_idx >= _composite_frames.size():
			frame_idx = (32 + h * 4) % _composite_frames.size()
		_apply_texture(_composite_frames[frame_idx])
	elif _anim_data:
		if frame_idx >= _anim_data.frames.size():
			frame_idx = frame_idx % _anim_data.frames.size()
		var tex: ImageTexture = _anim_data.decode_frame(frame_idx)
		if tex:
			_apply_texture(tex)

## Sets the player in or out of prone state
func set_prone(prone: bool) -> void:
	is_prone = prone
	is_movement_locked = prone
	queue_redraw()
	if prone:
		motion_state = MotionState.PRONE
		is_moving = false
		_current_waypoints.clear()
		_display_prone_frame()
	else:
		if motion_state == MotionState.PRONE:
			motion_state = MotionState.IDLE
		_reload_composite_frames()

## Plays the authentic prone-to-standing wake-up sequence
func play_wakeup_animation(duration: float = 2.0, on_complete: Callable = Callable()) -> void:
	is_prone = true
	is_movement_locked = true
	_is_animating_wakeup = true
	motion_state = MotionState.PRONE
	is_moving = false
	_current_waypoints.clear()
	
	var loader := _get_archive_loader()
	if loader and loader.has_method("get_player_awakening_composite_frames"):
		_awakening_frames = loader.get_player_awakening_composite_frames(role_id, equip_layers)
	
	var prone_tex: Texture2D = null
	var rise_tex: Texture2D = null
	var stand_tex: Texture2D = null
	
	if _awakening_frames.size() >= 3:
		prone_tex = _awakening_frames[0] # Frame 0: Prone (26-2.bmp)
		rise_tex = _awakening_frames[1] # Frame 1: Rising (26-1.bmp)
		stand_tex = _awakening_frames[2] # Frame 2: Stand (08-1.bmp)
	elif _composite_frames.size() >= 216:
		prone_tex = _composite_frames[105]
		rise_tex = _composite_frames[104]
		stand_tex = _composite_frames[32 + (current_heading % 8) * 4]
	
	if prone_tex and rise_tex and stand_tex:
		_apply_texture(prone_tex)
		var tween := create_tween()
		var step_dur: float = maxf(0.5, duration * 0.5)
		# Step 1: Rise to kneeling / halfway up (26-1.bmp)
		tween.tween_interval(step_dur)
		tween.tween_callback(func(): _apply_texture(rise_tex))
		# Step 2: Stand upright (08-1.bmp)
		tween.tween_interval(step_dur)
		tween.tween_callback(func():
			_apply_texture(stand_tex)
			is_prone = false
			_is_animating_wakeup = false
			motion_state = MotionState.IDLE
			_reload_composite_frames()
			wakeup_completed.emit()
			if on_complete.is_valid():
				on_complete.call()
		)
	else:
		# Fallback if frames not yet decoded
		is_prone = false
		_is_animating_wakeup = false
		motion_state = MotionState.IDLE
		_reload_composite_frames()
		wakeup_completed.emit()
		if on_complete.is_valid():
			on_complete.call()

# ==============================================================================
# Overhead Speech & Emoticon Bubble System
# ==============================================================================

var _speech_bubble_container: Control = null
var _speech_bubble_label: Label = null
var _speech_bubble_icon: TextureRect = null
var _speech_bubble_tween: Tween = null

func _ensure_speech_bubble() -> void:
	if _speech_bubble_container and is_instance_valid(_speech_bubble_container):
		return
	
	_speech_bubble_container = PanelContainer.new()
	_speech_bubble_container.name = "SpeechBubble"
	_speech_bubble_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech_bubble_container.z_index = 60
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 0.95, 0.95)
	sb.border_color = Color(0.2, 0.2, 0.25, 0.95)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 4.0
	_speech_bubble_container.add_theme_stylebox_override("panel", sb)
	
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech_bubble_container.add_child(hbox)
	
	_speech_bubble_icon = TextureRect.new()
	_speech_bubble_icon.name = "EmoteIcon"
	_speech_bubble_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech_bubble_icon.custom_minimum_size = Vector2(20, 20)
	_speech_bubble_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_speech_bubble_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_speech_bubble_icon.visible = false
	hbox.add_child(_speech_bubble_icon)
	
	_speech_bubble_label = Label.new()
	_speech_bubble_label.name = "SpeechLabel"
	_speech_bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speech_bubble_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.18, 1.0))
	_speech_bubble_label.add_theme_font_size_override("font_size", 12)
	_speech_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech_bubble_label.custom_minimum_size = Vector2(0, 16)
	hbox.add_child(_speech_bubble_label)
	
	_speech_bubble_container.position = Vector2(-36, -132)
	_speech_bubble_container.visible = false
	add_child(_speech_bubble_container)

## Displays an authentic overhead speech or emoticon bubble above the player
func show_speech_bubble(text_or_code: String, duration: float = 3.0) -> void:
	_ensure_speech_bubble()
	if not _speech_bubble_container:
		return
	
	if _speech_bubble_tween and _speech_bubble_tween.is_valid():
		_speech_bubble_tween.kill()
	
	var clean := text_or_code.strip_edges()
	var is_emote := false
	var emote_id := 0
	
	var regex := RegEx.new()
	regex.compile("#(\\d{1,2})")
	var regex_match = regex.search(clean)
	if regex_match:
		emote_id = clampi(int(regex_match.get_string(1)), 1, 31)
		is_emote = true
	
	if is_emote and emote_id > 0:
		_speech_bubble_label.visible = false
		_speech_bubble_icon.visible = true
		var emote_path := "res://assets/hud/icon_expre_%d.png" % emote_id
		if ResourceLoader.exists(emote_path):
			var tex: Texture2D = load(emote_path)
			if tex:
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(0, 0, 16, 16)
				_speech_bubble_icon.texture = atlas
	else:
		_speech_bubble_icon.visible = false
		_speech_bubble_label.visible = true
		_speech_bubble_label.text = clean
	
	_speech_bubble_container.visible = true
	_speech_bubble_container.scale = Vector2(0.2, 0.2)
	_speech_bubble_container.modulate.a = 0.0
	
	_speech_bubble_tween = create_tween()
	_speech_bubble_tween.tween_property(_speech_bubble_container, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_speech_bubble_tween.parallel().tween_property(_speech_bubble_container, "modulate:a", 1.0, 0.15)
	_speech_bubble_tween.tween_interval(duration)
	_speech_bubble_tween.tween_property(_speech_bubble_container, "modulate:a", 0.0, 0.3)
	_speech_bubble_tween.tween_callback(func():
		_speech_bubble_container.visible = false
	)

## Displays an authentic overhead emoticon bubble by index (1..31)
func show_emote_bubble(emote_id: Variant, duration: float = 3.0) -> void:
	var code := ""
	if emote_id is int:
		code = "#%02d" % emote_id
	else:
		code = str(emote_id)
	show_speech_bubble(code, duration)

