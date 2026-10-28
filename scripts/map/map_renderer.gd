class_name MapRenderer
extends Node2D

## Handles rendering of the 2D isometric world, background artwork from map.JMG,
## authentic HUD overlay, and entity coordinate management.

const MapData = preload("res://scripts/map/map_data.gd")
const IsometricMath = preload("res://scripts/map/isometric_math.gd")

signal map_loaded(map_id: int)
signal tile_clicked(world_coord: Vector2)

@export var current_map_id: int = 10001 # Default: Ship Deck
@export var archive_loader: Node = null

var current_map_name: String = "Ship Deck"
var _background_sprite: Sprite2D
var _map_data = null
var background_size: Vector2 = Vector2.ZERO
static var _cached_fallback_texture: ImageTexture = null

static func _get_fallback_dungeon_texture() -> ImageTexture:
	if _cached_fallback_texture:
		return _cached_fallback_texture
	
	var tile_w: int = 64
	var tile_h: int = 32
	var tile := Image.create(tile_w, tile_h, false, Image.FORMAT_RGBA8)
	tile.fill(Color(0.12, 0.13, 0.16, 1.0))
	for x in range(tile_w):
		tile.set_pixel(x, 0, Color(0.17, 0.19, 0.23, 1.0))
		tile.set_pixel(x, tile_h - 1, Color(0.08, 0.09, 0.11, 1.0))
	for y in range(tile_h):
		tile.set_pixel(0, y, Color(0.17, 0.19, 0.23, 1.0))
		tile.set_pixel(tile_w - 1, y, Color(0.08, 0.09, 0.11, 1.0))
	
	var full_w: int = 3200
	var full_h: int = 2800
	var full := Image.create(full_w, full_h, false, Image.FORMAT_RGBA8)
	for y in range(0, full_h, tile_h):
		for x in range(0, full_w, tile_w):
			full.blit_rect(tile, Rect2i(0, 0, tile_w, tile_h), Vector2i(x, y))
	
	_cached_fallback_texture = ImageTexture.create_from_image(full)
	return _cached_fallback_texture

@onready var hud: Control = get_node_or_null("../CanvasLayer/HUD")

# Backward compatibility accessors for HUD rects
var minimap_rect: TextureRect:
	get:
		return hud.minimap_bg if hud else null
var status_bar_rect: TextureRect:
	get:
		return hud.status_bg if hud else null
var chat_bar_rect: TextureRect:
	get:
		return hud.chat_input_bg if hud else null

func get_map_texture() -> Texture2D:
	return _background_sprite.texture if _background_sprite else null

func get_map_pixel_size() -> Vector2:
	if _background_sprite and _background_sprite.texture:
		return _background_sprite.texture.get_size()
	return background_size

## Finds associated Camera2D in parent or viewport
func get_camera() -> Camera2D:
	if has_node("../Camera2D"):
		return get_node("../Camera2D") as Camera2D
	if get_parent() and get_parent().has_node("Camera2D"):
		return get_parent().get_node("Camera2D") as Camera2D
	if is_inside_tree() and get_viewport():
		return get_viewport().get_camera_2d()
	return null

func _get_archive_loader() -> Node:
	if archive_loader and is_instance_valid(archive_loader):
		return archive_loader
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		if loop.root.has_node("ArchiveLoader"):
			return loop.root.get_node("ArchiveLoader")
	if is_inside_tree() and has_node("/root/ArchiveLoader"):
		return get_node("/root/ArchiveLoader")
	var al_script = load("res://scripts/core/archive_loader.gd")
	if al_script:
		archive_loader = al_script.new()
		if archive_loader.has_method("initialize_archives"):
			archive_loader.initialize_archives()
		if loop is SceneTree and loop.root:
			loop.root.add_child(archive_loader)
		return archive_loader
	return null

func _get_game_database() -> Node:
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		if loop.root.has_node("GameDatabase"):
			return loop.root.get_node("GameDatabase")
	if is_inside_tree():
		return get_node_or_null("/root/GameDatabase")
	return null

## Updates camera limits and clamps based on map background dimensions
func update_camera_limits(cam: Camera2D = null) -> void:
	if not cam:
		cam = get_camera()
	if not cam:
		return
	
	var map_size: Vector2 = get_map_pixel_size()
	if map_size == Vector2.ZERO:
		return
	
	var vp_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(800, 600)
	if map_size.x < vp_size.x:
		var extra_x: float = (vp_size.x - map_size.x) * 0.5
		cam.limit_left = int(-extra_x)
		cam.limit_right = int(map_size.x + extra_x)
	else:
		cam.limit_left = 0
		cam.limit_right = int(map_size.x)
	
	if map_size.y < vp_size.y:
		var extra_y: float = (vp_size.y - map_size.y) * 0.5
		cam.limit_top = int(-extra_y)
		cam.limit_bottom = int(map_size.y + extra_y)
	else:
		cam.limit_top = 0
		cam.limit_bottom = int(map_size.y)

func _ready() -> void:
	_setup_nodes()
	if is_inside_tree():
		var vp := get_viewport()
		if vp and not vp.size_changed.is_connected(update_camera_limits):
			vp.size_changed.connect(update_camera_limits)
	load_map(current_map_id)

