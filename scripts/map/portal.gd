class_name Portal
extends Node2D

## 2:1 Axonometric Portal / Warp Gate for Wonderland Online.
## Supports two animation types via portal_type export:
##   0 = DoorLight  (Atlas_DoorLight.png,      13 frames, 81x157 each)
##   1 = SmallDoor  (Atlas_SmallDoorLight.png,  4 frames, 40x78  each)
## Both use additive CanvasItemMaterial blending (BLEND_MODE_ADD).
## Proximity / cell-arrival trigger with 0.5s spawn-grace cooldown.

signal portal_triggered(portal: Portal, target_map_id: int, target_coords: Vector2)

enum PortalType { DOOR_LIGHT = 0, SMALL_DOOR = 1 }

## Legacy integer constants so map_view.gd can reference Portal.STYLE_DOOR / STYLE_SMALL_DOOR
const STYLE_DOOR: int       = 0
const STYLE_SMALL_DOOR: int = 1

@export var portal_id: int = 1
@export var portal_name: String = "Ship Cabin Entrance"
@export var target_map_id: int = 10002
@export var target_coords: Vector2 = Vector2(674.0, 1067.0)
@export var trigger_radius: float = 56.0
@export var portal_color: Color = Color(0.2, 0.75, 1.0, 0.85)
@export var portal_type: PortalType = PortalType.DOOR_LIGHT

var _pulse_timer: float = 0.0
var _player_inside: bool = false
var _hovered: bool = false
var trigger_cooldown: float = 0.5 # 0.5s grace period on spawn to prevent instant retriggering

## Per-type static frame caches (shared across all Portal instances of the same type)
static var _doorlight_frames: Array[Texture2D] = []
static var _smalldoor_frames: Array[Texture2D] = []

var _doorlight_sprite: Sprite2D = null
var label: Label = null

# --- Atlas paths ---
const ATLAS_DOORLIGHT_MAP: String    = "res://assets/map/Atlas_DoorLight.png"
const ATLAS_DOORLIGHT_SPR: String    = "res://assets/sprites/doorlight/Atlas_DoorLight.png"
const ATLAS_SMALLDOOR_MAP: String    = "res://assets/map/Atlas_SmallDoorLight.png"
const ATLAS_SMALLDOOR_SPR: String    = "res://assets/sprites/doorlight/Atlas_SmallDoorLight.png"

# --- Frame rects ---
## DoorLight: 13 frames at 81x157 in a 512x512 atlas
const DOORLIGHT_FRAME_RECTS: Array[Rect2] = [
	Rect2(0,   355, 81, 157),
	Rect2(246, 197, 81, 157),
	Rect2(328, 355, 81, 157),
	Rect2(164, 355, 81, 157),
	Rect2(164, 197, 81, 157),
	Rect2(0,   197, 81, 157),
	Rect2(164,  39, 81, 157),
	Rect2(0,    39, 81, 157),
	Rect2(246,  39, 81, 157),
	Rect2(82,  197, 81, 157),
	Rect2(82,  355, 81, 157),
	Rect2(82,   39, 81, 157),
	Rect2(246, 355, 81, 157)
]

## SmallDoorLight: 4 frames at 40x78 in a 256x256 atlas
const SMALLDOOR_FRAME_RECTS: Array[Rect2] = [
	Rect2(0,  20, 40, 78),
	Rect2(0,  99, 40, 78),
	Rect2(0,  178, 40, 78),
	Rect2(41, 178, 40, 78)
]

# --- Static loaders ---
static func _load_doorlight_frames() -> void:
	if not _doorlight_frames.is_empty():
		return
	var atlas_tex: Texture2D = _try_load_atlas([ATLAS_DOORLIGHT_MAP, ATLAS_DOORLIGHT_SPR])
	if atlas_tex:
		for rect in DOORLIGHT_FRAME_RECTS:
			var at := AtlasTexture.new()
			at.atlas = atlas_tex
			at.region = rect
			_doorlight_frames.append(at)
		return
	# Individual-file fallback
	for i in range(13):
		var path := "res://assets/sprites/doorlight/doorlight_%02d.png" % i
		var tex := _try_load_texture(path)
		if tex:
			_doorlight_frames.append(tex)

static func _load_smalldoor_frames() -> void:
	if not _smalldoor_frames.is_empty():
		return
	var atlas_tex: Texture2D = _try_load_atlas([ATLAS_SMALLDOOR_MAP, ATLAS_SMALLDOOR_SPR])
	if atlas_tex:
		for rect in SMALLDOOR_FRAME_RECTS:
			var at := AtlasTexture.new()
			at.atlas = atlas_tex
			at.region = rect
			_smalldoor_frames.append(at)

