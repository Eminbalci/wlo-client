extends SceneTree

## Automated Headless Verification Suite for Radar Minimap & Player Indicator Dot

const HUDScene = preload("res://scenes/ui/hud.tscn")
const MapViewScene = preload("res://scenes/world/map_view.tscn")
const MinimapMarkerClass = preload("res://scripts/ui/minimap_marker.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test Radar Minimap & Player Indicator Suite ---")
	print("=================================================================")
	
	# Allow Autoload singletons (ArchiveLoader, GameDatabase) to initialize
	await process_frame
	
	_run_hud_unit_tests()
	await _run_map_view_integration_tests()
	
	print("\n=================================================================")
	print("--- ALL RADAR MINIMAP TESTS PASSED WITH ZERO ERRORS ---")
	print("=================================================================")
	quit(0)

func _run_hud_unit_tests() -> void:
	print("\n[PART 1] Verifying standalone HUD Radar Minimap...")
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	
	assert(hud != null, "HUD must instantiate")
	assert(hud.minimap_dock != null, "minimap_dock must exist")
	assert(hud.minimap_dock.visible == true, "minimap_dock must be visible by default")
	
	assert(hud.minimap_frame != null, "minimap_frame must exist")
	assert(hud.minimap_frame.texture != null, "minimap_frame texture must be loaded")
	
	assert(hud.minimap_view != null, "minimap_view must exist")
	assert(hud.minimap_view.texture != null, "minimap_view texture must not be null on init")
	assert(hud.minimap_view.texture.get_size() == Vector2(212, 131), "minimap_view texture must be 212x131")
	assert(hud.minimap_view.clip_contents == true, "minimap_view must clip contents")
	print("  PASS: Initial minimap_view texture loaded: size=%s" % str(hud.minimap_view.texture.get_size()))
	
	# Verify PlayerMarker
	var marker = hud.player_marker
	assert(marker != null, "player_marker must exist inside MinimapView")
	assert(marker.visible == true, "player_marker must be visible")
	assert(marker is MinimapMarkerClass, "player_marker must be instance of MinimapMarker")
	print("  PASS: PlayerMarker verified inside MinimapView")
	
	# Test update_minimap positioning
	var content_rect: Rect2 = hud.get_minimap_content_rect()
	assert(content_rect.size == Vector2(212, 131), "Content rect must be 212x131")
	
	# Top-left (0.0, 0.0)
	hud.update_minimap(null, Vector2(0.0, 0.0))
	assert(hud.player_marker.position.distance_to(content_rect.position) < 0.01, "Marker must be at top-left")
	
	# Center (0.5, 0.5)
	hud.update_minimap(null, Vector2(0.5, 0.5))
	var expected_center: Vector2 = content_rect.position + content_rect.size * 0.5
	assert(hud.player_marker.position.distance_to(expected_center) < 0.01, "Marker must be at center")
	
	# Bottom-right (1.0, 1.0)
	hud.update_minimap(null, Vector2(1.0, 1.0))
	var expected_br: Vector2 = content_rect.position + content_rect.size
	assert(hud.player_marker.position.distance_to(expected_br) < 0.01, "Marker must be at bottom-right")
	print("  PASS: PlayerMarker positioning calculations verified at (0,0), (0.5,0.5), (1,1)")
	
	# Test update_coordinates updates marker proportionally
	hud.current_map_pixel_size = Vector2(2432, 1792)
	hud.update_coordinates(Vector2(1216, 896)) # exactly half
	assert(hud.player_marker.position.distance_to(expected_center) < 0.5, "Marker must position proportionally via update_coordinates")
	assert(hud.coord_label.text == "(1216, 896)", "Coordinates label must match: got %s" % hud.coord_label.text)
	print("  PASS: update_coordinates updates label and marker proportionally")
	
	# Test blinking green/yellow
	var initial_color: Color = marker.marker_color
	hud._process(0.26)
	var toggled_color: Color = marker.marker_color
	assert(initial_color != toggled_color, "Marker color must toggle on blink timer")
	hud._process(0.26)
	var reverted_color: Color = marker.marker_color
	assert(reverted_color == initial_color, "Marker color must toggle back on next blink period")
	print("  PASS: Player marker blinking color toggle verified: %s <-> %s" % [str(initial_color), str(toggled_color)])
	
	# Test minimap click signal and waypoint marker
	var clicked_arr := [Vector2(-1, -1)]
	hud.minimap_clicked.connect(func(norm: Vector2): clicked_arr[0] = norm)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(106, 65.5)
	hud._on_minimap_gui_input(click_event)
	assert(clicked_arr[0].distance_to(Vector2(0.5, 0.5)) < 0.02, "Minimap click must emit normalized pos approx (0.5, 0.5)")
	assert(hud.waypoint_marker != null, "waypoint_marker must exist")
	assert(hud.waypoint_marker.visible == true, "waypoint_marker must be visible after click")
	assert(hud.waypoint_marker.position.distance_to(expected_center) < 2.0, "waypoint_marker position mismatch")
	hud.clear_minimap_waypoint()
	assert(hud.waypoint_marker.visible == false, "waypoint_marker must hide on clear")
	print("  PASS: Minimap click-to-move input handler and waypoint marker verified")

	# Test Zoom In (+)
	assert(hud.btn_zoom_in != null, "btn_zoom_in missing")
	var initial_zoom: float = hud.minimap_zoom
	hud.btn_zoom_in.pressed.emit()
	assert(hud.minimap_zoom == initial_zoom + 0.25, "Minimap zoom in factor mismatch")
	assert(hud.minimap_view.scale == Vector2(hud.minimap_zoom, hud.minimap_zoom), "Minimap view scale mismatch on zoom in")
	print("  PASS: Minimap Zoom In (+) verified (zoom=%f)" % hud.minimap_zoom)

	# Test Zoom Out (-)
	assert(hud.btn_zoom_out != null, "btn_zoom_out missing")
	hud.btn_zoom_out.pressed.emit()
	assert(hud.minimap_zoom == initial_zoom, "Minimap zoom out factor mismatch")
	assert(hud.minimap_view.scale == Vector2(initial_zoom, initial_zoom), "Minimap view scale mismatch on zoom out")
	print("  PASS: Minimap Zoom Out (-) verified (zoom=%f)" % hud.minimap_zoom)

	# Test Style Collapse Toggle
	assert(hud.btn_minimap_toggle != null, "btn_minimap_toggle missing")
	assert(hud._minimap_is_collapsed == false, "Minimap should start uncollapsed")
	hud.btn_minimap_toggle.pressed.emit()
	assert(hud._minimap_is_collapsed == true, "Minimap should collapse")
	assert(hud.minimap_view.visible == false, "MinimapView should be hidden when collapsed")
	hud.btn_minimap_toggle.pressed.emit()
	assert(hud._minimap_is_collapsed == false, "Minimap should re-expand")
	assert(hud.minimap_view.visible == true, "MinimapView should be visible when expanded")
	print("  PASS: Minimap toggle style collapse verified")

	hud.queue_free()

