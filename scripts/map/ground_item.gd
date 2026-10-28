class_name GroundItem
extends Node2D

## Interactive Ground Item entity in Wonderland Online.
## Displays authentic 32x32 icon bitmap from item.BMg via ArchiveLoader,
## gentle bobbing floating animation, hover tooltip, click detection,
## proximity pickup (dist <= 180px), and respawn timer loop.

signal item_clicked(item: GroundItem)
signal item_picked_up(item: GroundItem, player: Node2D)
signal item_respawned(item: GroundItem)
signal fly_finished()

@export var item_id: int = 0
@export var slot: int = 1
@export var click_id: int = 1
@export var item_name: String = ""
@export var icon_id: int = 0
@export var respawn_seconds: float = 120.0
@export var pickup_distance: float = 180.0

var is_picked_up: bool = false
var is_flying: bool = false
var respawn_timer: float = 0.0

var _anim_timer: float = 0.0
var _sprite: Sprite2D = null
var _label: Label = null

func _init() -> void:
	_setup_visuals()

func _ready() -> void:
	z_index = clampi(int(position.y), -4096, 4096) # Y-sorting
	_setup_visuals()
	_load_texture()

func _setup_visuals() -> void:
	if not _sprite:
		_sprite = Sprite2D.new()
		_sprite.name = "ItemIconSprite"
		_sprite.centered = true
		_sprite.position = Vector2(0, -6)
		add_child(_sprite)
	
	if not _label:
		_label = Label.new()
		_label.name = "ItemLabel"
		_label.text = item_name
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.offset_left = -60.0
		_label.offset_right = 60.0
		_label.offset_top = -34.0
		_label.offset_bottom = -14.0
		_label.add_theme_font_size_override("font_size", 10)
		_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9, 1.0))
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_label.add_theme_constant_override("outline_size", 3)
		_label.visible = false # Shows only on hover
		add_child(_label)
	
	_load_texture()

func _load_texture() -> void:
	if not is_inside_tree():
		return
	var root_node := get_tree().root if get_tree() else null
	if not root_node:
		return
	var loader = root_node.get_node_or_null("ArchiveLoader")
	if not loader:
		return
	
	# If icon_id is 0 or item name is short/default, query GameDatabase for authentic item info
	if item_id > 0:
		var db = root_node.get_node_or_null("GameDatabase")
		if db and db.items:
			var rec = db.items.get_item(item_id)
			if rec:
				if icon_id <= 0:
					icon_id = rec.icon_id
				if item_name.is_empty() or item_name.length() <= 2 or item_name == "Resource":
					item_name = rec.name
					if _label:
						_label.text = item_name
	
	if icon_id > 0 and loader.has_method("get_item_icon"):
		var tex: ImageTexture = loader.get_item_icon(icon_id)
		if tex and _sprite:
			_sprite.texture = tex

func set_item_data(p_id: int, p_slot: int, p_cid: int, p_name: String, p_respawn: float, p_icon: int = 0) -> void:
	item_id = p_id
	slot = p_slot
	click_id = p_cid
	item_name = p_name
	respawn_seconds = p_respawn
	icon_id = p_icon
	if _label:
		_label.text = item_name
	if is_inside_tree():
		_load_texture()

func _process(delta: float) -> void:
	if is_picked_up and not is_flying:
		respawn_timer += delta
		if respawn_timer >= respawn_seconds:
			respawn()
		return
	
	_anim_timer += delta
	# Fixed grounded position on the terrain, no mid-air floating/bobbing
	if _sprite and not is_flying:
		_sprite.position = Vector2(0, -6)
	
	# Hover detection: show name only when mouse hovers over item
	if not is_flying and not is_picked_up:
		var mouse_pos := get_global_mouse_position()
		var is_hovered := mouse_pos.distance_to(global_position + Vector2(0, -6)) <= 28.0
		if _label and _label.visible != is_hovered:
			_label.visible = is_hovered
	
	queue_redraw()

func _draw() -> void:
	if is_picked_up and not is_flying:
		return
	if is_flying:
		return
	# 2:1 axonometric ground shadow beneath item
	var shadow_col := Color(0, 0, 0, 0.35)
	_draw_iso_ellipse(Vector2(0, 2), 12.0, 6.0, shadow_col)
	
	# Blue glowing aura & subtle ground sparkles
	var pulse := (sin(_anim_timer * 3.0) + 1.0) * 0.5
	var aura_col := Color(0.2, 0.65, 1.0, 0.45 + 0.3 * pulse)
	_draw_iso_ring(Vector2(0, 2), 13.0 + pulse * 2.0, 6.5 + pulse * 1.0, aura_col, 1.8)
	
	# Sparkle glints
	for i in range(3):
		var angle := _anim_timer * 2.5 + float(i) * (TAU / 3.0)
		var sp_pos := Vector2(cos(angle) * 11.0, -6.0 + sin(angle) * 5.0)
		var sp_alpha := clampf((sin(_anim_timer * 4.0 + float(i) * 2.0) + 1.0) * 0.5, 0.25, 0.85)
		draw_circle(sp_pos, 1.5, Color(0.5, 0.85, 1.0, sp_alpha))

func _draw_iso_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	const SEGMENTS := 16
	for i in range(SEGMENTS):
		var theta := float(i) * (TAU / float(SEGMENTS))
		pts.append(center + Vector2(cos(theta) * rx, sin(theta) * ry))
	draw_colored_polygon(pts, col)

func _draw_iso_ring(center: Vector2, rx: float, ry: float, col: Color, width: float = 1.5) -> void:
	var pts := PackedVector2Array()
	const SEGMENTS := 20
	for i in range(SEGMENTS + 1):
		var theta := float(i) * (TAU / float(SEGMENTS))
		pts.append(center + Vector2(cos(theta) * rx, sin(theta) * ry))
	draw_polyline(pts, col, width, true)

func can_pickup(player: Node2D) -> bool:
	if not player or is_picked_up or is_flying:
		return false
	var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
	return p_pos.distance_to(position) <= pickup_distance

func fly_to(target_pos: Vector2, on_complete: Callable = Callable()) -> void:
	if is_flying:
		return
	is_flying = true
	if _label:
		_label.visible = false
	
	visible = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2(0.3, 0.3), 0.28).set_ease(Tween.EASE_IN)
	tw.chain().finished.connect(func():
		is_flying = false
		visible = false
		scale = Vector2.ONE
		fly_finished.emit()
		if on_complete.is_valid():
			on_complete.call()
	)

func try_pickup(player: Node2D) -> bool:
	if not can_pickup(player):
		return false
	is_picked_up = true
	is_flying = false
	visible = false
	scale = Vector2.ONE
	respawn_timer = 0.0
	item_picked_up.emit(self, player)
	return true

func respawn() -> void:
	is_picked_up = false
	is_flying = false
	visible = true
	scale = Vector2.ONE
	if _label:
		_label.visible = false
	respawn_timer = 0.0
	item_respawned.emit(self)

func _unhandled_input(event: InputEvent) -> void:
	if is_picked_up or is_flying:
		return
	
	if event is InputEventMouseMotion:
		var mouse_pos := get_global_mouse_position()
		var is_near := mouse_pos.distance_to(global_position + Vector2(0, -6)) <= 28.0
		if _label and _label.visible != is_near:
			_label.visible = is_near
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		if mouse_pos.distance_to(global_position + Vector2(0, -6)) <= 28.0:
			item_clicked.emit(self)
			get_viewport().set_input_as_handled()
