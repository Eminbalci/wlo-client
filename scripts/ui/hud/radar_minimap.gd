class_name RadarMinimap
extends Control

## Modern, responsive Wonderland Online Radar Minimap Dock (226x144).
## Supports clean zoom in/out with clamping, dynamic coordinate and map name tracking,
## blinking player indicator, portal dot overlays, waypoint routing,
## style collapse, and click-to-move input dispatch.

const MinimapMarker = preload("res://scripts/ui/minimap_marker.gd")
const MinimapWaypoint = preload("res://scripts/ui/minimap_waypoint.gd")

signal minimap_clicked(norm_pos: Vector2)
signal zoom_changed(new_zoom: float)
signal collapsed_changed(is_collapsed: bool)
signal waypoint_set(world_pos: Vector2)

# UI Node References
@onready var minimap_frame: TextureRect = $MinimapFrame if has_node("MinimapFrame") else null
@onready var minimap_view: TextureRect = $MinimapView if has_node("MinimapView") else null
@onready var map_name_label: Label = $MapNameLabel if has_node("MapNameLabel") else null
@onready var coord_label: Label = $CoordinatesLabel if has_node("CoordinatesLabel") else null
@onready var btn_zoom_in: Button = $BtnZoomIn if has_node("BtnZoomIn") else null
@onready var btn_zoom_out: Button = $BtnZoomOut if has_node("BtnZoomOut") else null
@onready var btn_minimap_toggle: Button = $BtnMinimapToggle if has_node("BtnMinimapToggle") else null
@onready var player_marker: Control = $MinimapView/PlayerMarker if has_node("MinimapView/PlayerMarker") else null
@onready var waypoint_marker: Control = $MinimapView/WaypointMarker if has_node("MinimapView/WaypointMarker") else null
@onready var portals_container: Control = $MinimapView/PortalsContainer if has_node("MinimapView/PortalsContainer") else null

# Map state
var current_map_id: int = 10001
var current_map_pixel_size: Vector2 = Vector2(2432, 1792)
var current_player_norm_pos: Vector2 = Vector2(0.5, 0.5)

# Blinking player dot state
var _minimap_blink_timer: float = 0.0
var _minimap_blink_is_yellow: bool = false

# Zoom & Collapse state
var minimap_zoom: float = 1.0
var _minimap_is_collapsed: bool = false
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 3.0
const ZOOM_STEP: float = 0.25

# Portal dots dictionary: { id: String, node: ColorRect }
var _portal_dots: Dictionary = {}

func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_RIGHT
	_load_textures()
	_setup_markers()
	_setup_portals_container()
	_connect_controls()
	update_coordinates_norm(current_player_norm_pos)

func _process(delta: float) -> void:
	_process_player_marker_blink(delta)

## Loads authentic textures for frame and initial map thumbnail
func _load_textures() -> void:
	var loader := _get_archive_loader()
	if loader:
		if minimap_frame and loader.has_method("get_ui_texture"):
			var mm_frame_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/MiniMapForm.bmp")
			if mm_frame_tex:
				minimap_frame.texture = mm_frame_tex
		if minimap_view and loader.has_method("get_minimap_texture"):
			var mm_tex: ImageTexture = loader.get_minimap_texture(current_map_id)
			if mm_tex:
				minimap_view.texture = mm_tex

## Ensures PlayerMarker and WaypointMarker controls exist inside MinimapView
func _setup_markers() -> void:
	if not minimap_view:
		return
	minimap_view.clip_contents = true
	
	if not player_marker:
		var marker_node = minimap_view.get_node_or_null("PlayerMarker")
		if not marker_node:
			marker_node = MinimapMarker.new()
			marker_node.name = "PlayerMarker"
			minimap_view.add_child(marker_node)
		player_marker = marker_node
		
	if not waypoint_marker:
		var wp_node = minimap_view.get_node_or_null("WaypointMarker")
		if not wp_node:
			wp_node = MinimapWaypoint.new()
			wp_node.name = "WaypointMarker"
			minimap_view.add_child(wp_node)
		waypoint_marker = wp_node
		waypoint_marker.visible = false