func _run_map_view_integration_tests() -> void:
	print("\n[PART 2] Verifying MapView real-time map changes & minimap updates...")
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	
	await process_frame
	await process_frame
	
	var hud = map_view.get_node_or_null("CanvasLayer/HUD")
	var map_renderer = map_view.get_node_or_null("MapRenderer")
	var player = map_view.get_node_or_null("Entities/Player")
	
	assert(hud != null, "HUD must exist in MapView")
	assert(map_renderer != null, "MapRenderer must exist in MapView")
	assert(player != null, "Player must exist in MapView")
	
	# Initial map: 10001 (Ship Deck)
	assert(map_renderer.current_map_id == 10001, "Initial map must be 10001")
	assert(hud.map_name_label.text == "Ship Deck", "HUD map name must be Ship Deck (got %s)" % hud.map_name_label.text)
	assert(hud.minimap_view.texture != null, "Ship Deck minimap texture must be non-null")
	assert(hud.minimap_view.texture.get_size() == Vector2(212, 131), "Ship Deck minimap size must be 212x131")
	var deck_texture: Texture2D = hud.minimap_view.texture
	print("  PASS: Map 10001 (Ship Deck) active: minimap texture=%s size=%s" % [deck_texture, str(deck_texture.get_size())])
	
	# Verify player marker position updates during movement
	var p_start_pos: Vector2 = player.world_position
	print("  Player initial position: %s, marker pos: %s" % [str(p_start_pos), str(hud.player_marker.position)])
	assert(hud.player_marker.visible == true, "Marker must be visible")
	var prev_marker_pos: Vector2 = hud.player_marker.position
	
	# Simulate player walking
	player.set_target_world_position(Vector2(1200, 1070))
	for f in range(10):
		await process_frame
	
	print("  Player in motion: %s, marker pos: %s" % [str(player.world_position), str(hud.player_marker.position)])
	assert(hud.player_marker.position != prev_marker_pos, "Marker must update in real-time as player moves")
	print("  PASS: Real-time player marker position updates verified during movement")
	
	# Trigger warp to 10002 (Cabin)
	print("\n  Triggering warp to Map 10002 (Cabin)...")
	var cabin_coords := Vector2(674.0, 1067.0)
	map_view._on_portal_triggered(null, 10002, cabin_coords)
	
	await process_frame
	await process_frame
	
	assert(map_renderer.current_map_id == 10002, "MapRenderer must switch to 10002")
	assert(hud.map_name_label.text == "Cabin", "HUD map name must update to Cabin (got %s)" % hud.map_name_label.text)
	assert(hud.minimap_view.texture != null, "Cabin minimap texture must be non-null")
	assert(hud.minimap_view.texture.get_size() == Vector2(212, 131), "Cabin minimap size must be 212x131")
	assert(hud.minimap_view.texture != deck_texture, "Minimap texture MUST update on map change and differ from Ship Deck!")
	
	var cabin_texture: Texture2D = hud.minimap_view.texture
	print("  PASS: Map 10002 (Cabin) active: minimap texture updated! (differs from 10001: %s != %s)" % [deck_texture, cabin_texture])
	
	# Verify player marker matches cabin spawn coordinates
	var expected_cabin_norm := Vector2(674.0 / 1659.0, 1067.0 / 1266.0) # (0.406, 0.843)
	var content_r: Rect2 = hud.get_minimap_content_rect()
	var expected_cabin_pos: Vector2 = content_r.position + expected_cabin_norm * content_r.size
	assert(hud.player_marker.position.distance_to(expected_cabin_pos) < 2.0, "Marker must position at cabin coordinates: got %s, expected %s" % [str(hud.player_marker.position), str(expected_cabin_pos)])
	print("  PASS: Cabin marker coordinates verified at %s" % str(hud.player_marker.position))
	
	map_view.queue_free()