static func _try_load_atlas(paths: Array) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			var t: Texture2D = load(p)
			if t:
				return t
		elif FileAccess.file_exists(p):
			var img := Image.load_from_file(ProjectSettings.globalize_path(p))
			if img:
				var t := ImageTexture.create_from_image(img)
				if t:
					return t
	return null

static func _try_load_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

## Returns the active frame list for this instance's portal_type.
func _active_frames() -> Array[Texture2D]:
	if portal_type == PortalType.SMALL_DOOR:
		return _smalldoor_frames
	return _doorlight_frames

func _init() -> void:
	_load_doorlight_frames()
	_load_smalldoor_frames()
	_setup_doorlight_sprite()
	_setup_label()

func _ready() -> void:
	z_index = int(position.y) - 5 # Render just below character feet
	_setup_doorlight_sprite()
	_setup_label()
	_suppress_spawn_trigger()

func _setup_doorlight_sprite() -> void:
	if not _doorlight_sprite:
		_doorlight_sprite = Sprite2D.new()
		_doorlight_sprite.name = "DoorLightSprite"
		_doorlight_sprite.centered = true
		# SmallDoor is ~half the height of DoorLight; adjust offset accordingly
		_doorlight_sprite.offset = Vector2(0, -22) if portal_type == PortalType.SMALL_DOOR else Vector2(0, -42)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_doorlight_sprite.material = mat
		add_child(_doorlight_sprite)
		var frames := _active_frames()
		if not frames.is_empty():
			_doorlight_sprite.texture = frames[0]

## Compatibility shim used by map_view.gd: accepts STYLE_DOOR (0) or STYLE_SMALL_DOOR (1).
func set_portal_style(style: int) -> void:
	portal_type = PortalType.SMALL_DOOR if style == STYLE_SMALL_DOOR else PortalType.DOOR_LIGHT
	if _doorlight_sprite:
		_doorlight_sprite.offset = Vector2(0, -22) if portal_type == PortalType.SMALL_DOOR else Vector2(0, -42)
		var frames := _active_frames()
		if not frames.is_empty():
			_doorlight_sprite.texture = frames[0]
	else:
		_setup_doorlight_sprite()

func _setup_label() -> void:
	if not label:
		label = Label.new()
		label.name = "Label"
		label.text = ""
		label.visible = false
		add_child(label)
	else:
		label.text = ""
		label.visible = false

func _suppress_spawn_trigger() -> void:
	var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if player and ("world_position" in player):
		var dx: float = (player.world_position.x - position.x)
		var dy: float = (player.world_position.y - position.y) * 2.0
		var player_cell := Vector2i(int(floor(player.world_position.x / 20.0)), int(floor(player.world_position.y / 20.0)))
		var portal_cell := Vector2i(int(floor(position.x / 20.0)), int(floor(position.y / 20.0)))
		if sqrt(dx * dx + dy * dy) <= trigger_radius + 20.0 or player_cell == portal_cell:
			_player_inside = true

func mark_player_inside() -> void:
	_player_inside = true

func _process(delta: float) -> void:
	_pulse_timer += delta
	var frames := _active_frames()
	if not frames.is_empty() and _doorlight_sprite:
		var fps: float = 3.5 if portal_type == PortalType.SMALL_DOOR else 8.0
		var frame_idx := int(_pulse_timer * fps) % frames.size()
		_doorlight_sprite.texture = frames[frame_idx]
		_doorlight_sprite.modulate = Color(portal_color.r, portal_color.g, portal_color.b, 0.95)

	if trigger_cooldown > 0.0:
		trigger_cooldown -= delta
		_suppress_spawn_trigger()
		return

	_check_player_proximity()

func _draw() -> void:
	# Ground circles removed per user request
	pass

func _draw_iso_ellipse(_center: Vector2, _rx: float, _ry: float, _col: Color, _width: float) -> void:
	pass

func _check_player_proximity() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not ("world_position" in player):
		return

	var player_pos: Vector2 = player.world_position
	var dx: float = (player_pos.x - position.x)
	var dy: float = (player_pos.y - position.y) * 2.0
	var dist := sqrt(dx * dx + dy * dy)

	var player_cell := Vector2i(int(floor(player_pos.x / 20.0)), int(floor(player_pos.y / 20.0)))
	var portal_cell := Vector2i(int(floor(position.x / 20.0)), int(floor(position.y / 20.0)))
	var cell_match := (player_cell == portal_cell)

	if dist <= trigger_radius or cell_match:
		if not _player_inside:
			_player_inside = true
			portal_triggered.emit(self, target_map_id, target_coords)
	else:
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		var dx := mouse_pos.x - position.x
		var dy := (mouse_pos.y - position.y) * 2.0
		if sqrt(dx * dx + dy * dy) <= trigger_radius:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("set_target_world_position"):
				player.set_target_world_position(position)
				get_viewport().set_input_as_handled()