## Ensures PortalsContainer exists inside MinimapView
func _setup_portals_container() -> void:
	if not minimap_view:
		return
	if not portals_container:
		var p_node = minimap_view.get_node_or_null("PortalsContainer")
		if not p_node:
			p_node = Control.new()
			p_node.name = "PortalsContainer"
			p_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			minimap_view.add_child(p_node)
		portals_container = p_node

## Connects zoom, toggle, and view click signals
func _connect_controls() -> void:
	if btn_zoom_in and not btn_zoom_in.pressed.is_connected(_on_btn_zoom_in_pressed):
		btn_zoom_in.pressed.connect(_on_btn_zoom_in_pressed)
	if btn_zoom_out and not btn_zoom_out.pressed.is_connected(_on_btn_zoom_out_pressed):
		btn_zoom_out.pressed.connect(_on_btn_zoom_out_pressed)
	if btn_minimap_toggle and not btn_minimap_toggle.pressed.is_connected(_on_btn_minimap_toggle_pressed):
		btn_minimap_toggle.pressed.connect(_on_btn_minimap_toggle_pressed)
	if minimap_view and not minimap_view.gui_input.is_connected(_on_minimap_view_gui_input):
		minimap_view.gui_input.connect(_on_minimap_view_gui_input)

## Updates map thumbnail, map name and resets player position
func set_map(map_id: int, map_name: String, pixel_size: Vector2) -> void:
	current_map_id = map_id
	current_map_pixel_size = pixel_size
	if map_name_label:
		map_name_label.text = map_name
	
	var loader := _get_archive_loader()
	if loader and loader.has_method("get_minimap_texture") and minimap_view:
		var tex: ImageTexture = loader.get_minimap_texture(map_id)
		if tex:
			minimap_view.texture = tex
	clear_portal_dots()

## Updates coordinates from world position and map size
func update_coordinates(world_pos: Vector2, pixel_size: Vector2) -> void:
	current_map_pixel_size = pixel_size
	if pixel_size.x > 0.0 and pixel_size.y > 0.0:
		var norm_x: float = clampf(world_pos.x / pixel_size.x, 0.0, 1.0)
		var norm_y: float = clampf(world_pos.y / pixel_size.y, 0.0, 1.0)
		update_coordinates_norm(Vector2(norm_x, norm_y))
	else:
		if coord_label:
			coord_label.text = "(%d, %d)" % [int(world_pos.x), int(world_pos.y)]

## Updates coordinates and marker position from normalized (0..1) coords
func update_coordinates_norm(norm_pos: Vector2) -> void:
	current_player_norm_pos = norm_pos
	
	if coord_label:
		var wx: int = roundi(norm_pos.x * current_map_pixel_size.x)
		var wy: int = roundi(norm_pos.y * current_map_pixel_size.y)
		coord_label.text = "(%d, %d)" % [wx, wy]
		
	if player_marker and minimap_view:
		var view_sz: Vector2 = minimap_view.size
		if view_sz == Vector2.ZERO:
			view_sz = Vector2(212, 131)
		player_marker.position = Vector2(norm_pos.x * view_sz.x, norm_pos.y * view_sz.y)

## Handles mouse input on minimap view for click-to-move navigation
func _on_minimap_view_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not minimap_view:
			return
		var view_sz: Vector2 = minimap_view.size
		if view_sz.x <= 0.0 or view_sz.y <= 0.0:
			return
		var norm_x: float = clampf(event.position.x / view_sz.x, 0.0, 1.0)
		var norm_y: float = clampf(event.position.y / view_sz.y, 0.0, 1.0)
		var norm_pos := Vector2(norm_x, norm_y)
		
		if waypoint_marker:
			waypoint_marker.position = event.position
			waypoint_marker.visible = true
			if waypoint_marker.has_method("play_pulse"):
				waypoint_marker.play_pulse()
				
		var world_pos := Vector2(norm_x * current_map_pixel_size.x, norm_y * current_map_pixel_size.y)
		waypoint_set.emit(world_pos)
		minimap_clicked.emit(norm_pos)

