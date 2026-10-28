class_name HUDMinimap
extends RefCounted

## Sub-controller for Wonderland Online HUD Radar Minimap Dock (226x144).
## Encapsulates in-memory thumbnail extraction from map.JMG via ArchiveLoader,
## coordinate and map name tracking, blinking player marker, waypoint management,
## zoom in/out with clamping, collapse toggling, and click-to-move input.

const MinimapMarker = preload("res://scripts/ui/minimap_marker.gd")

signal minimap_clicked(norm_pos: Vector2)
signal zoom_changed(new_zoom: float)
signal collapsed_changed(is_collapsed: bool)

var _hud: Control = null

# Node references
var minimap_dock: Control = null
var minimap_frame: TextureRect = null
var minimap_view: TextureRect = null
var map_name_label: Label = null
var coord_label: Label = null
var player_marker: Control = null
var waypoint_marker: Control = null
var btn_zoom_in: Button = null
var btn_zoom_out: Button = null
var btn_minimap_toggle: Button = null

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

## Initializes references, loads authentic textures and hooks input events
func setup(hud: Control, nodes: Dictionary = {}) -> void:
	_hud = hud
	
	minimap_dock = nodes.get("minimap_dock", hud.get_node_or_null("RadarMinimapDock"))
	minimap_frame = nodes.get("minimap_frame", hud.get_node_or_null("RadarMinimapDock/MinimapFrame"))
	minimap_view = nodes.get("minimap_view", hud.get_node_or_null("RadarMinimapDock/MinimapView"))
	map_name_label = nodes.get("map_name_label", hud.get_node_or_null("RadarMinimapDock/MapNameLabel"))
	coord_label = nodes.get("coord_label", hud.get_node_or_null("RadarMinimapDock/CoordinatesLabel"))
	player_marker = nodes.get("player_marker", hud.get_node_or_null("RadarMinimapDock/MinimapView/PlayerMarker"))
	waypoint_marker = nodes.get("waypoint_marker", hud.get_node_or_null("RadarMinimapDock/MinimapView/WaypointMarker"))
	btn_zoom_in = nodes.get("btn_zoom_in", hud.get_node_or_null("RadarMinimapDock/BtnZoomIn"))
	btn_zoom_out = nodes.get("btn_zoom_out", hud.get_node_or_null("RadarMinimapDock/BtnZoomOut"))
	btn_minimap_toggle = nodes.get("btn_minimap_toggle", hud.get_node_or_null("RadarMinimapDock/BtnMinimapToggle"))
	
	_load_textures()
	_setup_markers()
	_connect_signals()

## Loads authentic textures for frame and initial map thumbnail from ArchiveLoader
func _load_textures() -> void:
	var loader: Node = null
	if _hud and _hud.is_inside_tree():
		loader = _hud.get_node_or_null("/root/ArchiveLoader")
	if not loader and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			loader = st.root.get_node_or_null("ArchiveLoader")
	
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
			var wp_script = load("res://scripts/ui/minimap_waypoint.gd")
			if wp_script:
				wp_node = Control.new()
				wp_node.set_script(wp_script)
				wp_node.name = "WaypointMarker"
				wp_node.visible = false
				minimap_view.add_child(wp_node)
		waypoint_marker = wp_node
	
	_update_marker_position()

## Connects button clicks and GUI input
func _connect_signals() -> void:
	if minimap_view and not minimap_view.gui_input.is_connected(on_gui_input):
		minimap_view.gui_input.connect(on_gui_input)
	
	if btn_zoom_in and not btn_zoom_in.pressed.is_connected(zoom_in):
		btn_zoom_in.pressed.connect(zoom_in)
	if btn_zoom_out and not btn_zoom_out.pressed.is_connected(zoom_out):
		btn_zoom_out.pressed.connect(zoom_out)
	if btn_minimap_toggle and not btn_minimap_toggle.pressed.is_connected(toggle_collapse):
		btn_minimap_toggle.pressed.connect(toggle_collapse)

## Per-frame update for player dot blinking state machine (green/yellow toggle every 0.25s)
func process(delta: float) -> void:
	if minimap_dock and minimap_dock.visible and player_marker and player_marker.visible:
		_minimap_blink_timer += delta
		if _minimap_blink_timer >= 0.25:
			_minimap_blink_timer = 0.0
			_minimap_blink_is_yellow = not _minimap_blink_is_yellow
			var dot_color: Color = Color(1.0, 0.92, 0.1, 1.0) if _minimap_blink_is_yellow else Color(0.15, 0.98, 0.2, 1.0)
			if player_marker.has_method("set_marker_color"):
				player_marker.set_marker_color(dot_color)
			else:
				player_marker.queue_redraw()

## Increments minimap zoom level
func zoom_in() -> void:
	set_zoom(minimap_zoom + 0.25)

## Decrements minimap zoom level
func zoom_out() -> void:
	set_zoom(minimap_zoom - 0.25)

## Sets minimap zoom level clamped between 0.75 and 2.5
func set_zoom(z: float) -> void:
	minimap_zoom = clampf(z, 0.75, 2.5)
	_apply_zoom()
	zoom_changed.emit(minimap_zoom)
	if _hud and _hud.has_signal("minimap_zoom_changed"):
		_hud.emit_signal("minimap_zoom_changed", minimap_zoom)

## Applies scale and pivot offset to MinimapView
func _apply_zoom() -> void:
	if not minimap_view:
		return
	var pivot: Vector2 = player_marker.position if player_marker and player_marker.visible else (minimap_view.size * 0.5)
	minimap_view.pivot_offset = pivot
	minimap_view.scale = Vector2(minimap_zoom, minimap_zoom)