func _setup_nodes() -> void:
	if _background_sprite == null or not is_instance_valid(_background_sprite):
		_background_sprite = get_node_or_null("BackgroundLayer") as Sprite2D
		if _background_sprite == null:
			_background_sprite = Sprite2D.new()
			_background_sprite.name = "BackgroundLayer"
			_background_sprite.centered = false
			add_child(_background_sprite)

func load_map(p_map_id: int) -> void:
	current_map_id = p_map_id
	_is_mouse_held = false
	if _background_sprite == null or not is_instance_valid(_background_sprite):
		_setup_nodes()
	
	# 1. Fetch background texture directly from in-memory archive using authentic scene_id from EveParser
	var bg_texture: ImageTexture = null
	var loader_node = _get_archive_loader()
	var ep = EveParser.new()
	var sid = ep.get_scene_id(current_map_id)
	if loader_node and loader_node.has_method("get_map_background"):
		bg_texture = loader_node.get_map_background(sid)
		if not bg_texture and sid != current_map_id:
			bg_texture = loader_node.get_map_background(current_map_id)
	
	if not bg_texture:
		# Fallback to authentic procedural cavern/dungeon floor texture so dungeon/cave maps are fully textured and navigable
		bg_texture = _get_fallback_dungeon_texture()
	
	if bg_texture:
		if _background_sprite:
			_background_sprite.texture = bg_texture
		background_size = bg_texture.get_size()
	else:
		if _background_sprite:
			_background_sprite.texture = null
		background_size = Vector2.ZERO
	
	# Update camera limits for the loaded background size
	update_camera_limits()
	
	# Keep parent node's map_size in sync if present
	var parent_node := get_parent()
	if parent_node:
		if "map_size" in parent_node:
			parent_node.map_size = background_size
		if parent_node.has_method("update_camera_limits"):
			parent_node.update_camera_limits()
	
	# 2. Resolve authentic map name from GameDatabase or canonical mapping
	current_map_name = "Ship Deck"
	match current_map_id:
		10001: current_map_name = "Ship Deck"
		10002: current_map_name = "Cabin"
		10003: current_map_name = "Ship Kitchen / Bunk"
		_: current_map_name = "Map %d" % current_map_id
	var db = _get_game_database()
	if db and db.scenes:
		var scene_info = db.scenes.get_scene(current_map_id)
		if scene_info and not scene_info.name.is_empty():
			current_map_name = scene_info.name
	
	# 3. Update HUD with map name, minimap context and coordinates
	if hud:
		var loader = _get_archive_loader()
		var mm_tex: Texture2D = loader.get_minimap_texture(current_map_id) if loader else null
		var map_sz: Vector2 = bg_texture.get_size() if bg_texture else Vector2.ZERO
		if hud.has_method("set_map_context"):
			hud.set_map_context(current_map_id, current_map_name, map_sz, mm_tex)
		elif hud.has_method("update_minimap") and mm_tex:
			hud.update_minimap(mm_tex, Vector2(0.5, 0.5))
		if hud.has_method("set_map_info"):
			hud.set_map_info(current_map_name, 1542, 675)
	
	# 4. Load collision data if available
	var disk_id: int = MapData.get_disk_map_id(current_map_id)
	var map_path := "res://assets/user/Map/%d.MapData" % disk_id
	if not FileAccess.file_exists(map_path) and FileAccess.file_exists("D:/GitHub/WLRI/user/Map/%d.MapData" % disk_id):
		map_path = "D:/GitHub/WLRI/user/Map/%d.MapData" % disk_id
	_map_data = MapData.load_map(current_map_id, map_path)
	
	map_loaded.emit(current_map_id)

var _is_mouse_held: bool = false
var _last_click_world_pos: Vector2 = Vector2(-99999, -99999)

func _process(_delta: float) -> void:
	if _is_mouse_held:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var world_pos: Vector2 = get_global_mouse_position()
			if world_pos.distance_squared_to(_last_click_world_pos) >= 25.0:
				_last_click_world_pos = world_pos
				tile_clicked.emit(world_pos)
			if hud and hud.has_method("set_map_info"):
				hud.set_map_info(current_map_name, int(world_pos.x), int(world_pos.y))
		else:
			_is_mouse_held = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_mouse_held = true
			var world_pos: Vector2 = get_global_mouse_position()
			_last_click_world_pos = world_pos
			tile_clicked.emit(world_pos)
			if hud and hud.has_method("set_map_info"):
				hud.set_map_info(current_map_name, int(world_pos.x), int(world_pos.y))
		else:
			_is_mouse_held = false
	elif event is InputEventMouseMotion and _is_mouse_held:
		var world_pos: Vector2 = get_global_mouse_position()
		if world_pos.distance_squared_to(_last_click_world_pos) >= 25.0:
			_last_click_world_pos = world_pos
			tile_clicked.emit(world_pos)
		if hud and hud.has_method("set_map_info"):
			hud.set_map_info(current_map_name, int(world_pos.x), int(world_pos.y))