## Zoom In (+) handler
func _on_btn_zoom_in_pressed() -> void:
	set_zoom(minimap_zoom + ZOOM_STEP)

## Zoom Out (-) handler
func _on_btn_zoom_out_pressed() -> void:
	set_zoom(minimap_zoom - ZOOM_STEP)

## Sets zoom level with clamping and updates view scale
func set_zoom(p_zoom: float) -> void:
	minimap_zoom = clampf(p_zoom, MIN_ZOOM, MAX_ZOOM)
	if minimap_view:
		minimap_view.pivot_offset = minimap_view.size * 0.5
		minimap_view.scale = Vector2(minimap_zoom, minimap_zoom)
	zoom_changed.emit(minimap_zoom)

## Minimap Toggle / Collapse button handler
func _on_btn_minimap_toggle_pressed() -> void:
	toggle_collapse()

## Toggles minimap collapse state
func toggle_collapse() -> void:
	_minimap_is_collapsed = not _minimap_is_collapsed
	if minimap_view:
		minimap_view.visible = not _minimap_is_collapsed
	if minimap_frame:
		minimap_frame.visible = not _minimap_is_collapsed
	collapsed_changed.emit(_minimap_is_collapsed)

## Adds or updates a portal dot marker on the minimap
func add_portal_dot(portal_id: String, norm_pos: Vector2, color: Color = Color(0.2, 0.7, 1.0)) -> void:
	if not portals_container:
		_setup_portals_container()
	if _portal_dots.has(portal_id):
		remove_portal_dot(portal_id)
		
	var dot := ColorRect.new()
	dot.name = "Portal_" + portal_id
	dot.size = Vector2(5, 5)
	dot.color = color
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var view_sz: Vector2 = minimap_view.size if minimap_view else Vector2(212, 131)
	dot.position = Vector2(norm_pos.x * view_sz.x - 2.5, norm_pos.y * view_sz.y - 2.5)
	portals_container.add_child(dot)
	_portal_dots[portal_id] = dot

## Removes a portal dot marker
func remove_portal_dot(portal_id: String) -> void:
	if _portal_dots.has(portal_id):
		var dot: Node = _portal_dots[portal_id]
		if dot and is_instance_valid(dot):
			if dot.get_parent():
				dot.get_parent().remove_child(dot)
			dot.queue_free()
		_portal_dots.erase(portal_id)

## Clears all portal dots
func clear_portal_dots() -> void:
	for id in _portal_dots.keys():
		var dot: Node = _portal_dots[id]
		if dot and is_instance_valid(dot):
			if dot.get_parent():
				dot.get_parent().remove_child(dot)
			dot.queue_free()
	_portal_dots.clear()

## Blinks the player marker color between green and yellow
func _process_player_marker_blink(delta: float) -> void:
	_minimap_blink_timer += delta
	if _minimap_blink_timer >= 0.4:
		_minimap_blink_timer = 0.0
		_minimap_blink_is_yellow = not _minimap_blink_is_yellow
		if player_marker:
			if player_marker.has_method("set_blinking_color"):
				player_marker.set_blinking_color(_minimap_blink_is_yellow)
			elif player_marker is ColorRect:
				(player_marker as ColorRect).color = Color(1.0, 0.92, 0.1, 1.0) if _minimap_blink_is_yellow else Color(0.15, 0.98, 0.2, 1.0)

func _get_archive_loader() -> Node:
	if is_inside_tree():
		var l := get_node_or_null("/root/ArchiveLoader")
		if l: return l
	if Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			return st.root.get_node_or_null("ArchiveLoader")
	return null