## Toggles minimap expanded/collapsed visibility
func toggle_collapse() -> void:
	_minimap_is_collapsed = not _minimap_is_collapsed
	if minimap_view:
		minimap_view.visible = not _minimap_is_collapsed
	if minimap_frame:
		minimap_frame.visible = not _minimap_is_collapsed
	if coord_label:
		coord_label.visible = not _minimap_is_collapsed
	collapsed_changed.emit(_minimap_is_collapsed)
	if _hud and _hud.has_signal("minimap_collapsed_changed"):
		_hud.emit_signal("minimap_collapsed_changed", _minimap_is_collapsed)

## Places waypoint marker at normalized map position [0.0..1.0]
func set_waypoint(norm_pos: Vector2) -> void:
	if not waypoint_marker or not minimap_view:
		return
	var content_rect := get_content_rect()
	var pos_in_view := content_rect.position + Vector2(
		clampf(norm_pos.x, 0.0, 1.0) * content_rect.size.x,
		clampf(norm_pos.y, 0.0, 1.0) * content_rect.size.y
	)
	waypoint_marker.position = pos_in_view
	waypoint_marker.visible = true

## Clears and hides waypoint marker
func clear_waypoint() -> void:
	if waypoint_marker:
		waypoint_marker.visible = false

## Updates the radar minimap texture and player normalized position
func update_minimap(map_texture: Texture2D = null, player_norm_pos: Vector2 = Vector2(-1, -1)) -> void:
	if map_texture != null and minimap_view:
		minimap_view.texture = map_texture
	
	if player_norm_pos.x >= 0.0 and player_norm_pos.y >= 0.0:
		current_player_norm_pos = player_norm_pos
		_update_marker_position()

## Sets comprehensive map context on the minimap
func set_map_context(p_map_id: int, p_map_name: String, p_map_size: Vector2 = Vector2.ZERO, p_map_texture: Texture2D = null) -> void:
	current_map_id = p_map_id
	if p_map_size.x > 0 and p_map_size.y > 0:
		current_map_pixel_size = p_map_size
	if map_name_label:
		map_name_label.text = p_map_name
	
	var tex_to_apply: Texture2D = p_map_texture
	if tex_to_apply == null:
		var loader: Node = null
		if _hud and _hud.is_inside_tree():
			loader = _hud.get_node_or_null("/root/ArchiveLoader")
		if not loader and Engine.get_main_loop() is SceneTree:
			var st := Engine.get_main_loop() as SceneTree
			if st.root:
				loader = st.root.get_node_or_null("ArchiveLoader")
		if loader and loader.has_method("get_minimap_texture"):
			tex_to_apply = loader.get_minimap_texture(p_map_id)
	
	if tex_to_apply != null:
		update_minimap(tex_to_apply)

## Updates the map name label
func update_map_name(m_name: String) -> void:
	if map_name_label:
		map_name_label.text = m_name

## Sets both map name and player coordinates simultaneously
func set_map_info(p_map_name: String, p_coord_x: int, p_coord_y: int) -> void:
	update_map_name(p_map_name)
	update_coordinates(Vector2(p_coord_x, p_coord_y))

## Updates coordinate label and normalizes position to update player marker
func update_coordinates(world_pos: Vector2) -> void:
	if coord_label:
		coord_label.text = "(%d, %d)" % [int(world_pos.x), int(world_pos.y)]
	
	if current_map_pixel_size.x > 0 and current_map_pixel_size.y > 0:
		var norm := Vector2(
			clampf(world_pos.x / current_map_pixel_size.x, 0.0, 1.0),
			clampf(world_pos.y / current_map_pixel_size.y, 0.0, 1.0)
		)
		update_minimap(null, norm)

## Handles input on MinimapView for click-to-move pathfinding waypoint
func on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var content_rect := get_content_rect()
		var local_pos: Vector2 = event.position - content_rect.position
		if content_rect.size.x > 0 and content_rect.size.y > 0:
			var norm_x: float = clampf(local_pos.x / content_rect.size.x, 0.0, 1.0)
			var norm_y: float = clampf(local_pos.y / content_rect.size.y, 0.0, 1.0)
			var norm_pos := Vector2(norm_x, norm_y)
			set_waypoint(norm_pos)
			minimap_clicked.emit(norm_pos)
			if _hud and _hud.has_signal("minimap_clicked"):
				_hud.emit_signal("minimap_clicked", norm_pos)
			if _hud and _hud.get_viewport():
				_hud.get_viewport().set_input_as_handled()

## Calculates exact content draw rectangle inside MinimapView accounting for stretch mode
func get_content_rect() -> Rect2:
	if not minimap_view:
		return Rect2(Vector2.ZERO, Vector2(212, 131))
	var view_size: Vector2 = minimap_view.size
	if minimap_view.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and minimap_view.texture:
		var tex_size: Vector2 = minimap_view.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var scale_factor: float = minf(view_size.x / tex_size.x, view_size.y / tex_size.y)
			var draw_size: Vector2 = tex_size * scale_factor
			var draw_pos: Vector2 = (view_size - draw_size) * 0.5
			return Rect2(draw_pos, draw_size)
	return Rect2(Vector2.ZERO, view_size)

## Internal helper to update player dot marker position in view
func _update_marker_position() -> void:
	if not player_marker or not minimap_view:
		return
	var content_rect := get_content_rect()
	var pos_in_view := content_rect.position + Vector2(
		clampf(current_player_norm_pos.x, 0.0, 1.0) * content_rect.size.x,
		clampf(current_player_norm_pos.y, 0.0, 1.0) * content_rect.size.y
	)
	player_marker.position = pos_in_view
	player_marker.visible = true
